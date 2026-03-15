class AppConstants {
  AppConstants._();

  static const String appName = 'Code Bench';
  static const String appVersion = '1.0.0';
  static const String oauthScheme = 'codebench';
  static const String oauthCallbackUrl = 'codebench://oauth/callback';

  // Window
  static const double minWindowWidth = 1000;
  static const double minWindowHeight = 650;

  // Pane defaults
  static const double defaultExplorerWidth = 220;
  static const double defaultChatWidth = 360;
  static const double minPaneWidth = 150;

  // Chat
  static const int maxInMemoryMessages = 100;
  static const int messagePaginationLimit = 50;

  // SharedPreferences keys
  static const String prefExplorerWidth = 'explorer_pane_width';
  static const String prefChatWidth = 'chat_pane_width';
  static const String prefWindowX = 'window_x';
  static const String prefWindowY = 'window_y';
  static const String prefWindowWidth = 'window_width';
  static const String prefWindowHeight = 'window_height';
}
