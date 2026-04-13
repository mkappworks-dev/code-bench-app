import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ide/repository/ide_launch_repository.dart';
import '../../data/ide/repository/ide_launch_repository_impl.dart';
import 'ide_exceptions.dart';

export 'ide_exceptions.dart';

part 'ide_service.g.dart';

@Riverpod(keepAlive: true)
IdeService ideService(Ref ref) {
  return IdeService(repo: ref.watch(ideLaunchRepositoryProvider));
}

/// Converts nullable `String?` error returns from [IdeLaunchRepository]
/// into typed [IdeLaunchFailedException] throws.
class IdeService {
  IdeService({required IdeLaunchRepository repo}) : _repo = repo;

  final IdeLaunchRepository _repo;

  Future<void> openVsCode(String path) async {
    final error = await _repo.openVsCode(path);
    if (error != null) {
      dLog('[IdeService] openVsCode failed: $error');
      throw IdeLaunchFailedException('VS Code', path, error);
    }
  }

  Future<void> openCursor(String path) async {
    final error = await _repo.openCursor(path);
    if (error != null) {
      dLog('[IdeService] openCursor failed: $error');
      throw IdeLaunchFailedException('Cursor', path, error);
    }
  }

  Future<void> openInFinder(String path) async {
    final error = await _repo.openInFinder(path);
    if (error != null) {
      dLog('[IdeService] openInFinder failed: $error');
      throw IdeLaunchFailedException('Finder', path, error);
    }
  }

  Future<void> openInTerminal(String path) async {
    final error = await _repo.openInTerminal(path);
    if (error != null) {
      dLog('[IdeService] openInTerminal failed: $error');
      throw IdeLaunchFailedException('Terminal', path, error);
    }
  }
}
