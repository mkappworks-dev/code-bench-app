// lib/features/providers/widgets/custom_endpoint_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'provider_card_helpers.dart';

class CustomEndpointCard extends ConsumerStatefulWidget {
  const CustomEndpointCard({
    super.key,
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
  ConsumerState<CustomEndpointCard> createState() => _CustomEndpointCardState();
}

class _CustomEndpointCardState extends ConsumerState<CustomEndpointCard> {
  bool _expanded = false;
  bool _obscureKey = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedUrl;
  late String _savedApiKey;

  @override
  void initState() {
    super.initState();
    _savedUrl = widget.initialUrl;
    _savedApiKey = widget.initialApiKey;
    _dotStatus = _savedUrl.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
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
  void didUpdateWidget(CustomEndpointCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl || oldWidget.initialApiKey != widget.initialApiKey) {
      setState(() {
        _savedUrl = widget.initialUrl;
        _savedApiKey = widget.initialApiKey;
        _dotStatus = _savedUrl.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
      });
    }
  }

  bool get _isUnsaved =>
      widget.urlController.text.trim() != _savedUrl || widget.apiKeyController.text.trim() != _savedApiKey;

  void _onFieldChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final DotStatus next;
    if (!_isUnsaved) {
      next = _savedUrl.isEmpty ? DotStatus.empty : _dotStatus;
    } else {
      next = DotStatus.unsaved;
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
    final ok = await ref.read(providersActionsProvider.notifier).testCustomEndpoint(url, apiKey);
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
    final ok = await ref.read(providersActionsProvider.notifier).testCustomEndpoint(url, apiKey);
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
        _dotStatus = verified ? DotStatus.savedVerified : DotStatus.savedUnverified;
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
      _dotStatus = DotStatus.empty;
      _testPassed = false;
      _showSaveAnyway = false;
    });
    AppSnackBar.show(context, 'Custom endpoint cleared', type: AppSnackBarType.success);
  }

  Color _dotColor(AppColors c) => switch (_dotStatus) {
    DotStatus.empty => c.mutedFg,
    DotStatus.unsaved => c.warning,
    DotStatus.savedVerified => c.success,
    DotStatus.savedUnverified => c.success.withValues(alpha: 0.45),
  };

  String _statusLabel() => switch (_dotStatus) {
    DotStatus.empty => 'Not configured',
    DotStatus.unsaved => 'Unsaved changes',
    DotStatus.savedVerified => 'Connected & saved',
    DotStatus.savedUnverified => 'Saved (unverified)',
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
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered) ? c.surfaceHoverOverlay : null,
            ),
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
                    const SizedBox(height: 8),
                    InlineErrorRow(message: 'Cannot connect to endpoint', onSaveAnyway: _saveAnyway),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InlineTestButton(
                        loading: _saveLoading,
                        testPassed: _testPassed,
                        passedLabel: '✓ Connected',
                        onPressed: _test,
                      ),
                      const SizedBox(width: 8),
                      InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 8),
                      InlineClearButton(label: '✕ All', onPressed: _clearAll),
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
