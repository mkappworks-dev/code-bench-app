import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/ai_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controllers = <AIProvider, TextEditingController>{
    AIProvider.openai: TextEditingController(),
    AIProvider.anthropic: TextEditingController(),
    AIProvider.gemini: TextEditingController(),
  };

  final _testResults = <AIProvider, bool?>{};
  final _testing = <AIProvider, bool>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _testConnection(AIProvider provider) async {
    final key = _controllers[provider]!.text.trim();
    if (key.isEmpty) return;

    setState(() => _testing[provider] = true);

    try {
      bool success = false;
      switch (provider) {
        case AIProvider.openai:
          success = await _testOpenAI(key);
        case AIProvider.anthropic:
          success = await _testAnthropic(key);
        case AIProvider.gemini:
          success = await _testGemini(key);
        default:
          success = false;
      }
      setState(() => _testResults[provider] = success);
    } catch (_) {
      setState(() => _testResults[provider] = false);
    } finally {
      setState(() => _testing[provider] = false);
    }
  }

  Future<bool> _testOpenAI(String key) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          connectTimeout: const Duration(seconds: 10),
          headers: {'Authorization': 'Bearer $key'},
        ),
      );
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testAnthropic(String key) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.anthropic.com/v1',
          connectTimeout: const Duration(seconds: 10),
          headers: {
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
      );
      await dio.post(
        '/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } catch (e) {
      if (e.toString().contains('400')) return true;
      return false;
    }
  }

  Future<bool> _testGemini(String key) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          connectTimeout: const Duration(seconds: 10),
        ),
      );
      await dio.get('/models?key=$key');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveAndContinue() async {
    final storage = ref.read(secureStorageSourceProvider);
    bool anyKey = false;

    setState(() => _saving = true);
    try {
      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isNotEmpty) {
          await storage.writeApiKey(entry.key.name, key);
          anyKey = true;
        }
      }

      if (!anyKey && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one API key'),
            backgroundColor: ThemeConstants.error,
          ),
        );
        return;
      }

      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Center(
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Code Bench',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure your AI providers to get started.',
                  style: TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                _ProviderKeyInput(
                  provider: AIProvider.openai,
                  controller: _controllers[AIProvider.openai]!,
                  testResult: _testResults[AIProvider.openai],
                  isTesting: _testing[AIProvider.openai] ?? false,
                  onTest: () => _testConnection(AIProvider.openai),
                ),
                const SizedBox(height: 20),
                _ProviderKeyInput(
                  provider: AIProvider.anthropic,
                  controller: _controllers[AIProvider.anthropic]!,
                  testResult: _testResults[AIProvider.anthropic],
                  isTesting: _testing[AIProvider.anthropic] ?? false,
                  onTest: () => _testConnection(AIProvider.anthropic),
                ),
                const SizedBox(height: 20),
                _ProviderKeyInput(
                  provider: AIProvider.gemini,
                  controller: _controllers[AIProvider.gemini]!,
                  testResult: _testResults[AIProvider.gemini],
                  isTesting: _testing[AIProvider.gemini] ?? false,
                  onTest: () => _testConnection(AIProvider.gemini),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveAndContinue,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      // Allow skipping — write a placeholder so guard passes
                      final storage = ref.read(secureStorageSourceProvider);
                      await storage.writeApiKey('ollama', 'local');
                      if (mounted) context.go('/dashboard');
                    },
                    child: const Text('Skip for now (use Ollama)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderKeyInput extends StatefulWidget {
  const _ProviderKeyInput({
    required this.provider,
    required this.controller,
    required this.testResult,
    required this.isTesting,
    required this.onTest,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final bool? testResult;
  final bool isTesting;
  final VoidCallback onTest;

  @override
  State<_ProviderKeyInput> createState() => _ProviderKeyInputState();
}

class _ProviderKeyInputState extends State<_ProviderKeyInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.provider.displayName,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.testResult != null) ...[
              const SizedBox(width: 8),
              Icon(
                widget.testResult! ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: widget.testResult!
                    ? ThemeConstants.success
                    : ThemeConstants.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                obscureText: _obscure,
                style: const TextStyle(color: ThemeConstants.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter API key...',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.isTesting ? null : widget.onTest,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ThemeConstants.borderColor),
                foregroundColor: ThemeConstants.textSecondary,
              ),
              child: widget.isTesting
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test'),
            ),
          ],
        ),
      ],
    );
  }
}
