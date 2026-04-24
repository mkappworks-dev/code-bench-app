// lib/features/providers/widgets/claude_cli_status_row.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/ai/models/cli_detection.dart';
import '../notifiers/claude_cli_detection_notifier.dart';

/// Compact status row showing whether the local `claude` CLI is installed
/// and authenticated. Rendered inside [AnthropicProviderCard] in both the
/// active-panel (when CLI is active) and the inactive-summary (when the API
/// key is active) positions.
class ClaudeCliStatusRow extends ConsumerWidget {
  const ClaudeCliStatusRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(claudeCliDetectionProvider);
    return switch (async) {
      AsyncLoading() => const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5))),
      AsyncError(:final error) => _row(context, color: c.error, statusLabel: 'probe failed', detail: '$error'),
      AsyncData(:final value) => _fromDetection(context, ref, value),
    };
  }

  Widget _fromDetection(BuildContext context, WidgetRef ref, CliDetection d) {
    final c = AppColors.of(context);
    return switch (d) {
      CliNotInstalled() => _row(
        context,
        color: c.mutedFg,
        statusLabel: 'not installed',
        detail: 'Install Claude Code to route Anthropic through your subscription.',
      ),
      CliInstalled(:final version, :final authStatus) => switch (authStatus) {
        CliAuthStatus.authenticated => _row(
          context,
          color: c.success,
          statusLabel: 'detected · v$version · authenticated',
          detail: 'Flip the switch below to route Anthropic through your subscription.',
          onRecheck: () => ref.read(claudeCliDetectionProvider.notifier).recheck(),
        ),
        CliAuthStatus.unauthenticated => _row(
          context,
          color: c.warning,
          statusLabel: 'detected · v$version · not authenticated',
          detail: 'Run this in a terminal to sign in:',
          // `claude` starts the interactive CLI (including the /login flow).
          // There is no `claude auth login` subcommand.
          cta: _copyCta(context, 'claude'),
        ),
        CliAuthStatus.unknown => _row(
          context,
          color: c.mutedFg,
          statusLabel: 'detected · v$version',
          detail: 'Sending a message will confirm your sign-in status.',
          onRecheck: () => ref.read(claudeCliDetectionProvider.notifier).recheck(),
        ),
      },
    };
  }

  Widget _row(
    BuildContext context, {
    required Color color,
    required String statusLabel,
    required String detail,
    VoidCallback? onRecheck,
    Widget? cta,
  }) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Claude Code CLI',
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text('● $statusLabel', style: TextStyle(color: color, fontSize: 11)),
            if (onRecheck != null) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: onRecheck,
                child: Text('↻ Re-check', style: TextStyle(color: c.accent, fontSize: 11)),
              ),
            ],
          ],
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ],
        if (cta != null) ...[const SizedBox(height: 6), cta],
      ],
    );
  }

  Widget _copyCta(BuildContext context, String command) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: c.codeBlockBg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: c.borderColor),
            ),
            child: Text(
              command,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: c.syntaxString),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _CopyButton(command: command),
      ],
    );
  }
}

/// Stateless wrapper around an ElevatedButton that copies [command] to the
/// clipboard. Extracted so the try/catch can live in a State class (widget
/// layer's sole permitted try/catch targets: launchUrl and Clipboard).
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await Clipboard.setData(ClipboardData(text: command));
          if (!context.mounted) return;
          AppSnackBar.show(context, 'Copied', type: AppSnackBarType.success);
        } catch (_) {
          if (!context.mounted) return;
          AppSnackBar.show(context, 'Copy failed', type: AppSnackBarType.error);
        }
      },
      child: const Text('Copy'),
    );
  }
}
