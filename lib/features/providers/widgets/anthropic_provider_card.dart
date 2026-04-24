import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/ai/models/cli_detection.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/claude_cli_detection_notifier.dart';
import '../notifiers/providers_actions.dart';
import '../notifiers/providers_notifier.dart';
import 'api_key_card.dart';
import 'claude_cli_card.dart';
import 'provider_card_helpers.dart';

/// Anthropic provider group: mini-header with radio transport selector, a
/// collapsible API Key card, and a non-collapsible Claude Code CLI status card.
class AnthropicProviderCard extends ConsumerWidget {
  const AnthropicProviderCard({super.key, required this.apiKeyController, required this.initialApiKey});

  final TextEditingController apiKeyController;
  final String initialApiKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(apiKeysProvider);
    return switch (state) {
      AsyncLoading() => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
      AsyncError() => Text(
        'Could not load provider settings — please restart the app.',
        style: TextStyle(color: AppColors.of(context).error, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
      AsyncData(:final value) => _buildGroup(context, ref, value),
    };
  }

  Widget _buildGroup(BuildContext context, WidgetRef ref, ApiKeysNotifierState s) {
    final c = AppColors.of(context);
    final isCli = s.anthropicTransport == 'cli';
    final saving = ref.watch(providersActionsProvider).isLoading;

    // Disable the CLI radio only when detection has completed and confirmed
    // the binary is not installed. During AsyncLoading, both radios stay enabled.
    final cliDisabled = switch (ref.watch(claudeCliDetectionProvider)) {
      AsyncData(value: CliNotInstalled()) => true,
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Anthropic',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TransportRadio(
              leftLabel: 'API Key',
              rightLabel: 'Claude Code CLI',
              selectedIndex: isCli ? 1 : 0,
              onChanged: saving ? null : (i) => _onTransportChanged(context, ref, i == 1),
              rightDisabled: cliDisabled,
              rightDisabledTooltip: 'Install Claude Code CLI to enable',
              loading: saving,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ApiKeyCard(
          provider: AIProvider.anthropic,
          controller: apiKeyController,
          initialValue: initialApiKey,
          showActivePill: !isCli,
        ),
        const SizedBox(height: 6),
        ClaudeCliCard(showActivePill: isCli),
      ],
    );
  }

  Future<void> _onTransportChanged(BuildContext context, WidgetRef ref, bool toCli) async {
    await ref.read(providersActionsProvider.notifier).saveAnthropicTransport(toCli ? 'cli' : 'api-key');
    if (!context.mounted) return;
    if (ref.read(providersActionsProvider).hasError) {
      AppSnackBar.show(context, 'Could not save transport — please retry', type: AppSnackBarType.error);
    }
  }
}
