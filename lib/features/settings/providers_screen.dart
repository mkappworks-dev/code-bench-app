import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/shared/ai_model.dart';
import 'notifiers/providers_notifier.dart';
import 'notifiers/settings_actions.dart';
import 'widgets/section_label.dart';

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
    try {
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
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not load API keys — please restart the app.', type: AppSnackBarType.error);
      }
    }
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
          _ApiKeyCard(
            provider: AIProvider.openai,
            controller: _controllers[AIProvider.openai]!,
            initialValue: _initialOpenAi,
          ),
          const SizedBox(height: 6),
          _ApiKeyCard(
            provider: AIProvider.anthropic,
            controller: _controllers[AIProvider.anthropic]!,
            initialValue: _initialAnthropic,
          ),
          const SizedBox(height: 6),
          _ApiKeyCard(
            provider: AIProvider.gemini,
            controller: _controllers[AIProvider.gemini]!,
            initialValue: _initialGemini,
          ),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          _OllamaCard(controller: _ollamaController, initialValue: _initialOllamaUrl),
          Divider(height: 36, thickness: 1, color: c.borderColor),
          SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          _CustomEndpointCard(
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

// ── Per-provider key card ─────────────────────────────────────────────────────

enum _DotStatus { empty, unsaved, savedVerified, savedUnverified }

// ── API key card (OpenAI · Anthropic · Gemini) ────────────────────────────────

class _ApiKeyCard extends ConsumerStatefulWidget {
  const _ApiKeyCard({required this.provider, required this.controller, required this.initialValue});

  final AIProvider provider;
  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<_ApiKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _saveTriggered = false;
  late _DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_ApiKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _savedValue = widget.initialValue;
        _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
      });
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? _DotStatus.empty : _DotStatus.savedVerified)
        : _DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Key is valid — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Invalid key', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() => _saveLoading = true);
    final ok = await ref.read(settingsActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      final saved = await ref.read(apiKeysProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) {
        _saveTriggered = false;
        return;
      }
      if (saved) {
        _savedValue = key;
        setState(() {
          _dotStatus = _DotStatus.savedVerified;
          _testPassed = false;
          _saveLoading = false;
        });
        AppSnackBar.show(context, 'API key saved', type: AppSnackBarType.success);
      } else {
        setState(() => _saveLoading = false);
        AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
      }
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Invalid key — not saved', type: AppSnackBarType.error);
    }
    _saveTriggered = false;
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Key cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Valid & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) _testPassed = false;
            }),
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
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
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
              child: Column(
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(loading: _saveLoading, testPassed: _testPassed, onPressed: _test),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ollama card (URL-only) ─────────────────────────────────────────────────────

class _OllamaCard extends ConsumerStatefulWidget {
  const _OllamaCard({required this.controller, required this.initialValue});

  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<_OllamaCard> createState() => _OllamaCardState();
}

class _OllamaCardState extends ConsumerState<_OllamaCard> {
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late _DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_OllamaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _savedValue = widget.initialValue;
        _dotStatus = _savedValue.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
      });
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? _DotStatus.empty : _DotStatus.savedVerified)
        : _DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Ollama is reachable — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Cannot connect to Ollama', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testOllamaUrl(url);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await _persist(url, verified: true);
    } else {
      setState(() {
        _saveLoading = false;
        _showSaveAnyway = true;
      });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    await _persist(url, verified: false);
  }

  Future<void> _persist(String url, {required bool verified}) async {
    final saved = await ref.read(apiKeysProvider.notifier).saveOllamaUrl(url);
    if (!mounted) return;
    if (saved) {
      _savedValue = url;
      setState(() {
        _dotStatus = verified ? _DotStatus.savedVerified : _DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(context, verified ? 'Ollama URL saved' : 'Saved (unverified)', type: AppSnackBarType.success);
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clear() async {
    widget.controller.clear();
    final ok = await ref.read(apiKeysProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    _savedValue = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(
      context,
      ok ? 'Ollama URL cleared' : 'Failed to clear — please retry',
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Connected & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) {
                _testPassed = false;
                _showSaveAnyway = false;
              }
            }),
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
                    'Ollama',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
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
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.controller,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:11434',
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    _InlineErrorRow(message: 'Cannot connect to Ollama', onSaveAnyway: _saveAnyway),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Custom endpoint card (URL + optional API key) ─────────────────────────────

class _CustomEndpointCard extends ConsumerStatefulWidget {
  const _CustomEndpointCard({
    required this.urlController,
    required this.apiKeyController,
    required this.initialUrl,
    required this.initialApiKey,
  });

  final TextEditingController urlController;
  final TextEditingController apiKeyController;
  final String initialUrl;
  final String initialApiKey;

  @override
  ConsumerState<_CustomEndpointCard> createState() => _CustomEndpointCardState();
}

class _CustomEndpointCardState extends ConsumerState<_CustomEndpointCard> {
  bool _expanded = false;
  bool _obscureKey = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late _DotStatus _dotStatus;
  late String _savedUrl;
  late String _savedApiKey;

  @override
  void initState() {
    super.initState();
    _savedUrl = widget.initialUrl;
    _savedApiKey = widget.initialApiKey;
    _dotStatus = _savedUrl.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
    widget.urlController.addListener(_onFieldChanged);
    widget.apiKeyController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onFieldChanged);
    widget.apiKeyController.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(_CustomEndpointCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl || oldWidget.initialApiKey != widget.initialApiKey) {
      setState(() {
        _savedUrl = widget.initialUrl;
        _savedApiKey = widget.initialApiKey;
        _dotStatus = _savedUrl.isNotEmpty ? _DotStatus.savedVerified : _DotStatus.empty;
      });
    }
  }

  bool get _isUnsaved =>
      widget.urlController.text.trim() != _savedUrl || widget.apiKeyController.text.trim() != _savedApiKey;

  void _onFieldChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final _DotStatus next;
    if (!_isUnsaved) {
      next = _savedUrl.isEmpty ? _DotStatus.empty : _dotStatus;
    } else {
      next = _DotStatus.unsaved;
    }
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) return;
    setState(() => _saveLoading = false);
    if (ok) {
      setState(() => _testPassed = true);
      AppSnackBar.show(context, 'Endpoint reachable — click Save to persist', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Cannot connect to endpoint', type: AppSnackBarType.error);
    }
  }

  Future<void> _save() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty || _saveTriggered) return;
    _saveTriggered = true;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    final ok = await ref.read(settingsActionsProvider.notifier).testCustomEndpoint(url, apiKey);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await _persist(url, apiKey, verified: true);
    } else {
      setState(() {
        _saveLoading = false;
        _showSaveAnyway = true;
      });
    }
    _saveTriggered = false;
  }

  Future<void> _saveAnyway() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    final apiKey = widget.apiKeyController.text.trim();
    setState(() {
      _saveLoading = true;
      _showSaveAnyway = false;
    });
    await _persist(url, apiKey, verified: false);
  }

  Future<void> _persist(String url, String apiKey, {required bool verified}) async {
    final saved = await ref.read(apiKeysProvider.notifier).saveCustomEndpoint(url, apiKey);
    if (!mounted) return;
    if (saved) {
      _savedUrl = url;
      _savedApiKey = apiKey;
      setState(() {
        _dotStatus = verified ? _DotStatus.savedVerified : _DotStatus.savedUnverified;
        _testPassed = false;
        _saveLoading = false;
      });
      AppSnackBar.show(
        context,
        verified ? 'Custom endpoint saved' : 'Saved (unverified)',
        type: AppSnackBarType.success,
      );
    } else {
      setState(() => _saveLoading = false);
      AppSnackBar.show(context, 'Failed to save — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _clearAll() async {
    widget.urlController.clear();
    widget.apiKeyController.clear();
    await ref.read(apiKeysProvider.notifier).clearCustomEndpoint();
    await ref.read(apiKeysProvider.notifier).clearCustomApiKey();
    if (!mounted) return;
    _savedUrl = '';
    _savedApiKey = '';
    setState(() {
      _dotStatus = _DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(context, 'Custom endpoint cleared', type: AppSnackBarType.success);
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    _DotStatus.empty => c.mutedFg,
    _DotStatus.unsaved => c.warning,
    _DotStatus.savedVerified => c.success,
    _DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    _DotStatus.empty => 'Not configured',
    _DotStatus.unsaved => 'Unsaved changes',
    _DotStatus.savedVerified => 'Connected & saved',
    _DotStatus.savedUnverified => 'Saved (unverified)',
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
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) {
                _testPassed = false;
                _showSaveAnyway = false;
              }
            }),
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
                    'Custom',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(),
                    style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
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
              child: Column(
                children: [
                  AppTextField(
                    controller: widget.urlController,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:1234/v1',
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: widget.apiKeyController,
                    obscureText: _obscureKey,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'API Key (optional)',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 6),
                    _InlineErrorRow(message: 'Cannot connect to endpoint', onSaveAnyway: _saveAnyway),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 4),
                      _InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 4),
                      _InlineClearButton(label: '✕ All', onPressed: _clearAll),
                    ],
                  ),
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
  const _InlineTestButton({
    required this.loading,
    required this.onPressed,
    this.testPassed = false,
    this.passedLabel = '✓ Valid',
  });

  final bool loading;
  final VoidCallback onPressed;
  final bool testPassed;
  final String passedLabel;

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

    final fgColor = testPassed ? c.success : c.accent;
    final bgColor = testPassed ? c.success.withValues(alpha: 0.12) : c.accentTintMid;
    final borderColor = testPassed ? c.success.withValues(alpha: 0.3) : c.accent.withValues(alpha: 0.35);
    final label = testPassed ? passedLabel : 'Test';

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

class _InlineSaveButton extends StatelessWidget {
  const _InlineSaveButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loading) {
      return SizedBox(
        width: 54,
        height: 26,
        child: Center(
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 54,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(5)),
        child: Text(
          'Save',
          style: TextStyle(color: Colors.white, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _InlineErrorRow extends StatelessWidget {
  const _InlineErrorRow({required this.message, required this.onSaveAnyway});

  final String message;
  final VoidCallback onSaveAnyway;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.errorTintBg,
        border: Border.all(color: c.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
          InkWell(
            onTap: onSaveAnyway,
            borderRadius: BorderRadius.circular(2),
            child: Text(
              'Save anyway',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineClearButton extends StatelessWidget {
  const _InlineClearButton({required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasLabel = label != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: hasLabel ? null : const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.deepBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: hasLabel
            ? Text(
                label!,
                style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              )
            : Icon(AppIcons.close, size: 11, color: c.error),
      ),
    );
  }
}
