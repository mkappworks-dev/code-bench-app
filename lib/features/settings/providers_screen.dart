import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../data/models/ai_model.dart';
import 'notifiers/providers_notifier.dart';
import 'notifiers/settings_actions.dart';
import 'settings_widgets.dart';

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
    await ref
        .read(apiKeysProvider.notifier)
        .saveAll(
          providerKeys: {for (final e in _controllers.entries) e.key: e.value.text},
          ollamaUrl: _ollamaController.text.trim(),
          customEndpoint: _customEndpointController.text.trim(),
          customApiKey: _customApiKeyController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved'), backgroundColor: ThemeConstants.success));
    }
  }

  Future<void> _deleteKey(AIProvider provider) async {
    await ref.read(apiKeysProvider.notifier).deleteKey(provider);
    _controllers[provider]!.clear();
  }

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      ok
          ? const SnackBar(content: Text('Ollama is running!'), backgroundColor: ThemeConstants.success)
          : const SnackBar(content: Text('Cannot connect to Ollama.'), backgroundColor: ThemeConstants.error),
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
          const SizedBox(height: 16),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: ApiConstants.ollamaDefaultBaseUrl,
                trailing: SizedBox(width: 200, child: InlineTextField(controller: _ollamaController)),
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
          const SizedBox(height: 16),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          SettingsGroup(
            rows: [
              SettingsRow(
                label: 'Base URL',
                description: 'http://localhost:1234/v1',
                trailing: SizedBox(width: 200, child: InlineTextField(controller: _customEndpointController)),
              ),
              SettingsRow(
                label: 'API Key',
                description: 'sk-... or leave blank',
                trailing: SizedBox(
                  width: 200,
                  child: InlineTextField(controller: _customApiKeyController, obscureText: true),
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
    final hasKey = widget.controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.inputSurface,
        border: Border.all(color: ThemeConstants.deepBorder),
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
                    decoration: BoxDecoration(
                      color: hasKey ? ThemeConstants.success : ThemeConstants.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasKey ? 'Configured' : 'Not configured',
                    style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 11),
                  ),
                  const Spacer(),
                  Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: ThemeConstants.mutedFg),
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
                    child: TextField(
                      controller: widget.controller,
                      obscureText: _obscure,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 12,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'API key',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 14, color: ThemeConstants.error),
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
