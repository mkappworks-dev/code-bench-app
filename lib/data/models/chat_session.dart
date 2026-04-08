import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_session.freezed.dart';
part 'chat_session.g.dart';

@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String sessionId,
    required String title,
    required String modelId,
    required String providerId,
    String? projectId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isPinned,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
}
