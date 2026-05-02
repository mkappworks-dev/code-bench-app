class AppConstants {
  AppConstants._();

  static const String appName = 'Code Bench';
  static const String appVersion = '0.1.0';
  static const String oauthScheme = 'codebench';
  static const String oauthCallbackUrl = 'codebench://oauth/callback';

  // Window
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;

  // Sidebar
  static const double sidebarWidth = 224;

  // Chat
  static const int maxInMemoryMessages = 100;
  static const int messagePaginationLimit = 50;

  // SharedPreferences keys
  static const String prefWindowX = 'window_x';
  static const String prefWindowY = 'window_y';
  static const String prefWindowWidth = 'window_width';
  static const String prefWindowHeight = 'window_height';
  static const String prefUpdateLastChecked = 'update_last_checked';
  static const String prefUpdateLastCheckedFailed = 'update_last_checked_failed';
}
