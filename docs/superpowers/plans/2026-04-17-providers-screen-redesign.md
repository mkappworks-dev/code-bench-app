# Providers Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `ProvidersScreen` with a unified expandable-card design where every provider uses the same layout, Test only verifies (no save), Save validates-then-persists, and the status dot tracks persistence state only.

**Architecture:** Single file change (`providers_screen.dart`). All notifier methods (`saveKey`, `saveOllamaUrl`, `clearOllamaUrl`, `saveCustomEndpoint`, `clearCustomEndpoint`, `clearCustomApiKey`, `testApiKey`, `testOllamaUrl`, `testCustomEndpoint`, `deleteKey`) already exist — this is a pure UI rewrite. No new providers, no new notifiers.

**Tech Stack:** Flutter/Dart, Riverpod (ConsumerStatefulWidget), AppColors tokens.

---

## File map

| File | Change |
|---|---|
| `lib/features/settings/providers_screen.dart` | Full rewrite — new `_DotStatus` enum, three card classes, separate Test/Save buttons |

---

## Background: What Changes and Why

The current screen has two problems:
1. Ollama and Custom Endpoint use `SettingsGroup`/`SettingsRow` rows — a different style from the expandable `_ProviderKeyCard` used for API keys.
2. The Test button auto-saves on success. The new design separates Test (verify only) from Save (validate + persist).

**New dot states (`_DotStatus`):**
- `empty` — nothing saved (`_savedValue` is empty, field is empty)
- `unsaved` — field text differs from `_savedValue`
- `savedVerified` — saved after a successful connectivity/validity check (full green dot)
- `savedUnverified` — saved via "Save anyway" after a failed check (dim green dot, 45% opacity)

**`_savedValue` pattern:** Each card stores a `_savedValue` string (for Ollama/Custom: the URL; for API keys: the key). Set from `initialValue` at construction, updated on every successful Save or Clear. `_onTextChanged` compares `controller.text.trim()` against `_savedValue` to drive the dot.

**Test button label:** Shows `'Test'` by default. After a successful test within the current expanded session, shows `'✓ Valid'` (API keys) or `'✓ Connected'` (URL providers). Resets to `'Test'` when the card collapses or the field text changes.

**Save flow:**
- Calls the validation method first
- If valid → saves → dot goes `savedVerified` → success toast
- If invalid (API keys) → dot unchanged → error toast ("Invalid key")
- If connectivity fails (URL providers) → shows inline error row with "Save anyway" link
- "Save anyway" → saves without validation → dot goes `savedUnverified` → success toast "Saved (unverified)"

**Custom Endpoint** — two controllers (`_urlController`, `_apiKeyController`), saved atomically. The dot tracks `_savedUrl` and `_savedApiKey` separately; `_isUnsaved` is true when either field differs from its saved value.

---

## Task 1: New enum + updated `_InlineTestButton` + new `_InlineSaveButton`

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

- [ ] **Step 1: Replace `_KeyStatus` enum with `_DotStatus`**

Find and replace the existing `enum _KeyStatus { empty, unsaved, valid, invalid }` with:

```dart
enum _DotStatus { empty, unsaved, savedVerified, savedUnverified }
```

- [ ] **Step 2: Replace `_InlineTestButton`**

Replace the entire `_InlineTestButton` class with the new version that takes `testPassed` (bool) instead of `status` (`_KeyStatus?`):

```dart
class _InlineTestButton extends StatelessWidget {
  const _InlineTestButton({
    required this.loading,
    required this.onPressed,
    this.testPassed = false,
    this.passedLabel = '✓ Valid',
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool testPassed;
  final String passedLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 62,
        height: 26,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
          ),
        ),
      );
    }

    final fgColor = testPassed ? c.success : c.accent;
    final bgColor = testPassed ? c.success.withValues(alpha: 0.12) : c.accentTintMid;
    final borderColor = testPassed ? c.success.withValues(alpha: 0.3) : c.accent.withValues(alpha: 0.35);
    final label = testPassed ? passedLabel : 'Test';

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 62,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add `_InlineSaveButton` after `_InlineTestButton`**

```dart
class _InlineSaveButton extends StatelessWidget {
  const _InlineSaveButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 54,
        height: 26,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 54,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_InlineErrorRow` after `_InlineSaveButton`**

This is shown inside a card when connectivity fails, offering "Save anyway":

```dart
class _InlineErrorRow extends StatelessWidget {
  const _InlineErrorRow({required this.message, required this.onSaveAnyway});

  final String message;
  final VoidCallback onSaveAnyway;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.errorTintBg,
        border: Border.all(color: c.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
          GestureDetector(
            onTap: onSaveAnyway,
            child: Text(
              'Save anyway',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run analyze**

```bash
cd /path/to/worktree && flutter analyze lib/features/settings/providers_screen.dart 2>&1
```

Expected: errors about `_KeyStatus` no longer existing — that's fine, the cards still reference it. Fix those in subsequent tasks.

---

## Task 2: `_ApiKeyCard` (replaces `_ProviderKeyCard`)

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

Replace the entire `_ProviderKeyCard` + `_ProviderKeyCardState` with `_ApiKeyCard` + `_ApiKeyCardState`.

- [ ] **Step 1: Replace the card class**

Delete the `_ProviderKeyCard` and `_ProviderKeyCardState` classes entirely. Add:

```dart
// ── API key card (OpenAI · Anthropic · Gemini) ────────────────────────────────

class _ApiKeyCard extends ConsumerStatefulWidget {
  const _ApiKeyCard({
    required this.provider,
    required this.controller,
    required this.initialValue,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<_ApiKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _saveTriggered = false; // prevent double-tap during save
  late _DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_ApiKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent finished async load — update _savedValue and re-derive status.
    if (oldWidget.initialValue != widget.initialValue) {
      _savedValue = widget.initialValue;
      _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    // Reset test-passed label if user edits the field.
    if (_testPassed) setState(() => _testPassed = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? _DotStatus.empty : _DotStatus.savedVerified)
        : _DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Key is valid — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Invalid key', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() => _saveLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) { _saveTriggered = false; return; }
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) { _saveTriggered = false; return; }
      if (saved) {
        _savedValue = key;
        setState(() {
          _dotStatus = _DotStatus.savedVerified;
          _testPassed = false;
          _saveLoading = false;
        });
        AppSnackBar.show(context, 'API key saved', type: AppSnackBarType.success);
      } else {
        setState(() => _saveLoading = false);
        AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
      }
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
    }
    _saveTriggered = false;
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Valid & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) _testPassed = false;
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(_statusLabel(), style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  const Spacer(),
                  Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: widget.controller,
                          obscureText: _obscure,
                          fontSize: 12,
                          fontFamily: ThemeConstants.editorFontFamily,
                          hintText: 'API key',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/providers_screen.dart 2>&1
```

Fix any issues. The `_ProviderKeyCard` reference in `_ProvidersScreenState.build` will still error — that's fixed in Task 5.

---

## Task 3: `_OllamaCard`

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

Add `_OllamaCard` after the `_ApiKeyCard` classes.

- [ ] **Step 1: Add the class**

```dart
// ── Ollama card (URL-only) ─────────────────────────────────────────────────────

class _OllamaCard extends ConsumerStatefulWidget {
  const _OllamaCard({required this.controller, required this.initialValue});

  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<_OllamaCard> createState() => _OllamaCardState();
}

class _OllamaCardState extends ConsumerState<_OllamaCard> {
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late _DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_OllamaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _savedValue = widget.initialValue;
      _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? _DotStatus.empty : _DotStatus.savedVerified)
        : _DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() { _saveLoading = true; _testPassed = false; _showSaveAnyway = false; });
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Ollama is reachable — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Cannot connect to Ollama', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() { _saveLoading = true; _showSaveAnyway = false; });
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) { _saveTriggered = false; return; }
    if (ok) {
      await _persist(url, verified: true);
    } else {
      setState(() { _saveLoading = false; _showSaveAnyway = true; });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() { _saveLoading = true; _showSaveAnyway = false; });
    await _persist(url, verified: false);
  }

  Future<void> _persist(String url, {required bool verified}) async {
    final saved = await ref.read(apiKeysProvider.notifier).saveOllamaUrl(url);
    if (!mounted) return;
    if (saved) {
      _savedValue = url;
      setState(() {
        _dotStatus = verified ? _DotStatus.savedVerified : _DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(
        context,
        verified ? 'Ollama URL saved' : 'Saved (unverified)',
        type: AppSnackBarType.success,
      );
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Ollama URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Connected & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) { _testPassed = false; _showSaveAnyway = false; }
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text('Ollama', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(_statusLabel(), style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  const Spacer(),
                  Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.controller,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:11434',
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    _InlineErrorRow(
                      message: 'Cannot connect to Ollama',
                      onSaveAnyway: _saveAnyway,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/settings/providers_screen.dart 2>&1
```

Expected: no new errors from this class. Remaining errors are from `_ProvidersScreenState` — fixed in Task 5.

---

## Task 4: `_CustomEndpointCard`

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

Add `_CustomEndpointCard` after `_OllamaCard`.

- [ ] **Step 1: Add the class**

```dart
// ── Custom endpoint card (URL + optional API key) ─────────────────────────────

class _CustomEndpointCard extends ConsumerStatefulWidget {
  const _CustomEndpointCard({
    required this.urlController,
    required this.apiKeyController,
    required this.initialUrl,
    required this.initialApiKey,
  });

  final TextEditingController urlController;
  final TextEditingController apiKeyController;
  final String initialUrl;
  final String initialApiKey;

  @override
  ConsumerState<_CustomEndpointCard> createState() => _CustomEndpointCardState();
}

class _CustomEndpointCardState extends ConsumerState<_CustomEndpointCard> {
  bool _expanded = false;
  bool _obscureKey = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late _DotStatus _dotStatus;
  late String _savedUrl;
  late String _savedApiKey;

  @override
  void initState() {
    super.initState();
    _savedUrl = widget.initialUrl;
    _savedApiKey = widget.initialApiKey;
    _dotStatus = _savedUrl.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.urlController.addListener(_onFieldChanged);
    widget.apiKeyController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onFieldChanged);
    widget.apiKeyController.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_CustomEndpointCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl || oldWidget.initialApiKey != widget.initialApiKey) {
      _savedUrl = widget.initialUrl;
      _savedApiKey = widget.initialApiKey;
      _dotStatus = _savedUrl.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    }
  }

  bool get _isUnsaved =>
      widget.urlController.text.trim() != _savedUrl ||
      widget.apiKeyController.text.trim() != _savedApiKey;

  void _onFieldChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final url = widget.urlController.text.trim();
    _DotStatus next;
    if (!_isUnsaved) {
      next = _savedUrl.isEmpty ? _DotStatus.empty : _dotStatus;
    } else {
      next = _DotStatus.unsaved;
    }
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() { _saveLoading = true; _testPassed = false; _showSaveAnyway = false; });
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Endpoint reachable — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Cannot connect to endpoint', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() { _saveLoading = true; _showSaveAnyway = false; });
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) { _saveTriggered = false; return; }
    if (ok) {
      await _persist(url, apiKey, verified: true);
    } else {
      setState(() { _saveLoading = false; _showSaveAnyway = true; });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() { _saveLoading = true; _showSaveAnyway = false; });
    await _persist(url, apiKey, verified: false);
  }

  Future<void> _persist(String url, String apiKey, {required bool verified}) async {
    final saved = await ref.read(apiKeysProvider.notifier).saveCustomEndpoint(url, apiKey);
    if (!mounted) return;
    if (saved) {
      _savedUrl = url;
      _savedApiKey = apiKey;
      setState(() {
        _dotStatus = verified ? _DotStatus.savedVerified : _DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(
        context,
        verified ? 'Custom endpoint saved' : 'Saved (unverified)',
        type: AppSnackBarType.success,
      );
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearAll() async {
    widget.urlController.clear();
    widget.apiKeyController.clear();
    await ref.read(apiKeysProvider.notifier).clearCustomEndpoint();
    await ref.read(apiKeysProvider.notifier).clearCustomApiKey();
    if (!mounted) return;
    _savedUrl = '';
    _savedApiKey = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(context, 'Custom endpoint cleared', type: AppSnackBarType.success);
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Connected & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) { _testPassed = false; _showSaveAnyway = false; }
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text('Custom', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(_statusLabel(), style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  const Spacer(),
                  Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.urlController,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:1234/v1',
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: widget.apiKeyController,
                    obscureText: _obscureKey,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'API Key (optional)',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    _InlineErrorRow(
                      message: 'Cannot connect to endpoint',
                      onSaveAnyway: _saveAnyway,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(label: '✕ All', onPressed: _clearAll),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

Note: `_InlineClearButton` needs a `label` parameter for the "✕ All" variant — add it in Step 2.

- [ ] **Step 2: Update `_InlineClearButton` to accept an optional label**

Replace the `_InlineClearButton` class with:

```dart
class _InlineClearButton extends StatelessWidget {
  const _InlineClearButton({required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasLabel = label != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 26,
        padding: hasLabel
            ? const EdgeInsets.symmetric(horizontal: 8)
            : const EdgeInsets.symmetric(horizontal: 8),
        constraints: hasLabel ? null : const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: hasLabel
            ? Text(label!, style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall))
            : Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
```

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/features/settings/providers_screen.dart 2>&1
```

---

## Task 5: Update `_ProvidersScreenState`

**Files:**
- Modify: `lib/features/settings/providers_screen.dart`

Replace `_ProvidersScreenState` with the new version that uses the three card classes and passes `initialValue` fields.

- [ ] **Step 1: Replace `_ProvidersScreenState`**

Replace the entire class:

```dart
class ProvidersScreen extends ConsumerStatefulWidget {
  const ProvidersScreen({super.key});

  @override
  ConsumerState<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends ConsumerState<ProvidersScreen> {
  final _controllers = <AIProvider, TextEditingController>{
    AIProvider.openai: TextEditingController(),
    AIProvider.anthropic: TextEditingController(),
    AIProvider.gemini: TextEditingController(),
  };
  final _ollamaController = TextEditingController();
  final _customEndpointController = TextEditingController();
  final _customApiKeyController = TextEditingController();

  // Initial values — set on load, passed to cards so they can seed _savedValue.
  String _initialOpenAi = '';
  String _initialAnthropic = '';
  String _initialGemini = '';
  String _initialOllamaUrl = '';
  String _initialCustomEndpoint = '';
  String _initialCustomApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      final s = await ref.read(apiKeysProvider.future);
      if (!mounted) return;
      _controllers[AIProvider.openai]!.text = s.openai;
      _controllers[AIProvider.anthropic]!.text = s.anthropic;
      _controllers[AIProvider.gemini]!.text = s.gemini;
      _ollamaController.text = s.ollamaUrl;
      _customEndpointController.text = s.customEndpoint;
      _customApiKeyController.text = s.customApiKey;
      setState(() {
        _initialOpenAi = s.openai;
        _initialAnthropic = s.anthropic;
        _initialGemini = s.gemini;
        _initialOllamaUrl = s.ollamaUrl;
        _initialCustomEndpoint = s.customEndpoint;
        _initialCustomApiKey = s.customApiKey;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not load API keys — please restart the app.',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _ollamaController.dispose();
    _customEndpointController.dispose();
    _customApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('API Keys'),
          const SizedBox(height: 8),
          _ApiKeyCard(
            provider: AIProvider.openai,
            controller: _controllers[AIProvider.openai]!,
            initialValue: _initialOpenAi,
          ),
          const SizedBox(height: 6),
          _ApiKeyCard(
            provider: AIProvider.anthropic,
            controller: _controllers[AIProvider.anthropic]!,
            initialValue: _initialAnthropic,
          ),
          const SizedBox(height: 6),
          _ApiKeyCard(
            provider: AIProvider.gemini,
            controller: _controllers[AIProvider.gemini]!,
            initialValue: _initialGemini,
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          _OllamaCard(
            controller: _ollamaController,
            initialValue: _initialOllamaUrl,
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          _CustomEndpointCard(
            urlController: _customEndpointController,
            apiKeyController: _customApiKeyController,
            initialUrl: _initialCustomEndpoint,
            initialApiKey: _initialCustomApiKey,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Remove now-unused imports**

Remove the import for `settings_group.dart` and `api_constants.dart` if they are no longer referenced. Check the top of the file and delete:

```dart
import '../../core/constants/api_constants.dart';    // remove if unused
import 'widgets/settings_group.dart';                // remove if unused
```

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/features/settings/providers_screen.dart 2>&1
```

Fix all remaining errors. Common issues:
- Any reference to `_KeyStatus` → replace with `_DotStatus`
- Missing `displayName` on `AIProvider` — check `lib/data/shared/ai_model.dart` for the exact getter name

---

## Task 6: Format, test, commit

- [ ] **Step 1: dart format**

```bash
dart format lib/features/settings/providers_screen.dart
```

- [ ] **Step 2: Full analyze**

```bash
flutter analyze lib/features/settings/
```

Expected: no issues.

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: same pass/fail count as before this task (no new regressions — this is a pure UI change with no test-covered logic).

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/providers_screen.dart
git commit -m "feat: redesign ProvidersScreen — unified cards, separate Test/Save, persistence-only dot"
```

---

## Post-task checks

- [ ] **Manual smoke-test** — run the app and verify:
  1. All three API key cards collapse/expand correctly
  2. Typing in a field → dot goes yellow
  3. Test on a valid key → toast "Key is valid", button shows "✓ Valid", dot stays yellow
  4. Save on a valid key → dot goes full green
  5. Test on an invalid key → error toast, dot stays yellow
  6. Save on an invalid key → error toast, nothing saved
  7. Ollama with a running server → Save → full green dot
  8. Ollama with server down → Save → inline "Cannot connect / Save anyway" → "Save anyway" → dim green dot
  9. Custom Endpoint: same connectivity flow as Ollama
  10. ✕ / ✕ All → field clears, dot goes gray
