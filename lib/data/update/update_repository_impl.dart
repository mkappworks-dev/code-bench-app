import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'datasource/update_datasource.dart';
import 'datasource/update_datasource_dio.dart';
import 'models/update_info.dart';
import 'update_repository.dart';

part 'update_repository_impl.g.dart';

@Riverpod(keepAlive: true)
UpdateRepository updateRepository(Ref ref) => UpdateRepositoryImpl(datasource: ref.watch(updateDatasourceProvider));

class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl({required UpdateDatasource datasource}) : _ds = datasource;

  final UpdateDatasource _ds;

  @override
  Future<UpdateInfo?> fetchLatestRelease() => _ds.fetchLatestRelease();

  @override
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  }) => _ds.downloadRelease(url: url, version: version, onProgress: onProgress);
}
