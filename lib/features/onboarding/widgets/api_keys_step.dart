import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/buttons.dart';
import '../../providers/notifiers/providers_notifier.dart';
import '../../providers/widgets/api_keys_list.dart';

class ApiKeysStep extends ConsumerWidget {
  const ApiKeysStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  /// True once the user has saved at least one API key or selected the
  /// CLI transport for any provider that supports it. The "Continue"
  /// button stays disabled until then.
  bool _hasAnyConfig(ApiKeysNotifierState s) =>
      s.openai.isNotEmpty ||
      s.anthropic.isNotEmpty ||
      s.gemini.isNotEmpty ||
      s.ollamaUrl.isNotEmpty ||
      s.customEndpoint.isNotEmpty ||
      s.anthropicTransport == 'cli' ||
      s.openaiTransport == 'cli';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canContinue = switch (ref.watch(apiKeysProvider)) {
      AsyncData(:final value) => _hasAnyConfig(value),
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: SingleChildScrollView(child: ApiKeysList())),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ChipButton(label: 'Skip for now', onPressed: onSkip, size: ChipButtonSize.medium),
            PrimaryButton(label: 'Continue →', onPressed: canContinue ? onContinue : null),
          ],
        ),
      ],
    );
  }
}
