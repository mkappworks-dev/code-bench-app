import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/shared/ai_model.dart';
import '../../providers/notifiers/ai_provider_status_notifier.dart';
import '../../providers/notifiers/providers_actions.dart';
import '../../providers/widgets/provider_card_helpers.dart';

class ApiKeysStep extends ConsumerStatefulWidget {
  const ApiKeysStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  ConsumerState<ApiKeysStep> createState() => _ApiKeysStepState();
}

class _ApiKeysStepState extends ConsumerState<ApiKeysStep> {
  final List<AIProvider> _addedProviders = [AIProvider.anthropic];
  final Map<AIProvider, TextEditingController> _controllers = {AIProvider.anthropic: TextEditingController()};
  final Set<AIProvider> _savedProviders = {};
  bool _cliSelected = false;
  bool _saving = false;

  bool get _canContinue => _savedProviders.isNotEmpty || _cliSelected;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
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
      _savedProviders.remove(provider);
    });
  }

  Future<void> _showProviderPicker(BuildContext btnCtx) async {
    final c = AppColors.of(btnCtx);
    final available = AIProvider.values.where((p) => !_addedProviders.contains(p)).toList();
    if (available.isEmpty) return;

    final picked = await showInstantMenuAnchoredTo<AIProvider>(
      buttonContext: btnCtx,
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: c.faintFg),
      ),
      items: available
          .map(
            (p) => PopupMenuItem(
              value: p,
              height: 30,
              child: Text(
                p.displayName,
                style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ),
          )
          .toList(),
    );

    if (picked != null) _addProvider(picked);
  }

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

  Future<void> _saveAll() async {
    if (!_canContinue) return;
    setState(() => _saving = true);
    final actions = ref.read(providersActionsProvider.notifier);
    for (final provider in _addedProviders) {
      final key = _controllers[provider]!.text.trim();
      if (key.isEmpty) continue;
      await actions.saveApiKey(provider.name, key);
      if (!mounted) {
        setState(() => _saving = false);
        return;
      }
      if (ref.read(providersActionsProvider).hasError) {
        setState(() => _saving = false);
        return;
      }
    }
    setState(() => _saving = false);
    if (!mounted) return;
    widget.onContinue();
  }

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
}

// ── Collapsible provider card ─────────────────────────────────────────────────

class _OnboardingProviderCard extends ConsumerStatefulWidget {
  const _OnboardingProviderCard({
    super.key,
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
  final VoidCallback onSaved;
  final VoidCallback onCliUsed;

  @override
  ConsumerState<_OnboardingProviderCard> createState() => _OnboardingProviderCardState();
}

class _OnboardingProviderCardState extends ConsumerState<_OnboardingProviderCard> {
  late bool _expanded;
  bool _hovered = false;
  bool _obscure = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  DotStatus _dotStatus = DotStatus.empty;
  String _savedValue = '';

  bool get _isUrlProvider => widget.provider == AIProvider.ollama || widget.provider == AIProvider.custom;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_OnboardingProviderCard old) {
    super.didUpdateWidget(old);
    if (widget.initiallyExpanded && !old.initiallyExpanded) {
      setState(() => _expanded = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
        : DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
    });
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

  Future<void> _save() async {
    final value = widget.controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _saveLoading = true);

    if (_isUrlProvider) {
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

  (Color dotColor, String label) _badgeInfo(AppColors c) => switch (_dotStatus) {
    DotStatus.empty => (c.mutedFg, 'Not configured'),
    DotStatus.unsaved => (c.warning, 'Unsaved changes'),
    DotStatus.savedVerified => (c.success, 'Valid & saved'),
    DotStatus.savedUnverified => (c.success.withValues(alpha: 0.45), 'Saved (unverified)'),
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dotColor, badgeLabel) = _badgeInfo(c);

    final headerRow = Row(
      children: [
        Text(
          widget.provider.displayName,
          style: TextStyle(color: c.headingText, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
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
              style: TextStyle(color: dotColor, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
          ],
        ),
        if (widget.canRemove) ...[const SizedBox(width: 8), _RemoveButton(onPressed: widget.onRemove)],
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
              onTap: () => setState(() => _expanded = !_expanded),
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
                child: headerRow,
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
                  if (widget.showCliBanner) ...[_CliBanner(onUseCli: widget.onCliUsed), const SizedBox(height: 8)],
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
                      if (!_isUrlProvider) ...[
                        InlineTestButton(loading: _saveLoading, testPassed: _testPassed, onPressed: _test),
                        const SizedBox(width: 6),
                      ],
                      InlineSaveButton(loading: false, onPressed: _save),
                      if (_savedValue.isNotEmpty) ...[const SizedBox(width: 6), InlineClearButton(onPressed: _clear)],
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
}

// ── CLI detection banner ──────────────────────────────────────────────────────

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
            style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeLabel, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ── Remove button ─────────────────────────────────────────────────────────────

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
