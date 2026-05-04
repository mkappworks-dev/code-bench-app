import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chip_button.dart';
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
    final c = AppColors.of(context);
    final canContinue = switch (ref.watch(apiKeysProvider)) {
      AsyncData(:final value) => _hasAnyConfig(value),
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: SingleChildScrollView(
            child: Padding(padding: EdgeInsets.fromLTRB(0, 0, 16, 0), child: ApiKeysList()),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ChipButton(label: 'Skip for now', onPressed: onSkip, size: ChipButtonSize.medium),
            Opacity(
              opacity: canContinue ? 1.0 : 0.4,
              child: MouseRegion(
                cursor: canContinue ? SystemMouseCursors.click : MouseCursor.defer,
                child: GestureDetector(
                  onTap: canContinue ? onContinue : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
                    child: Text('Continue →', style: TextStyle(color: c.onAccent, fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
