import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../settings/widgets/section_label.dart';
import '../../data/mcp/models/mcp_server_config.dart';
import 'notifiers/mcp_server_status_notifier.dart';
import 'notifiers/mcp_servers_actions.dart';
import 'notifiers/mcp_servers_failure.dart';
import 'notifiers/mcp_servers_notifier.dart';
import 'widgets/mcp_server_card.dart';
import 'widgets/mcp_server_editor_dialog.dart';

class McpServersScreen extends ConsumerStatefulWidget {
  const McpServersScreen({super.key});

  @override
  ConsumerState<McpServersScreen> createState() => _McpServersScreenState();
}

class _McpServersScreenState extends ConsumerState<McpServersScreen> {
  Future<void> _saveServer(McpServerConfig config) async {
    await ref.read(mcpServersActionsProvider.notifier).save(config);
    if (!mounted) return;
    if (ref.read(mcpServersActionsProvider).hasError) throw Exception('save failed');
  }

  void _openAdd() {
    showDialog<void>(
      context: context,
      builder: (_) => McpServerEditorDialog(onSave: _saveServer),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mcpServersActionsProvider, (_, next) {
      if (next is! AsyncError) return;
      final failure = next.error;
      if (failure is! McpServersFailure) return;
      final msg = switch (failure) {
        McpServersSaveError() => 'Failed to save MCP server',
        McpServersRemoveError() => 'Failed to remove MCP server',
        McpServersUnknownError() => 'Unexpected error',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
    });

    final c = AppColors.of(context);
    final serversAsync = ref.watch(mcpServersProvider);
    final statusMap = ref.watch(mcpServerStatusProvider);

    return Scaffold(
      backgroundColor: c.sidebarBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                SectionLabel('MCP Servers'),
                const Spacer(),
                GestureDetector(
                  onTap: _openAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.chipFill,
                      border: Border.all(color: c.chipStroke),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: c.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Add Server',
                          style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: serversAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
              data: (servers) => servers.isEmpty
                  ? _EmptyState(onAdd: _openAdd)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: servers.length,
                      itemBuilder: (_, i) => McpServerCard(
                        config: servers[i],
                        status: statusMap[servers[i].id] ?? const McpServerStatus.stopped(),
                        onEdit: (config) {
                          showDialog<void>(
                            context: context,
                            builder: (_) => McpServerEditorDialog(initial: config, onSave: _saveServer),
                          );
                        },
                        onRemove: (id) => ref.read(mcpServersActionsProvider.notifier).remove(id),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.extension_outlined, size: 40, color: c.mutedFg),
          const SizedBox(height: 12),
          Text(
            'No MCP servers configured',
            style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Add your first server',
              style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}
