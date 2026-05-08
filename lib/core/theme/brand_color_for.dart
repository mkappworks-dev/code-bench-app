import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Maps a provider id (as stored on `ChatMessage.providerId` or
/// emitted by datasources) to its brand color. Same-vendor pairs
/// (`claude-cli`/`anthropic`, `codex`/`openai`) share a brand.
/// Returns `c.accent` for `custom`, unknown ids, or null.
Color brandColorFor(String? providerId, AppColors c) {
  return switch (providerId) {
    'claude-cli' || 'anthropic' => c.brandAnthropic,
    'codex' || 'openai' => c.brandOpenAI,
    'gemini' => c.brandGemini,
    'ollama' => c.brandOllama,
    _ => c.accent,
  };
}
