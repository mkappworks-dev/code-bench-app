import '../models/update_info.dart';

abstract interface class UpdateDatasource {
  Future<UpdateInfo?> fetchLatestRelease();
  Future<String> downloadRelease({
    required String url,
    required String version,
    required void Function(int received, int total) onProgress,
  });
}
