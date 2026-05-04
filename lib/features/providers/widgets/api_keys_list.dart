// lib/features/providers/widgets/api_keys_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/providers_notifier.dart';
import 'anthropic_provider_card.dart';
import 'custom_endpoint_card.dart';
import 'gemini_provider_card.dart';
import 'ollama_card.dart';
import 'openai_provider_card.dart';

/// Vertical stack of all five provider cards (OpenAI, Anthropic, Gemini,
/// Ollama, Custom Endpoint). Owns the text controllers and the initial
/// values loaded from [apiKeysProvider]; each card handles its own
/// save/test/clear behaviour and transport selection internally.
///
/// Used by both the providers settings screen and the onboarding API-keys
/// step so the cards behave identically in both places.
class ApiKeysList extends ConsumerStatefulWidget {
  const ApiKeysList({super.key});

  @override
  ConsumerState<ApiKeysList> createState() => _ApiKeysListState();
}

class _ApiKeysListState extends ConsumerState<ApiKeysList> {
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
    ref.listen(apiKeysProvider, (_, next) {
      if (!mounted || next is! AsyncError) return;
      AppSnackBar.show(context, 'Could not load API keys — please restart the app.', type: AppSnackBarType.error);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpenAIProviderCard(controller: _controllers[AIProvider.openai]!, initialApiKey: _initialOpenAi),
        const SizedBox(height: 16),
        AnthropicProviderCard(controller: _controllers[AIProvider.anthropic]!, initialApiKey: _initialAnthropic),
        const SizedBox(height: 16),
        GeminiProviderCard(controller: _controllers[AIProvider.gemini]!, initialApiKey: _initialGemini),
        const SizedBox(height: 16),
        OllamaCard(controller: _ollamaController, initialValue: _initialOllamaUrl),
        const SizedBox(height: 16),
        CustomEndpointCard(
          urlController: _customEndpointController,
          apiKeyController: _customApiKeyController,
          initialUrl: _initialCustomEndpoint,
          initialApiKey: _initialCustomApiKey,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
