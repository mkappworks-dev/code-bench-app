// lib/features/update/widgets/update_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/update_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/update/models/update_info.dart';
import '../../../data/update/models/update_state.dart';
import '../notifiers/update_failure.dart';
import '../notifiers/update_notifier.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key, required this.info});

  final UpdateInfo info;

  static Future<void> show(BuildContext context, UpdateInfo info) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpdateDialog(info: info),
  );

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProvider);
    final busy = updateState is UpdateStateDownloading || updateState is UpdateStateInstalling;

    final title = switch (updateState) {
      UpdateStateDownloading() => 'Downloading…',
      UpdateStateInstalling() => 'Installing…',
      UpdateStateError() => 'Update Failed',
      _ => 'Update Available',
    };

    final subtitle = switch (updateState) {
      UpdateStateDownloading(:final progress) => 'Downloading… ${(progress * 100).round()}%',
      UpdateStateInstalling() => 'The app will restart shortly',
      UpdateStateError() => 'Something went wrong',
      _ => 'Code Bench ${widget.info.version} is ready',
    };

    return AppDialog(
      icon: AppIcons.update,
      iconType: AppDialogIconType.teal,
      title: title,
      subtitle: subtitle,
      maxWidth: 400,
      content: _DialogContent(info: widget.info, updateState: updateState, currentVersion: _currentVersion),
      actions: [
        AppDialogAction.cancel(
          label: busy ? 'Hide' : 'Cancel',
          onPressed: busy
              ? Navigator.of(context)
                    .pop // hides dialog; download continues in background
              : () {
                  ref.read(updateProvider.notifier).dismiss();
                  Navigator.of(context).pop();
                },
        ),
        AppDialogAction.primary(
          label: 'Download & Install',
          onPressed: switch (updateState) {
            UpdateStateAvailable() ||
            UpdateStateError() => () => unawaited(ref.read(updateProvider.notifier).downloadAndInstall(widget.info)),
            _ => null,
          },
        ),
      ],
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.info, required this.updateState, required this.currentVersion});

  final UpdateInfo info;
  final UpdateState updateState;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version badge row
        Row(
          children: [
            _VersionBadge(label: currentVersion.isEmpty ? '…' : 'v$currentVersion', isNew: false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(AppIcons.arrowRight, size: 12, color: c.textMuted),
            ),
            _VersionBadge(label: 'v${info.version}', isNew: true),
          ],
        ),
        const SizedBox(height: 12),
        // State-specific content
        switch (updateState) {
          UpdateStateDownloading(:final progress) => _ProgressBar(progress: progress),
          UpdateStateInstalling() => const _InstallingRow(),
          UpdateStateError(:final failure) => _ErrorRow(failure: failure, info: info),
          _ => _ReleaseNotes(notes: info.releaseNotes),
        },
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label, required this.isNew});
  final String label;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNew ? c.accentTintLight : c.chipFill,
        border: Border.all(color: isNew ? c.accentBorderTeal : c.chipStroke),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: isNew ? c.accentLight : c.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.faintBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Text(
          notes.isEmpty ? 'No release notes.' : notes,
          style: TextStyle(color: c.textSecondary, fontSize: 11, height: 1.6),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Downloading update…', style: TextStyle(color: c.textMuted, fontSize: 10)),
            Text('${(progress * 100).round()}%', style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: c.chipFill,
            valueColor: AlwaysStoppedAnimation(c.accent),
          ),
        ),
      ],
    );
  }
}

class _InstallingRow extends StatelessWidget {
  const _InstallingRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent)),
        const SizedBox(width: 10),
        Text('Replacing app bundle and relaunching…', style: TextStyle(color: c.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.failure, required this.info});
  final UpdateFailure failure;
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final message = switch (failure) {
      UpdateNetworkError() => 'Could not reach GitHub. Check your connection.',
      UpdateDownloadFailed() => 'Download failed. Check your connection and try again.',
      UpdateInstallFailed() => 'Install failed. Try downloading manually.',
      UpdateUnknownError() => 'Something went wrong. Try downloading manually.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: c.error, fontSize: 11)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            try {
              launchUrl(Uri.parse('https://github.com/$kGithubOwner/$kGithubRepo/releases/latest'));
            } catch (_) {}
          },
          child: Text(
            'Download manually →',
            style: TextStyle(
              color: c.accent,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: c.accent,
            ),
          ),
        ),
      ],
    );
  }
}
