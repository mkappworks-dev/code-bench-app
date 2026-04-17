import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/shared/ai_model.dart';
import 'notifiers/providers_notifier.dart';
import 'notifiers/settings_actions.dart';
import 'widgets/section_label.dart';
import 'widgets/settings_group.dart';

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

  bool _ollamaLoading = false;
  bool _customLoading = false;

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
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not load API keys — please restart the app.', type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    if (url.isEmpty) return;
    setState(() => _ollamaLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    setState(() => _ollamaLoading = false);
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveOllamaUrl(url);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        saved ? 'Ollama URL saved' : 'Connected but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to Ollama', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearOllama() async {
    _ollamaController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Ollama URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Future<void> _testCustomEndpoint() async {
    final url = _customEndpointController.text.trim();
    if (url.isEmpty) return;
    final apiKey = _customApiKeyController.text.trim();
    setState(() => _customLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) return;
    setState(() => _customLoading = false);
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveCustomEndpoint(url, apiKey);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        saved ? 'Custom endpoint saved' : 'Connected but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      AppSnackBar.show(context, 'Cannot connect to endpoint', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearCustomEndpoint() async {
    _customEndpointController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearCustomEndpoint();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Custom URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Future<void> _clearCustomApiKey() async {
    _customApiKeyController.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearCustomApiKey();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Custom API key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
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
          ...AIProvider.values
              .where((p) => p != AIProvider.ollama && p != AIProvider.custom)
              .map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProviderKeyCard(
                    provider: provider,
                    controller: _controllers[provider]!,
                    initialHasKey: _controllers[provider]!.text.isNotEmpty,
                  ),
                ),
              ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: ApiConstants.ollamaDefaultBaseUrl,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(controller: _ollamaController, fontFamily: ThemeConstants.editorFontFamily),
                    ),
                    const SizedBox(width: 6),
                    _InlineTestButton(loading: _ollamaLoading, onPressed: _testOllama),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearOllama),
                  ],
                ),
                isLast: true,
              ),
            ],
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: 'http://localhost:1234/v1',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(
                        controller: _customEndpointController,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _InlineTestButton(loading: _customLoading, onPressed: _testCustomEndpoint),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearCustomEndpoint),
                  ],
                ),
              ),
              SettingsRow(
                label: 'API Key',
                description: 'sk-... or leave blank',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: AppTextField(
                        controller: _customApiKeyController,
                        obscureText: true,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                    ),
                    const SizedBox(width: 6 + 62),
                    const SizedBox(width: 4),
                    _InlineClearButton(onPressed: _clearCustomApiKey),
                  ],
                ),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Per-provider key card ─────────────────────────────────────────────────────

enum _KeyStatus { empty, unsaved, valid, invalid }

class _ProviderKeyCard extends ConsumerStatefulWidget {
  const _ProviderKeyCard({required this.provider, required this.controller, required this.initialHasKey});

  final AIProvider provider;
  final TextEditingController controller;
  final bool initialHasKey;

  @override
  ConsumerState<_ProviderKeyCard> createState() => _ProviderKeyCardState();
}

class _ProviderKeyCardState extends ConsumerState<_ProviderKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _loading = false;
  late _KeyStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialHasKey ? _KeyStatus.valid : _KeyStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_ProviderKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHasKey && _status == _KeyStatus.unsaved) {
      setState(() => _status = _KeyStatus.valid);
    }
  }

  void _onTextChanged() {
    if (_loading) return;
    final isEmpty = widget.controller.text.isEmpty;
    final nextStatus = isEmpty ? _KeyStatus.empty : _KeyStatus.unsaved;
    if (_status != nextStatus) setState(() => _status = nextStatus);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _loading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) return;
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) return;
      setState(() {
        _status = _KeyStatus.valid;
        _loading = false;
      });
      AppSnackBar.show(
        context,
        saved ? 'API key saved' : 'Valid but failed to save — please retry',
        type: saved ? AppSnackBarType.success : AppSnackBarType.error,
      );
    } else {
      setState(() {
        _status = _KeyStatus.invalid;
        _loading = false;
      });
      AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
    }
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    setState(() => _status = _KeyStatus.empty);
    AppSnackBar.show(
      context,
      ok ? 'Key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_status) {
    _KeyStatus.empty => c.mutedFg,
    _KeyStatus.unsaved => c.warning,
    _KeyStatus.valid => c.success,
    _KeyStatus.invalid => c.error,
  };

  String _statusLabel() => switch (_status) {
    _KeyStatus.empty => 'Not configured',
    _KeyStatus.unsaved => 'Unsaved changes',
    _KeyStatus.valid => 'Valid & saved',
    _KeyStatus.invalid => 'Invalid key',
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
            onTap: () => setState(() => _expanded = !_expanded),
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
              child: Row(
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
                  const SizedBox(width: 8),
                  _InlineTestButton(loading: _loading, status: _status, onPressed: _test),
                  const SizedBox(width: 4),
                  _InlineClearButton(onPressed: _clear),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared inline buttons ─────────────────────────────────────────────────────

class _InlineTestButton extends StatelessWidget {
  const _InlineTestButton({required this.loading, required this.onPressed, this.status});

  final bool loading;
  final VoidCallback onPressed;
  final _KeyStatus? status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 62,
        height: 26,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
        ),
      );
    }

    final (label, fgColor, bgColor, borderColor) = switch (status) {
      _KeyStatus.valid => ('✓ Valid', c.success, c.success.withValues(alpha: 0.12), c.success.withValues(alpha: 0.3)),
      _KeyStatus.invalid => ('✗ Invalid', c.error, c.error.withValues(alpha: 0.12), c.error.withValues(alpha: 0.3)),
      _ => ('Test', c.accent, c.accentTintMid, c.accent.withValues(alpha: 0.35)),
    };

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
          style: TextStyle(color: fgColor, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _InlineClearButton extends StatelessWidget {
  const _InlineClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 28,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
