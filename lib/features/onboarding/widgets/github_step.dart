import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/repository.dart';
import '../../../services/github/github_api_service.dart';
import '../../../services/github/github_auth_service.dart';

class GithubStep extends ConsumerStatefulWidget {
  const GithubStep({super.key, required this.onContinue, required this.onSkip});
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  ConsumerState<GithubStep> createState() => _GithubStepState();
}

class _GithubStepState extends ConsumerState<GithubStep> {
  bool _connecting = false;
  GitHubAccount? _account;
  bool _showPat = false;
  final _patController = TextEditingController();
  bool _testingPat = false;
  bool? _patValid;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAccount() async {
    final account = await ref.read(githubAuthServiceProvider).getStoredAccount();
    if (mounted && account != null) setState(() => _account = account);
  }

  Future<void> _connectOAuth() async {
    setState(() => _connecting = true);
    try {
      final account = await ref.read(githubAuthServiceProvider).authenticate();
      if (mounted) setState(() => _account = account);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GitHub auth failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    await ref.read(githubAuthServiceProvider).signOut();
    if (mounted) setState(() => _account = null);
  }

  Future<void> _testPat() async {
    final token = _patController.text.trim();
    if (token.isEmpty) return;
    setState(() => _testingPat = true);
    try {
      final svc = GitHubApiService(token);
      final username = await svc.validateToken();
      if (mounted) {
        setState(() {
          _patValid = username != null;
          if (username != null) {
            _account = GitHubAccount(username: username, avatarUrl: '', email: null, name: null);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _patValid = false);
    } finally {
      if (mounted) setState(() => _testingPat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_account != null) {
      return _ConnectedView(
        account: _account!,
        onDisconnect: _disconnect,
        onContinue: widget.onContinue,
        onSkip: widget.onSkip,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OAuth button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF24292E), // GitHub brand colour
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _connecting ? null : _connectOAuth,
          icon: _connecting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.link, size: 16),
          label: Text(_connecting ? 'Connecting…' : 'Continue with GitHub', style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 20),

        // PAT fallback
        GestureDetector(
          onTap: () => setState(() => _showPat = !_showPat),
          child: Row(
            children: [
              Text(
                'Use a Personal Access Token instead',
                style: TextStyle(
                  color: ThemeConstants.accent,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 14,
                color: ThemeConstants.accent,
              ),
            ],
          ),
        ),

        if (_showPat) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _patController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token',
                    labelStyle: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: ThemeConstants.uiFontSizeSmall,
                    ),
                    suffixIcon: _patValid == null
                        ? null
                        : Icon(
                            _patValid! ? Icons.check_circle : Icons.error,
                            color: _patValid! ? ThemeConstants.success : ThemeConstants.error,
                            size: 16,
                          ),
                  ),
                  style: TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _testingPat ? null : _testPat,
                child: _testingPat
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Test', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await Process.run('open', ['https://github.com/settings/tokens/new']);
            },
            child: Text(
              'Create a token on GitHub →',
              style: TextStyle(
                color: ThemeConstants.accent,
                fontSize: ThemeConstants.uiFontSizeSmall,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const Spacer(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({
    required this.account,
    required this.onDisconnect,
    required this.onContinue,
    required this.onSkip,
  });

  final GitHubAccount account;
  final VoidCallback onDisconnect;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeConstants.panelBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ThemeConstants.faintFg),
          ),
          child: Row(
            children: [
              if (account.avatarUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(account.avatarUrl, width: 40, height: 40),
                )
              else
                Icon(Icons.person, size: 40, color: ThemeConstants.textSecondary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: ThemeConstants.success),
                      const SizedBox(width: 4),
                      Text(
                        account.username,
                        style: TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: ThemeConstants.uiFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (account.name != null)
                    Text(
                      account.name!,
                      style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                    ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: onDisconnect,
                child: Text(
                  'Disconnect',
                  style: TextStyle(color: ThemeConstants.textMuted, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Skip for now', style: TextStyle(fontSize: 12)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ThemeConstants.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onContinue,
              child: const Text('Continue →', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
