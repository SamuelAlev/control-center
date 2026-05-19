/// The timeline layout: a horizontal axis of periods, each with a stack of
/// event cards below it, grouped by `section`.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Widest an event card grows before its text wraps.
const double _kMaxCardWidth = 150;

/// Gap between adjacent periods.
const double _kColumnGap = 18;

/// Gap between stacked event cards.
const double _kCardGap = 8;

/// Lays [timeline] out into a paint-ready scene.
CcMermaidScene layoutMermaidTimeline(
  CcMermaidTimeline timeline, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  if (timeline.entries.isEmpty) {
    return CcMermaidScene.empty;
  }

  final primitives = <CcMermaidPrimitive>[];
  final sectionBands = <CcMermaidPrimitive>[];

  // Measure every column first: width is driven by the widest card.
  final columns = <({double width, List<List<String>> cards, String period})>[];
  for (final entry in timeline.entries) {
    var width =
        ruler.measure(entry.period, CcMermaidTextRole.label).width +
        style.nodePadding.horizontal;
    final cards = <List<String>>[];
    for (final event in entry.events) {
      final lines = wrapMermaidLines(
        [event],
        CcMermaidTextRole.note,
        ruler,
        maxWidth: _kMaxCardWidth,
      );
      cards.add(lines);
      final size = measureMermaidLines(
        lines,
        CcMermaidTextRole.note,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      width = math.max(width, size.width + style.nodePadding.horizontal);
    }
    columns.add((width: width, cards: cards, period: entry.period));
  }

  final periodHeight =
      ruler.lineHeight(CcMermaidTextRole.label) + style.nodePadding.vertical;
  final sectionHeight = timeline.entries.any((entry) => entry.section != null)
      ? ruler.lineHeight(CcMermaidTextRole.cluster) + 10
      : 0.0;
  final axisY = sectionHeight + periodHeight + 14;

  var x = 0.0;
  String? currentSection;
  var sectionStart = 0.0;
  var sectionIndex = -1;

  void closeSection(double end) {
    if (currentSection == null) {
      return;
    }
    final section = currentSection;
    final size = ruler.measure(section, CcMermaidTextRole.cluster);
    final band = Rect.fromLTWH(
      sectionStart,
      0,
      math.max(end - sectionStart, size.width + 16),
      sectionHeight - 4,
    );
    sectionBands.add(
      CcMermaidShapePrim(
        rect: band,
        shape: CcMermaidNodeShape.roundRect,
        role: CcMermaidPaintRole.series,
        seriesIndex: sectionIndex,
        stroked: false,
      ),
    );
    sectionBands.add(
      CcMermaidTextPrim(
        text: section,
        rect: band,
        role: CcMermaidTextRole.cluster,
      ),
    );
  }

  for (var i = 0; i < columns.length; i++) {
    final column = columns[i];
    final entry = timeline.entries[i];
    if (entry.section != currentSection) {
      closeSection(x - _kColumnGap / 2);
      currentSection = entry.section;
      sectionStart = x;
      sectionIndex++;
    }

    final center = x + column.width / 2;

    // Period chip above the axis.
    final chip = Rect.fromLTWH(
      x,
      axisY - periodHeight - 10,
      column.width,
      periodHeight,
    );
    primitives.add(
      CcMermaidShapePrim(
        rect: chip,
        shape: CcMermaidNodeShape.stadium,
        role: CcMermaidPaintRole.node,
      ),
    );
    primitives.add(
      CcMermaidTextPrim(
        text: column.period,
        rect: chip,
        role: CcMermaidTextRole.label,
      ),
    );

    // Axis tick.
    primitives.add(
      CcMermaidPathPrim(
        points: [Offset(center, chip.bottom), Offset(center, axisY)],
        role: CcMermaidPaintRole.edge,
      ),
    );

    // Event cards below the axis.
    var cardY = axisY + 16;
    for (final lines in column.cards) {
      final size = measureMermaidLines(
        lines,
        CcMermaidTextRole.note,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      final card = Rect.fromLTWH(
        x,
        cardY,
        column.width,
        size.height + style.nodePadding.vertical,
      );
      primitives.add(
        CcMermaidShapePrim(
          rect: card,
          shape: CcMermaidNodeShape.roundRect,
          role: CcMermaidPaintRole.node,
        ),
      );
      primitives.addAll(
        stackTextLines(
          lines,
          CcMermaidTextRole.note,
          ruler,
          box: card,
          lineSpacing: style.lineSpacing,
        ),
      );
      cardY = card.bottom + _kCardGap;
    }

    x += column.width + _kColumnGap;
  }
  closeSection(x - _kColumnGap);

  // The axis line runs the full width, behind the ticks and cards.
  final axis = CcMermaidPathPrim(
    points: [Offset(0, axisY), Offset(math.max(x - _kColumnGap, 40), axisY)],
    role: CcMermaidPaintRole.divider,
  );

  return finalizeScene(
    prependSceneTitle(
      [...sectionBands, axis, ...primitives],
      timeline.title,
      ruler,
    ),
    padding: style.canvasPadding,
  );
}
