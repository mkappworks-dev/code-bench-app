import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/datasource/binary_resolver_process.dart';

part 'claude_cli_prompt_service.g.dart';

@Riverpod(keepAlive: true)
ClaudeCliPromptService claudeCliPromptService(Ref ref) => ClaudeCliPromptService();

/// Runs one-shot `claude -p "..."` invocations for features that need a
/// single AI-generated text response without a persistent chat session
/// (e.g. PR title/body generation when Anthropic is configured via the
/// Claude Code CLI transport instead of a direct API key).
///
/// Binary resolution is cached after the first successful probe so
/// repeated calls within the same session skip the shell round-trip.
class ClaudeCliPromptService {
  String? _resolvedPath;
  String? _shellPath;

  /// Sends [prompt] to the local `claude` binary in one-shot (`-p`) mode
  /// and returns the trimmed plain-text response.  Returns `null` when the
  /// binary cannot be located, the process exits non-zero, or any other
  /// error occurs — callers should treat `null` as "use fallback".
  Future<String?> generate(String prompt) async {
    try {
      if (_resolvedPath == null) {
        final resolution = await resolveBinary('claude');
        if (resolution is! BinaryFound) {
          dLog('[ClaudeCliPromptService] claude binary not found: ${resolution.runtimeType}');
          return null;
        }
        _resolvedPath = resolution.path;
        _shellPath = resolution.shellPath;
      }

      final env = _shellPath != null ? {...Platform.environment, 'PATH': _shellPath!} : null;

      final result = await Process.run(_resolvedPath!, [
        '-p',
        prompt,
        '--output-format',
        'text',
      ], environment: env).timeout(const Duration(seconds: 30));

      if (result.exitCode != 0) {
        dLog('[ClaudeCliPromptService] claude exited ${result.exitCode}');
        return null;
      }

      final text = (result.stdout as String).trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      dLog('[ClaudeCliPromptService] generate failed: ${e.runtimeType}');
      return null;
    }
  }
}
