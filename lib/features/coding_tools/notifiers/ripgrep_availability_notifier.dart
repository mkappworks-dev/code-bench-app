import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/coding_tools/ripgrep_availability_service.dart' as svc;

part 'ripgrep_availability_notifier.g.dart';

/// Feature-layer state notifier for the ripgrep availability check.
/// Widgets watch [ripgrepAvailabilityProvider]; "Check again" calls [recheck].
@Riverpod(keepAlive: true)
class RipgrepAvailabilityNotifier extends _$RipgrepAvailabilityNotifier {
  @override
  Future<bool> build() => ref.watch(svc.ripgrepAvailabilityProvider.future);

  Future<void> recheck() async {
    ref.invalidate(svc.ripgrepAvailabilityProvider);
  }
}
