/// Sizes and paint primitives for flowchart, state, class and ER diagrams:
/// what each node, subgraph box and edge looks like once the layered layout
/// (graph_layout.dart) has decided where it goes.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/geometry.dart';
import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Widest a node label grows before it soft-wraps.
const double _kMaxLabelWidth = 210;

/// Widest an edge label grows before it soft-wraps.
const double kMermaidMaxEdgeLabelWidth = 160;

/// How far a self-loop bulges out from its node.
const double _kSelfLoopReach = 26;

/// Measures and draws the pieces of a layered mermaid graph.
class MermaidGraphShapes {
  /// Draws with [style], measuring text through [ruler].
  const MermaidGraphShapes({required this.style, required this.ruler});

  /// Spacing, padding and corner radii.
  final CcMermaidStyle style;

  /// Measures label text.
  final CcMermaidTextRuler ruler;

  /// Gap between a subgraph's top border and its title.
  double get clusterTitleTop => style.clusterPadding * 0.5;

  /// Size of a subgraph's title text.
  Size clusterTitleSize(CcMermaidCluster cluster) => measureMermaidLines(
    cluster.lines,
    CcMermaidTextRole.cluster,
    ruler,
    lineSpacing: style.lineSpacing,
  );

  /// The subgraph box and its title, top-left inside the border.
  List<CcMermaidPrimitive> clusterPrimitives(
    CcMermaidCluster cluster,
    Rect box,
  ) {
    final out = <CcMermaidPrimitive>[
      CcMermaidShapePrim(
        rect: box,
        shape: CcMermaidNodeShape.roundRect,
        role: CcMermaidPaintRole.cluster,
      ),
    ];
    if (cluster.lines.isNotEmpty) {
      final size = clusterTitleSize(cluster);
      out.addAll(
        stackTextLines(
          cluster.lines,
          CcMermaidTextRole.cluster,
          ruler,
          box: Rect.fromLTWH(
            box.left + 12,
            box.top + clusterTitleTop,
            box.width - 24,
            size.height,
          ),
          lineSpacing: style.lineSpacing,
          align: CcMermaidTextAlign.left,
          muted: true,
        ),
      );
    }
    return out;
  }

  /// A routed edge's line, markers and cardinality labels.
  List<CcMermaidPrimitive> edgePrimitives(
    CcMermaidEdge edge,
    List<Offset> points,
  ) {
    if (edge.stroke == CcMermaidEdgeStroke.invisible || points.length < 2) {
      return const [];
    }
    return [
      CcMermaidPathPrim(
        points: points,
        stroke: edge.stroke,
        startMarker: edge.startMarker,
        endMarker: edge.endMarker,
        cornerRadius: style.edgeCornerRadius,
      ),
      ..._cardinalityPrimitives(edge, points),
    ];
  }

  /// A node's box (visual space), label wrapped and padded for its shape.
  Size measure(CcMermaidNode node, {required bool horizontal}) {
    switch (node.shape) {
      case CcMermaidNodeShape.startPoint:
        return const Size(16, 16);
      case CcMermaidNodeShape.endPoint:
        return const Size(20, 20);
      case CcMermaidNodeShape.choice:
        return const Size(34, 34);
      case CcMermaidNodeShape.bar:
        return horizontal ? const Size(8, 64) : const Size(64, 8);
      case CcMermaidNodeShape.compartments:
        return _measureCompartments(node);
      case CcMermaidNodeShape.note:
        final lines = wrapMermaidLines(
          node.displayLines,
          CcMermaidTextRole.note,
          ruler,
          maxWidth: _kMaxLabelWidth,
        );
        final text = measureMermaidLines(
          lines,
          CcMermaidTextRole.note,
          ruler,
          lineSpacing: style.lineSpacing,
        );
        return Size(
          math.max(text.width + style.nodePadding.horizontal, 60),
          text.height + style.nodePadding.vertical,
        );
      default:
        final lines = wrapMermaidLines(
          node.displayLines,
          CcMermaidTextRole.label,
          ruler,
          maxWidth: _kMaxLabelWidth,
        );
        final text = measureMermaidLines(
          lines,
          CcMermaidTextRole.label,
          ruler,
          lineSpacing: style.lineSpacing,
        );
        final inflation = shapeInflation(node.shape);
        return Size(
          math.max(
            text.width * inflation.widthFactor + style.nodePadding.horizontal,
            inflation.minWidth,
          ),
          math.max(
            text.height * inflation.heightFactor + style.nodePadding.vertical,
            26,
          ),
        );
    }
  }

  Size _measureCompartments(CcMermaidNode node) {
    final header = measureMermaidLines(
      [
        if (node.stereotype != null) '«${node.stereotype}»',
        ...node.displayLines,
      ],
      CcMermaidTextRole.label,
      ruler,
      lineSpacing: style.lineSpacing,
    );
    var width = header.width;
    var height = header.height + style.nodePadding.vertical;
    for (final compartment in node.compartments) {
      for (final row in compartment) {
        final size = ruler.measure(row, CcMermaidTextRole.compartment);
        width = math.max(width, size.width);
        height += size.height + style.lineSpacing;
      }
      height += style.nodePadding.vertical;
    }
    return Size(
      math.max(width + style.nodePadding.horizontal, 90),
      math.max(height, 34),
    );
  }

  /// A node's shape and label drawn into [rect].
  List<CcMermaidPrimitive> nodePrimitives(CcMermaidNode node, Rect rect) {
    final out = <CcMermaidPrimitive>[];
    switch (node.shape) {
      case CcMermaidNodeShape.startPoint:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
            stroked: false,
          ),
        );
        return out;
      case CcMermaidNodeShape.endPoint:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
          ),
        );
        return out;
      case CcMermaidNodeShape.bar:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
            stroked: false,
          ),
        );
        return out;
      case CcMermaidNodeShape.choice:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.node,
          ),
        );
        return out;
      case CcMermaidNodeShape.note:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.note,
          ),
        );
        out.addAll(
          stackTextLines(
            wrapMermaidLines(
              node.displayLines,
              CcMermaidTextRole.note,
              ruler,
              maxWidth: _kMaxLabelWidth,
            ),
            CcMermaidTextRole.note,
            ruler,
            box: rect,
            lineSpacing: style.lineSpacing,
          ),
        );
        return out;
      case CcMermaidNodeShape.compartments:
        return _compartmentPrimitives(node, rect);
      default:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.node,
          ),
        );
        out.addAll(
          stackTextLines(
            wrapMermaidLines(
              node.displayLines,
              CcMermaidTextRole.label,
              ruler,
              maxWidth: _kMaxLabelWidth,
            ),
            CcMermaidTextRole.label,
            ruler,
            box: rect,
            lineSpacing: style.lineSpacing,
          ),
        );
        return out;
    }
  }

  List<CcMermaidPrimitive> _compartmentPrimitives(
    CcMermaidNode node,
    Rect rect,
  ) {
    final out = <CcMermaidPrimitive>[
      CcMermaidShapePrim(
        rect: rect,
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.node,
      ),
    ];
    final headerLines = [
      if (node.stereotype != null) '«${node.stereotype}»',
      ...node.displayLines,
    ];
    final headerSize = measureMermaidLines(
      headerLines,
      CcMermaidTextRole.label,
      ruler,
      lineSpacing: style.lineSpacing,
    );
    var y = rect.top + style.nodePadding.top;
    out.addAll(
      stackTextLines(
        headerLines,
        CcMermaidTextRole.label,
        ruler,
        box: Rect.fromLTWH(rect.left, y, rect.width, headerSize.height),
        lineSpacing: style.lineSpacing,
      ),
    );
    y += headerSize.height + style.nodePadding.bottom;

    for (final compartment in node.compartments) {
      out.add(
        CcMermaidPathPrim(
          points: [Offset(rect.left, y), Offset(rect.right, y)],
          role: CcMermaidPaintRole.divider,
        ),
      );
      y += style.nodePadding.top;
      for (final row in compartment) {
        final size = ruler.measure(row, CcMermaidTextRole.compartment);
        out.add(
          CcMermaidTextPrim(
            text: row,
            rect: Rect.fromLTWH(
              rect.left + style.nodePadding.left,
              y,
              rect.width - style.nodePadding.horizontal,
              size.height,
            ),
            role: CcMermaidTextRole.compartment,
            align: CcMermaidTextAlign.left,
          ),
        );
        y += size.height + style.lineSpacing;
      }
      y += style.nodePadding.bottom - style.lineSpacing;
    }
    return out;
  }

  /// Class/ER cardinality labels, tucked just inside each end of the line.
  List<CcMermaidPrimitive> _cardinalityPrimitives(
    CcMermaidEdge edge,
    List<Offset> points,
  ) {
    final out = <CcMermaidPrimitive>[];
    void place(String text, Offset anchor, Offset toward) {
      final size = ruler.measure(text, CcMermaidTextRole.edgeLabel);
      final direction = toward - anchor;
      final length = direction.distance;
      if (length == 0) {
        return;
      }
      final along = anchor + direction / length * (size.height + 8);
      // Nudge perpendicular so the text sits beside the line, not on it.
      final normal = Offset(-direction.dy, direction.dx) / length;
      final center = along + normal * (size.height / 2 + 2);
      out.add(
        CcMermaidTextPrim(
          text: text,
          rect: Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          role: CcMermaidTextRole.edgeLabel,
          muted: true,
        ),
      );
    }

    if (edge.startCardinality != null) {
      place(edge.startCardinality!, points.first, points[1]);
    }
    if (edge.endCardinality != null) {
      place(edge.endCardinality!, points.last, points[points.length - 2]);
    }
    return out;
  }

  /// An edge label on its backing plate.
  List<CcMermaidPrimitive> edgeLabelPrimitives(List<String> lines, Rect rect) {
    return [
      CcMermaidShapePrim(
        rect: rect,
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.edgeLabel,
        stroked: false,
      ),
      ...stackTextLines(
        lines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        box: rect,
        lineSpacing: style.lineSpacing,
      ),
    ];
  }

  /// A self-loop leaves the trailing edge of its node, bulges out, and comes
  /// back — the label rides outside the bulge.
  List<CcMermaidPrimitive> selfLoopPrimitives(
    CcMermaidEdge edge,
    Rect rect, {
    required bool horizontal,
  }) {
    const reach = _kSelfLoopReach;
    final points = horizontal
        ? <Offset>[
            Offset(rect.center.dx - rect.width / 4, rect.bottom),
            Offset(rect.center.dx - rect.width / 4, rect.bottom + reach),
            Offset(rect.center.dx + rect.width / 4, rect.bottom + reach),
            Offset(rect.center.dx + rect.width / 4, rect.bottom),
          ]
        : <Offset>[
            Offset(rect.right, rect.center.dy - rect.height / 4),
            Offset(rect.right + reach, rect.center.dy - rect.height / 4),
            Offset(rect.right + reach, rect.center.dy + rect.height / 4),
            Offset(rect.right, rect.center.dy + rect.height / 4),
          ];
    final out = <CcMermaidPrimitive>[
      CcMermaidPathPrim(
        points: points,
        stroke: edge.stroke == CcMermaidEdgeStroke.invisible
            ? CcMermaidEdgeStroke.solid
            : edge.stroke,
        startMarker: edge.startMarker,
        endMarker: edge.endMarker,
        cornerRadius: 6,
      ),
    ];
    if (edge.hasLabel) {
      final lines = wrapMermaidLines(
        edge.labelLines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        maxWidth: kMermaidMaxEdgeLabelWidth,
      );
      final size = measureMermaidLines(
        lines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      final labelRect = horizontal
          ? Rect.fromCenter(
              center: Offset(
                rect.center.dx,
                rect.bottom + reach + size.height / 2 + 4,
              ),
              width: size.width + 8,
              height: size.height + 4,
            )
          : Rect.fromCenter(
              center: Offset(
                rect.right + reach + size.width / 2 + 6,
                rect.center.dy,
              ),
              width: size.width + 8,
              height: size.height + 4,
            );
      out.addAll(edgeLabelPrimitives(lines, labelRect));
    }
    return out;
  }
}
