import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/utils/debug_logger.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/platform_utils.dart';
import 'data/datasources/local/app_database.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Global Flutter error handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    dLog('[FlutterError] ${details.exceptionAsString()}');
  };

  // Initialize window manager for desktop
  if (PlatformUtils.isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: const Size(
          AppConstants.minWindowWidth + 200,
          AppConstants.minWindowHeight + 100,
        ),
        minimumSize: const Size(
          AppConstants.minWindowWidth,
          AppConstants.minWindowHeight,
        ),
        center: true,
        titleBarStyle: TitleBarStyle.hidden,
        title: AppConstants.appName,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        // Eagerly initialize the database
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const CodeBenchApp(),
    ),
  );
}
