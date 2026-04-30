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
      final data = response.data!;
      final tagName = (data['tag_name'] as String? ?? '');
      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      if (version.isEmpty) return null;
      final assets = (data['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final asset = assets.firstWhere((a) => a['name'] == kUpdateAssetName, orElse: () => {});
      final downloadUrl = asset['browser_download_url'] as String?;
      if (downloadUrl == null) return null;
      return UpdateInfo(
        version: version,
        releaseNotes: data['body'] as String? ?? '',
        downloadUrl: downloadUrl,
        publishedAt: DateTime.parse(data['published_at'] as String),
      );
    } on DioException catch (e, st) {
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
    final savePath = '${Directory.systemTemp.path}/cb-update-$version.zip';
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
      return savePath;
    } on DioException catch (e, st) {
      dLog('[UpdateDatasource] downloadRelease failed: $e\n$st');
      throw UpdateDownloadException(e.message);
    }
  }
}
