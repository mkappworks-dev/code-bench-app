import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/shared/ai_model.dart';
import '../../settings/notifiers/settings_actions.dart';

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
  final Map<AIProvider, bool?> _testResults = {};
  final Map<AIProvider, bool> _testing = {};
  bool _saving = false;

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
      _testResults.remove(provider);
      _testing.remove(provider);
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

  Future<void> _testConnection(AIProvider provider) async {
    final key = _controllers[provider]!.text.trim();
    if (key.isEmpty) return;
    setState(() => _testing[provider] = true);
    try {
      final success = await ref.read(settingsActionsProvider.notifier).testApiKey(provider, key);
      if (!mounted) return;
      setState(() => _testResults[provider] = success);
    } finally {
      // Guard the finally as well: tests have a 10s connect timeout, so the
      // user can easily hit Skip and unmount the widget before the await
      // resolves. Without the check Flutter logs "setState called after
      // dispose" in debug and throws in release.
      if (mounted) setState(() => _testing[provider] = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    var allSaved = true;
    try {
      final actions = ref.read(settingsActionsProvider.notifier);
      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isEmpty) continue;
        await actions.saveApiKey(entry.key.name, key);
        if (!mounted) return;
        if (ref.read(settingsActionsProvider).hasError) {
          allSaved = false;
          break;
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (allSaved) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.listen(settingsActionsProvider, (_, next) {
      if (!_saving) return;
      if (next is! AsyncError || !mounted) return;
      AppSnackBar.show(context, 'Failed to save API key — please try again', type: AppSnackBarType.error);
    });

    final allAdded = _addedProviders.length == AIProvider.values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              ..._addedProviders.map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProviderRow(
                    provider: provider,
                    controller: _controllers[provider]!,
                    testResult: _testResults[provider],
                    isTesting: _testing[provider] ?? false,
                    canRemove: _addedProviders.length > 1,
                    onTest: () => _testConnection(provider),
                    onRemove: () => _removeProvider(provider),
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
        const SizedBox(height: 16),
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
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _saving ? null : _saveAll,
              child: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save & Continue', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Provider row ─────────────────────────────────────────────────────────────

class _ProviderRow extends StatefulWidget {
  const _ProviderRow({
    required this.provider,
    required this.controller,
    required this.testResult,
    required this.isTesting,
    required this.canRemove,
    required this.onTest,
    required this.onRemove,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final bool? testResult;
  final bool isTesting;
  final bool canRemove;
  final VoidCallback onTest;
  final VoidCallback onRemove;

  @override
  State<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends State<_ProviderRow> {
  bool _obscure = true;

  bool get _isUrlProvider => widget.provider == AIProvider.ollama || widget.provider == AIProvider.custom;

  bool get _supportsTest =>
      widget.provider == AIProvider.openai ||
      widget.provider == AIProvider.anthropic ||
      widget.provider == AIProvider.gemini;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.provider.displayName.toUpperCase(),
            style: TextStyle(color: c.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: !_isUrlProvider && _obscure,
            style: TextStyle(color: c.textPrimary, fontSize: 13, fontFamily: ThemeConstants.editorFontFamily),
            decoration: InputDecoration(hintText: _isUrlProvider ? 'http://localhost:11434' : 'API key...'),
          ),
        ),
        if (!_isUrlProvider) ...[
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 16, color: c.textSecondary),
            onPressed: () => setState(() => _obscure = !_obscure),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
        if (_supportsTest) ...[
          const SizedBox(width: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final rc = AppColors.of(context);
              final hasKey = value.text.trim().isNotEmpty;
              final Color borderCol = !hasKey
                  ? rc.borderColor
                  : widget.testResult == true
                  ? rc.success
                  : widget.testResult == false
                  ? rc.error
                  : rc.borderColor;
              final Color fgCol = widget.testResult == true
                  ? rc.success
                  : widget.testResult == false
                  ? rc.error
                  : rc.textSecondary;
              final isEnabled = hasKey && !widget.isTesting;
              return GestureDetector(
                onTap: isEnabled ? widget.onTest : null,
                child: Opacity(
                  opacity: isEnabled ? 1.0 : 0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.isTesting
                        ? SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: fgCol),
                          )
                        : Text(
                            widget.testResult == true
                                ? '✓ OK'
                                : widget.testResult == false
                                ? '✗ Fail'
                                : 'Test',
                            style: TextStyle(
                              color: fgCol,
                              fontSize: ThemeConstants.uiFontSizeSmall,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(Icons.close, size: 14, color: widget.canRemove ? c.textSecondary : c.borderColor),
          onPressed: widget.canRemove ? widget.onRemove : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
          tooltip: widget.canRemove ? 'Remove' : null,
        ),
      ],
    );
  }
}
