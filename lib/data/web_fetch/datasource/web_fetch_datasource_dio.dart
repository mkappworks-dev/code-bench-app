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

  @override
  Future<String> fetch({required String url}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ArgumentError('Invalid URL: $url');
    }
    if (!{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      throw ArgumentError('Only http and https URLs are supported. Got: ${uri.scheme}');
    }
    if (isPrivateHost(uri.host)) {
      sLog('[WebFetchDatasourceDio] SSRF blocked: $url');
      throw ArgumentError('Fetching private or internal network addresses is not allowed.');
    }

    final Response<String> response;
    try {
      response = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
    } on DioException catch (e) {
      dLog('[WebFetchDatasourceDio] fetch failed: ${e.type} ${e.response?.statusCode} $url');
      throw NetworkException('Failed to fetch URL', statusCode: e.response?.statusCode, originalError: e);
    }

    final body = response.data ?? '';
    final contentType = (response.headers.value('content-type') ?? '').toLowerCase();

    if (contentType.contains('text/html') || contentType.isEmpty) {
      return htmlToText(body);
    }
    // text/*, application/json, application/*+json, application/xml, application/*+xml
    if (contentType.startsWith('text/') ||
        contentType.contains('application/json') ||
        contentType.contains('application/xml') ||
        contentType.contains('+json') ||
        contentType.contains('+xml')) {
      return _cap(body);
    }
    final mime = contentType.split(';').first.trim();
    throw ArgumentError('web_fetch only supports text content. The URL returned $mime.');
  }

  /// Returns true when [host] is a loopback or RFC-1918 private address.
  /// Uses string matching only — no DNS resolution.
  static bool isPrivateHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h == '[::1]' || h == '::1') return true;

    final parts = h.split('.');
    if (parts.length != 4) return false;

    final octets = parts.map(int.tryParse).toList();
    if (octets.any((o) => o == null)) return false;

    final a = octets[0]!, b = octets[1]!;
    if (a == 127) return true;
    if (a == 0) return true;
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 169 && b == 254) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;

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
