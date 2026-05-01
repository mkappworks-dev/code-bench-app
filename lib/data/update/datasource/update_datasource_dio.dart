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

/// Hosts the update path is allowed to fetch from. Validated against both the
/// release-API endpoint and the asset download URL (which is release-author
/// controlled and could otherwise point anywhere). Also re-asserted against
/// `Response.realUri` after redirects to catch a CDN-redirect off-allowlist.
const _kAllowedDownloadHosts = {
  'github.com',
  'objects.githubusercontent.com',
  'github-releases.githubusercontent.com',
  'release-assets.githubusercontent.com',
};

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
      // Re-assert allowlist on the *final* URL after any redirects.
      _assertAllowedHost(response.realUri.toString());

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
        _assertAllowedHost(downloadUrl);

        final publishedAtRaw = data['published_at'] as String?;
        final publishedAt = publishedAtRaw == null ? DateTime.now() : DateTime.parse(publishedAtRaw);

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
    _assertAllowedHost(url);
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
      // Re-assert allowlist on the *final* URL after any redirects. If the
      // CDN ever redirects off-allowlist, refuse the bytes we just wrote.
      try {
        _assertAllowedHost(response.realUri.toString());
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

  void _assertAllowedHost(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https' || !_kAllowedDownloadHosts.contains(uri.host)) {
      sLog('[UpdateDatasource] Refusing non-allowlisted update URL: $rawUrl');
      throw UpdateNetworkException('Update URL is not from an allowlisted host: ${uri?.host ?? "(unparseable)"}');
    }
  }
}
