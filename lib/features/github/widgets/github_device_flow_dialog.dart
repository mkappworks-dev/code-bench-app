import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/github/models/device_code_response.dart';
import '../notifiers/github_auth_notifier.dart';

/// Frosted-glass dialog implementing the GitHub Device Flow user-facing screen.
///
/// Mounted by tapping "Connect with GitHub". On mount it asks the notifier to
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
  // Stashed verification URL shown as a fallback when browser launch fails.
  String? _launchFailedUri;
  // Guard against the cascade rebuild of gitHubAuthProvider (triggered by
  // ref.invalidate(githubApiDatasourceProvider) after Device Flow completes)
  // firing a second AsyncData(account) while the dialog route is still in its
  // exit animation. Without this, the second fire would call Navigator.pop()
  // on an already-popping route, causing the !_debugLocked assertion.
  bool _dismissed = false;

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

  Future<void> _onTryAgain() async {
    // Cancel the in-flight poll before requesting a new device code, so the
    // stale poller from the failed attempt doesn't race the new one.
    ref.read(gitHubAuthProvider.notifier).cancelDeviceFlow();
    setState(() {
      _error = null;
      _code = null;
      _launchFailedUri = null;
    });
    await _start();
  }

  Future<void> _openBrowser(String uri) async {
    try {
      await launchUrl(Uri.parse(uri));
    } catch (_) {
      // launchUrl is widget-permitted. On failure, surface the URL inline so
      // the user can open it manually — it is not displayed anywhere else.
      if (mounted) setState(() => _launchFailedUri = uri);
    }
  }

  Future<void> _copyCode(String userCode) async {
    try {
      await Clipboard.setData(ClipboardData(text: userCode));
    } catch (_) {
      // Clipboard is widget-permitted; nothing to do on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gitHubAuthProvider, (previous, next) {
      next.whenData((account) {
        if (account != null && mounted && !_dismissed) {
          _dismissed = true;
          Navigator.of(context).pop();
        }
      });
      if (next.hasError && mounted) {
        setState(() => _error = userMessage(next.error!));
      }
    });

    final code = _code;
    final error = _error;

    final String subtitle;
    if (error != null) {
      subtitle = "Couldn't request a device code";
    } else if (code == null) {
      subtitle = 'Requesting code…';
    } else {
      subtitle = 'Two steps to authorize Code Bench';
    }

    final List<AppDialogAction> actions;
    if (error != null) {
      actions = [
        AppDialogAction.primary(label: 'Try again', onPressed: _onTryAgain),
        AppDialogAction.cancel(onPressed: _onCancel),
      ];
    } else if (code != null) {
      actions = [
        AppDialogAction.primary(label: 'Open GitHub', onPressed: () => _openBrowser(code.verificationUri)),
        AppDialogAction.cancel(onPressed: _onCancel),
      ];
    } else {
      actions = [AppDialogAction.cancel(onPressed: _onCancel)];
    }

    // PopScope blocks Escape / system-back from dismissing the route. The
    // only sanctioned exit is the Cancel action, which routes through
    // [_onCancel] so the notifier's cancel path runs.
    return PopScope(
      canPop: false,
      child: AppDialog(
        icon: AppIcons.github,
        iconType: AppDialogIconType.teal,
        title: 'Sign in to GitHub',
        subtitle: subtitle,
        content: _DeviceFlowContent(code: code, error: error, launchFailedUri: _launchFailedUri, onCopyCode: _copyCode),
        actions: actions,
      ),
    );
  }
}

class _DeviceFlowContent extends StatelessWidget {
  const _DeviceFlowContent({required this.code, required this.error, required this.onCopyCode, this.launchFailedUri});

  final DeviceCodeResponse? code;
  final String? error;
  final String? launchFailedUri;
  final Future<void> Function(String userCode) onCopyCode;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.08),
            border: Border.all(color: c.error.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GITHUB SAID',
                style: TextStyle(color: c.error, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(error!, style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.45)),
            ],
          ),
        ),
      );
    }

    if (code == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final userCode = code!.userCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // Hero code chip — tap to copy.
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onCopyCode(userCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: c.chipFill,
                border: Border.all(color: c.chipStroke),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SelectableText(
                  userCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Auto-clipboard hint — confirms the silent copy that fires on mount.
        Center(
          child: Text(
            '✓  Copied to clipboard — tap code to copy again',
            style: TextStyle(color: c.textMuted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
        // 2-step checklist.
        _Step(number: 1, label: 'Code copied — ready to paste', done: true),
        const SizedBox(height: 8),
        _Step(number: 2, label: 'Open the verification URL and paste'),
        const SizedBox(height: 16),
        // Pulse + waiting indicator, sits just above the actions divider.
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingDot(),
              const SizedBox(width: 8),
              Text('Waiting for authorization', style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (launchFailedUri != null) ...[const SizedBox(height: 12), _LaunchFailedBanner(uri: launchFailedUri!)],
      ],
    );
  }
}

/// Shown when `launchUrl` fails so the user has a manual fallback.
class _LaunchFailedBanner extends StatelessWidget {
  const _LaunchFailedBanner({required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.08),
        border: Border.all(color: c.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Couldn't open browser — copy this URL instead:",
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          SelectableText(
            uri,
            style: TextStyle(fontFamily: 'monospace', color: c.textPrimary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, this.done = false});

  final int number;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accentBg = c.accent.withValues(alpha: 0.15);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? c.accent : accentBg,
            shape: BoxShape.circle,
            border: done ? null : Border.all(color: c.accent.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: done
              ? Icon(AppIcons.check, size: 12, color: c.onAccent)
              : Text(
                  '$number',
                  style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label, style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

/// Soft teal dot that pulses to indicate background polling. Not a spinner —
/// the polling cadence is on the order of seconds, so a slow pulse reads as
/// "alive" without becoming visual noise.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        // Two-stage opacity: ramp up 0→1 over first half, ease back 1→0.4
        // over the second. Avoids the "blink off" feel of a sine wave.
        final opacity = t < 0.5 ? 0.4 + (t * 2) * 0.6 : 1.0 - ((t - 0.5) * 2) * 0.6;
        final glow = (1 - t) * 6;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: opacity),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.4), blurRadius: glow, spreadRadius: 0)],
          ),
        );
      },
    );
  }
}
