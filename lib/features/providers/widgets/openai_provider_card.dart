import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/ai_provider_status_notifier.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'install_command.dart';
import 'provider_card_helpers.dart';
import 'selectable_transport_card.dart';

/// OpenAI provider entry — API Key (Dio HTTP) or Codex SDK (subprocess).
/// Mirrors [AnthropicProviderCard]'s shape; differences are the binary
/// name, install command, registered datasource id, and the persistence
/// flag (`openaiTransport`).
class OpenAIProviderCard extends ConsumerStatefulWidget {
  const OpenAIProviderCard({super.key, required this.controller, required this.initialApiKey});

  final TextEditingController controller;
  final String initialApiKey;

  @override
  ConsumerState<OpenAIProviderCard> createState() => _OpenAIProviderCardState();
}

class _OpenAIProviderCardState extends ConsumerState<OpenAIProviderCard> {
  static const _providerId = 'codex';
  static const _binaryName = 'codex';
  static const _installCommand = 'brew install codex';

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
  void didUpdateWidget(OpenAIProviderCard oldWidget) {
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
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(AIProvider.openai, key);
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
    final ok = await ref.read(providersActionsProvider.notifier).testApiKey(AIProvider.openai, key);
    if (!mounted) {
      _saveTriggered = false;
      return;
    }
    if (ok) {
      await ref.read(providersActionsProvider.notifier).saveKey(AIProvider.openai, key);
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
    await ref.read(providersActionsProvider.notifier).deleteKey(AIProvider.openai);
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

  Future<void> _setTransport(String value) async {
    if (_saveLoading) return;
    await ref.read(providersActionsProvider.notifier).saveOpenaiTransport(value);
    if (!mounted) return;
    if (ref.read(providersActionsProvider).hasError) {
      AppSnackBar.show(context, 'Could not save transport — please retry', type: AppSnackBarType.error);
    }
  }

  Future<void> _recheckSdk() async {
    await ref.read(aiProviderStatusProvider.notifier).recheck();
    if (!mounted) return;
    final state = ref.read(aiProviderStatusProvider);
    if (state.hasError) {
      AppSnackBar.show(context, 'Recheck failed — please retry', type: AppSnackBarType.error);
      return;
    }
    final entries = switch (state) {
      AsyncData(:final value) => value,
      _ => const <ProviderEntry>[],
    };
    final entry = entries.where((e) => e.id == _providerId).firstOrNull;
    if (entry?.isAvailable ?? false) {
      AppSnackBar.show(context, 'Codex SDK detected', type: AppSnackBarType.success);
      return;
    }
    final reason = entry?.status is ProviderUnavailable
        ? (entry!.status as ProviderUnavailable).reasonKind
        : ProviderUnavailableReason.missing;
    final message = switch (reason) {
      ProviderUnavailableReason.unhealthy => '$_binaryName is installed but not responding — try reinstalling',
      ProviderUnavailableReason.detectionFailed => 'Could not probe $_binaryName — please retry',
      ProviderUnavailableReason.notRegistered => '$_binaryName provider is not registered',
      ProviderUnavailableReason.missing => '$_binaryName not found on PATH',
    };
    AppSnackBar.show(context, message, type: AppSnackBarType.error);
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

  ProviderEntry? _sdkEntry() => switch (ref.watch(aiProviderStatusProvider)) {
    AsyncData(:final value) => value.where((e) => e.id == _providerId).firstOrNull,
    _ => null,
  };

  CardStatusBadge _sdkBadge({required bool selected}) {
    final entry = _sdkEntry();
    final loading = ref.watch(aiProviderStatusProvider) is AsyncLoading;
    if (loading) return const CardStatusBadge(label: 'Checking…', tone: TransportBadgeTone.muted);
    return switch (entry?.status) {
      ProviderAvailable(:final version) => CardStatusBadge(
        label: 'Installed · $version',
        tone: TransportBadgeTone.success,
      ),
      ProviderUnavailable() =>
        selected
            ? const CardStatusBadge(label: 'Active · Not installed', tone: TransportBadgeTone.error)
            : const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
      null => const CardStatusBadge(label: 'Not installed', tone: TransportBadgeTone.muted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiKeysProvider);
    return switch (state) {
      AsyncLoading() => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      AsyncError() => Text(
        'Could not load provider settings — please restart the app.',
        style: TextStyle(color: AppColors.of(context).error, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
      AsyncData(:final value) => _buildGroup(context, value),
    };
  }

  Widget _buildGroup(BuildContext context, ApiKeysNotifierState s) {
    final c = AppColors.of(context);
    final isSdk = s.openaiTransport == 'sdk';
    final sdkEntry = _sdkEntry();
    final sdkAvailable = sdkEntry?.isAvailable ?? false;
    final brokenSdkActive = isSdk && sdkEntry != null && !sdkAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OpenAI',
          style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SelectableTransportCard(
          title: 'API Key',
          selected: !isSdk,
          initiallyExpanded: _dotStatus != DotStatus.savedVerified && _dotStatus != DotStatus.savedUnverified,
          badge: _apiKeyBadge(),
          onTap: isSdk ? () => _setTransport('api-key') : null,
          body: _OpenAIApiKeyBody(
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
          title: 'Codex SDK',
          selected: isSdk,
          disabled: !sdkAvailable && !brokenSdkActive,
          errorState: brokenSdkActive,
          initiallyExpanded: brokenSdkActive,
          badge: _sdkBadge(selected: isSdk),
          onTap: !isSdk && sdkAvailable ? () => _setTransport('sdk') : null,
          body: _CodexSdkBody(
            sdkEntry: sdkEntry,
            broken: brokenSdkActive,
            onRecheck: _recheckSdk,
            onSwitchToApiKey: () => _setTransport('api-key'),
            installCommand: _installCommand,
            binaryName: _binaryName,
          ),
        ),
      ],
    );
  }
}

class _OpenAIApiKeyBody extends StatelessWidget {
  const _OpenAIApiKeyBody({
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

class _CodexSdkBody extends StatelessWidget {
  const _CodexSdkBody({
    required this.sdkEntry,
    required this.broken,
    required this.onRecheck,
    required this.onSwitchToApiKey,
    required this.installCommand,
    required this.binaryName,
  });

  final ProviderEntry? sdkEntry;
  final bool broken;
  final VoidCallback onRecheck;
  final VoidCallback onSwitchToApiKey;
  final String installCommand;
  final String binaryName;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (broken) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '⚠ $binaryName no longer detected',
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          _CardButton(label: 'Switch to API Key', onPressed: onSwitchToApiKey),
          const SizedBox(width: 6),
          _CardButton(label: 'Recheck', onPressed: onRecheck),
        ],
      );
    }
    if (!(sdkEntry?.isAvailable ?? false)) {
      return Row(
        children: [
          Expanded(child: InstallCommand(command: installCommand)),
          const SizedBox(width: 6),
          _CardButton(label: 'Recheck', onPressed: onRecheck),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            'Local $binaryName binary · OAuth via $binaryName login',
            style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _CardButton(label: 'Recheck', onPressed: onRecheck),
      ],
    );
  }
}

class _CardButton extends StatefulWidget {
  const _CardButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<_CardButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: _hovered ? 0.22 : 0.12),
            border: Border.all(color: c.accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.label,
            style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
