import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/github/models/device_code_response.dart';
import '../notifiers/github_auth_notifier.dart';

/// Frosted-glass dialog implementing the GitHub Device Flow user-facing screen.
///
/// Mounted by tapping "Sign in with GitHub". On mount it asks the notifier to
/// `startDeviceFlow()`, displays the resulting 8-character code (auto-copying
/// it to clipboard), and listens for the auth provider to transition to a
/// signed-in state — at which point the dialog dismisses itself.
class GitHubDeviceFlowDialog extends ConsumerStatefulWidget {
  const GitHubDeviceFlowDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    // The dialog must only dismiss via Cancel (so the notifier's cancel path
    // runs and the in-flight poll is released). Tap-outside / Escape would
    // pop the route directly, leaving the background poller racing a stale
    // notifier state.
    barrierDismissible: false,
    builder: (_) => const GitHubDeviceFlowDialog(),
  );

  @override
  ConsumerState<GitHubDeviceFlowDialog> createState() => _GitHubDeviceFlowDialogState();
}

class _GitHubDeviceFlowDialogState extends ConsumerState<GitHubDeviceFlowDialog> {
  DeviceCodeResponse? _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer kicking off the device-flow request until after the first frame.
    // startDeviceFlow() synchronously sets `state = AsyncLoading`, which
    // Riverpod forbids while a widget is still mounting. The post-frame
    // callback ensures the dialog is fully attached before we mutate the
    // notifier.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  Future<void> _start() async {
    final code = await ref.read(gitHubAuthProvider.notifier).startDeviceFlow();
    if (!mounted || code == null) return;
    setState(() => _code = code);
    try {
      await Clipboard.setData(ClipboardData(text: code.userCode));
    } catch (_) {
      // Clipboard is widget-permitted; nothing to do on failure.
    }
  }

  void _onCancel() {
    ref.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gitHubAuthProvider, (previous, next) {
      next.whenData((account) {
        if (account != null && mounted) Navigator.of(context).pop();
      });
      if (next.hasError && mounted) {
        setState(() => _error = next.error.toString());
      }
    });

    final code = _code;
    final error = _error;

    // PopScope blocks Escape / system-back from dismissing the route. The
    // only sanctioned exit is the Cancel action, which routes through
    // [_onCancel] so the notifier's cancel path runs.
    return PopScope(
      canPop: false,
      child: AppDialog(
        icon: AppIcons.github,
        iconType: AppDialogIconType.teal,
        title: 'Sign in to GitHub',
        subtitle: code == null ? 'Requesting code…' : 'Enter this code at github.com/login/device',
        content: _DeviceFlowContent(code: code, error: error),
        actions: [AppDialogAction.cancel(onPressed: _onCancel)],
      ),
    );
  }
}

class _DeviceFlowContent extends StatelessWidget {
  const _DeviceFlowContent({required this.code, required this.error});

  final DeviceCodeResponse? code;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(error!, style: TextStyle(color: c.error)),
      );
    }

    if (code == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: c.chipFill, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(
            code!.userCode,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () async {
                try {
                  await launchUrl(Uri.parse(code!.verificationUri));
                } catch (_) {
                  // launchUrl is widget-permitted; failures are swallowed
                  // because the user can still copy the URL manually.
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open browser'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: code!.userCode));
                } catch (_) {
                  // Clipboard is widget-permitted; nothing to do on failure.
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy code'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Waiting for authorization…', style: TextStyle(color: c.textMuted, fontSize: 13)),
      ],
    );
  }
}
