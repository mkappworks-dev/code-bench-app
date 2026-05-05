import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/datasource/binary_resolver_process.dart';

part 'claude_cli_prompt_service.g.dart';

@Riverpod(keepAlive: true)
ClaudeCliPromptService claudeCliPromptService(Ref ref) => ClaudeCliPromptService();

// One-shot `claude -p` runner; binary path is cached after the first successful probe.
class ClaudeCliPromptService {
  String? _resolvedPath;
  String? _shellPath;

  // Returns null on any error — callers should fall back to a default value.
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
