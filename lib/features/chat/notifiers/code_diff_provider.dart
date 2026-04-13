import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/apply/repository/apply_repository_impl.dart';

part 'code_diff_provider.freezed.dart';
part 'code_diff_provider.g.dart';

@freezed
abstract class DiffResult with _$DiffResult {
  const factory DiffResult({required String? originalContent, required List<Diff> diffs}) = _DiffResult;
}

/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).
@riverpod
Future<DiffResult?> codeDiff(
  Ref ref, {
  required String absolutePath,
  required String projectPath,
  required String newContent,
}) async {
  try {
    final original = await ref.read(applyRepositoryProvider).readOriginalForDiff(absolutePath, projectPath);
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(original ?? '', newContent);
    dmp.diffCleanupSemantic(diffs);
    return DiffResult(originalContent: original, diffs: diffs);
  } on StateError {
    return null;
  } on IOException {
    return null;
  } catch (_) {
    return null;
  }
}
