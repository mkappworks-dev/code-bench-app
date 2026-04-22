import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/session/models/permission_request.dart';
import '../notifiers/agent_permission_request_notifier.dart';
import '../utils/permission_request_preview.dart';

class PermissionRequestCard extends ConsumerStatefulWidget {
  const PermissionRequestCard({super.key, required this.request});
  final PermissionRequest request;

  @override
  ConsumerState<PermissionRequestCard> createState() => _PermissionRequestCardState();
}

class _PermissionRequestCardState extends ConsumerState<PermissionRequestCard> {
  bool _expanded = false;

  List<String>? _buildPreviewLines() => PermissionRequestPreview.buildLines(widget.request);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final previewLines = _buildPreviewLines();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.05),
        border: Border.all(color: c.warning.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: c.warning),
              const SizedBox(width: 6),
              Text('Allow ', style: TextStyle(color: c.textPrimary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.request.toolName,
                  style: TextStyle(color: c.warning, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              Text('?', style: TextStyle(color: c.textPrimary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.request.summary,
            style: TextStyle(color: c.textSecondary, fontSize: 11, fontFamily: 'monospace'),
          ),
          // existing collapsible diff — skip for bash
          if (previewLines != null && widget.request.toolName != 'bash') ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Hide diff ▴' : 'Show diff ▾',
                style: TextStyle(color: c.textMuted, fontSize: 10),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.codeBlockBg,
                  border: Border.all(color: c.subtleBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in previewLines)
                      Text(
                        line,
                        style: TextStyle(color: c.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
            ],
          ],
          // bash: always-visible command code block
          if (widget.request.toolName == 'bash' && previewLines != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.codeBlockBg,
                border: Border.all(color: c.subtleBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                previewLines.first,
                style: TextStyle(color: c.textPrimary, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 4),
            Text('Denylist rules do not restrict bash commands.', style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => ref.read(agentPermissionRequestProvider.notifier).resolve(false),
                style: TextButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  side: BorderSide(color: c.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Deny'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ref.read(agentPermissionRequestProvider.notifier).resolve(true),
                style: TextButton.styleFrom(
                  foregroundColor: c.success,
                  backgroundColor: c.success.withValues(alpha: 0.15),
                  side: BorderSide(color: c.success.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                child: const Text('Allow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
