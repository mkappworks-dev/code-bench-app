// lib/features/providers/widgets/ollama_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/providers_actions.dart';
import 'provider_card_helpers.dart';

class OllamaCard extends ConsumerStatefulWidget {
  const OllamaCard({super.key, required this.controller, required this.initialValue});

  final TextEditingController controller;
  final String initialValue;

  @override
  ConsumerState<OllamaCard> createState() => _OllamaCardState();
}

class _OllamaCardState extends ConsumerState<OllamaCard> {
  bool _expanded = false;
  bool _hovered = false;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _showSaveAnyway = false;
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
  void didUpdateWidget(OllamaCard oldWidget) {
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
    if (_showSaveAnyway) setState(() => _showSaveAnyway = false);
    final text = widget.controller.text.trim();
    final next = text == _savedValue
        ? (_savedValue.isEmpty ? DotStatus.empty : DotStatus.savedVerified)
        : DotStatus.unsaved;
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
    final ok = await ref.read(providersActionsProvider.notifier).testOllamaUrl(url);
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
    final ok = await ref.read(providersActionsProvider.notifier).testOllamaUrl(url);
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
    await ref.read(providersActionsProvider.notifier).saveOllamaUrl(url);
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
      _savedValue = url;
      setState(() {
        _dotStatus = verified ? DotStatus.savedVerified : DotStatus.savedUnverified;
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
    await ref.read(providersActionsProvider.notifier).clearOllamaUrl();
    if (!mounted) return;
    if (!ref.read(providersActionsProvider).hasError) {
      widget.controller.clear();
      _savedValue = '';
      setState(() {
        _dotStatus = DotStatus.empty;
        _testPassed = false;
        _showSaveAnyway = false;
      });
      AppSnackBar.show(context, 'Ollama URL cleared', type: AppSnackBarType.success);
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
          'Ollama Server URL',
          style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        _OllamaStatusBadge(status: _dotStatus, label: _statusLabel()),
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
                    controller: widget.controller,
                    fontFamily: ThemeConstants.editorFontFamily,
                    hintText: 'http://localhost:11434',
                  ),
                  if (_showSaveAnyway) ...[
                    const SizedBox(height: 8),
                    InlineErrorRow(message: 'Cannot connect to Ollama', onSaveAnyway: _saveAnyway),
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
                      InlineClearButton(onPressed: _clear),
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

class _OllamaStatusBadge extends StatelessWidget {
  const _OllamaStatusBadge({required this.status, required this.label});
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
