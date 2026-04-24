import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/ai/models/cli_detection.dart';
import '../notifiers/claude_cli_detection_notifier.dart';
import 'provider_card_helpers.dart';

class ClaudeCliCard extends ConsumerWidget {
  const ClaudeCliCard({super.key, this.showActivePill = false});

  final bool showActivePill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(claudeCliDetectionProvider);
    return switch (async) {
      AsyncLoading() => _shell(
        context,
        dotColor: c.mutedFg,
        statusLabel: 'Probing…',
        trailing: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.mutedFg)),
      ),
      AsyncError(:final error) => _shell(
        context,
        dotColor: c.error,
        statusLabel: 'Probe failed',
        trailing: _recheckButton(context, ref),
        body: Text(
          '$error',
          style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ),
      AsyncData(:final value) => _fromDetection(context, ref, value),
    };
  }

  Widget _fromDetection(BuildContext context, WidgetRef ref, CliDetection d) {
    final c = AppColors.of(context);
    return switch (d) {
      CliNotInstalled() => _shell(
        context,
        dotColor: c.mutedFg,
        statusLabel: 'Not installed',
        trailing: _recheckButton(context, ref),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Install Claude Code to route Anthropic through your subscription.',
              style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(height: 4),
            const _InstallLink(),
          ],
        ),
      ),
      CliInstalled(:final version, :final authStatus) => switch (authStatus) {
        CliAuthStatus.authenticated => _shell(
          context,
          dotColor: c.success,
          statusLabel: 'Detected · v$version · authenticated',
          trailing: _recheckButton(context, ref),
        ),
        CliAuthStatus.unauthenticated => _shell(
          context,
          dotColor: c.success,
          statusLabel: 'Detected · v$version · not authenticated',
          trailing: _recheckButton(context, ref),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Run this in a terminal to sign in:',
                style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
              const SizedBox(height: 6),
              const _CopyChip(command: 'claude'),
            ],
          ),
        ),
        CliAuthStatus.unknown => _shell(
          context,
          dotColor: c.success,
          statusLabel: 'Detected · v$version',
          trailing: _recheckButton(context, ref),
        ),
      },
    };
  }

  Widget _shell(
    BuildContext context, {
    required Color dotColor,
    required String statusLabel,
    Widget? trailing,
    Widget? body,
  }) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  'Claude Code CLI',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
                if (showActivePill) ...[const SizedBox(width: 8), const ActivePill()],
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          if (body != null) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: body),
        ],
      ),
    );
  }

  Widget _recheckButton(BuildContext context, WidgetRef ref) => const _RecheckButton();
}

class _RecheckButton extends ConsumerStatefulWidget {
  const _RecheckButton();

  @override
  ConsumerState<_RecheckButton> createState() => _RecheckButtonState();
}

class _RecheckButtonState extends ConsumerState<_RecheckButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          await ref.read(claudeCliDetectionProvider.notifier).recheck();
          if (!context.mounted) return;
          if (ref.read(claudeCliDetectionProvider).hasError) {
            AppSnackBar.show(context, 'Claude CLI detection failed', type: AppSnackBarType.error);
          } else {
            AppSnackBar.show(context, 'Claude CLI detection successful', type: AppSnackBarType.success);
          }
        },
        child: Text(
          '↻ Re-check',
          style: TextStyle(
            color: _hovered ? c.accent.withValues(alpha: 0.65) : c.accent,
            fontSize: ThemeConstants.uiFontSizeSmall,
          ),
        ),
      ),
    );
  }
}

class _InstallLink extends StatelessWidget {
  const _InstallLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://claude.ai/download');
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && context.mounted) {
            AppSnackBar.show(context, 'Could not open browser', type: AppSnackBarType.error);
          }
        } catch (e) {
          if (!context.mounted) return;
          dLog('[ClaudeCliCard] launchUrl failed: $e');
          AppSnackBar.show(context, 'Could not open browser', type: AppSnackBarType.error);
        }
      },
      child: Text(
        'Get Claude Code →',
        style: TextStyle(
          color: AppColors.of(context).accent,
          fontSize: ThemeConstants.uiFontSizeSmall,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: c.inputSurface,
              border: Border.all(color: c.borderColor),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              command,
              style: TextStyle(
                fontFamily: ThemeConstants.editorFontFamily,
                fontSize: ThemeConstants.uiFontSizeSmall,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _CopyButton(command: command),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    return InlineClearButton(
      label: 'Copy',
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
    );
  }
}
