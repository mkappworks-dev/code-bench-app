import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/ai_model.dart';
import '../../services/ai/ai_service_factory.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final storage = ref.read(secureStorageSourceProvider);
    for (final provider in _controllers.keys) {
      final key = await storage.readApiKey(provider.name);
      if (key != null) _controllers[provider]!.text = key;
    }
    final ollamaUrl = await storage.readOllamaUrl();
    _ollamaController.text = ollamaUrl ?? ApiConstants.ollamaDefaultBaseUrl;
    final customEndpoint = await storage.readCustomEndpoint();
    if (customEndpoint != null) _customEndpointController.text = customEndpoint;
    final customApiKey = await storage.readCustomApiKey();
    if (customApiKey != null) _customApiKeyController.text = customApiKey;
    setState(() {});
  }

  Future<void> _saveKeys() async {
    final storage = ref.read(secureStorageSourceProvider);
    for (final entry in _controllers.entries) {
      final key = entry.value.text.trim();
      if (key.isNotEmpty) {
        await storage.writeApiKey(entry.key.name, key);
      } else {
        await storage.deleteApiKey(entry.key.name);
      }
    }
    final ollamaUrl = _ollamaController.text.trim();
    if (ollamaUrl.isNotEmpty) {
      await storage.writeOllamaUrl(ollamaUrl);
    }
    final customEndpoint = _customEndpointController.text.trim();
    await storage.writeCustomEndpoint(customEndpoint);
    final customApiKey = _customApiKeyController.text.trim();
    await storage.writeCustomApiKey(customApiKey);

    ref.invalidate(aiServiceProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: ThemeConstants.success,
        ),
      );
    }
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

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    try {
      final testDio = Dio(
        BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 5)),
      );
      await testDio.get('/api/tags');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ollama is running!'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot connect to Ollama. Make sure it is running.'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            _SectionHeader(title: 'API Keys'),
            const SizedBox(height: 16),

            ...AIProvider.values
                .where((p) => p != AIProvider.ollama && p != AIProvider.custom)
                .map(
                  (provider) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ApiKeyField(
                      provider: provider,
                      controller: _controllers[provider]!,
                    ),
                  ),
                ),

            const SizedBox(height: 16),
            _SectionHeader(title: 'Ollama (Local)'),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Base URL',
              hint: ApiConstants.ollamaDefaultBaseUrl,
              controller: _ollamaController,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _testOllama,
              icon: const Icon(Icons.play_arrow_outlined, size: 14),
              label: const Text('Test Connection'),
            ),

            const SizedBox(height: 16),
            _SectionHeader(title: 'Custom Endpoint (OpenAI-compatible)'),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Base URL',
              hint: 'http://localhost:1234/v1',
              controller: _customEndpointController,
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'API Key (optional)',
              hint: 'sk-... or leave blank',
              controller: _customApiKeyController,
              obscureText: true,
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _saveKeys,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: ThemeConstants.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({required this.provider, required this.controller});

  final AIProvider provider;
  final TextEditingController controller;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.provider.displayName,
      hint: 'API key',
      controller: widget.controller,
      obscureText: _obscure,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          size: 16,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 13,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
            decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
          ),
        ],
      ),
    );
  }
}
