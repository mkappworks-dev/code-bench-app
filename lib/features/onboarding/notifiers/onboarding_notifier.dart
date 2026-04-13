import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_notifier.g.dart';

// Not keepAlive — scoped to onboarding screen lifetime.
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  static const int totalSteps = 3;

  @override
  int build() => 0;

  void next() {
    if (state < totalSteps - 1) state = state + 1;
  }

  void back() {
    if (state > 0) state = state - 1;
  }

  void goTo(int step) {
    assert(step >= 0 && step < totalSteps);
    state = step;
  }
}
