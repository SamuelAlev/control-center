/// The pie-chart layout: a circle of weighted slices plus a labeled legend.
///
/// Status is never carried by color alone — every slice is named in the legend
/// with its share and slices big enough to hold text get their percentage
/// printed inside — so the chart survives a monochrome print or color-blind
/// viewing.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Diameter of the pie.
const double _kDiameter = 190;

/// Gap between the circle and the legend column.
const double _kLegendGap = 26;

/// Legend swatch edge length.
const double _kSwatchSize = 11;

/// Smallest share that gets its percentage printed inside the slice.
const double _kInlineLabelThreshold = 0.06;

/// Lays [pie] out into a paint-ready scene.
CcMermaidScene layoutMermaidPie(
  CcMermaidPie pie, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  final total = pie.total;
  if (pie.slices.isEmpty || total <= 0) {
    return CcMermaidScene.empty;
  }

  final primitives = <CcMermaidPrimitive>[];
  const circle = Rect.fromLTWH(0, 0, _kDiameter, _kDiameter);

  // Mermaid starts at 12 o'clock and sweeps clockwise.
  var angle = -math.pi / 2;
  for (var i = 0; i < pie.slices.length; i++) {
    final share = pie.slices[i].value / total;
    final sweep = share * math.pi * 2;
    primitives.add(
      CcMermaidArcPrim(
        rect: circle,
        startAngle: angle,
        sweepAngle: sweep,
        seriesIndex: i,
      ),
    );
    if (share >= _kInlineLabelThreshold) {
      final text = '${(share * 100).toStringAsFixed(share >= 0.1 ? 0 : 1)}%';
      final size = ruler.measure(text, CcMermaidTextRole.legend);
      final middle = angle + sweep / 2;
      const radius = _kDiameter * 0.29;
      final center =
          circle.center +
          Offset(math.cos(middle) * radius, math.sin(middle) * radius);
      primitives.add(
        CcMermaidTextPrim(
          text: text,
          rect: Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          role: CcMermaidTextRole.legend,
          seriesIndex: i,
        ),
      );
    }
    angle += sweep;
  }

  // Legend column, one row per slice.
  var y = 0.0;
  final rowHeight = math.max(
    ruler.lineHeight(CcMermaidTextRole.legend) + 6,
    _kSwatchSize + 6,
  );
  final legendLeft = circle.right + _kLegendGap;
  for (var i = 0; i < pie.slices.length; i++) {
    final slice = pie.slices[i];
    final share = slice.value / total;
    final label = pie.showData
        ? '${slice.label} — ${_formatValue(slice.value)}'
        : '${slice.label} — ${(share * 100).toStringAsFixed(share >= 0.1 ? 0 : 1)}%';
    final size = ruler.measure(label, CcMermaidTextRole.legend);
    primitives.add(
      CcMermaidShapePrim(
        rect: Rect.fromLTWH(
          legendLeft,
          y + (rowHeight - _kSwatchSize) / 2,
          _kSwatchSize,
          _kSwatchSize,
        ),
        shape: CcMermaidNodeShape.roundRect,
        role: CcMermaidPaintRole.series,
        seriesIndex: i,
        stroked: false,
      ),
    );
    primitives.add(
      CcMermaidTextPrim(
        text: label,
        rect: Rect.fromLTWH(
          legendLeft + _kSwatchSize + 8,
          y,
          size.width,
          rowHeight,
        ),
        role: CcMermaidTextRole.legend,
        align: CcMermaidTextAlign.left,
      ),
    );
    y += rowHeight;
  }

  return finalizeScene(
    prependSceneTitle(primitives, pie.title, ruler),
    padding: style.canvasPadding,
  );
}

/// Formats a slice value without a trailing `.0` on whole numbers.
String _formatValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
