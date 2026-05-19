/// The TextPainter-backed text ruler: ONE place where diagram text is measured
/// and painted.
///
/// Layout asks it for sizes, the painter asks it for glyphs — both go through
/// the same cache, so a label can never be measured with one style and drawn
/// with another (the classic source of text spilling out of a box).
library;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:flutter/widgets.dart';

/// Measures and paints mermaid text through a cache of laid-out [TextPainter]s.
class CcMermaidTextPainterRuler extends CcMermaidTextRuler {
  /// Creates a [CcMermaidTextPainterRuler].
  CcMermaidTextPainterRuler({
    required this.style,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.ltr,
  });

  /// The active stylesheet.
  final CcMermaidStyle style;

  /// The host's text scaler, so diagram text honors accessibility text sizing.
  final TextScaler textScaler;

  /// Paragraph direction.
  final TextDirection textDirection;

  final Map<String, TextPainter> _cache = {};

  /// The text style for [role].
  TextStyle styleFor(CcMermaidTextRole role) => switch (role) {
    CcMermaidTextRole.label => style.label,
    CcMermaidTextRole.title => style.resolvedTitle,
    CcMermaidTextRole.cluster => style.resolvedClusterLabel,
    CcMermaidTextRole.edgeLabel => style.resolvedEdgeLabel,
    CcMermaidTextRole.compartment => style.resolvedCompartment,
    CcMermaidTextRole.note => style.resolvedNote,
    CcMermaidTextRole.legend => style.resolvedLegend,
  };

  TextPainter _painter(String text, CcMermaidTextRole role, {Color? color}) {
    final key = '${role.index}|${color?.toARGB32() ?? 0}|$text';
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final base = styleFor(role);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: color == null ? base : base.copyWith(color: color),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    // Bound the cache: a streaming surface can churn through many labels, and a
    // ruler outlives a single frame.
    if (_cache.length > 256) {
      _cache.clear();
    }
    _cache[key] = painter;
    return painter;
  }

  @override
  Size measure(String text, CcMermaidTextRole role) =>
      _painter(text, role).size;

  @override
  double lineHeight(CcMermaidTextRole role) => _painter('Ag', role).size.height;

  /// Paints [text] inside [rect], vertically centered and horizontally aligned
  /// per [align].
  void paint(
    Canvas canvas,
    String text,
    CcMermaidTextRole role,
    Rect rect, {
    required Color color,
    CcMermaidTextAlign align = CcMermaidTextAlign.center,
  }) {
    final painter = _painter(text, role, color: color);
    final dx = switch (align) {
      CcMermaidTextAlign.left => rect.left,
      CcMermaidTextAlign.right => rect.right - painter.width,
      CcMermaidTextAlign.center => rect.center.dx - painter.width / 2,
    };
    painter.paint(canvas, Offset(dx, rect.center.dy - painter.height / 2));
  }
}
