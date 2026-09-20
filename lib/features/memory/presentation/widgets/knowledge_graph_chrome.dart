import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

/// A single node placed on the canvas. Backed by a [ValueNotifier<Offset>] so
/// dragging it rebuilds only this widget (and repaints the edge layer) rather
/// than the whole graph.
class GraphNode extends StatelessWidget {
  /// Creates a [GraphNode].
  const GraphNode({
    required this.position,
    required this.size,
    required this.onMoved,
    required this.child,
    super.key,
  });

  /// Live canvas position of this node.
  final ValueNotifier<Offset> position;

  /// Layout size of the card.
  final Size size;

  /// Called on every drag update so the host can stop re-flowing this node.
  final VoidCallback onMoved;

  /// The card widget placed at [position].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, pos, child) {
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: size.width,
          height: size.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A trackpad two-finger scroll is a request to move the VIEW, not
            // this card. A pan recogniser accepts pan-zoom events as readily as
            // pointer drags and, being the inner one, wins the arena — so a
            // scroll that happened to start over a node dragged the node
            // instead of panning, amplified by 1/scale (four screen pixels per
            // finger pixel at the zoom floor). Excluding the trackpad kind
            // leaves the gesture to the viewer; a click-drag on a laptop
            // trackpad arrives as a mouse pointer, so dragging still works.
            supportedDevices: const {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.unknown,
            },
            // `delta` arrives in this widget's local (content) coordinates,
            // already corrected for the viewer's zoom, so it applies directly.
            onPanUpdate: (details) {
              position.value += details.delta;
              onMoved();
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// One row in the knowledge-graph legend.
class LegendItem extends StatelessWidget {
  /// Creates a [LegendItem].
  const LegendItem({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  /// Glyph shown beside [label].
  final IconData icon;

  /// Color of the glyph.
  final Color color;

  /// Legend text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: CcTypography.caption.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
