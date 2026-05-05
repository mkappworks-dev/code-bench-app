import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../../../layout/notifiers/ide_launch_actions.dart';
import '../notifiers/ripgrep_availability_notifier.dart';

class RipgrepAvailabilityBanner extends ConsumerStatefulWidget {
  const RipgrepAvailabilityBanner({super.key});

  @override
  ConsumerState<RipgrepAvailabilityBanner> createState() => _RipgrepAvailabilityBannerState();
}

class _RipgrepAvailabilityBannerState extends ConsumerState<RipgrepAvailabilityBanner> {
  // Holds the last resolved availability so the banner stays visible during a
  // recheck (which briefly puts the provider into AsyncLoading).
  bool? _lastKnown;

  // Set to true when the user manually triggers a recheck so the listener
  // knows to show a snackbar when the check resolves.
  bool _recheckRequested = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ripgrepAvailabilityStateProvider);

    if (state.hasValue) _lastKnown = state.value;

    ref.listen(ripgrepAvailabilityStateProvider, (prev, next) {
      if (!_recheckRequested) return;
      if (next.isLoading || !next.hasValue) return;
      _recheckRequested = false;
      if (next.value!) {
        AppSnackBar.show(context, 'ripgrep is active — fast search enabled.', type: AppSnackBarType.success);
      } else {
        AppSnackBar.show(context, 'ripgrep not found — using Pure Dart fallback.', type: AppSnackBarType.warning);
      }
    });

    // True initial load — no previous data yet.
    if (_lastKnown == null) {
      return const Padding(padding: EdgeInsets.only(bottom: 16), child: LinearProgressIndicator());
    }

    final isChecking = state.isLoading;

    return _lastKnown! ? _buildAvailableRow(isChecking: isChecking) : _buildFallbackBanner(isChecking: isChecking);
  }

  Widget _buildAvailableRow({required bool isChecking}) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border.all(color: c.success.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(AppIcons.check, size: 13, color: c.success),
          const SizedBox(width: 7),
          Text(
            'Grep backend: ripgrep',
            style: TextStyle(
              fontSize: ThemeConstants.uiFontSizeSmall,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          _RecheckControl(isChecking: isChecking, onRecheck: _recheck),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner({required bool isChecking}) {
    final c = AppColors.of(context);
    final installCmd = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'brew install ripgrep',
      TargetPlatform.linux => 'sudo apt install ripgrep',
      _ => 'winget install ripgrep',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border.all(color: c.warning.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.warning, size: 13, color: c.warning),
              const SizedBox(width: 7),
              Text(
                'Grep backend: Pure Dart (fallback)',
                style: TextStyle(
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              _RecheckControl(isChecking: isChecking, onRecheck: _recheck),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Install ripgrep for faster searches.',
            style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.glassFill,
              border: Border.all(color: c.subtleBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    installCmd,
                    style: TextStyle(
                      fontSize: ThemeConstants.uiFontSizeSmall,
                      fontFamily: ThemeConstants.editorFontFamily,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _IconBtn(icon: AppIcons.copy, color: c.textSecondary, onTap: () => _copyCmd(installCmd)),
                const SizedBox(width: 4),
                _IconBtn(
                  icon: AppIcons.terminal,
                  color: c.success,
                  borderColor: c.success.withValues(alpha: 0.3),
                  fillColor: c.success.withValues(alpha: 0.08),
                  tooltip: 'Open terminal (command copied)',
                  onTap: () => _openTerminal(installCmd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _recheck() {
    _recheckRequested = true;
    ref.read(ripgrepAvailabilityStateProvider.notifier).recheck();
  }

  Future<void> _copyCmd(String cmd) async {
    await Clipboard.setData(ClipboardData(text: cmd));
    if (!mounted) return;
    AppSnackBar.show(context, 'Copied!', type: AppSnackBarType.success);
  }

  Future<void> _openTerminal(String installCmd) async {
    // Copy the install command first so the user can paste immediately.
    await Clipboard.setData(ClipboardData(text: installCmd));
    if (!mounted) return;
    final projectId = ref.read(activeProjectIdProvider);
    final path =
        ref.read(projectsProvider).whenOrNull(data: (list) => list.firstWhereOrNull((p) => p.id == projectId)?.path) ??
        '';
    ref.read(ideLaunchActionsProvider.notifier).openInTerminal(path);
  }
}

/// Renders either a "Recheck" tap target or a small spinner while checking.
class _RecheckControl extends StatelessWidget {
  const _RecheckControl({required this.isChecking, required this.onRecheck});

  final bool isChecking;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (isChecking) {
      return SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.textMuted));
    }
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onRecheck,
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: const TextStyle(fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: const Text('Recheck'),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.borderColor,
    this.fillColor,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color? borderColor;
  final Color? fillColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inner = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: fillColor ?? c.glassFill,
        border: Border.all(color: borderColor ?? c.subtleBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, size: 13, color: color),
    );
    return GestureDetector(
      onTap: onTap,
      child: tooltip != null ? Tooltip(message: tooltip!, child: inner) : inner,
    );
  }
}
