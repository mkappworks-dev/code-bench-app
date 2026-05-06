import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Visual tone of the status badge in a [SelectableTransportCard]. Each tone
/// pairs a colour with a small leading dot — see the per-provider cards
/// (`AnthropicProviderCard`, `OpenAIProviderCard`, `GeminiProviderCard`) for
/// the full mapping of tone → label.
enum TransportBadgeTone { muted, success, warning, error, savedUnverified }

/// Status badge shown in the right edge of a [SelectableTransportCard]'s
/// header row. Renders as `[● label]` with the dot tinted by [tone].
///
/// Does not include the "Active" affordance — selection is communicated by
/// the radio dot + accent border on [SelectableTransportCard].
class CardStatusBadge extends StatelessWidget {
  const CardStatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final TransportBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dotColor, textColor) = switch (tone) {
      TransportBadgeTone.muted => (c.mutedFg, c.textSecondary),
      TransportBadgeTone.success => (c.success, c.success),
      TransportBadgeTone.warning => (c.warning, c.warning),
      TransportBadgeTone.error => (c.error, c.error),
      TransportBadgeTone.savedUnverified => (c.success.withValues(alpha: 0.45), c.textSecondary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ],
    );
  }
}

/// Visual shell for one transport option (e.g. "API Key" or "Claude Code CLI").
///
/// Renders a bordered banner with a leading radio dot, a title, a right-aligned
/// status badge, and a chevron. Tapping the banner selects this transport;
/// tapping the chevron toggles the body visibility (collapsed by default to
/// keep the providers screen compact).
///
/// Selection is communicated by an accent-coloured border + a filled radio
/// dot. There is intentionally **no** background tint — see the brainstorm
/// mockup; the border/dot pair was judged enough.
class SelectableTransportCard extends StatefulWidget {
  const SelectableTransportCard({
    super.key,
    required this.title,
    required this.body,
    required this.selected,
    required this.badge,
    this.disabled = false,
    this.errorState = false,
    this.initiallyExpanded = false,
    this.onTap,
  });

  final String title;
  final Widget body;
  final bool selected;
  final Widget badge;

  /// Whether the body is visible on first build. Defaults to `false` — the
  /// banner-only state is the compact default. Pass `true` for cards that
  /// need attention out of the gate (e.g. broken-active CLI error state, or
  /// "Not configured" API key).
  final bool initiallyExpanded;

  /// Mutes the card and prevents [onTap] from firing. Used for CLI options
  /// when the binary is not on PATH, or for not-yet-implemented transports.
  /// Note: child widgets inside [body] (e.g. a "Recheck" button) remain
  /// interactive — only the card-level tap is suppressed.
  final bool disabled;

  /// Paints the border + radio dot in the error colour. Used for the
  /// "selected CLI transport but binary went missing" recovery state, where
  /// the card stays selected (so the next message doesn't silently fall back)
  /// but visibly broken.
  final bool errorState;

  final VoidCallback? onTap;

  @override
  State<SelectableTransportCard> createState() => _SelectableTransportCardState();
}

class _SelectableTransportCardState extends State<SelectableTransportCard> {
  bool _hovered = false;
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  void didUpdateWidget(SelectableTransportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-respect parent-driven attention on transitions: e.g. the CLI card
    // entering the error state should pop open even if the user had it
    // collapsed before.
    if (widget.initiallyExpanded && !oldWidget.initiallyExpanded) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final interactive = widget.onTap != null && !widget.disabled;
    final borderColor = widget.errorState ? c.error.withValues(alpha: 0.4) : c.deepBorder;
    final dotColor = widget.errorState
        ? c.error
        : (widget.selected ? c.accent : (interactive ? c.textSecondary : c.mutedFg));

    final headerRow = Row(
      children: [
        _RadioDot(selected: widget.selected, dotColor: dotColor),
        const SizedBox(width: 10),
        Text(
          widget.title,
          style: TextStyle(color: c.headingText, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        widget.badge,
        const SizedBox(width: 8),
        _ChevronButton(expanded: _expanded, onTap: _toggleExpanded),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tap the banner area to select; the chevron has its own gesture
          // detector that wins the arena (deeper) so expand/collapse doesn't
          // also flip the radio.
          Opacity(
            opacity: widget.disabled ? 0.6 : 1.0,
            child: MouseRegion(
              cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
              onEnter: (_) {
                if (interactive) setState(() => _hovered = true);
              },
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: interactive ? widget.onTap : null,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _hovered && interactive
                        ? Color.alphaBlend(c.surfaceHoverOverlay, c.inputSurface)
                        : c.inputSurface,
                    borderRadius: _expanded
                        ? const BorderRadius.vertical(top: Radius.circular(3))
                        : BorderRadius.circular(3),
                  ),
                  child: headerRow,
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, thickness: 1, color: c.borderColor),
            Container(
              color: c.sidebarBackground,
              padding: const EdgeInsets.fromLTRB(27, 9, 10, 10),
              child: widget.body,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Icon(expanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 14, color: c.mutedFg),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.dotColor});

  final bool selected;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: dotColor, width: 1.5),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
            )
          : null,
    );
  }
}
