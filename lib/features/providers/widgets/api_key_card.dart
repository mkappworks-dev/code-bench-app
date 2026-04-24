// lib/features/providers/widgets/api_key_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/providers_actions.dart';
import 'provider_card_helpers.dart';

class ApiKeyCard extends ConsumerStatefulWidget {
  const ApiKeyCard({
    super.key,
    required this.provider,
    required this.controller,
    required this.initialValue,
    this.showActivePill = false,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final String initialValue;
  final bool showActivePill;

  @override
  ConsumerState<ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<ApiKeyCard> {
  bool _obscure = true;
  bool _expanded = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialValue;
    _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(ApiKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _savedValue = widget.initialValue;
        _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
      });
    }
  }

  void _onTextChanged() {
    if (_saveLoading) return;
    if (_testPassed) setState(() => _testPassed = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
        : DotStatus.unsaved;
    if (_dotStatus != next) setState(() => _dotStatus = next);
  }

  Future<void> _test() async {
    final key = widget.controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saveLoading = true;
      _testPassed = false;
    });
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, key);
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
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(widget.provider, key);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await ref.read(providersActionsProvider.notifier).saveKey(widget.provider, key);
      if (!mounted) {
        _saveTriggered = false;
        return;
      }
      if (!ref.read(providersActionsProvider).hasError) {
        _savedValue = key;
        setState(() {
          _dotStatus = DotStatus.savedVerified;
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
    await ref.read(providersActionsProvider.notifier).deleteKey(widget.provider);
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
      widget.controller.clear();
      _savedValue = '';
      setState(() {
        _dotStatus = DotStatus.empty;
        _testPassed = false;
      });
      AppSnackBar.show(context, 'Key cleared', type: AppSnackBarType.success);
    } else {
      AppSnackBar.show(context, 'Failed to clear — please retry', type: AppSnackBarType.error);
    }
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
    DotStatus.savedVerified => 'Valid & saved',
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
              if (!_expanded) _testPassed = false;
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
                  if (widget.showActivePill) ...[const SizedBox(width: 8), const ActivePill()],
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InlineTestButton(loading: _saveLoading, testPassed: _testPassed, onPressed: _test),
                      const SizedBox(width: 8),
                      InlineSaveButton(loading: false, onPressed: _save),
                      const SizedBox(width: 8),
                      InlineClearButton(onPressed: _clear),
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
