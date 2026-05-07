import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Zero-animation drop-in for [showMenu].
///
/// Flutter < 3.16 hard-codes the popup scale/fade inside [_PopupMenuRoute] with
/// no public duration override.  This replaces the route entirely with a
/// [PopupRoute] whose [transitionDuration] is [Duration.zero] and whose
/// [buildPage] renders the same [PopupMenuEntry] widgets in a [Material] panel
/// positioned via [CustomSingleChildLayout].
///
/// [PopupMenuItem.handleTap] calls `Navigator.pop(context, value)` which
/// completes this route exactly as it would for the built-in route — no extra
/// wiring required.
Future<T?> showInstantMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  Color? color,
  ShapeBorder? shape,
  double elevation = 8.0,
  double? minWidth,
  double? anchorCenterX,
  double? anchorRightOffset,
  bool openAbove = false,
}) {
  return Navigator.of(context).push<T>(
    _InstantMenuRoute<T>(
      items: items,
      position: position,
      color: color,
      shape: shape,
      elevation: elevation,
      minWidth: minWidth,
      anchorCenterX: anchorCenterX,
      anchorRightOffset: anchorRightOffset,
      openAbove: openAbove,
    ),
  );
}

/// Use inside an onTap wrapped in a [Builder] so [buttonContext] resolves to the button itself.
Future<T?> showInstantMenuAnchoredTo<T>({
  required BuildContext buttonContext,
  required List<PopupMenuEntry<T>> items,
  Color? color,
  ShapeBorder? shape,
  double elevation = 8.0,
}) {
  final button = buttonContext.findRenderObject() as RenderBox;
  final overlay = Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomLeft = topLeft + Offset(0, button.size.height);

  // Express the horizontal anchor as a distance from the right edge so the
  // popup tracks the button when the window is resized horizontally. For
  // right-aligned buttons (the common case in the top action bar) this value
  // stays constant, whereas an absolute anchorCenterX would become stale.
  final anchorRightOffset = overlay.size.width - topLeft.dx - button.size.width / 2;

  return showInstantMenu<T>(
    context: buttonContext,
    position: RelativeRect.fromLTRB(
      bottomLeft.dx,
      bottomLeft.dy,
      overlay.size.width - bottomLeft.dx - button.size.width,
      overlay.size.height - bottomLeft.dy,
    ),
    items: items,
    color: color,
    shape: shape,
    elevation: elevation,
    minWidth: button.size.width,
    anchorRightOffset: anchorRightOffset,
  );
}

class _InstantMenuRoute<T> extends PopupRoute<T> {
  _InstantMenuRoute({
    required this.items,
    required this.position,
    this.color,
    this.shape,
    this.elevation = 8.0,
    this.minWidth,
    this.anchorCenterX,
    this.anchorRightOffset,
    this.openAbove = false,
  });

  final List<PopupMenuEntry<T>> items;
  final RelativeRect position;
  final Color? color;
  final ShapeBorder? shape;
  final double elevation;
  final double? minWidth;
  final double? anchorCenterX;
  final double? anchorRightOffset;
  final bool openAbove;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '';

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  Widget buildPage(BuildContext context, Animation<double> a, Animation<double> s) {
    final bg = color ?? Theme.of(context).popupMenuTheme.color ?? Theme.of(context).colorScheme.surface;
    return CustomSingleChildLayout(
      delegate: _MenuLayout(
        position: position,
        anchorCenterX: anchorCenterX,
        anchorRightOffset: anchorRightOffset,
        openAbove: openAbove,
      ),
      child: Material(
        color: bg,
        shape: shape,
        elevation: elevation,
        child: IntrinsicWidth(
          stepWidth: 56,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: math.min(minWidth ?? 112, 280), maxWidth: 280),
            // ExcludeSemantics prevents the SemanticsRole.menuItem assertion
            // that fires when PopupMenuItem is rendered outside Flutter's own
            // _PopupMenu route (which provides the required SemanticsRole.menu
            // ancestor). Desktop popup menus are mouse-driven, so this is fine.
            child: ExcludeSemantics(
              // Scroll wrapper so dynamic lists don't overflow the loose screen-height constraint from [_MenuLayout].
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({required this.position, this.anchorCenterX, this.anchorRightOffset, this.openAbove = false});
  final RelativeRect position;

  /// Absolute x coordinate to center the popup on. Stale after horizontal
  /// window resize — prefer [anchorRightOffset] for right-aligned buttons.
  final double? anchorCenterX;

  /// Distance from the screen's right edge to the button's center x.
  /// Recomputed each layout pass using the current [size.width], so the popup
  /// tracks right-aligned buttons as the window resizes horizontally.
  final double? anchorRightOffset;

  /// When true, the menu is anchored from the bottom of the screen using
  /// [position.bottom] (distance from button bottom to screen bottom).
  /// This stays stable when the window resizes vertically because bottom-docked
  /// widgets maintain a constant distance from the screen bottom.
  final bool openAbove;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = math.max(8.0, size.width - childSize.width - 8.0);
    final double x;
    if (anchorRightOffset != null) {
      // Derive center from the right edge — stable for right-docked buttons.
      final double buttonCenterX = size.width - anchorRightOffset!;
      x = (buttonCenterX - childSize.width / 2).clamp(8.0, maxX);
    } else if (anchorCenterX != null) {
      x = (anchorCenterX! - childSize.width / 2).clamp(8.0, maxX);
    } else {
      x = position.left.clamp(8.0, maxX);
    }

    final double y;
    if (openAbove) {
      // Use position.bottom (distance from button bottom to screen bottom) as the
      // anchor. size.height - position.bottom tracks the button's current bottom
      // even as the window resizes, because the widget stays at a fixed distance
      // from the screen bottom.
      final double buttonBottomY = size.height - position.bottom;
      y = buttonBottomY - childSize.height;
    } else {
      // Open below or auto: use position.top as anchor, prefer below, fall back above.
      final double spaceBelow = size.height - position.top;
      y = spaceBelow >= childSize.height + 8 ? position.top : position.top - childSize.height;
    }
    final double maxY = math.max(8.0, size.height - childSize.height - 8.0);

    return Offset(x, y.clamp(8.0, maxY));
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      position != old.position ||
      anchorCenterX != old.anchorCenterX ||
      anchorRightOffset != old.anchorRightOffset ||
      openAbove != old.openAbove;
}
