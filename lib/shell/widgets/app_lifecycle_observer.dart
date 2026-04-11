import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project_sidebar/project_sidebar_notifier.dart';
import '../../services/git/git_live_state_provider.dart';

/// Wraps its child and invalidates [gitLiveStateProvider] for every tracked
/// project whenever the app window regains focus. Works on macOS, Windows,
/// and Linux via [AppLifecycleState.resumed].
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _invalidateAll();
  }

  void _invalidateAll() {
    final projectsAsync = ref.read(projectsProvider);
    projectsAsync.whenData((projects) {
      for (final project in projects) {
        ref.invalidate(gitLiveStateProvider(project.path));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
