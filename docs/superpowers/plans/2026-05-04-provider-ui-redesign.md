# Provider UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the visual language for provider cards across Settings and Onboarding, fixing hover/opacity/border inconsistencies and replacing the flat onboarding form with collapsible cards.

**Architecture:** Pure widget-layer changes — no notifier, service, or data-layer modifications. All state stays in existing widget state classes; the onboarding step gains a new `_OnboardingProviderCard` private widget to replace `_ProviderRow`. No new files needed.

**Tech Stack:** Flutter/Dart, Riverpod (`ref.watch` / `ref.read`), `AppColors` for all colours, `ThemeConstants` for font sizes.

---

## File Map

| File | What changes |
|---|---|
| `lib/features/providers/widgets/selectable_transport_card.dart` | Remove accent border on selected; move Opacity to header-only |
| `lib/features/providers/widgets/anthropic_provider_card.dart` | `initiallyExpanded: false` on API Key card; add InstallCommand to broken branch |
| `lib/features/providers/widgets/openai_provider_card.dart` | `initiallyExpanded: false` on API Key card; add InstallCommand to broken branch |
| `lib/features/providers/widgets/gemini_provider_card.dart` | `initiallyExpanded: false` on API Key card |
| `lib/features/providers/widgets/ollama_card.dart` | Replace bespoke shell with unified chrome |
| `lib/features/providers/widgets/custom_endpoint_card.dart` | Replace bespoke shell with unified chrome |
| `lib/features/onboarding/widgets/api_keys_step.dart` | Full redesign — collapsible cards, CLI banner, scrollable list |

---

## Task 1: `selectable_transport_card.dart` — remove accent border + header-only opacity

**Files:**
- Modify: `lib/features/providers/widgets/selectable_transport_card.dart`

### Background

Two problems in the current file:

1. **Border**: line 127 uses `c.accent.withValues(alpha: 0.5)` when `widget.selected`. This makes selected cards look the same as "connected/valid" status, which confuses selection with health state. Fix: always use `c.deepBorder`, error state keeps `c.error.withValues(alpha: 0.4)`.

2. **Opacity**: lines 155–183 wrap the entire `Column(header + body)` in `Opacity(opacity: widget.disabled ? 0.6 : 1.0)`. This dims the body too — including the "Recheck" button inside the CLI card body. Fix: move `Opacity` to wrap only the header `MouseRegion`, leaving the body at full opacity.

- [ ] **Step 1: Fix `borderColor` — remove accent on selected**

In `_SelectableTransportCardState.build()`, change line 125–127:

```dart
// BEFORE
final borderColor = widget.errorState
    ? c.error.withValues(alpha: 0.4)
    : (widget.selected ? c.accent.withValues(alpha: 0.5) : c.borderColor);

// AFTER
final borderColor = widget.errorState ? c.error.withValues(alpha: 0.4) : c.deepBorder;
```

Also remove the `borderColor` local variable reference to `c.borderColor` — it is no longer used. The `c.deepBorder` is assigned directly.

- [ ] **Step 2: Split Opacity — wrap header only, not body**

The current structure (lines 155–183):

```dart
child: Opacity(
  opacity: widget.disabled ? 0.6 : 1.0,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          if (interactive) setState(() => _hovered = true);
        },
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: interactive ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: headerRow,
        ),
      ),
      if (_expanded) ...[
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.only(left: 22), child: widget.body),
      ],
    ],
  ),
),
```

Replace with (Opacity moved inside Column, wrapping only the MouseRegion):

```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Opacity(
      opacity: widget.disabled ? 0.6 : 1.0,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          if (interactive) setState(() => _hovered = true);
        },
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: interactive ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: headerRow,
        ),
      ),
    ),
    if (_expanded) ...[
      const SizedBox(height: 10),
      Padding(padding: const EdgeInsets.only(left: 22), child: widget.body),
    ],
  ],
),
```

- [ ] **Step 3: Verify**

```bash
cd .worktrees/feat/2026-05-04-provider-ui-redesign
flutter analyze lib/features/providers/widgets/selectable_transport_card.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/providers/widgets/selectable_transport_card.dart
git commit -m "feat(providers): remove accent border on selected card; header-only disabled opacity"
```

---

## Task 2: `anthropic_provider_card.dart` — collapse by default + InstallCommand in broken branch

**Files:**
- Modify: `lib/features/providers/widgets/anthropic_provider_card.dart`

### Background

Two problems:

1. **API Key card opens by default**: `initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified` expands the card whenever no key is saved (i.e. always on first install). Change to `false` — users deliberately open it.

2. **Broken branch missing install command**: When `broken == true` (CLI was selected but binary went missing), `_ClaudeCliBody` shows error text + buttons but not the install command. The `installCommand` parameter is already in scope — just wire it up.

- [ ] **Step 1: Collapse API Key card by default**

In `_AnthropicProviderCardState._buildGroup()`, line 253, change:

```dart
// BEFORE
initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified,

// AFTER
initiallyExpanded: false,
```

- [ ] **Step 2: Add InstallCommand to broken branch in `_ClaudeCliBody`**

In `_ClaudeCliBody.build()`, the broken branch (lines 373–389):

```dart
// BEFORE
if (broken) {
  return Row(
    children: [
      Expanded(
        child: Text(
          '⚠ $binaryName no longer detected',
          style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 6),
      _CardButton(label: 'Switch to API Key', onPressed: onSwitchToApiKey),
      const SizedBox(width: 6),
      _CardButton(label: 'Recheck', onPressed: onRecheck),
    ],
  );
}
```

Replace with:

```dart
// AFTER
if (broken) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '⚠ $binaryName no longer detected',
        style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: InstallCommand(command: installCommand)),
          const SizedBox(width: 6),
          _CardButton(label: 'Switch to API Key', onPressed: onSwitchToApiKey),
          const SizedBox(width: 6),
          _CardButton(label: 'Recheck', onPressed: onRecheck),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/providers/widgets/anthropic_provider_card.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/providers/widgets/anthropic_provider_card.dart
git commit -m "feat(providers): collapse Anthropic API Key card by default; add install command to broken branch"
```

---

## Task 3: `openai_provider_card.dart` — collapse by default + InstallCommand in broken branch

**Files:**
- Modify: `lib/features/providers/widgets/openai_provider_card.dart`

Same two changes as Task 2, for the OpenAI card. The broken branch widget class is `_CodexCliBody` (not `_ClaudeCliBody`).

- [ ] **Step 1: Collapse API Key card by default**

In `_OpenAIProviderCardState._buildGroup()`, line 248, change:

```dart
// BEFORE
initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified,

// AFTER
initiallyExpanded: false,
```

- [ ] **Step 2: Add InstallCommand to broken branch in `_CodexCliBody`**

In `_CodexCliBody.build()`, the broken branch (lines 354–370):

```dart
// BEFORE
if (broken) {
  return Row(
    children: [
      Expanded(
        child: Text(
          '⚠ $binaryName no longer detected',
          style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 6),
      _CardButton(label: 'Switch to API Key', onPressed: onSwitchToApiKey),
      const SizedBox(width: 6),
      _CardButton(label: 'Recheck', onPressed: onRecheck),
    ],
  );
}
```

Replace with:

```dart
// AFTER
if (broken) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '⚠ $binaryName no longer detected',
        style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: InstallCommand(command: installCommand)),
          const SizedBox(width: 6),
          _CardButton(label: 'Switch to API Key', onPressed: onSwitchToApiKey),
          const SizedBox(width: 6),
          _CardButton(label: 'Recheck', onPressed: onRecheck),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/providers/widgets/openai_provider_card.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/providers/widgets/openai_provider_card.dart
git commit -m "feat(providers): collapse OpenAI API Key card by default; add install command to broken branch"
```

---

## Task 4: `gemini_provider_card.dart` — collapse API Key by default

**Files:**
- Modify: `lib/features/providers/widgets/gemini_provider_card.dart`

Gemini has no CLI transport yet (placeholder "Coming in Phase 9"), so only the `initiallyExpanded` fix applies.

- [ ] **Step 1: Collapse API Key card by default**

In `_GeminiProviderCardState.build()`, line 167, change:

```dart
// BEFORE
initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified,

// AFTER
initiallyExpanded: false,
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/providers/widgets/gemini_provider_card.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/providers/widgets/gemini_provider_card.dart
git commit -m "feat(providers): collapse Gemini API Key card by default"
```

---

## Task 5: `ollama_card.dart` — unified chrome

**Files:**
- Modify: `lib/features/providers/widgets/ollama_card.dart`

### Background

Current shell: `Container(color: c.inputSurface, borderRadius: 8px)` + `InkWell` for hover/expand. This makes OllamaCard visually different from transport cards (8px vs 4px radius, full-card input surface vs header-only). Replace with the unified chrome pattern:

- Outer `Container`: `border: Border.all(color: c.deepBorder)`, `borderRadius: 4px`, no fill
- Header: `Container(color: c.inputSurface)` + `MouseRegion` + `GestureDetector` (matches SelectableTransportCard pattern)
- Hover: `c.surfaceHoverOverlay` blended on header bg  
- Divider: 1px `c.borderColor` between header and body
- Body: `Container(color: c.sidebarBackground)` with padding `9px 10px 10px`

Replace the entire `build()` return value. All logic methods (`_test`, `_save`, `_persist`, etc.) are unchanged.

- [ ] **Step 1: Replace `build()` in `_OllamaCardState`**

Current `build()` starting at line 170 returns:

```dart
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
          if (!_expanded) {
            _testPassed = false;
            _showSaveAnyway = false;
          }
        }),
        borderRadius: BorderRadius.circular(8),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? c.surfaceHoverOverlay : null,
        ),
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
                'Ollama',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusLabel(),
                style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
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
                const SizedBox(height: 8),
                InlineErrorRow(message: 'Cannot connect to Ollama', onSaveAnyway: _saveAnyway),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  InlineTestButton(
                    loading: _saveLoading,
                    testPassed: _testPassed,
                    passedLabel: '✓ Connected',
                    onPressed: _test,
                  ),
                  const SizedBox(width: 8),
                  InlineSaveButton(loading: false, onPressed: _save),
                  const SizedBox(width: 8),
                  InlineClearButton(onPressed: _clear),
                ],
              ),
            ],
          ),
        ),
    ],
  ),
);
```

Replace with:

```dart
final headerContent = Row(
  children: [
    Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
    ),
    const SizedBox(width: 10),
    Text(
      'Ollama',
      style: TextStyle(
        color: c.headingText,
        fontSize: ThemeConstants.uiFontSizeSmall,
        fontWeight: FontWeight.w600,
      ),
    ),
    const Spacer(),
    _OllamaStatusBadge(status: _dotStatus, label: _statusLabel()),
    const SizedBox(width: 8),
    Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
  ],
);

return Container(
  decoration: BoxDecoration(
    border: Border.all(color: c.deepBorder),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => setState(() {
            _expanded = !_expanded;
            if (!_expanded) {
              _testPassed = false;
              _showSaveAnyway = false;
            }
          }),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _hovered ? Color.alphaBlend(c.surfaceHoverOverlay, c.inputSurface) : c.inputSurface,
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(3))
                  : BorderRadius.circular(3),
            ),
            child: headerContent,
          ),
        ),
      ),
      if (_expanded) ...[
        Divider(height: 1, thickness: 1, color: c.borderColor),
        Container(
          color: c.sidebarBackground,
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: widget.controller,
                fontFamily: ThemeConstants.editorFontFamily,
                hintText: 'http://localhost:11434',
              ),
              if (_showSaveAnyway) ...[
                const SizedBox(height: 8),
                InlineErrorRow(message: 'Cannot connect to Ollama', onSaveAnyway: _saveAnyway),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  InlineTestButton(
                    loading: _saveLoading,
                    testPassed: _testPassed,
                    passedLabel: '✓ Connected',
                    onPressed: _test,
                  ),
                  const SizedBox(width: 8),
                  InlineSaveButton(loading: false, onPressed: _save),
                  const SizedBox(width: 8),
                  InlineClearButton(onPressed: _clear),
                ],
              ),
            ],
          ),
        ),
      ],
    ],
  ),
);
```

Also add `bool _hovered = false;` to `_OllamaCardState` fields (alongside the existing `bool _expanded = false;`).

Add the `_OllamaStatusBadge` private widget at the bottom of the file (outside `_OllamaCardState`). It mirrors the `CardStatusBadge` layout but uses the `DotStatus`-driven color directly:

```dart
class _OllamaStatusBadge extends StatelessWidget {
  const _OllamaStatusBadge({required this.status, required this.label});
  final DotStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dotColor, textColor) = switch (status) {
      DotStatus.empty => (c.mutedFg, c.textMuted),
      DotStatus.unsaved => (c.warning, c.warning),
      DotStatus.savedVerified => (c.success, c.success),
      DotStatus.savedUnverified => (c.success.withValues(alpha: 0.45), c.textSecondary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/providers/widgets/ollama_card.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/providers/widgets/ollama_card.dart
git commit -m "feat(providers): replace OllamaCard bespoke shell with unified chrome"
```

---

## Task 6: `custom_endpoint_card.dart` — unified chrome

**Files:**
- Modify: `lib/features/providers/widgets/custom_endpoint_card.dart`

Exact same chrome replacement as Task 5. The only differences are: two input fields instead of one, the card label is `'Custom'`, and there is no `_statusLabel()` method (copy it from OllamaCard pattern — it already exists in `_CustomEndpointCardState`).

- [ ] **Step 1: Add `_hovered` field**

Add `bool _hovered = false;` to `_CustomEndpointCardState` fields alongside `bool _expanded = false;`.

- [ ] **Step 2: Add `_CustomStatusBadge` private widget**

At the bottom of the file, add (same structure as `_OllamaStatusBadge`):

```dart
class _CustomStatusBadge extends StatelessWidget {
  const _CustomStatusBadge({required this.status, required this.label});
  final DotStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dotColor, textColor) = switch (status) {
      DotStatus.empty => (c.mutedFg, c.textMuted),
      DotStatus.unsaved => (c.warning, c.warning),
      DotStatus.savedVerified => (c.success, c.success),
      DotStatus.savedUnverified => (c.success.withValues(alpha: 0.45), c.textSecondary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Replace `build()` in `_CustomEndpointCardState`**

Replace the entire `build()` return value (lines 204–300). The header row now shows the status badge using `_CustomStatusBadge`. The body contains two input fields instead of one.

```dart
final headerContent = Row(
  children: [
    Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
    ),
    const SizedBox(width: 10),
    Text(
      'Custom',
      style: TextStyle(
        color: c.headingText,
        fontSize: ThemeConstants.uiFontSizeSmall,
        fontWeight: FontWeight.w600,
      ),
    ),
    const Spacer(),
    _CustomStatusBadge(status: _dotStatus, label: _statusLabel()),
    const SizedBox(width: 8),
    Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
  ],
);

return Container(
  decoration: BoxDecoration(
    border: Border.all(color: c.deepBorder),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => setState(() {
            _expanded = !_expanded;
            if (!_expanded) {
              _testPassed = false;
              _showSaveAnyway = false;
            }
          }),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _hovered ? Color.alphaBlend(c.surfaceHoverOverlay, c.inputSurface) : c.inputSurface,
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(3))
                  : BorderRadius.circular(3),
            ),
            child: headerContent,
          ),
        ),
      ),
      if (_expanded) ...[
        Divider(height: 1, thickness: 1, color: c.borderColor),
        Container(
          color: c.sidebarBackground,
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 8),
                InlineErrorRow(message: 'Cannot connect to endpoint', onSaveAnyway: _saveAnyway),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  InlineTestButton(
                    loading: _saveLoading,
                    testPassed: _testPassed,
                    passedLabel: '✓ Connected',
                    onPressed: _test,
                  ),
                  const SizedBox(width: 8),
                  InlineSaveButton(loading: false, onPressed: _save),
                  const SizedBox(width: 8),
                  InlineClearButton(label: '✕ All', onPressed: _clearAll),
                ],
              ),
            ],
          ),
        ),
      ],
    ],
  ),
);
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/providers/widgets/custom_endpoint_card.dart
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/providers/widgets/custom_endpoint_card.dart
git commit -m "feat(providers): replace CustomEndpointCard bespoke shell with unified chrome"
```

---

## Task 7: `api_keys_step.dart` — collapsible cards + CLI detection banner

**Files:**
- Modify: `lib/features/onboarding/widgets/api_keys_step.dart`

### Background

The current widget uses a flat `_ProviderRow` (label on left, input field, test button, remove button — all inline). Replace with `_OnboardingProviderCard` — a collapsible card using the same chrome as the settings cards (unified chrome). Key differences from settings cards:

- No radio dot (onboarding has no transport selection per card)
- Status badge is a simple `_OnboardingStatusBadge` (dot + label, driven by `_dotStatus`)
- A ✕ remove button sits between badge and chevron (hidden when only 1 card remains)
- Body background: `c.sidebarBackground`
- For Anthropic specifically: if `claude-cli` is detected as `ProviderAvailable`, the card auto-expands and shows a teal CLI banner at the top of the body

### State changes in `_ApiKeysStepState`

Add:
- `final Set<AIProvider> _savedProviders = {}` — tracks which providers have a saved key; gates Save & Continue
- `bool _cliSelected = false` — set to true when user taps "Use CLI"; also gates Save & Continue

Remove:
- `final Map<AIProvider, bool?> _testResults = {}` — test state moves into each `_OnboardingProviderCard`
- `final Map<AIProvider, bool> _testing = {}` — same

Remove methods:
- `_testConnection(AIProvider)` — moves into `_OnboardingProviderCard`

Add method `_useAnthropicCli()`:
```dart
Future<void> _useAnthropicCli() async {
  await ref.read(providersActionsProvider.notifier).saveAnthropicTransport('cli');
  if (!mounted) return;
  if (!ref.read(providersActionsProvider).hasError) {
    setState(() => _cliSelected = true);
    widget.onContinue();
  } else {
    AppSnackBar.show(context, 'Could not save CLI transport — please retry', type: AppSnackBarType.error);
  }
}
```

Change `_saveAll()` to only iterate `_addedProviders` controllers, call `saveApiKey(provider.name, key)` per non-empty key, then call `widget.onContinue()`:
```dart
Future<void> _saveAll() async {
  setState(() => _saving = true);
  try {
    final actions = ref.read(providersActionsProvider.notifier);
    for (final provider in _addedProviders) {
      final key = _controllers[provider]!.text.trim();
      if (key.isEmpty) continue;
      await actions.saveApiKey(provider.name, key);
      if (!mounted) return;
      if (ref.read(providersActionsProvider).hasError) return;
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
  if (!mounted) return;
  widget.onContinue();
}
```

Note: `_saveAll()` is kept as a fallback for the Save & Continue button, but the primary save flow is per-card Save buttons that set `_savedProviders`. The Save & Continue button is enabled via `_canContinue`:
```dart
bool get _canContinue => _savedProviders.isNotEmpty || _cliSelected;
```

### CLI detection in `_ApiKeysStepState`

Add getter for Claude CLI entry (requires adding import for `ai_provider_status_notifier.dart`):
```dart
// add import at top:
import '../../providers/notifiers/ai_provider_status_notifier.dart';
```

In `build()`, watch the provider:
```dart
final cliStatus = ref.watch(aiProviderStatusProvider);
final claudeCliEntry = switch (cliStatus) {
  AsyncData(:final value) => value.where((e) => e.id == 'claude-cli').firstOrNull,
  _ => null,
};
final cliDetected = claudeCliEntry?.isAvailable ?? false;
```

### New widget: `_OnboardingProviderCard`

Replace `_ProviderRow` entirely with `_OnboardingProviderCard`. This is a `ConsumerStatefulWidget`.

```dart
class _OnboardingProviderCard extends ConsumerStatefulWidget {
  const _OnboardingProviderCard({
    required this.provider,
    required this.controller,
    required this.canRemove,
    required this.showCliBanner,
    required this.initiallyExpanded,
    required this.onRemove,
    required this.onSaved,
    required this.onCliUsed,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final bool canRemove;
  final bool showCliBanner;
  final bool initiallyExpanded;
  final VoidCallback onRemove;
  final VoidCallback onSaved;   // called after successful save
  final VoidCallback onCliUsed; // called when "Use CLI" tapped
}
```

`_OnboardingProviderCardState` fields:
```dart
bool _expanded;
bool _hovered = false;
bool _obscure = true;
bool _saveLoading = false;
bool _testPassed = false;
DotStatus _dotStatus = DotStatus.empty;
String _savedValue = '';

// Ollama and Custom use a URL field, not an API key; no obscuring, no Test button.
bool get _isUrlProvider =>
    widget.provider == AIProvider.ollama || widget.provider == AIProvider.custom;
```

`initState`:
```dart
@override
void initState() {
  super.initState();
  _expanded = widget.initiallyExpanded;
  widget.controller.addListener(_onTextChanged);
}
```

`didUpdateWidget` — auto-expand when CLI is detected (parent toggles `initiallyExpanded`):
```dart
@override
void didUpdateWidget(_OnboardingProviderCard old) {
  super.didUpdateWidget(old);
  if (widget.initiallyExpanded && !old.initiallyExpanded) {
    setState(() => _expanded = true);
  }
}
```

`dispose`:
```dart
@override
void dispose() {
  widget.controller.removeListener(_onTextChanged);
  super.dispose();
}
```

`_onTextChanged`:
```dart
void _onTextChanged() {
  if (_saveLoading) return;
  if (_testPassed) setState(() => _testPassed = false);
  final text = widget.controller.text.trim();
  final next = text == _savedValue
      ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
      : DotStatus.unsaved;
  if (_dotStatus != next) setState(() => _dotStatus = next);
}
```

`_test`:
```dart
Future<void> _test() async {
  final key = widget.controller.text.trim();
  if (key.isEmpty) return;
  setState(() { _saveLoading = true; _testPassed = false; });
  final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, key);
  if (!mounted) return;
  setState(() => _saveLoading = false);
  if (ok) {
    setState(() => _testPassed = true);
    AppSnackBar.show(context, 'Key is valid — click Save to persist', type: AppSnackBarType.success);
  } else {
    AppSnackBar.show(context, 'Invalid key', type: AppSnackBarType.error);
  }
}
```

`_save`:

URL providers (Ollama, Custom) save without a prior test — they have no `testApiKey` equivalent in onboarding. API-key providers test first, matching settings card behaviour.

```dart
Future<void> _save() async {
  final value = widget.controller.text.trim();
  if (value.isEmpty) return;
  setState(() => _saveLoading = true);

  if (_isUrlProvider) {
    // URL providers: save directly without testing (no Test button in onboarding)
    await ref.read(providersActionsProvider.notifier).saveApiKey(widget.provider.name, value);
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
      _savedValue = value;
      setState(() {
        _dotStatus = DotStatus.savedUnverified;
        _saveLoading = false;
      });
      widget.onSaved();
      AppSnackBar.show(context, 'Saved', type: AppSnackBarType.success);
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
    return;
  }

  final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, value);
  if (!mounted) return;
  if (ok) {
    await ref.read(providersActionsProvider.notifier).saveKey(widget.provider, value);
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
      _savedValue = value;
      setState(() {
        _dotStatus = DotStatus.savedVerified;
        _testPassed = false;
        _saveLoading = false;
      });
      widget.onSaved();
      AppSnackBar.show(context, 'API key saved', type: AppSnackBarType.success);
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  } else {
    setState(() => _saveLoading = false);
    AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
  }
}
```

`_badge` helper:
```dart
(Color dotColor, String label) _badgeInfo(AppColors c) => switch (_dotStatus) {
  DotStatus.empty => (c.mutedFg, 'Not configured'),
  DotStatus.unsaved => (c.warning, 'Unsaved changes'),
  DotStatus.savedVerified => (c.success, 'Valid & saved'),
  DotStatus.savedUnverified => (c.success.withValues(alpha: 0.45), 'Saved (unverified)'),
};
```

`build()` — the full card:
```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  final (dotColor, badgeLabel) = _badgeInfo(c);

  final headerRow = Row(
    children: [
      Text(
        widget.provider.displayName,
        style: TextStyle(
          color: c.headingText,
          fontSize: ThemeConstants.uiFontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
      // status badge
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 5),
          Text(
            badgeLabel,
            style: TextStyle(
              color: dotColor,
              fontSize: ThemeConstants.uiFontSizeLabel,
            ),
          ),
        ],
      ),
      if (widget.canRemove) ...[
        const SizedBox(width: 8),
        _RemoveButton(onPressed: widget.onRemove),
      ],
      const SizedBox(width: 8),
      Icon(
        _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
        size: 14,
        color: c.mutedFg,
      ),
    ],
  );

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: c.deepBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _hovered
                    ? Color.alphaBlend(c.surfaceHoverOverlay, c.inputSurface)
                    : c.inputSurface,
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(3))
                    : BorderRadius.circular(3),
              ),
              child: headerRow,
            ),
          ),
        ),
        // Body
        if (_expanded) ...[
          Divider(height: 1, thickness: 1, color: c.borderColor),
          Container(
            color: c.sidebarBackground,
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CLI banner (Anthropic only, when claude-cli detected)
                if (widget.showCliBanner) ...[
                  _CliBanner(onUseCli: widget.onCliUsed),
                  const SizedBox(height: 8),
                ],
                // Input field — URL for Ollama/Custom, API key for all others
                AppTextField(
                  controller: widget.controller,
                  obscureText: _isUrlProvider ? false : _obscure,
                  fontSize: 12,
                  fontFamily: ThemeConstants.editorFontFamily,
                  hintText: _isUrlProvider
                      ? 'http://localhost:11434'
                      : (widget.showCliBanner ? 'Or enter API key' : 'API key'),
                  suffixIcon: _isUrlProvider
                      ? null
                      : IconButton(
                          icon: Icon(_obscure ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // URL providers (Ollama, Custom) do not expose a Test button in
                    // onboarding — their URLs are saved unverified, matching the
                    // current _ProviderRow behaviour for _supportsTest == false.
                    if (!_isUrlProvider) ...[
                      InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        onPressed: _test,
                      ),
                      const SizedBox(width: 6),
                    ],
                    InlineSaveButton(loading: false, onPressed: _save),
                    if (_savedValue.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InlineClearButton(onPressed: _clear),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
```

Add `_clear()` method to `_OnboardingProviderCardState`:
```dart
Future<void> _clear() async {
  await ref.read(providersActionsProvider.notifier).deleteKey(widget.provider);
  if (!mounted) return;
  if (!ref.read(providersActionsProvider).hasError) {
    widget.controller.clear();
    _savedValue = '';
    setState(() {
      _dotStatus = DotStatus.empty;
      _testPassed = false;
    });
    AppSnackBar.show(context, 'Key cleared', type: AppSnackBarType.success);
  } else {
    AppSnackBar.show(context, 'Failed to clear — please retry', type: AppSnackBarType.error);
  }
}
```

### New private widgets

Add `_CliBanner` widget (shown inside Anthropic card body when CLI is detected):

```dart
class _CliBanner extends StatelessWidget {
  const _CliBanner({required this.onUseCli});
  final VoidCallback onUseCli;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.accentTintLight,
        border: Border.all(color: c.accentBorderTeal),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Claude Code CLI found · no API key needed',
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ),
          const SizedBox(width: 6),
          _UseCliButton(onPressed: onUseCli),
        ],
      ),
    );
  }
}
```

Add `_UseCliButton` widget:

```dart
class _UseCliButton extends StatefulWidget {
  const _UseCliButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_UseCliButton> createState() => _UseCliButtonState();
}

class _UseCliButtonState extends State<_UseCliButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? c.accentTintMid : c.accentTintLight,
            border: Border.all(color: c.accentBorderTeal),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'Use CLI',
            style: TextStyle(
              color: c.accent,
              fontSize: ThemeConstants.uiFontSizeLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
```

Add `_RemoveButton` widget (the ✕ in the card header):

```dart
class _RemoveButton extends StatefulWidget {
  const _RemoveButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? c.surfaceHoverOverlay : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '✕',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
        ),
      ),
    );
  }
}
```

### Updated `_ApiKeysStepState.build()`

```dart
@override
Widget build(BuildContext context) {
  final c = AppColors.of(context);
  ref.listen(providersActionsProvider, (_, next) {
    if (!_saving) return;
    if (next is! AsyncError || !mounted) return;
    AppSnackBar.show(context, 'Failed to save API key — please try again', type: AppSnackBarType.error);
  });

  final cliStatus = ref.watch(aiProviderStatusProvider);
  final claudeCliEntry = switch (cliStatus) {
    AsyncData(:final value) => value.where((e) => e.id == 'claude-cli').firstOrNull,
    _ => null,
  };
  final cliDetected = claudeCliEntry?.isAvailable ?? false;

  final allAdded = _addedProviders.length == AIProvider.values.length;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          children: [
            ..._addedProviders.map(
              (provider) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _OnboardingProviderCard(
                  key: ValueKey(provider),
                  provider: provider,
                  controller: _controllers[provider]!,
                  canRemove: _addedProviders.length > 1,
                  showCliBanner: provider == AIProvider.anthropic && cliDetected,
                  initiallyExpanded: provider == AIProvider.anthropic && cliDetected,
                  onRemove: () => _removeProvider(provider),
                  onSaved: () => setState(() => _savedProviders.add(provider)),
                  onCliUsed: _useAnthropicCli,
                ),
              ),
            ),
            if (!allAdded)
              Builder(
                builder: (btnCtx) => TextButton.icon(
                  onPressed: () => _showProviderPicker(btnCtx),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add another provider'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: widget.onSkip,
            style: TextButton.styleFrom(
              foregroundColor: c.textMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
          ),
          Opacity(
            opacity: _canContinue ? 1.0 : 0.4,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: (_saving || !_canContinue) ? null : _saveAll,
              child: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save & Continue', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 1: Update state fields and add imports**

Add to imports:
```dart
import '../../providers/notifiers/ai_provider_status_notifier.dart';
```

In `_ApiKeysStepState`, add fields:
```dart
final Set<AIProvider> _savedProviders = {};
bool _cliSelected = false;

bool get _canContinue => _savedProviders.isNotEmpty || _cliSelected;
```

Remove fields:
```dart
// DELETE these two lines:
final Map<AIProvider, bool?> _testResults = {};
final Map<AIProvider, bool> _testing = {};
```

Update `_removeProvider` to also clean up `_savedProviders`:
```dart
void _removeProvider(AIProvider provider) {
  setState(() {
    _addedProviders.remove(provider);
    _controllers[provider]?.dispose();
    _controllers.remove(provider);
    _savedProviders.remove(provider);
  });
}
```

- [ ] **Step 2: Add `_useAnthropicCli()` method**

```dart
Future<void> _useAnthropicCli() async {
  await ref.read(providersActionsProvider.notifier).saveAnthropicTransport('cli');
  if (!mounted) return;
  if (!ref.read(providersActionsProvider).hasError) {
    setState(() => _cliSelected = true);
    widget.onContinue();
  } else {
    AppSnackBar.show(context, 'Could not save CLI transport — please retry', type: AppSnackBarType.error);
  }
}
```

- [ ] **Step 3: Update `_saveAll()` method**

Replace the existing `_saveAll()`:
```dart
Future<void> _saveAll() async {
  if (!_canContinue) return;
  setState(() => _saving = true);
  try {
    final actions = ref.read(providersActionsProvider.notifier);
    for (final provider in _addedProviders) {
      final key = _controllers[provider]!.text.trim();
      if (key.isEmpty) continue;
      await actions.saveApiKey(provider.name, key);
      if (!mounted) return;
      if (ref.read(providersActionsProvider).hasError) return;
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
  if (!mounted) return;
  widget.onContinue();
}
```

- [ ] **Step 4: Delete `_testConnection()` method** (test logic moves into `_OnboardingProviderCard`)

- [ ] **Step 5: Replace `build()` with the version shown above**

- [ ] **Step 6: Delete `_ProviderRow` and its state class**

Delete the `_ProviderRow` `StatefulWidget`, its `_ProviderRowState`, and any associated helper classes that were only used by `_ProviderRow`. These start after the closing `}` of `_ApiKeysStepState.build()` and run to the end of the file. In the original file (before your edits in this task) this is everything from line 200 onwards.

- [ ] **Step 7: Add `_OnboardingProviderCard`, `_CliBanner`, `_UseCliButton`, `_RemoveButton` private widgets** using the code shown in the Background section above.

- [ ] **Step 8: Verify**

```bash
flutter analyze lib/features/onboarding/widgets/api_keys_step.dart
```

Expected: no issues. If there are issues with `AppIcons` references, check `lib/core/constants/app_icons.dart` for the correct constant names (`AppIcons.hideSecret`, `AppIcons.showSecret`, `AppIcons.chevronUp`, `AppIcons.chevronDown`).

- [ ] **Step 9: Run full analyze**

```bash
flutter analyze
```

Expected: no issues across all files.

- [ ] **Step 10: Run tests**

```bash
flutter test
```

Expected: all passing.

- [ ] **Step 11: Visual check**

```bash
flutter run -d macos
```

Open Settings › Providers and verify:
- All provider cards (Anthropic, OpenAI, Gemini) start collapsed
- OllamaCard and CustomEndpointCard have 4px radius, `inputSurface` header, `sidebarBackground` body
- Clicking a transport card expands it cleanly; body is at full opacity even when CLI card is disabled
- Selected transport card has no accent border — just `deepBorder`
- Broken-active CLI state shows InstallCommand between error text and buttons

Relaunch the onboarding step and verify:
- Single Anthropic card, collapsed by default
- Tapping header expands it to show API key field + Test + Save buttons
- Save button updates the badge and enables Save & Continue
- Add provider picker works; ✕ is hidden on the last remaining card
- If `claude` CLI is on PATH: Anthropic card auto-expands with CLI banner; "Use CLI" advances the step

- [ ] **Step 12: Commit**

```bash
git add lib/features/onboarding/widgets/api_keys_step.dart
git commit -m "feat(onboarding): replace flat provider rows with collapsible cards and CLI detection"
```
