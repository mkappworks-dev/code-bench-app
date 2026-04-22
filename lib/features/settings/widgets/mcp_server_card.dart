import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../notifiers/mcp_server_status_notifier.dart';

class McpServerCard extends StatelessWidget {
  const McpServerCard({
    super.key,
    required this.config,
    required this.status,
    required this.onEdit,
    required this.onRemove,
  });

  final McpServerConfig config;
  final McpServerStatus status;
  final void Function(McpServerConfig) onEdit;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(status: status),
                const SizedBox(width: 8),
                Text(config.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                _TransportBadge(transport: config.transport),
                const Spacer(),
                _ActionMenu(config: config, onEdit: onEdit, onRemove: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.transport == McpTransport.stdio ? (config.command ?? '') : (config.url ?? ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: c.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            if (status case McpServerRunning()) ...[
              const SizedBox(height: 8),
              Text('Tools loaded', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.success)),
            ],
            if (status case McpServerError(:final message)) ...[
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final McpServerStatus status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (status) {
      McpServerRunning() => c.success,
      McpServerError() => c.error,
      McpServerStarting() => c.warning,
      McpServerStopped() || McpServerPendingRemoval() => c.textSecondary,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TransportBadge extends StatelessWidget {
  const _TransportBadge({required this.transport});
  final McpTransport transport;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.chipFill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.chipStroke),
      ),
      child: Text(
        transport == McpTransport.stdio ? 'stdio' : 'HTTP/SSE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.chipText),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.config, required this.onEdit, required this.onRemove});

  final McpServerConfig config;
  final void Function(McpServerConfig) onEdit;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit(config);
        if (value == 'remove') onRemove(config.id);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'remove',
          child: Text('Remove', style: TextStyle(color: c.error)),
        ),
      ],
    );
  }
}
