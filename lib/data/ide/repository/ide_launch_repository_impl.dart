import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/_core/preferences/general_preferences.dart';
import '../datasource/ide_launch_datasource.dart';
import '../datasource/ide_launch_datasource_process.dart';
import 'ide_launch_repository.dart';

part 'ide_launch_repository_impl.g.dart';

@Riverpod(keepAlive: true)
IdeLaunchRepository ideLaunchRepository(Ref ref) {
  return IdeLaunchRepositoryImpl(
    datasource: ref.watch(ideLaunchDatasourceProvider),
    prefs: ref.watch(generalPreferencesProvider),
  );
}

class IdeLaunchRepositoryImpl implements IdeLaunchRepository {
  IdeLaunchRepositoryImpl({required IdeLaunchDatasource datasource, required GeneralPreferences prefs})
    : _ds = datasource,
      _prefs = prefs;

  final IdeLaunchDatasource _ds;
  final GeneralPreferences _prefs;

  @override
  Future<String?> openVsCode(String path) => _ds.openVsCode(path);

  @override
  Future<String?> openCursor(String path) => _ds.openCursor(path);

  @override
  Future<String?> openInFinder(String path) => _ds.openInFinder(path);

  @override
  Future<String?> openInTerminal(String path) async {
    final app = await _prefs.getTerminalApp();
    return _ds.openInTerminal(path, app);
  }
}
