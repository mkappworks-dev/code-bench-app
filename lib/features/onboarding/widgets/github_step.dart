import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/repository.dart';
import '../../../services/github/github_api_service.dart';
import '../../../services/github/github_auth_service.dart';

class GithubStep extends ConsumerStatefulWidget {
  const GithubStep({super.key, required this.onContinue});
  final VoidCallback onContinue;

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
      return _ConnectedView(account: _account!, onDisconnect: _disconnect, onContinue: widget.onContinue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OAuth button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF24292E),
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
              const Text(
                'Use a Personal Access Token instead',
                style: TextStyle(color: Color(0xFF4A7CFF), fontSize: 11, decoration: TextDecoration.underline),
              ),
              const SizedBox(width: 4),
              Icon(
                _showPat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 14,
                color: const Color(0xFF4A7CFF),
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
                    labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    suffixIcon: _patValid == null
                        ? null
                        : Icon(
                            _patValid! ? Icons.check_circle : Icons.error,
                            color: _patValid! ? Colors.green : Colors.red,
                            size: 16,
                          ),
                  ),
                  style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _testingPat ? null : _testPat,
                child: _testingPat
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await Process.run('open', ['https://github.com/settings/tokens/new']);
            },
            child: const Text(
              'Create a token on GitHub →',
              style: TextStyle(color: Color(0xFF4A7CFF), fontSize: 11, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.account, required this.onDisconnect, required this.onContinue});

  final GitHubAccount account;
  final VoidCallback onDisconnect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              if (account.avatarUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(account.avatarUrl, width: 40, height: 40),
                )
              else
                const Icon(Icons.person, size: 40, color: Color(0xFF888888)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        account.username,
                        style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (account.name != null)
                    Text(account.name!, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: onDisconnect,
                child: const Text('Disconnect', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A7CFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: onContinue,
          child: const Text('Continue →', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
