/// The scene: a laid-out diagram as flat, positioned drawing primitives.
///
/// The scene is the seam between layout and paint. Layout decides GEOMETRY and
/// names each piece's semantic ROLE; the painter resolves roles to colors from
/// the host's [CcMermaidStyle]. Nothing here carries a `Color`, so a theme flip
/// repaints without re-laying out and layout stays unit-testable by asserting
/// rectangles instead of pixels.
library;

import 'dart:ui' show Offset, Rect, Size;

import 'package:cc_markdown/src/mermaid/model.dart';

/// What a primitive IS, so the painter can pick its colors.
enum CcMermaidPaintRole {
  /// A diagram node / participant box.
  node,

  /// A terminal marker, fork bar, or other accented solid.
  accent,

  /// A `subgraph` / composite-state container.
  cluster,

  /// A note box.
  note,

  /// An edge, lifeline, or connector.
  edge,

  /// A label chip sitting on top of an edge.
  edgeLabel,

  /// A sequence activation bar.
  activation,

  /// A sequence block frame (`loop`, `alt`, …).
  frame,

  /// A separator rule (class compartments, sequence dividers).
  divider,

  /// A palette-colored series (pie slices, legend swatches, timeline sections).
  series,
}

/// Which text style a run uses.
enum CcMermaidTextRole {
  /// Node / participant labels.
  label,

  /// The diagram title.
  title,

  /// Cluster and frame titles.
  cluster,

  /// Edge labels and cardinalities.
  edgeLabel,

  /// Class members, ER attributes — the monospace-ish compartment rows.
  compartment,

  /// Note body text.
  note,

  /// Legend rows, pie percentages, section labels.
  legend,
}

/// Horizontal alignment of a text run inside its box.
enum CcMermaidTextAlign {
  /// Start-aligned.
  left,

  /// Centered.
  center,

  /// End-aligned.
  right,
}

/// Base type of every drawing primitive.
sealed class CcMermaidPrimitive {
  /// Creates a [CcMermaidPrimitive].
  const CcMermaidPrimitive();
}

/// A filled + stroked outline (node, cluster, note, activation bar, frame).
final class CcMermaidShapePrim extends CcMermaidPrimitive {
  /// Creates a [CcMermaidShapePrim].
  const CcMermaidShapePrim({
    required this.rect,
    required this.shape,
    required this.role,
    this.dashed = false,
    this.filled = true,
    this.stroked = true,
    this.seriesIndex,
    this.strokeWidth,
  });

  /// The shape's bounding box.
  final Rect rect;

  /// Which outline to trace.
  final CcMermaidNodeShape shape;

  /// Color role.
  final CcMermaidPaintRole role;

  /// Whether the outline is dashed.
  final bool dashed;

  /// Whether to fill.
  final bool filled;

  /// Whether to stroke.
  final bool stroked;

  /// Palette index for [CcMermaidPaintRole.series].
  final int? seriesIndex;

  /// Stroke width override.
  final double? strokeWidth;
}

/// A text run positioned inside [rect] (single line; multi-line labels emit one
/// primitive per line so layout owns leading).
final class CcMermaidTextPrim extends CcMermaidPrimitive {
  /// Creates a [CcMermaidTextPrim].
  const CcMermaidTextPrim({
    required this.text,
    required this.rect,
    required this.role,
    this.align = CcMermaidTextAlign.center,
    this.muted = false,
    this.seriesIndex,
  });

  /// The literal text.
  final String text;

  /// The box the run is placed in (the painter vertically centers within it).
  final Rect rect;

  /// Which text style to use.
  final CcMermaidTextRole role;

  /// Horizontal alignment inside [rect].
  final CcMermaidTextAlign align;

  /// Whether to draw in the muted (secondary) text color.
  final bool muted;

  /// Palette index when the run is colored by series (legend rows).
  final int? seriesIndex;
}

/// A polyline (an edge, a lifeline, a leader line), optionally with end
/// decorations and rounded corners.
final class CcMermaidPathPrim extends CcMermaidPrimitive {
  /// Creates a [CcMermaidPathPrim].
  const CcMermaidPathPrim({
    required this.points,
    this.stroke = CcMermaidEdgeStroke.solid,
    this.role = CcMermaidPaintRole.edge,
    this.startMarker = CcMermaidEdgeMarker.none,
    this.endMarker = CcMermaidEdgeMarker.none,
    this.cornerRadius = 8,
  });

  /// Two or more points, already clipped to their endpoints' outlines.
  final List<Offset> points;

  /// Stroke pattern.
  final CcMermaidEdgeStroke stroke;

  /// Color role.
  final CcMermaidPaintRole role;

  /// Decoration at [points] first.
  final CcMermaidEdgeMarker startMarker;

  /// Decoration at [points] last.
  final CcMermaidEdgeMarker endMarker;

  /// Corner rounding applied at interior vertices.
  final double cornerRadius;
}

/// A pie slice.
final class CcMermaidArcPrim extends CcMermaidPrimitive {
  /// Creates a [CcMermaidArcPrim].
  const CcMermaidArcPrim({
    required this.rect,
    required this.startAngle,
    required this.sweepAngle,
    required this.seriesIndex,
  });

  /// The bounding square of the circle.
  final Rect rect;

  /// Start angle in radians (0 = 3 o'clock, mermaid starts at 12).
  final double startAngle;

  /// Sweep in radians, clockwise.
  final double sweepAngle;

  /// Palette index.
  final int seriesIndex;
}

/// A stick figure for `actor` participants.
final class CcMermaidActorPrim extends CcMermaidPrimitive {
  /// Creates a [CcMermaidActorPrim].
  const CcMermaidActorPrim(this.rect);

  /// The figure's bounding box.
  final Rect rect;
}

/// A laid-out diagram: primitives in paint order plus the logical canvas size.
class CcMermaidScene {
  /// Creates a [CcMermaidScene].
  const CcMermaidScene({
    required this.size,
    required this.primitives,
    this.hitTargets = const [],
  });

  /// An empty scene (nothing to draw).
  static const CcMermaidScene empty = CcMermaidScene(
    size: Size.zero,
    primitives: [],
  );

  /// The diagram's logical size, in layout units (the view scales this).
  final Size size;

  /// Primitives in back-to-front paint order.
  final List<CcMermaidPrimitive> primitives;

  /// Clickable regions produced by flowchart `click` bindings.
  final List<CcMermaidHitTarget> hitTargets;

  /// Whether there is anything to draw.
  bool get isEmpty => primitives.isEmpty;
}

/// A tappable region: a node with a `click` binding.
class CcMermaidHitTarget {
  /// Creates a [CcMermaidHitTarget].
  const CcMermaidHitTarget({
    required this.rect,
    required this.nodeId,
    this.href,
    this.tooltip,
  });

  /// The node's box in scene coordinates.
  final Rect rect;

  /// The node id.
  final String nodeId;

  /// The bound URL, or null.
  final String? href;

  /// The bound tooltip, or null.
  final String? tooltip;
}

/// Measures text the way the painter will draw it — the one source of truth for
/// label metrics, so layout never guesses a glyph width.
abstract class CcMermaidTextRuler {
  /// Creates a [CcMermaidTextRuler].
  const CcMermaidTextRuler();

  /// The size [text] occupies in [role]'s style.
  Size measure(String text, CcMermaidTextRole role);

  /// The line height of [role]'s style (used for empty rows).
  double lineHeight(CcMermaidTextRole role);
}
