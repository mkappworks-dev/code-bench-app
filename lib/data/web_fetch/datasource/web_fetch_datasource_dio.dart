import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import 'web_fetch_datasource.dart';

class WebFetchDatasourceDio implements WebFetchDatasource {
  WebFetchDatasourceDio()
    : _dio = DioFactory.create(
        baseUrl: '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: false,
        headers: const {
          'User-Agent': 'CodeBench/1.0 (web fetch)',
          'Accept': 'text/html,text/plain,application/json,*/*',
        },
      );

  /// Test-only constructor that accepts a pre-configured [Dio] instance so
  /// tests can inject a fake [HttpClientAdapter] without hitting real URLs.
  @visibleForTesting
  WebFetchDatasourceDio.withDio(this._dio);

  final Dio _dio;

  static const int _kCap = 100000; // 100k chars — matches Claude Code's model-facing cap
  static const int _kMaxBytes = 5 * 1024 * 1024; // 5 MiB response body cap
  static const int _kMaxHops = 5; // redirect follow limit

  @override
  Future<String> fetch({required String url}) async {
    var currentUrl = url;

    for (var hop = 0; hop <= _kMaxHops; hop++) {
      final uri = _validateUri(currentUrl);
      await _ensureResolvedHostIsPublic(uri);

      final cancel = CancelToken();
      final Response<String> response;
      try {
        response = await _dio.get<String>(
          currentUrl,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: false,
            validateStatus: (s) => s != null && s < 400,
          ),
          cancelToken: cancel,
          onReceiveProgress: (received, _) {
            if (received > _kMaxBytes && !cancel.isCancelled) {
              cancel.cancel('size-cap');
            }
          },
        );
      } on DioException catch (e) {
        dLog('[WebFetchDatasourceDio] fetch failed: ${e.type} ${e.response?.statusCode} ${_safeUrl(currentUrl)}');
        if (e.type == DioExceptionType.cancel) {
          throw NetworkException('Response body exceeds ${_kMaxBytes ~/ 1024} KB limit');
        }
        throw NetworkException('Failed to fetch URL', statusCode: e.response?.statusCode, originalError: e);
      }

      final status = response.statusCode ?? 0;
      if (status >= 300 && status < 400) {
        currentUrl = _resolveRedirect(currentUrl, response, status);
        continue;
      }

      final body = response.data;
      if (body == null) {
        dLog('[WebFetchDatasourceDio] null response body status=$status ${_safeUrl(currentUrl)}');
        throw NetworkException('Server returned an empty response body', statusCode: status);
      }
      return _processBody(body, response, currentUrl);
    }

    throw NetworkException('Too many redirects (> $_kMaxHops)');
  }

  /// Parses [url], validates scheme, and runs the literal SSRF guard on the
  /// host. Throws [ArgumentError] on any failure.
  Uri _validateUri(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ArgumentError('Invalid URL: $url');
    }
    if (!{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      throw ArgumentError('Only http and https URLs are supported. Got: ${uri.scheme}');
    }
    if (isPrivateHost(uri.host)) {
      sLog('[WebFetchDatasourceDio] SSRF blocked (literal): ${uri.scheme}://${uri.host}');
      throw ArgumentError('Fetching private or internal network addresses is not allowed.');
    }
    return uri;
  }

  /// Resolves [uri.host] via DNS and rejects if any resolved address is
  /// private/loopback/link-local/multicast/CGNAT (checked through
  /// [isPrivateHost]).
  ///
  /// Note: this closes the numeric-encoding bypass class (`2130706433`,
  /// `0x7f000001`, `127.1`, `127.0.0.1.nip.io`, etc.) because the OS resolver
  /// normalises those to a real IP which we then re-check. It does NOT
  /// prevent DNS rebinding — the name could resolve to a different IP at
  /// Dio's connect time. That race requires IP pinning or outbound firewall
  /// rules and is out of scope here.
  Future<void> _ensureResolvedHostIsPublic(Uri uri) async {
    final stripped = _stripBrackets(uri.host.toLowerCase());
    // Already an IP literal → _validateUri already ran isPrivateHost on it.
    if (InternetAddress.tryParse(stripped) != null) return;

    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(stripped);
    } on SocketException catch (e) {
      dLog('[WebFetchDatasourceDio] DNS lookup failed host=${uri.host} msg=${e.message}');
      throw NetworkException('DNS lookup failed for ${uri.host}', originalError: e);
    }
    if (addresses.isEmpty) {
      throw NetworkException('Host ${uri.host} could not be resolved');
    }
    for (final addr in addresses) {
      if (isPrivateHost(addr.address)) {
        sLog(
          '[WebFetchDatasourceDio] SSRF blocked (post-resolution): '
          '${uri.scheme}://${uri.host} → ${addr.address}',
        );
        throw ArgumentError('Fetching private or internal network addresses is not allowed.');
      }
    }
  }

  /// Pulls the `Location` header from a 3xx [response] and returns the
  /// absolute redirect target resolved against [currentUrl].
  /// Throws [NetworkException] when the header is missing or malformed.
  String _resolveRedirect(String currentUrl, Response<String> response, int status) {
    final location = response.headers.value('location');
    if (location == null || location.isEmpty) {
      throw NetworkException('Redirect response missing Location header', statusCode: status);
    }
    final next = Uri.tryParse(location);
    if (next == null) {
      throw NetworkException('Redirect Location is not a valid URL', statusCode: status);
    }
    final resolved = next.hasScheme ? next : Uri.parse(currentUrl).resolveUri(next);
    return resolved.toString();
  }

  /// Decodes a 2xx response body based on content-type. HTML → text
  /// extraction; text/json/xml → pass-through capped at 100k chars;
  /// anything else → [NetworkException].
  String _processBody(String body, Response<String> response, String url) {
    final contentType = (response.headers.value('content-type') ?? '').toLowerCase();

    if (contentType.contains('text/html') || contentType.isEmpty) {
      return htmlToText(body);
    }
    if (contentType.startsWith('text/') ||
        contentType.contains('application/json') ||
        contentType.contains('application/xml') ||
        contentType.contains('+json') ||
        contentType.contains('+xml')) {
      return _cap(body);
    }
    final mime = contentType.split(';').first.trim();
    dLog('[WebFetchDatasourceDio] unsupported content-type=$mime ${_safeUrl(url)}');
    throw NetworkException('web_fetch only supports text content. The URL returned $mime.');
  }

  /// Returns [url] with query string stripped — safe for log output.
  /// Query strings can carry OAuth tokens / session ids and must not leak.
  static String _safeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '<unparseable>';
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
  }

  static String _stripBrackets(String host) {
    return host.startsWith('[') && host.endsWith(']') ? host.substring(1, host.length - 1) : host;
  }

  /// Returns true when [host] is a loopback, link-local, multicast, CGNAT,
  /// or RFC-1918 private address. **Literal parsing only** — no DNS
  /// resolution. Callers that need DNS-aware rejection should additionally
  /// resolve the hostname and re-check each returned address.
  ///
  /// Loopback / link-local / multicast for both IPv4 and IPv6 come from
  /// [InternetAddress]. RFC-1918, CGNAT, and `0.0.0.0` are not classified by
  /// `dart:io` and stay as explicit checks.
  static bool isPrivateHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost') return true;

    final stripped = _stripBrackets(h);

    final addr = InternetAddress.tryParse(stripped);
    if (addr == null) return false;

    if (addr.isLoopback || addr.isLinkLocal || addr.isMulticast) return true;
    if (addr.address == '0.0.0.0' || addr.address == '::') return true;

    if (addr.type == InternetAddressType.IPv4) {
      final p = addr.address.split('.').map(int.parse).toList();
      if (p[0] == 10) return true;
      if (p[0] == 192 && p[1] == 168) return true;
      if (p[0] == 172 && p[1] >= 16 && p[1] <= 31) return true;
      if (p[0] == 100 && p[1] >= 64 && p[1] <= 127) return true; // CGNAT 100.64.0.0/10
      if (p[0] == 255 && p[1] == 255 && p[2] == 255 && p[3] == 255) return true; // broadcast
    }

    // IPv4-mapped IPv6 (::ffff:a.b.c.d) bypasses isLoopback/isLinkLocal —
    // extract the embedded IPv4 and re-check.
    if (addr.type == InternetAddressType.IPv6) {
      final raw = addr.rawAddress;
      final isMapped = raw.length == 16 && raw.take(10).every((b) => b == 0) && raw[10] == 0xff && raw[11] == 0xff;
      if (isMapped) {
        return isPrivateHost('${raw[12]}.${raw[13]}.${raw[14]}.${raw[15]}');
      }
    }

    return false;
  }

  /// Converts an HTML string to readable markdown-ish plain text.
  /// Removes script, style, nav, footer, header, noscript, and iframe.
  /// Preserves headings, links, code blocks, lists, and bold/italic inline markers.
  static String htmlToText(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    for (final tag in ['script', 'style', 'nav', 'footer', 'header', 'noscript', 'iframe']) {
      document.querySelectorAll(tag).forEach((el) => el.remove());
    }

    final buf = StringBuffer();
    final root = document.body ?? document.documentElement;
    if (root != null) _nodeToText(root, buf);
    return _cap(buf.toString().trim());
  }

  static void _nodeToText(dom.Element el, StringBuffer buf) {
    for (final node in el.nodes) {
      if (node is dom.Text) {
        final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.trim().isNotEmpty) buf.write(text);
        continue;
      }
      if (node is! dom.Element) continue;

      switch (node.localName) {
        case 'h1':
          buf.write('\n\n# ');
          _nodeToText(node, buf);
          buf.write('\n\n');
        case 'h2':
          buf.write('\n\n## ');
          _nodeToText(node, buf);
          buf.write('\n\n');
        case 'h3':
          buf.write('\n\n### ');
          _nodeToText(node, buf);
          buf.write('\n\n');
        case 'h4' || 'h5' || 'h6':
          buf.write('\n\n#### ');
          _nodeToText(node, buf);
          buf.write('\n\n');
        case 'p' || 'div' || 'section' || 'article' || 'main':
          buf.write('\n');
          _nodeToText(node, buf);
          buf.write('\n');
        case 'br':
          buf.write('\n');
        case 'li':
          buf.write('\n- ');
          _nodeToText(node, buf);
        case 'a':
          final href = node.attributes['href'];
          final inner = StringBuffer();
          _nodeToText(node, inner);
          final text = inner.toString().trim();
          if (href != null && href.isNotEmpty && text.isNotEmpty) {
            buf.write('[$text]($href)');
          } else {
            buf.write(text);
          }
        case 'pre':
          buf.write('\n```\n');
          buf.write(node.text.trim());
          buf.write('\n```\n');
        case 'code':
          buf.write('`');
          buf.write(node.text);
          buf.write('`');
        case 'strong' || 'b':
          buf.write('**');
          _nodeToText(node, buf);
          buf.write('**');
        case 'em' || 'i':
          buf.write('_');
          _nodeToText(node, buf);
          buf.write('_');
        case 'hr':
          buf.write('\n---\n');
        default:
          _nodeToText(node, buf);
      }
    }
  }

  static String _cap(String text) {
    if (text.length <= _kCap) return text;
    return '${text.substring(0, _kCap)}\n[Content truncated at 100k characters]';
  }
}
