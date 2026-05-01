// lib/features/providers/providers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/shared/ai_model.dart';
import '../settings/widgets/section_label.dart';
import 'notifiers/providers_notifier.dart';
import 'widgets/anthropic_provider_card.dart';
import 'widgets/custom_endpoint_card.dart';
import 'widgets/gemini_provider_card.dart';
import 'widgets/ollama_card.dart';
import 'widgets/openai_provider_card.dart';

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

    ref.listen(apiKeysProvider, (_, next) {
      if (!mounted) return;
      if (next is AsyncError) {
        AppSnackBar.show(context, 'Could not load API keys — please restart the app.', type: AppSnackBarType.error);
      }
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('API Keys'),
          const SizedBox(height: 8),
          OpenAIProviderCard(controller: _controllers[AIProvider.openai]!, initialApiKey: _initialOpenAi),
          const SizedBox(height: 16),
          AnthropicProviderCard(controller: _controllers[AIProvider.anthropic]!, initialApiKey: _initialAnthropic),
          const SizedBox(height: 16),
          GeminiProviderCard(controller: _controllers[AIProvider.gemini]!, initialApiKey: _initialGemini),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          OllamaCard(controller: _ollamaController, initialValue: _initialOllamaUrl),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          CustomEndpointCard(
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
