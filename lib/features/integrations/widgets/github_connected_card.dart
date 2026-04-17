// lib/features/integrations/widgets/github_connected_card.dart
import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/github/models/repository.dart';

class GithubConnectedCard extends StatefulWidget {
  const GithubConnectedCard({super.key, required this.account, required this.onDisconnect});

  final GitHubAccount account;
  final VoidCallback onDisconnect;

  @override
  State<GithubConnectedCard> createState() => _GithubConnectedCardState();
}

class _GithubConnectedCardState extends State<GithubConnectedCard> {
  bool _disconnectHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (widget.account.avatarUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.account.avatarUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => PersonIcon(c: c),
              ),
            )
          else
            PersonIcon(c: c),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.username,
                style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: c.success),
                  const SizedBox(width: 3),
                  Text('Connected', style: TextStyle(color: c.success, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _disconnectHovered = true),
            onExit: (_) => setState(() => _disconnectHovered = false),
            child: GestureDetector(
              onTap: widget.onDisconnect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _disconnectHovered ? c.deepBorder : Colors.transparent,
                  border: Border.all(color: c.deepBorder),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Disconnect',
                  style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, required this.c});

  final AppColors c;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: c.inputSurface, shape: BoxShape.circle),
    child: Icon(Icons.person, size: 20, color: c.textSecondary),
  );
}
