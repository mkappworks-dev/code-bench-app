import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/notifiers/general_prefs_notifier.dart';
import 'router/app_router.dart';

class CodeBenchApp extends ConsumerWidget {
  const CodeBenchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(generalPrefsProvider).value?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Code Bench',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
