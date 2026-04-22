import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/coding_tools/ripgrep_availability_service.dart' as svc;

part 'ripgrep_availability_notifier.g.dart';

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityStateProvider]; "Check again" calls [recheck].
@Riverpod(keepAlive: true)
class RipgrepAvailabilityStateNotifier extends _$RipgrepAvailabilityStateNotifier {
  @override
  Future<bool> build() => ref.watch(svc.ripgrepAvailabilityProvider.future);

  void recheck() {
    state = const AsyncLoading();
    ref.invalidate(svc.ripgrepAvailabilityProvider);
  }
}
