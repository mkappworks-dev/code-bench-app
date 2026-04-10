class ApiConstants {
  ApiConstants._();

  // OpenAI
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiChatEndpoint = '/chat/completions';
  static const String openAiModelsEndpoint = '/models';

  // Anthropic
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicChatEndpoint = '/messages';
  static const String anthropicVersion = '2023-06-01';

  // Gemini
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  // Ollama defaults
  static const String ollamaDefaultBaseUrl = 'http://localhost:11434';
  static const String ollamaTagsEndpoint = '/api/tags';
  static const String ollamaChatEndpoint = '/api/chat';

  // GitHub
  static const String githubApiBaseUrl = 'https://api.github.com';
  static const String githubAuthUrl = 'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl = 'https://github.com/login/oauth/access_token';
  static const String githubScopes = 'repo,read:user,user:email';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 5);
}
