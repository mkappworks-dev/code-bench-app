import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/chat_session.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.inputSurface : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? ThemeConstants.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Title
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  color: isActive ? ThemeConstants.textPrimary : ThemeConstants.mutedFg,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Time
            Text(
              _relativeTime(session.updatedAt),
              style: const TextStyle(
                color: ThemeConstants.faintFg,
                fontSize: ThemeConstants.uiFontSizeBadge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
