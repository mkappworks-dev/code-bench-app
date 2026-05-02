// lib/data/update/datasource/update_datasource_dio.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/update_constants.dart';
import '../../../core/utils/debug_logger.dart';
import '../../_core/http/dio_factory.dart';
import '../models/update_info.dart';
import '../update_exception.dart';
import 'update_datasource.dart';

part 'update_datasource_dio.g.dart';

/// Hosts allowed to serve the GitHub releases *metadata* API. Re-asserted
/// against every redirect hop and the final URL.
const _kAllowedApiHosts = {'api.github.com'};

/// Hosts allowed to serve the *asset zip* download. The asset URL comes from
/// release metadata (release-author controlled), so the allowlist is the
/// integrity boundary. Re-asserted against every redirect hop and the final
/// URL — an off-allowlist intermediate could otherwise proxy attacker bytes
/// through a final-allowed CDN.
const _kAllowedDownloadHosts = {
  'github.com',
  'objects.githubusercontent.com',
  'github-releases.githubusercontent.com',
  'release-assets.githubusercontent.com',
};

/// Path prefix the `github.com` host is pinned to. `browser_download_url` is
/// release-author controlled, so without this pin a compromised publisher
/// could point downloads at any github.com path (other repos, gists, etc.).
final _kGithubReleasePathPrefix = '/$kGithubOwner/$kGithubRepo/releases/download/';

@Riverpod(keepAlive: true)
UpdateDatasource updateDatasource(Ref ref) => UpdateDatasourceDio();

class UpdateDatasourceDio implements UpdateDatasource {
  UpdateDatasourceDio()
    : _dio = DioFactory.create(
        baseUrl: '',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

  final Dio _dio;

  @override
  Future<UpdateInfo?> fetchLatestRelease() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$kGithubOwner/$kGithubRepo/releases/latest',
      );
      _assertAllowedRedirectChain(response, allowed: _kAllowedApiHosts);

      final data = response.data;
      if (data == null) {
        sLog('[UpdateDatasource] fetchLatestRelease: empty response body');
        throw const UpdateNetworkException('Empty response from GitHub releases API.');
      }

      try {
        final tagName = (data['tag_name'] as String?) ?? '';
        final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        if (version.isEmpty) return null;

        final assets = (data['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final asset = assets.cast<Map<String, dynamic>?>().firstWhere(
          (a) => a != null && a['name'] == kUpdateAssetName,
          orElse: () => null,
        );
        if (asset == null) {
          // Treat a tagged release that ships no matching asset as a real
          // error — silently returning "no update" hides a config bug.
          throw UpdateNetworkException('Release $tagName has no asset named "$kUpdateAssetName".');
        }
        final downloadUrl = asset['browser_download_url'] as String?;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          throw UpdateNetworkException('Release $tagName asset has no browser_download_url.');
        }
        _assertAllowedHost(downloadUrl, allowed: _kAllowedDownloadHosts);

        final publishedAtRaw = data['published_at'] as String?;
        // Tolerate malformed/missing published_at — release usability shouldn't
        // hinge on a timestamp the UI only renders informationally.
        final publishedAt = (publishedAtRaw == null ? null : DateTime.tryParse(publishedAtRaw)) ?? DateTime.now();

        return UpdateInfo(
          version: version,
          releaseNotes: data['body'] as String? ?? '',
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
        );
      } on UpdateException {
        rethrow;
      } catch (e, st) {
        dLog('[UpdateDatasource] malformed release payload: ${e.runtimeType}: $e\n$st');
        throw UpdateNetworkException('Malformed release payload from GitHub (${e.runtimeType}).');
      }
    } on DioException catch (e, st) {
      // 404 = no published release yet; not an error condition for the caller.
      if (e.response?.statusCode == 404) return null;
      dLog('[UpdateDatasource] fetchLatestRelease failed: $e\n$st');
      throw UpdateNetworkException(e.message);
    }
  }

  @override
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  }) async {
    _assertAllowedHost(url, allowed: _kAllowedDownloadHosts);
    // Randomised tempdir per attempt — defeats predictable-path symlink
    // pre-planting on the zip download path.
    final tempDir = await Directory.systemTemp.createTemp('cb-update-zip-');
    final savePath = '${tempDir.path}/cb-update-$version.zip';
    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
      // Re-assert allowlist on every redirect hop and the final URL. If any
      // intermediate or the destination is off-allowlist, refuse the bytes we
      // just wrote — bouncing through an attacker host before landing at a
      // real GitHub asset URL would otherwise pass a final-only check.
      try {
        _assertAllowedRedirectChain(response, allowed: _kAllowedDownloadHosts);
      } on UpdateException {
        try {
          await File(savePath).delete();
        } catch (e) {
          dLog('[UpdateDatasource] cleanup of $savePath after redirect rejection failed: $e');
        }
        rethrow;
      }
      return savePath;
    } on DioException catch (e, st) {
      dLog('[UpdateDatasource] downloadRelease failed: $e\n$st');
      throw UpdateDownloadException(e.message);
    }
  }

  /// Validates every redirect hop and the final URL against [allowed].
  /// Dio's default `followRedirects: true` only exposes the final URL via
  /// `realUri`; without per-hop checks an attacker-controlled intermediate
  /// could proxy bytes before bouncing to a real allowlisted host.
  void _assertAllowedRedirectChain(Response<dynamic> response, {required Set<String> allowed}) {
    for (final redirect in response.redirects) {
      _assertAllowedHost(redirect.location.toString(), allowed: allowed);
    }
    _assertAllowedHost(response.realUri.toString(), allowed: allowed);
  }

  void _assertAllowedHost(String rawUrl, {required Set<String> allowed}) {
    final uri = Uri.tryParse(rawUrl);
    final basicallyOk =
        uri != null &&
        uri.scheme == 'https' &&
        // Defense-in-depth against authority-confusion parses
        // (`https://allowed@evil.com/`, `https://allowed#@evil.com/`).
        uri.userInfo.isEmpty &&
        !uri.hasFragment &&
        allowed.contains(uri.host);
    // `browser_download_url` is release-author controlled, so on github.com
    // (the one host that serves arbitrary user content) pin owner/repo path.
    final pathOk = !basicallyOk || uri.host != 'github.com' || uri.path.startsWith(_kGithubReleasePathPrefix);
    if (!basicallyOk || !pathOk) {
      sLog('[UpdateDatasource] Refusing non-allowlisted update URL: $rawUrl');
      throw UpdateNetworkException('Update URL is not from an allowlisted host: ${uri?.host ?? "(unparseable)"}');
    }
  }
}
