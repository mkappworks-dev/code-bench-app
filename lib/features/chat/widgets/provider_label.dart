String? providerLabelFor(String? providerId) {
  if (providerId == null || providerId.isEmpty) return null;
  return switch (providerId) {
    'claude-cli' => 'Claude Code CLI',
    'codex' => 'Codex CLI',
    'anthropic' => 'Anthropic API',
    'openai' => 'OpenAI API',
    'gemini' => 'Gemini API',
    'ollama' => 'Ollama',
    'custom' => 'Custom',
    // Fall through with the raw id so legacy or renamed providers still surface a badge.
    _ => providerId,
  };
}
