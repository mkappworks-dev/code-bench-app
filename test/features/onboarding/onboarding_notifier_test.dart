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
    expect(c.read(onboardingProvider), 0);
  });

  test('next advances step', () {
    final c = makeContainer();
    c.read(onboardingProvider.notifier).next();
    expect(c.read(onboardingProvider), 1);
  });

  test('next clamps at step 2', () {
    final c = makeContainer();
    c.read(onboardingProvider.notifier).next();
    c.read(onboardingProvider.notifier).next();
    c.read(onboardingProvider.notifier).next();
    expect(c.read(onboardingProvider), 2);
  });

  test('back decrements step', () {
    final c = makeContainer();
    c.read(onboardingProvider.notifier).next();
    c.read(onboardingProvider.notifier).back();
    expect(c.read(onboardingProvider), 0);
  });

  test('back clamps at step 0', () {
    final c = makeContainer();
    c.read(onboardingProvider.notifier).back();
    expect(c.read(onboardingProvider), 0);
  });
}
