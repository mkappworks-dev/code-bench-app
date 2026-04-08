import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/datasources/local/onboarding_preferences.dart';
import '../features/chat/chat_home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/github/github_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/compare/compare_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shell/desktop_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final prefs = ref.read(onboardingPreferencesProvider);
      final done = await prefs.isCompleted();
      if (!done && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DesktopShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatHomeScreen(),
          ),
          GoRoute(
            path: '/chat/new',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/chat/:sessionId',
            builder: (context, state) =>
                ChatScreen(sessionId: state.pathParameters['sessionId']),
          ),
          GoRoute(
            path: '/editor',
            builder: (context, state) => const EditorScreen(),
          ),
          GoRoute(
            path: '/github',
            builder: (context, state) => const GithubScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/compare',
            builder: (context, state) => const CompareScreen(),
          ),
        ],
      ),
    ],
  );
}
