import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/shared/ai_model.dart';
import 'api_key_card.dart';

/// Placeholder provider card matching [AnthropicProviderCard]'s visual weight
/// for providers whose CLI transport isn't implemented yet (OpenAI's Codex
/// CLI — Phase 8; Gemini CLI — Phase 9). Renders the existing API key card
/// inline with a "Coming in Phase N" annotation.
class ComingSoonProviderCard extends StatelessWidget {
  const ComingSoonProviderCard({
    super.key,
    required this.provider,
    required this.providerName,
    required this.cliName,
    required this.comingInPhase,
    required this.apiKeyController,
    required this.initialApiKey,
  });

  final AIProvider provider;
  final String providerName;
  final String cliName;
  final String comingInPhase;
  final TextEditingController apiKeyController;
  final String initialApiKey;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.panelBackground,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  providerName,
                  style: TextStyle(color: c.headingText, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text('● Active: API Key', style: TextStyle(color: c.textSecondary, fontSize: 11)),
                const SizedBox(width: 10),
                Text('· $cliName coming in $comingInPhase', style: TextStyle(color: c.mutedFg, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ApiKeyCard(provider: provider, controller: apiKeyController, initialValue: initialApiKey),
          ),
        ],
      ),
    );
  }
}
