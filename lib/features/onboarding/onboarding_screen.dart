import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/datasources/local/onboarding_preferences.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/ai_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<AIProvider> _addedProviders = [AIProvider.anthropic];
  final Map<AIProvider, TextEditingController> _controllers = {
    AIProvider.anthropic: TextEditingController(),
  };
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

  Future<void> _showProviderPicker() async {
    final available =
        AIProvider.values.where((p) => !_addedProviders.contains(p)).toList();
    if (available.isEmpty) return;

    final picked = await showDialog<AIProvider>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: ThemeConstants.panelBackground,
        title: const Text(
          'Add a provider',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
        ),
        children: [
          ...available.map(
            (p) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text(
                p.displayName,
                style: const TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text(
              'Cancel',
              style:
                  TextStyle(color: ThemeConstants.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (picked != null) _addProvider(picked);
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
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $key'},
      ));
      await dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _testAnthropic(String key) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.anthropic.com/v1',
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ));
      await dio.post('/messages', data: {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
      });
      return true;
    } catch (e) {
      if (e.toString().contains('400')) return true;
      return false;
    }
  }

  Future<bool> _testGemini(String key) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 10),
      ));
      await dio.get('/models?key=$key');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _skip() async {
    final prefs = ref.read(onboardingPreferencesProvider);
    await prefs.markCompleted();
    if (mounted) context.go('/dashboard');
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageSourceProvider);
      final prefs = ref.read(onboardingPreferencesProvider);

      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isNotEmpty) {
          await storage.writeApiKey(entry.key.name, key);
        }
      }

      await prefs.markCompleted();
      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAdded = _addedProviders.length == AIProvider.values.length;

    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Row(
        children: [
          // ── Left panel (38%) — branding ──────────────────────────────
          Expanded(
            flex: 38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                  colors: [
                    Color(0xFF111111),
                    Color(0xFF0A0A0A),
                    Color(0xFF050505)
                  ],
                ),
                border: Border(
                  right: BorderSide(color: Color(0xFF2A2A2A)),
                ),
              ),
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007ACC), Color(0xFF004F85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Code Bench',
                        style: TextStyle(
                          color: Color(0xFFF0F0F0),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI-powered coding workspace',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FeatureCard(
                    icon: '⚡',
                    title: 'Multi-provider AI',
                    subtitle: 'OpenAI · Anthropic · Gemini · Ollama',
                  ),
                  const SizedBox(height: 8),
                  _FeatureCard(
                    icon: '🖊',
                    title: 'Smart Code Editor',
                    subtitle: 'AI apply · diff view · file explorer',
                  ),
                  const SizedBox(height: 8),
                  _FeatureCard(
                    icon: '🐙',
                    title: 'GitHub Integration',
                    subtitle: 'PRs · commits · repo browser',
                  ),
                  const Spacer(),
                  const Text(
                    '🔒 Keys stored in your OS keychain',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel — form ────────────────────────────────────────
          Expanded(
            flex: 62,
            child: Container(
              color: const Color(0xFF141414),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add API Keys',
                    style: TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add now or any time in Settings.',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  if (!allAdded) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _showProviderPicker,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add another provider'),
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeConstants.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: ThemeConstants.borderColor),
                            foregroundColor: ThemeConstants.textSecondary,
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveAndContinue,
                          child: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save & Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon  $title',
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

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

  bool get _isUrlProvider =>
      widget.provider == AIProvider.ollama ||
      widget.provider == AIProvider.custom;

  bool get _supportsTest =>
      widget.provider == AIProvider.openai ||
      widget.provider == AIProvider.anthropic ||
      widget.provider == AIProvider.gemini;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.provider.displayName.toUpperCase(),
            style: const TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: !_isUrlProvider && _obscure,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 13,
              fontFamily: ThemeConstants.editorFontFamily,
            ),
            decoration: InputDecoration(
              hintText:
                  _isUrlProvider ? 'http://localhost:11434' : 'API key...',
            ),
          ),
        ),
        if (!_isUrlProvider) ...[
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: ThemeConstants.textSecondary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
        if (_supportsTest) ...[
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: widget.isTesting ? null : widget.onTest,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.testResult == true
                    ? ThemeConstants.success
                    : ThemeConstants.borderColor,
              ),
              foregroundColor: widget.testResult == true
                  ? ThemeConstants.success
                  : ThemeConstants.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: widget.isTesting
                ? const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.testResult == true ? '✓ OK' : 'Test',
                    style: const TextStyle(fontSize: 11),
                  ),
          ),
        ],
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            Icons.close,
            size: 14,
            color: widget.canRemove
                ? ThemeConstants.textSecondary
                : ThemeConstants.borderColor,
          ),
          onPressed: widget.canRemove ? widget.onRemove : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
          tooltip: widget.canRemove ? 'Remove' : null,
        ),
      ],
    );
  }
}
