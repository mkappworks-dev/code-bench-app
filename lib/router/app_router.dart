import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/_core/preferences/onboarding_preferences.dart';
import '../features/chat/chat_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../layout/chat_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/chat',
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
        pageBuilder: (context, state) => const NoTransitionPage(child: OnboardingScreen()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(child: ChatShell(child: child)),
        routes: [
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(child: ChatScreen()),
          ),
          GoRoute(
            path: '/chat/:sessionId',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: ChatScreen(sessionId: state.pathParameters['sessionId'])),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
      ),
    ],
  );
}
