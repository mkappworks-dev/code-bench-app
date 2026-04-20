import 'package:freezed_annotation/freezed_annotation.dart';

import '../session/models/ask_user_question.dart';
import '../session/models/permission_request.dart';
import '../session/models/tool_event.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageRole {
  user,
  assistant,
  system,
  interrupted;

  String get value => name;
}

@freezed
abstract class CodeBlock with _$CodeBlock {
  const factory CodeBlock({required String code, String? language, String? filename}) = _CodeBlock;

  factory CodeBlock.fromJson(Map<String, dynamic> json) => _$CodeBlockFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String sessionId,
    required MessageRole role,
    required String content,
    @Default([]) List<CodeBlock> codeBlocks,
    @Default([]) List<ToolEvent> toolEvents,
    required DateTime timestamp,
    @Default(false) bool isStreaming,
    AskUserQuestion? askQuestion,
    @Default(false) bool iterationCapReached,
    PermissionRequest? pendingPermissionRequest,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
