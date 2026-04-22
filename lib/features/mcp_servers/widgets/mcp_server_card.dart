import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mcp/models/mcp_server_config.dart';
import '../notifiers/mcp_server_status_notifier.dart';

class McpServerCard extends StatefulWidget {
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
  final Future<void> Function(String id) onRemove;

  @override
  State<McpServerCard> createState() => _McpServerCardState();
}

class _McpServerCardState extends State<McpServerCard> {
  bool _confirming = false;
  bool _removing = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final config = widget.config;
    final status = widget.status;
    final detail = config.transport == McpTransport.stdio ? (config.command ?? '') : (config.url ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.inputSurface,
        border: Border.all(color: c.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(status: status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _TransportBadge(transport: config.transport),
              if (!_confirming) ...[
                const SizedBox(width: 8),
                _ActionButtons(
                  config: config,
                  onEdit: widget.onEdit,
                  onRequestRemove: () => setState(() => _confirming = true),
                ),
              ],
            ],
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSize,
                fontFamily: ThemeConstants.editorFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (status case McpServerRunning()) ...[
            const SizedBox(height: 4),
            Text(
              'Tools loaded',
              style: TextStyle(color: c.success, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
          ],
          if (status case McpServerError(:final message)) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_confirming) ...[
            const SizedBox(height: 6),
            _InlineConfirmRow(
              removing: _removing,
              onCancel: () => setState(() => _confirming = false),
              onConfirm: () async {
                setState(() => _removing = true);
                await widget.onRemove(config.id);
                if (mounted)
                  setState(() {
                    _confirming = false;
                    _removing = false;
                  });
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineConfirmRow extends StatelessWidget {
  const _InlineConfirmRow({required this.removing, required this.onCancel, required this.onConfirm});

  final bool removing;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Remove this server?',
            style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
        ),
        const SizedBox(width: 8),
        _ConfirmButton(
          label: '✕  Cancel',
          onTap: removing ? null : onCancel,
          borderColor: c.chipStroke,
          bgColor: c.chipFill,
          hoverBgColor: c.chipStroke,
          textColor: c.textSecondary,
        ),
        const SizedBox(width: 4),
        _ConfirmButton(
          label: removing ? '…' : '✓  Remove',
          onTap: removing ? null : onConfirm,
          borderColor: c.error.withValues(alpha: 0.4),
          bgColor: c.error.withValues(alpha: 0.1),
          hoverBgColor: c.error.withValues(alpha: 0.2),
          textColor: c.error,
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  const _ConfirmButton({
    required this.label,
    required this.onTap,
    required this.borderColor,
    required this.bgColor,
    required this.hoverBgColor,
    required this.textColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color bgColor;
  final Color hoverBgColor;
  final Color textColor;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered && enabled ? widget.hoverBgColor : widget.bgColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.textColor.withValues(alpha: enabled ? 1.0 : 0.5),
              fontSize: ThemeConstants.uiFontSizeLabel,
            ),
          ),
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
      McpServerStopped() || McpServerPendingRemoval() => c.mutedFg,
    };
    return Container(
      width: 7,
      height: 7,
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
        style: TextStyle(color: c.chipText, fontSize: ThemeConstants.uiFontSizeLabel),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.config, required this.onEdit, required this.onRequestRemove});

  final McpServerConfig config;
  final void Function(McpServerConfig) onEdit;
  final VoidCallback onRequestRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconActionButton(
          icon: AppIcons.rename,
          color: c.mutedFg,
          hoverColor: c.textPrimary,
          onTap: () => onEdit(config),
        ),
        const SizedBox(width: 2),
        _IconActionButton(icon: AppIcons.trash, color: c.mutedFg, hoverColor: c.error, onTap: onRequestRemove),
      ],
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({required this.icon, required this.color, required this.hoverColor, required this.onTap});

  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: Icon(
              widget.icon,
              key: ValueKey(_hovered),
              size: 13,
              color: _hovered ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
