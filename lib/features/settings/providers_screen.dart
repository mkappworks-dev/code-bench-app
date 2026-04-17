import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snack_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final s = await ref.read(apiKeysProvider.future);
    if (!mounted) return;
    _controllers[AIProvider.openai]!.text = s.openai;
    _controllers[AIProvider.anthropic]!.text = s.anthropic;
    _controllers[AIProvider.gemini]!.text = s.gemini;
    _ollamaController.text = s.ollamaUrl;
    _customEndpointController.text = s.customEndpoint;
    _customApiKeyController.text = s.customApiKey;
    setState(() {});
  }

  Future<void> _saveKeys() async {
    final ok = await ref
        .read(apiKeysProvider.notifier)
        .saveAll(
          providerKeys: {for (final e in _controllers.entries) e.key: e.value.text},
          ollamaUrl: _ollamaController.text.trim(),
          customEndpoint: _customEndpointController.text.trim(),
          customApiKey: _customApiKeyController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(context, 'Settings saved', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Failed to save settings — please try again', type: AppSnackBarType.error);
    }
  }

  Future<void> _deleteKey(AIProvider provider) async {
    final ok = await ref.read(apiKeysProvider.notifier).deleteKey(provider);
    if (ok) _controllers[provider]!.clear();
  }

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    AppSnackBar.show(
      context,
      ok ? 'Ollama is running!' : 'Cannot connect to Ollama.',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
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
                    onDelete: () => _deleteKey(provider),
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
                trailing: SizedBox(
                  width: 200,
                  child: AppTextField(controller: _ollamaController, fontFamily: ThemeConstants.editorFontFamily),
                ),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _testOllama,
            icon: const Icon(AppIcons.run, size: 12),
            label: const Text('Test Connection', style: TextStyle(fontSize: 11)),
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: 'http://localhost:1234/v1',
                trailing: SizedBox(
                  width: 200,
                  child: AppTextField(
                    controller: _customEndpointController,
                    fontFamily: ThemeConstants.editorFontFamily,
                  ),
                ),
              ),
              SettingsRow(
                label: 'API Key',
                description: 'sk-... or leave blank',
                trailing: SizedBox(
                  width: 200,
                  child: AppTextField(
                    controller: _customApiKeyController,
                    obscureText: true,
                    fontFamily: ThemeConstants.editorFontFamily,
                  ),
                ),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: _saveKeys,
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Provider key card ─────────────────────────────────────────────────────────

class _ProviderKeyCard extends StatefulWidget {
  const _ProviderKeyCard({required this.provider, required this.controller, required this.onDelete});

  final AIProvider provider;
  final TextEditingController controller;
  final VoidCallback onDelete;

  @override
  State<_ProviderKeyCard> createState() => _ProviderKeyCardState();
}

class _ProviderKeyCardState extends State<_ProviderKeyCard> {
  bool _obscure = true;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasKey = widget.controller.text.isNotEmpty;
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
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: hasKey ? c.success : c.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasKey ? 'Configured' : 'Not configured',
                    style: TextStyle(color: c.textSecondary, fontSize: 11),
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
                  IconButton(
                    icon: Icon(AppIcons.close, size: 14, color: c.error),
                    tooltip: 'Remove key',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
