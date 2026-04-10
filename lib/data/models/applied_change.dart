import 'package:freezed_annotation/freezed_annotation.dart';

part 'applied_change.freezed.dart';

@freezed
class AppliedChange with _$AppliedChange {
  const factory AppliedChange({
    required String id, // uuid
    required String sessionId,
    required String messageId, // ChatMessage that contained the code block
    required String filePath, // absolute path on disk
    String? originalContent, // null = file didn't exist before Apply
    required String newContent, // content that was written to disk
    required DateTime appliedAt,
  }) = _AppliedChange;
}
