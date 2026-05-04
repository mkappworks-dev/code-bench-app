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
import 'selectable_transport_card.dart';

/// Gemini provider entry — API Key only for now. The Gemini CLI option is
/// rendered as a permanently-disabled selectable card with a "Coming in
/// Phase 9" badge so the surface looks consistent with [AnthropicProviderCard]
/// / [OpenAIProviderCard]; once a `GeminiCliDatasourceProcess` lands and gets
/// registered in `AIProviderService`, this card can adopt the same broken /
/// not-installed / installed branches the others use.
class GeminiProviderCard extends ConsumerStatefulWidget {
  const GeminiProviderCard({super.key, required this.controller, required this.initialApiKey});

  final TextEditingController controller;
  final String initialApiKey;

  @override
  ConsumerState<GeminiProviderCard> createState() => _GeminiProviderCardState();
}

class _GeminiProviderCardState extends ConsumerState<GeminiProviderCard> {
  bool _obscure = true;
  bool _saveLoading = false;
  bool _testPassed = false;
  bool _saveTriggered = false;
  late DotStatus _dotStatus;
  late String _savedValue;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.initialApiKey;
    _dotStatus = _savedValue.isNotEmpty ? DotStatus.savedVerified : DotStatus.empty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(GeminiProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialApiKey != widget.initialApiKey) {
      setState(() {
        _savedValue = widget.initialApiKey;
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
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(AIProvider.gemini, key);
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
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(AIProvider.gemini, key);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await ref.read(providersActionsProvider.notifier).saveKey(AIProvider.gemini, key);
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
    await ref.read(providersActionsProvider.notifier).deleteKey(AIProvider.gemini);
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

  CardStatusBadge _apiKeyBadge() => switch (_dotStatus) {
    DotStatus.empty => const CardStatusBadge(label: 'Not configured', tone: TransportBadgeTone.muted),
    DotStatus.unsaved => const CardStatusBadge(label: 'Unsaved changes', tone: TransportBadgeTone.warning),
    DotStatus.savedVerified => const CardStatusBadge(label: 'Valid & saved', tone: TransportBadgeTone.success),
    DotStatus.savedUnverified => const CardStatusBadge(
      label: 'Saved (unverified)',
      tone: TransportBadgeTone.savedUnverified,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gemini',
          style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SelectableTransportCard(
          // Always selected — there's no other option to pick yet.
          title: 'API Key',
          selected: true,
          initiallyExpanded: false,
          badge: _apiKeyBadge(),
          body: _GeminiApiKeyBody(
            controller: widget.controller,
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            saveLoading: _saveLoading,
            testPassed: _testPassed,
            onTest: _test,
            onSave: _save,
            onClear: _clear,
          ),
        ),
        const SizedBox(height: 6),
        SelectableTransportCard(
          title: 'Gemini CLI',
          selected: false,
          disabled: true,
          badge: const CardStatusBadge(label: 'Coming in Phase 9', tone: TransportBadgeTone.muted),
          body: Text(
            'Will use the gemini CLI when released',
            style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _GeminiApiKeyBody extends StatelessWidget {
  const _GeminiApiKeyBody({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.saveLoading,
    required this.testPassed,
    required this.onTest,
    required this.onSave,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool saveLoading;
  final bool testPassed;
  final VoidCallback onTest;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            obscureText: obscure,
            fontSize: 12,
            fontFamily: ThemeConstants.editorFontFamily,
            hintText: 'API key',
            suffixIcon: IconButton(
              icon: Icon(obscure ? AppIcons.hideSecret : AppIcons.showSecret, size: 14),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(width: 6),
        InlineTestButton(loading: saveLoading, testPassed: testPassed, onPressed: onTest),
        const SizedBox(width: 6),
        InlineSaveButton(loading: false, onPressed: onSave),
        const SizedBox(width: 6),
        InlineClearButton(onPressed: onClear),
      ],
    );
  }
}
