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
}) {
  return Navigator.of(context).push<T>(
    _InstantMenuRoute<T>(items: items, position: position, color: color, shape: shape, elevation: elevation),
  );
}

/// Shows [showInstantMenu] anchored just below the bottom-left of the widget
/// whose [buttonContext] is passed. Use inside an onTap handler wrapped in a
/// [Builder] so [buttonContext] resolves to the button itself (not its parent).
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
  );
}

class _InstantMenuRoute<T> extends PopupRoute<T> {
  _InstantMenuRoute({required this.items, required this.position, this.color, this.shape, this.elevation = 8.0});

  final List<PopupMenuEntry<T>> items;
  final RelativeRect position;
  final Color? color;
  final ShapeBorder? shape;
  final double elevation;

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
      delegate: _MenuLayout(position: position),
      child: Material(
        color: bg,
        shape: shape,
        elevation: elevation,
        child: IntrinsicWidth(
          stepWidth: 56,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 280),
            // ExcludeSemantics prevents the SemanticsRole.menuItem assertion
            // that fires when PopupMenuItem is rendered outside Flutter's own
            // _PopupMenu route (which provides the required SemanticsRole.menu
            // ancestor). Desktop popup menus are mouse-driven, so this is fine.
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({required this.position});
  final RelativeRect position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = math.max(8.0, size.width - childSize.width - 8.0);
    final double x = position.left.clamp(8.0, maxX);

    // Open above if there's not enough room below the anchor point.
    final double spaceBelow = size.height - position.top;
    final double y = spaceBelow >= childSize.height + 8 ? position.top : position.top - childSize.height;
    final double maxY = math.max(8.0, size.height - childSize.height - 8.0);

    return Offset(x, y.clamp(8.0, maxY));
  }

  @override
  bool shouldRelayout(_MenuLayout old) => position != old.position;
}
