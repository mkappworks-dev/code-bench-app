import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/applied_change.dart';
import '../../features/chat/chat_notifier.dart';
import '../filesystem/filesystem_service.dart';

part 'apply_service.g.dart';

@Riverpod(keepAlive: true)
ApplyService applyService(Ref ref) {
  return ApplyService(
    fs: ref.watch(filesystemServiceProvider),
    notifier: ref.read(appliedChangesProvider.notifier),
  );
}

class ApplyService {
  ApplyService({
    required FilesystemService fs,
    required AppliedChanges notifier,
    String Function()? uuidGen,
  })  : _fs = fs,
        _notifier = notifier,
        _uuidGen = uuidGen ?? (() => const Uuid().v4());

  final FilesystemService _fs;
  final AppliedChanges _notifier;
  final String Function() _uuidGen;

  Future<void> applyChange({
    required String filePath,
    required String newContent,
    required String sessionId,
    required String messageId,
  }) async {
    String? originalContent;
    try {
      originalContent = await _fs.readFile(filePath);
    } catch (_) {
      // File doesn't exist — originalContent stays null
    }

    await _fs.writeFile(filePath, newContent);

    _notifier.apply(AppliedChange(
      id: _uuidGen(),
      sessionId: sessionId,
      messageId: messageId,
      filePath: filePath,
      originalContent: originalContent,
      newContent: newContent,
      appliedAt: DateTime.now(),
    ));
  }

  Future<void> revertChange({
    required AppliedChange change,
    required bool isGit,
    required String projectPath,
  }) async {
    if (change.originalContent == null) {
      // File was created by Apply — delete it
      await _fs.deleteFile(change.filePath);
    } else if (isGit) {
      await Process.run(
        'git',
        ['checkout', '--', change.filePath],
        workingDirectory: projectPath,
      );
    } else {
      await _fs.writeFile(change.filePath, change.originalContent!);
    }

    _notifier.revert(change.id);
  }
}
