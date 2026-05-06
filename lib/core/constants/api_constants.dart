class ApiConstants {
  ApiConstants._();

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiChatEndpoint = '/chat/completions';
  static const String openAiModelsEndpoint = '/models';

  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicChatEndpoint = '/messages';
  static const String anthropicVersion = '2023-06-01';

  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static const String ollamaDefaultBaseUrl = 'http://localhost:11434';
  static const String ollamaTagsEndpoint = '/api/tags';
  static const String ollamaChatEndpoint = '/api/chat';

  static const String githubApiBaseUrl = 'https://api.github.com';

  // Public client identifier for the `Benchlabs Codebench` GitHub App. Embedded
  // in the binary by design — Device Flow (RFC 8628) treats `client_id` as a
  // non-secret. Forks must register their own GitHub App and replace this.
  static const String githubClientId = 'Iv23liSxSoUtHVlXrNGx';

  // Slug must match the App's URL slug in github.com/settings/apps. Forks must replace.
  static const String githubAppInstallUrl = 'https://github.com/apps/benchlabs-codebench/installations/new';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 5);
}
