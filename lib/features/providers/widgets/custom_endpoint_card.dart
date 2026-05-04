// lib/features/providers/widgets/custom_endpoint_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/providers_actions.dart';
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
  bool _hovered = false;
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
    await ref.read(providersActionsProvider.notifier).saveCustomEndpoint(url, apiKey);
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
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
    await ref.read(providersActionsProvider.notifier).clearCustomEndpoint();
    if (!mounted || ref.read(providersActionsProvider).hasError) {
      if (mounted) AppSnackBar.show(context, 'Failed to clear — please retry', type: AppSnackBarType.error);
      return;
    }
    await ref.read(providersActionsProvider.notifier).clearCustomApiKey();
    if (!mounted || ref.read(providersActionsProvider).hasError) {
      if (mounted) AppSnackBar.show(context, 'Failed to clear — please retry', type: AppSnackBarType.error);
      return;
    }
    widget.urlController.clear();
    widget.apiKeyController.clear();
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
    final headerContent = Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: _dotColor(c), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          'Custom Server URL/API Key',
          style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        _CustomStatusBadge(status: _dotStatus, label: _statusLabel()),
        const SizedBox(width: 8),
        Icon(_expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: () => setState(() {
                _expanded = !_expanded;
                if (!_expanded) {
                  _testPassed = false;
                  _showSaveAnyway = false;
                }
              }),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _hovered ? Color.alphaBlend(c.surfaceHoverOverlay, c.inputSurface) : c.inputSurface,
                  borderRadius: _expanded
                      ? const BorderRadius.vertical(top: Radius.circular(3))
                      : BorderRadius.circular(3),
                ),
                child: headerContent,
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, thickness: 1, color: c.borderColor),
            Container(
              color: c.sidebarBackground,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}

class _CustomStatusBadge extends StatelessWidget {
  const _CustomStatusBadge({required this.status, required this.label});
  final DotStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dotColor, textColor) = switch (status) {
      DotStatus.empty => (c.mutedFg, c.textMuted),
      DotStatus.unsaved => (c.warning, c.warning),
      DotStatus.savedVerified => (c.success, c.success),
      DotStatus.savedUnverified => (c.success.withValues(alpha: 0.45), c.textSecondary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ],
    );
  }
}
