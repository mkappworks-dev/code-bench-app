import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'diff_body.dart';

enum ApplyCardState { ready, applied, failed }

class ApplyDiffCard extends ConsumerWidget {
  const ApplyDiffCard({
    super.key,
    required this.filename,
    required this.language,
    required this.diffText,
    required this.additions,
    required this.deletions,
    required this.state,
    this.errorMessage,
    this.onApply,
    this.onReDiff,
    this.onCopy,
    this.onOpenInEditor,
  });

  final String filename;
  final String language;
  final String diffText;
  final int additions;
  final int deletions;
  final ApplyCardState state;
  final String? errorMessage;
  final VoidCallback? onApply;
  final VoidCallback? onReDiff;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenInEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isFailed = state == ApplyCardState.failed;

    final accentColor = isFailed ? c.error : c.borderColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: c.codeBlockBg,
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            filename: filename,
            additions: additions,
            deletions: deletions,
            state: state,
            onApply: onApply,
            onReDiff: onReDiff,
            onCopy: onCopy,
            onOpenInEditor: onOpenInEditor,
          ),
          if (isFailed && errorMessage != null) _ErrorBanner(message: errorMessage!),
          if (!isFailed)
            Opacity(
              opacity: state == ApplyCardState.applied ? 0.75 : 1.0,
              child: DiffBody(diffText: diffText),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.filename,
    required this.additions,
    required this.deletions,
    required this.state,
    this.onApply,
    this.onReDiff,
    this.onCopy,
    this.onOpenInEditor,
  });

  final String filename;
  final int additions;
  final int deletions;
  final ApplyCardState state;
  final VoidCallback? onApply;
  final VoidCallback? onReDiff;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenInEditor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              filename,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (additions > 0)
            Text(
              '+$additions',
              style: TextStyle(
                color: c.diffAdd,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
          if (additions > 0 && deletions > 0) const SizedBox(width: 4),
          if (deletions > 0)
            Text(
              '-$deletions',
              style: TextStyle(
                color: c.diffDel,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
            ),
          const SizedBox(width: 8),
          if (state == ApplyCardState.applied) _AppliedPill(),
          if (state == ApplyCardState.ready) ...[
            if (onCopy != null) ...[
              _IconBtn(icon: AppIcons.copy, tooltip: 'Copy', onTap: onCopy!),
              const SizedBox(width: 6),
            ],
            if (onOpenInEditor != null) ...[
              _IconBtn(icon: AppIcons.externalLink, tooltip: 'Open in editor', onTap: onOpenInEditor!),
              const SizedBox(width: 6),
            ],
            _TextBtn(label: 'Apply', icon: AppIcons.apply, onTap: onApply),
          ],
          if (state == ApplyCardState.failed) _TextBtn(label: 'Re-diff', icon: AppIcons.refresh, onTap: onReDiff),
        ],
      ),
    );
  }
}

class _AppliedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.success.withValues(alpha: 0.15),
        border: Border.all(color: c.success.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.check, size: 10, color: c.success),
          const SizedBox(width: 4),
          Text(
            'applied',
            style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
        ],
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  const _TextBtn({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.mutedFg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 12, color: c.mutedFg),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 12, color: c.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}
