import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  PlatformUtils._();

  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMobile => isIOS || isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static String get platformName {
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Unknown';
  }

  static String get pathSeparator => Platform.pathSeparator;

  static String get homeDirectory {
    if (isMacOS || isLinux) {
      return Platform.environment['HOME'] ?? '/';
    } else if (isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['HOMEDRIVE']! +
              Platform.environment['HOMEPATH']!;
    }
    return '/';
  }
}
