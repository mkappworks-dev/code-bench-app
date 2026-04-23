import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/shared/ai_model.dart';
import '../notifiers/providers_notifier.dart';
import 'api_key_card.dart';
import 'claude_cli_status_row.dart';

/// Composite Anthropic provider card with a transport switch (API key vs
/// Claude Code CLI). The active transport's panel occupies the main body;
/// the inactive transport's summary sits next to the switch at the bottom.
class AnthropicProviderCard extends ConsumerWidget {
  const AnthropicProviderCard({super.key, required this.apiKeyController, required this.initialApiKey});

  final TextEditingController apiKeyController;
  final String initialApiKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final state = ref.watch(apiKeysProvider);
    return switch (state) {
      AsyncLoading() => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      AsyncError(:final error) => Text('Failed to load: $error', style: TextStyle(color: c.error)),
      AsyncData(:final value) => _buildCard(context, ref, value),
    };
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, ApiKeysNotifierState s) {
    final c = AppColors.of(context);
    final isCli = s.anthropicTransport == 'cli';
    return Container(
      decoration: BoxDecoration(
        color: c.panelBackground,
        border: Border.all(color: isCli ? c.accent : c.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_header(context, isCli), _activePanel(context, s, isCli), _toggleRow(context, ref, s, isCli)],
      ),
    );
  }

  Widget _header(BuildContext context, bool isCli) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            'Anthropic',
            style: TextStyle(color: c.headingText, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '● Active: ${isCli ? "Claude Code CLI" : "API Key"}',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _activePanel(BuildContext context, ApiKeysNotifierState s, bool isCli) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isCli
          ? const ClaudeCliStatusRow()
          : ApiKeyCard(provider: AIProvider.anthropic, controller: apiKeyController, initialValue: initialApiKey),
    );
  }

  Widget _toggleRow(BuildContext context, WidgetRef ref, ApiKeysNotifierState s, bool isCli) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.deepBackground,
        border: Border(top: BorderSide(color: c.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route through Claude Code CLI',
                  style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                isCli ? _inactiveApiKeySummary(context, s) : const ClaudeCliStatusRow(),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Switch(
            value: isCli,
            onChanged: (v) => ref.read(apiKeysProvider.notifier).setAnthropicTransport(v ? 'cli' : 'api-key'),
          ),
        ],
      ),
    );
  }

  Widget _inactiveApiKeySummary(BuildContext context, ApiKeysNotifierState s) {
    final c = AppColors.of(context);
    final key = s.anthropic;
    final masked = key.isEmpty ? 'Not set' : '${key.substring(0, key.length.clamp(0, 10))}…';
    return Row(
      children: [
        Text('API key: ', style: TextStyle(color: c.textSecondary, fontSize: 11)),
        Text(
          masked,
          style: TextStyle(fontFamily: 'monospace', color: c.mutedFg, fontSize: 11),
        ),
        Text(' · saved · inactive', style: TextStyle(color: c.mutedFg, fontSize: 11)),
      ],
    );
  }
}
