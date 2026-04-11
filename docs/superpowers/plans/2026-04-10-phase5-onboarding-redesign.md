# Phase 5 — Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-screen API key onboarding with a polished three-step wizard: **API Keys → GitHub → Add First Project**. All steps are skippable. Left branding panel is unchanged; only the right content panel changes between steps.

**Architecture:** `OnboardingScreen` becomes a wizard shell driven by an `OnboardingController` generated `@riverpod Notifier<int>` (scoped to the screen). Step widgets are extracted into dedicated files under `lib/features/onboarding/widgets/`. GitHub OAuth reuses the existing `GitHubAuthService`. Folder selection uses the `file_picker` package (already in project). Navigation to the main screen uses the existing `GoRouter` setup.

**Tech Stack:** Flutter, Riverpod, `freezed`, existing `GitHubAuthService`, existing `SecureStorageSource`, existing `ProjectService`, `file_picker` (already in pubspec), `GitDetector`.

---

## File Map

| Status | File | Responsibility |
|---|---|---|
| Modify | `lib/features/onboarding/onboarding_screen.dart` | Rewrite — wizard shell with `OnboardingController`, step routing, left panel unchanged |
| **Create** | `lib/features/onboarding/notifiers/onboarding_notifier.dart` | `OnboardingController` — generated `@riverpod Notifier<int>` holding current step (0–2) |
| **Create** | `lib/features/onboarding/widgets/step_progress_indicator.dart` | Three pill-shaped dots + `STEP N OF 3` label + step title/subtitle |
| **Create** | `lib/features/onboarding/widgets/api_keys_step.dart` | Extracted API key form from current `OnboardingScreen` |
| **Create** | `lib/features/onboarding/widgets/github_step.dart` | OAuth + PAT fallback step; delegates auth to `GitHubAuthService` |
| **Create** | `lib/features/onboarding/widgets/add_project_step.dart` | Drag-and-drop folder zone + browse button; calls `ProjectService.addExistingFolder` |
| **Create** | `test/features/onboarding/onboarding_notifier_test.dart` | Unit tests for `OnboardingController` step transitions |
| **Create** | `test/features/onboarding/add_project_step_test.dart` | Widget test for folder selection flow |

---

## Task 1: `OnboardingController` notifier

**Files:**
- Create: `lib/features/onboarding/notifiers/onboarding_notifier.dart`
- Create: `test/features/onboarding/onboarding_notifier_test.dart`

- [ ] **Step 1.1: Write failing tests**

  Create `test/features/onboarding/onboarding_notifier_test.dart`:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench/features/onboarding/notifiers/onboarding_notifier.dart';

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
  ```

- [ ] **Step 1.2: Run to confirm they fail**

  ```bash
  flutter test test/features/onboarding/onboarding_notifier_test.dart
  ```

  Expected: compilation error — `onboardingControllerProvider` not found.

- [ ] **Step 1.3: Create `OnboardingController`**

  Create `lib/features/onboarding/notifiers/onboarding_notifier.dart`:

  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'onboarding_notifier.g.dart';

  // Not keepAlive — scoped to onboarding screen lifetime.
  @riverpod
  class OnboardingController extends _$OnboardingController {
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
  ```

- [ ] **Step 1.4: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected: `onboarding_notifier.g.dart` generated.

- [ ] **Step 1.5: Run tests to confirm they pass**

  ```bash
  flutter test test/features/onboarding/onboarding_notifier_test.dart
  ```

  Expected: 5 tests pass.

- [ ] **Step 1.6: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 1.7: Commit**

  ```bash
  git add lib/features/onboarding/notifiers/ \
         test/features/onboarding/onboarding_notifier_test.dart
  git commit -m "feat: OnboardingController — step notifier for wizard"
  ```

---

## Task 2: `StepProgressIndicator` widget

**Files:**
- Create: `lib/features/onboarding/widgets/step_progress_indicator.dart`

- [ ] **Step 2.1: Create `StepProgressIndicator`**

  Create `lib/features/onboarding/widgets/step_progress_indicator.dart`:

  ```dart
  import 'package:flutter/material.dart';

  class StepProgressIndicator extends StatelessWidget {
    const StepProgressIndicator({
      super.key,
      required this.currentStep,
      required this.totalSteps,
      required this.stepTitle,
      required this.stepSubtitle,
    });

    final int currentStep;
    final int totalSteps;
    final String stepTitle;
    final String stepSubtitle;

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dots
          Row(
            children: List.generate(totalSteps, (i) {
              Color dotColor;
              if (i < currentStep) {
                dotColor = const Color(0xFF4A7CFF);              // completed
              } else if (i == currentStep) {
                dotColor = const Color(0xFF4A7CFF).withOpacity(0.5); // current
              } else {
                dotColor = const Color(0xFF2A2A2A);              // upcoming
              }
              return Padding(
                padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Step label
          Text(
            'STEP ${currentStep + 1} OF $totalSteps',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Step title
          Text(
            stepTitle,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stepSubtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              stepSubtitle,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }
  }
  ```

- [ ] **Step 2.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 2.3: Commit**

  ```bash
  git add lib/features/onboarding/widgets/step_progress_indicator.dart
  git commit -m "feat: StepProgressIndicator widget for onboarding wizard"
  ```

---

## Task 3: Rewrite `OnboardingScreen` as wizard shell

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`

Read the full current file before modifying so the left branding panel code can be preserved exactly.

- [ ] **Step 3.1: Read the current onboarding screen**

  Read `lib/features/onboarding/onboarding_screen.dart` to understand the existing left panel layout (branding, logo, tagline). You'll extract that content into the new wizard shell unchanged.

- [ ] **Step 3.2: Rewrite `OnboardingScreen` as wizard shell**

  Replace the entire content of `lib/features/onboarding/onboarding_screen.dart` with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import 'notifiers/onboarding_notifier.dart';
  import 'widgets/step_progress_indicator.dart';
  import 'widgets/api_keys_step.dart';
  import 'widgets/github_step.dart';
  import 'widgets/add_project_step.dart';

  class OnboardingScreen extends ConsumerWidget {
    const OnboardingScreen({super.key});

    static const _stepTitles = [
      'Connect AI Providers',
      'Connect GitHub',
      'Add Your First Project',
    ];

    static const _stepSubtitles = [
      'Add API keys to use AI in Code Bench',
      'Link your GitHub account for PR features',
      'Point Code Bench at a local folder to begin',
    ];

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final step = ref.watch(onboardingControllerProvider);

      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Row(
          children: [
            // ── Left: branding (38% width, unchanged from original) ──────────
            const _BrandingPanel(),
            // ── Right: content (62% width) ───────────────────────────────────
            Expanded(
              flex: 62,
              child: _ContentPanel(
                step: step,
                stepTitles: _stepTitles,
                stepSubtitles: _stepSubtitles,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── Left branding panel ────────────────────────────────────────────────────

  class _BrandingPanel extends StatelessWidget {
    const _BrandingPanel();

    @override
    Widget build(BuildContext context) {
      return Expanded(
        flex: 38,
        child: Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.all(48),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo placeholder — replace with actual asset if available
              Icon(Icons.code, color: Color(0xFF4A7CFF), size: 48),
              SizedBox(height: 24),
              Text(
                'Code Bench',
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your AI-powered coding workspace',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── Right content panel ────────────────────────────────────────────────────

  class _ContentPanel extends ConsumerWidget {
    const _ContentPanel({
      required this.step,
      required this.stepTitles,
      required this.stepSubtitles,
    });

    final int step;
    final List<String> stepTitles;
    final List<String> stepSubtitles;

    void _next(BuildContext context, WidgetRef ref) {
      final controller = ref.read(onboardingControllerProvider.notifier);
      if (step < OnboardingController.totalSteps - 1) {
        controller.next();
      } else {
        context.go('/');
      }
    }

    void _skip(BuildContext context, WidgetRef ref) => _next(context, ref);

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button (steps 1 and 2 only)
            if (step > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(onboardingControllerProvider.notifier).back(),
                  icon: const Icon(Icons.chevron_left, size: 16,
                      color: Color(0xFF888888)),
                  label: const Text('Back',
                      style:
                          TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ),
              )
            else
              const SizedBox(height: 32),
            const SizedBox(height: 16),
            StepProgressIndicator(
              currentStep: step,
              totalSteps: OnboardingController.totalSteps,
              stepTitle: stepTitles[step],
              stepSubtitle: stepSubtitles[step],
            ),
            const SizedBox(height: 32),
            // Step content
            Expanded(
              child: switch (step) {
                0 => ApiKeysStep(onContinue: () => _next(context, ref)),
                1 => GithubStep(onContinue: () => _next(context, ref)),
                2 => AddProjectStep(onComplete: () => context.go('/')),
                _ => const SizedBox.shrink(),
              },
            ),
            // Footer navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _skip(context, ref),
                  child: const Text('Skip for now',
                      style:
                          TextStyle(color: Color(0xFF666666), fontSize: 12)),
                ),
                if (step < 2)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _next(context, ref),
                    child: const Text('Continue →',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      );
    }
  }
  ```

  **Important:** Read the actual branding panel content from the original file's left section before overwriting. The `_BrandingPanel` above is a placeholder — replace its body with the exact layout from the original file if it differs.

- [ ] **Step 3.3: Run build_runner**

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Step 3.4: Verify analyze**

  ```bash
  flutter analyze
  ```

  Expected: errors about missing `ApiKeysStep`, `GithubStep`, `AddProjectStep` — that is fine, they will be created in following tasks.

- [ ] **Step 3.5: Commit skeleton (compile errors expected)**

  Do NOT commit yet — wait until all step widgets exist in Task 6.

---

## Task 4: `ApiKeysStep` widget

**Files:**
- Create: `lib/features/onboarding/widgets/api_keys_step.dart`

The API key form currently lives inline in `OnboardingScreen`. This task extracts it into its own widget.

- [ ] **Step 4.1: Read the existing onboarding screen to find API key form code**

  Read `lib/features/onboarding/onboarding_screen.dart` (the file before your rewrite in Task 3). Identify all state fields and UI related to: `_addedProviders`, `_controllers`, `_testResults`, `_testing`, `_saving`, and `_buildProviderRow`.

- [ ] **Step 4.2: Create `ApiKeysStep`**

  Create `lib/features/onboarding/widgets/api_keys_step.dart` by moving the extracted form code:

  ```dart
  import 'package:dio/dio.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../data/datasources/local/secure_storage_source.dart';
  import '../../../data/models/ai_model.dart';

  class ApiKeysStep extends ConsumerStatefulWidget {
    const ApiKeysStep({super.key, required this.onContinue});
    final VoidCallback onContinue;

    @override
    ConsumerState<ApiKeysStep> createState() => _ApiKeysStepState();
  }

  class _ApiKeysStepState extends ConsumerState<ApiKeysStep> {
    final List<AIProvider> _addedProviders = [AIProvider.anthropic];
    final Map<AIProvider, TextEditingController> _controllers = {
      AIProvider.anthropic: TextEditingController(),
    };
    final Map<AIProvider, bool?> _testResults = {};
    final Map<AIProvider, bool> _testing = {};
    bool _saving = false;

    @override
    void dispose() {
      for (final c in _controllers.values) c.dispose();
      super.dispose();
    }

    void _addProvider(AIProvider provider) {
      setState(() {
        _addedProviders.add(provider);
        _controllers[provider] = TextEditingController();
      });
    }

    void _removeProvider(AIProvider provider) {
      setState(() {
        _addedProviders.remove(provider);
        _controllers[provider]?.dispose();
        _controllers.remove(provider);
        _testResults.remove(provider);
        _testing.remove(provider);
      });
    }

    Future<void> _testKey(AIProvider provider) async {
      final key = _controllers[provider]?.text.trim() ?? '';
      if (key.isEmpty) return;
      setState(() => _testing[provider] = true);
      try {
        // Minimal connectivity test — provider-specific
        final url = switch (provider) {
          AIProvider.anthropic =>
            'https://api.anthropic.com/v1/models',
          AIProvider.openAi => 'https://api.openai.com/v1/models',
          AIProvider.gemini =>
            'https://generativelanguage.googleapis.com/v1/models?key=$key',
          _ => null,
        };
        if (url == null) {
          setState(() {
            _testResults[provider] = false;
            _testing[provider] = false;
          });
          return;
        }
        final dio = Dio();
        final response = await dio.get(
          url,
          options: Options(
            headers: {
              if (provider == AIProvider.anthropic) ...{
                'x-api-key': key,
                'anthropic-version': '2023-06-01',
              } else if (provider == AIProvider.openAi)
                'Authorization': 'Bearer $key',
            },
            validateStatus: (s) => s != null && s < 500,
          ),
        );
        setState(() {
          _testResults[provider] = response.statusCode == 200;
          _testing[provider] = false;
        });
      } catch (_) {
        setState(() {
          _testResults[provider] = false;
          _testing[provider] = false;
        });
      }
    }

    Future<void> _saveAll() async {
      setState(() => _saving = true);
      final storage = ref.read(secureStorageSourceProvider);
      for (final provider in _addedProviders) {
        final key = _controllers[provider]?.text.trim() ?? '';
        if (key.isNotEmpty) {
          await storage.writeApiKey(provider, key);
        }
      }
      setState(() => _saving = false);
      widget.onContinue();
    }

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider rows
          Expanded(
            child: ListView(
              children: [
                for (final provider in _addedProviders)
                  _ProviderRow(
                    provider: provider,
                    controller: _controllers[provider]!,
                    testResult: _testResults[provider],
                    testing: _testing[provider] ?? false,
                    onTest: () => _testKey(provider),
                    onRemove: _addedProviders.length > 1
                        ? () => _removeProvider(provider)
                        : null,
                  ),
                // Add provider dropdown
                _AddProviderButton(
                  addedProviders: _addedProviders,
                  onAdd: _addProvider,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Note: "Continue →" is in the wizard shell footer; this button
          // is the primary save action on this step.
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A7CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _saving ? null : _saveAll,
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save & Continue',
                    style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
  }

  // ── Provider row ─────────────────────────────────────────────────────────────

  class _ProviderRow extends StatelessWidget {
    const _ProviderRow({
      required this.provider,
      required this.controller,
      required this.testResult,
      required this.testing,
      required this.onTest,
      required this.onRemove,
    });

    final AIProvider provider;
    final TextEditingController controller;
    final bool? testResult;
    final bool testing;
    final VoidCallback onTest;
    final VoidCallback? onRemove;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '${provider.name} API Key',
                  labelStyle: const TextStyle(
                      color: Color(0xFF888888), fontSize: 11),
                  suffixIcon: testResult == null
                      ? null
                      : Icon(
                          testResult! ? Icons.check_circle : Icons.error,
                          color: testResult!
                              ? Colors.green
                              : Colors.red,
                          size: 16,
                        ),
                ),
                style: const TextStyle(
                    color: Color(0xFFE0E0E0), fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: testing ? null : onTest,
              child: testing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Test',
                      style: TextStyle(fontSize: 11)),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: onRemove,
              ),
            ],
          ],
        ),
      );
    }
  }

  // ── Add provider button ───────────────────────────────────────────────────

  class _AddProviderButton extends StatelessWidget {
    const _AddProviderButton({
      required this.addedProviders,
      required this.onAdd,
    });

    final List<AIProvider> addedProviders;
    final ValueChanged<AIProvider> onAdd;

    @override
    Widget build(BuildContext context) {
      final available = AIProvider.values
          .where((p) => !addedProviders.contains(p))
          .toList();
      if (available.isEmpty) return const SizedBox.shrink();
      return PopupMenuButton<AIProvider>(
        tooltip: 'Add provider',
        color: const Color(0xFF1E1E1E),
        itemBuilder: (_) => available
            .map((p) =>
                PopupMenuItem(value: p, child: Text(p.name)))
            .toList(),
        onSelected: onAdd,
        child: TextButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add provider',
              style: TextStyle(fontSize: 11)),
        ),
      );
    }
  }
  ```

  **Note:** The `SecureStorageSource.writeApiKey(AIProvider, String)` method may not exist yet. Read `lib/data/datasources/local/secure_storage_source.dart` and use whatever write method is available for API keys (e.g., `writeAnthropicKey`, etc.). Adapt the `_saveAll` method accordingly.

- [ ] **Step 4.2b: Read SecureStorageSource to verify correct write method**

  Read `lib/data/datasources/local/secure_storage_source.dart` and update the `_saveAll` method in `ApiKeysStep` to use the correct method signature.

- [ ] **Step 4.3: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 4.4: Commit**

  ```bash
  git add lib/features/onboarding/widgets/api_keys_step.dart
  git commit -m "feat: ApiKeysStep — extracted from OnboardingScreen"
  ```

---

## Task 5: `GithubStep` widget

**Files:**
- Create: `lib/features/onboarding/widgets/github_step.dart`

- [ ] **Step 5.1: Create `GithubStep`**

  Create `lib/features/onboarding/widgets/github_step.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../data/models/repository.dart';
  import '../../../services/github/github_auth_service.dart';
  import '../../../services/github/github_api_service.dart';

  class GithubStep extends ConsumerStatefulWidget {
    const GithubStep({super.key, required this.onContinue});
    final VoidCallback onContinue;

    @override
    ConsumerState<GithubStep> createState() => _GithubStepState();
  }

  class _GithubStepState extends ConsumerState<GithubStep> {
    bool _connecting = false;
    GitHubAccount? _account;
    bool _showPat = false;
    final _patController = TextEditingController();
    bool _testingPat = false;
    bool? _patValid;

    @override
    void initState() {
      super.initState();
      _checkExistingAccount();
    }

    @override
    void dispose() {
      _patController.dispose();
      super.dispose();
    }

    Future<void> _checkExistingAccount() async {
      final account =
          await ref.read(githubAuthServiceProvider).getStoredAccount();
      if (mounted && account != null) setState(() => _account = account);
    }

    Future<void> _connectOAuth() async {
      setState(() => _connecting = true);
      try {
        final account =
            await ref.read(githubAuthServiceProvider).authenticate();
        if (mounted) setState(() => _account = account);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GitHub auth failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _connecting = false);
      }
    }

    Future<void> _disconnect() async {
      await ref.read(githubAuthServiceProvider).signOut();
      if (mounted) setState(() => _account = null);
    }

    Future<void> _testPat() async {
      final token = _patController.text.trim();
      if (token.isEmpty) return;
      setState(() => _testingPat = true);
      try {
        final svc = GitHubApiService(token);
        final username = await svc.validateToken();
        if (mounted) {
          setState(() {
            _patValid = username != null;
            if (username != null) {
              _account = GitHubAccount(
                username: username,
                avatarUrl: '',
                email: null,
                name: null,
              );
            }
          });
        }
      } catch (_) {
        if (mounted) setState(() => _patValid = false);
      } finally {
        if (mounted) setState(() => _testingPat = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_account != null) {
        return _ConnectedView(
          account: _account!,
          onDisconnect: _disconnect,
          onContinue: widget.onContinue,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OAuth button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF24292E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _connecting ? null : _connectOAuth,
            icon: _connecting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link, size: 16),
            label: Text(
              _connecting ? 'Connecting…' : 'Continue with GitHub',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // PAT fallback
          GestureDetector(
            onTap: () => setState(() => _showPat = !_showPat),
            child: Row(
              children: [
                Text(
                  'Use a Personal Access Token instead',
                  style: TextStyle(
                    color: const Color(0xFF4A7CFF),
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showPat
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 14,
                  color: const Color(0xFF4A7CFF),
                ),
              ],
            ),
          ),

          if (_showPat) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Personal Access Token',
                      labelStyle: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11),
                      suffixIcon: _patValid == null
                          ? null
                          : Icon(
                              _patValid! ? Icons.check_circle : Icons.error,
                              color: _patValid! ? Colors.green : Colors.red,
                              size: 16,
                            ),
                    ),
                    style: const TextStyle(
                        color: Color(0xFFE0E0E0), fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _testingPat ? null : _testPat,
                  child: _testingPat
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await Process.run(
                    'open', ['https://github.com/settings/tokens/new']);
              },
              child: const Text(
                'Create a token on GitHub →',
                style: TextStyle(
                  color: Color(0xFF4A7CFF),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  class _ConnectedView extends StatelessWidget {
    const _ConnectedView({
      required this.account,
      required this.onDisconnect,
      required this.onContinue,
    });

    final GitHubAccount account;
    final VoidCallback onDisconnect;
    final VoidCallback onContinue;

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              children: [
                if (account.avatarUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(account.avatarUrl,
                        width: 40, height: 40),
                  )
                else
                  const Icon(Icons.person, size: 40,
                      color: Color(0xFF888888)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          account.username,
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (account.name != null)
                      Text(account.name!,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect',
                      style: TextStyle(
                          color: Color(0xFF666666), fontSize: 11)),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A7CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onContinue,
            child: const Text('Continue →',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
  }
  ```

  Add `import 'dart:io';` at the top since `Process.run` is used.

  Note: `GitHubApiService` will need the `validateToken` method added in Phase 3 Task 9. If Phase 3 is not yet complete, add a temporary `validateToken` stub to `GitHubApiService` that returns null.

- [ ] **Step 5.2: Verify analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 5.3: Commit**

  ```bash
  git add lib/features/onboarding/widgets/github_step.dart
  git commit -m "feat: GithubStep — OAuth + PAT fallback onboarding step"
  ```

---

## Task 6: `AddProjectStep` widget

**Files:**
- Create: `lib/features/onboarding/widgets/add_project_step.dart`
- Create: `test/features/onboarding/add_project_step_test.dart`

- [ ] **Step 6.1: Write failing widget test**

  Create `test/features/onboarding/add_project_step_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:code_bench/features/onboarding/widgets/add_project_step.dart';

  void main() {
    testWidgets('shows drop zone with "Drop a folder here" text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddProjectStep(onComplete: () {}),
            ),
          ),
        ),
      );
      expect(find.text('Drop a folder here'), findsOneWidget);
    });

    testWidgets('"Add Project" button is disabled by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddProjectStep(onComplete: () {}),
            ),
          ),
        ),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  }
  ```

- [ ] **Step 6.2: Run to confirm they fail**

  ```bash
  flutter test test/features/onboarding/add_project_step_test.dart
  ```

  Expected: compilation error.

- [ ] **Step 6.3: Create `AddProjectStep`**

  Create `lib/features/onboarding/widgets/add_project_step.dart`:

  ```dart
  import 'dart:io';

  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lucide_icons_flutter/lucide_icons.dart';

  import '../../../services/project/git_detector.dart';
  import '../../../services/project/project_service.dart';

  class AddProjectStep extends ConsumerStatefulWidget {
    const AddProjectStep({super.key, required this.onComplete});
    final VoidCallback onComplete;

    @override
    ConsumerState<AddProjectStep> createState() => _AddProjectStepState();
  }

  class _AddProjectStepState extends ConsumerState<AddProjectStep> {
    String? _selectedPath;
    bool _adding = false;

    bool get _isGitRepo =>
        _selectedPath != null && GitDetector.isGitRepo(_selectedPath!);

    Future<void> _browse() async {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) setState(() => _selectedPath = result);
    }

    Future<void> _addProject() async {
      if (_selectedPath == null) return;
      setState(() => _adding = true);
      try {
        await ref
            .read(projectServiceProvider)
            .addExistingFolder(_selectedPath!);
        if (mounted) widget.onComplete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add project: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _adding = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildDropZone()),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A7CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed:
                _selectedPath == null || _adding ? null : _addProject,
            child: _adding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Add Project',
                    style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    Widget _buildDropZone() {
      if (_selectedPath != null) {
        return _SelectedFolderPreview(
          path: _selectedPath!,
          isGit: _isGitRepo,
          onChangeTap: () {
            setState(() => _selectedPath = null);
          },
          onBrowse: _browse,
        );
      }

      return DragTarget<String>(
        onAcceptWithDetails: (details) {
          setState(() => _selectedPath = details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isDragOver = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isDragOver
                  ? const Color(0xFF1A1F2E)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDragOver
                    ? const Color(0xFF4A7CFF)
                    : const Color(0xFF2A2A2A),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📁',
                    style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                const Text(
                  'Drop a folder here',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('— or —',
                    style: TextStyle(
                        color: Color(0xFF666666), fontSize: 11)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _browse,
                  child: const Text('Browse for folder…',
                      style: TextStyle(
                          color: Color(0xFF4A7CFF), fontSize: 12)),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // ── Selected folder preview ────────────────────────────────────────────────

  class _SelectedFolderPreview extends StatelessWidget {
    const _SelectedFolderPreview({
      required this.path,
      required this.isGit,
      required this.onChangeTap,
      required this.onBrowse,
    });

    final String path;
    final bool isGit;
    final VoidCallback onChangeTap;
    final VoidCallback onBrowse;

    String get _projectName {
      final segments = path.split(Platform.pathSeparator)
        ..removeWhere((s) => s.isEmpty);
      return segments.isNotEmpty ? segments.last : path;
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.folderOpen,
                    size: 18, color: Color(0xFF888888)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _projectName,
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isGit) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F3D1F),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFF1A6B35)),
                              ),
                              child: const Text('git',
                                  style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 9)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        path,
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onBrowse,
              child: const Text('Change folder',
                  style: TextStyle(
                    color: Color(0xFF4A7CFF),
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 6.4: Run tests to confirm they pass**

  ```bash
  flutter test test/features/onboarding/add_project_step_test.dart
  ```

  Expected: 2 tests pass.

- [ ] **Step 6.5: Verify full wizard compiles**

  ```bash
  flutter analyze
  ```

  Expected: no issues now that all three step widgets exist.

- [ ] **Step 6.6: Commit**

  ```bash
  git add lib/features/onboarding/widgets/add_project_step.dart \
         lib/features/onboarding/onboarding_screen.dart \
         lib/features/onboarding/notifiers/ \
         lib/features/onboarding/widgets/step_progress_indicator.dart \
         lib/features/onboarding/widgets/api_keys_step.dart \
         lib/features/onboarding/widgets/github_step.dart \
         test/features/onboarding/
  git commit -m "feat: Phase 5 — 3-step onboarding wizard (API Keys, GitHub, Add Project)"
  ```

---

## Task 7: Final checks

- [ ] **Step 7.1: Run full test suite**

  ```bash
  flutter test
  ```

- [ ] **Step 7.2: Format**

  ```bash
  dart format lib/ test/
  ```

- [ ] **Step 7.3: Analyze**

  ```bash
  flutter analyze
  ```

- [ ] **Step 7.4: Manual smoke test**

  Run `flutter run -d macos`. Clear onboarding preferences (`OnboardingPreferences`) so the onboarding screen shows. Verify:
  - Three-step wizard shell renders with progress dots
  - Step 1: API key form works (save advances to step 2, skip advances to step 2)
  - Step 2: OAuth button opens browser; connected state shows username; PAT fallback shows/hides
  - Step 3: Browse button opens folder picker; selected folder shows preview with git badge if applicable; "Add Project" navigates to main screen with project active
  - Back button works on steps 2 and 3
