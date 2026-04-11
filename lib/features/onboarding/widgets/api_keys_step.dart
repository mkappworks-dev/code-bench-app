import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/datasources/local/secure_storage_source.dart';
import '../../../data/models/ai_model.dart';

class ApiKeysStep extends ConsumerStatefulWidget {
  const ApiKeysStep({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  ConsumerState<ApiKeysStep> createState() => _ApiKeysStepState();
}

class _ApiKeysStepState extends ConsumerState<ApiKeysStep> {
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
                    color: ThemeConstants.textPrimary, fontSize: 13),
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

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageSourceProvider);
      for (final entry in _controllers.entries) {
        final key = entry.value.text.trim();
        if (key.isNotEmpty) {
          await storage.writeApiKey(entry.key.name, key);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
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
                TextButton.icon(
                  onPressed: _showProviderPicker,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add another provider'),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeConstants.accent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ThemeConstants.accent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: _saving ? null : _saveAll,
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save & Continue', style: TextStyle(fontSize: 12)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: widget.isTesting
                ? const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2))
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
