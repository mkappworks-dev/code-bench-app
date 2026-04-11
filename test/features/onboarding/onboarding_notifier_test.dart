import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/features/onboarding/notifiers/onboarding_notifier.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('starts at step 0', () {
    final c = makeContainer();
    expect(c.read(onboardingControllerProvider), 0);
  });

  test('next advances step', () {
    final c = makeContainer();
    c.read(onboardingControllerProvider.notifier).next();
    expect(c.read(onboardingControllerProvider), 1);
  });

  test('next clamps at step 2', () {
    final c = makeContainer();
    c.read(onboardingControllerProvider.notifier).next();
    c.read(onboardingControllerProvider.notifier).next();
    c.read(onboardingControllerProvider.notifier).next();
    expect(c.read(onboardingControllerProvider), 2);
  });

  test('back decrements step', () {
    final c = makeContainer();
    c.read(onboardingControllerProvider.notifier).next();
    c.read(onboardingControllerProvider.notifier).back();
    expect(c.read(onboardingControllerProvider), 0);
  });

  test('back clamps at step 0', () {
    final c = makeContainer();
    c.read(onboardingControllerProvider.notifier).back();
    expect(c.read(onboardingControllerProvider), 0);
  });
}
