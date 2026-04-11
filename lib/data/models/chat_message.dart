import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageRole {
  user,
  assistant,
  system;

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
    required DateTime timestamp,
    @Default(false) bool isStreaming,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
