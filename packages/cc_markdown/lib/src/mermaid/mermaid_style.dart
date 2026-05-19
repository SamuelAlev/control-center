import 'package:flutter/widgets.dart';

/// The diagram stylesheet: colors, text styles and layout metrics for mermaid
/// rendering, with NO theme coupling (the host builds one from its design
/// tokens, exactly like [CcMarkdownStyle]).
///
/// Author-supplied mermaid theming (`%%{init: {'theme': …}}%%`, `style`,
/// `classDef`) is deliberately ignored by the engine: hardcoded hex from an LLM
/// or a PR body would fight the app's light/dark palette and its contrast
/// floor. Diagrams are themed HERE, once.
///
/// Full value equality is deliberate: the view memoizes laid-out scenes by
/// `(source, style, width)`, so a token-driven rebuild that produces an equal
/// style is a non-event.
@immutable
class CcMermaidStyle {
  /// Creates a [CcMermaidStyle].
  const CcMermaidStyle({
    this.label = const TextStyle(fontSize: 13, color: Color(0xFF1F2328)),
    this.title,
    this.clusterLabel,
    this.edgeLabel,
    this.compartment,
    this.note,
    this.legend,
    this.nodeFill = const Color(0xFFF6F8FA),
    this.nodeBorder = const Color(0xFFD0D7DE),
    this.accent = const Color(0xFF6E7781),
    this.clusterFill = const Color(0x0A000000),
    this.clusterBorder = const Color(0xFFD0D7DE),
    this.noteFill = const Color(0xFFFFF8C5),
    this.noteBorder = const Color(0xFFD4A72C),
    this.edgeColor = const Color(0xFF6E7781),
    this.edgeLabelFill = const Color(0xFFFFFFFF),
    this.activationFill = const Color(0x1F6E7781),
    this.frameFill = const Color(0x08000000),
    this.frameBorder = const Color(0xFFD0D7DE),
    this.dividerColor = const Color(0xFFD0D7DE),
    this.mutedTextColor = const Color(0xFF656D76),
    this.background,
    this.seriesPalette = kCcMermaidDefaultPalette,
    this.nodePadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.nodeSpacing = 26,
    this.rankSpacing = 44,
    this.clusterPadding = 18,
    this.canvasPadding = const EdgeInsets.all(10),
    this.edgeStrokeWidth = 1.4,
    this.thickStrokeWidth = 2.6,
    this.dashPattern = const [5, 4],
    this.arrowLength = 10,
    this.arrowWidth = 8,
    this.cornerRadius = 6,
    this.edgeCornerRadius = 8,
    this.lineSpacing = 2,
    this.maxScale = 1,
    this.minScale = 0.45,
  });

  /// Node and participant label style. Every other text style falls back to it.
  final TextStyle label;

  /// Diagram title style (defaults to [label], bolder and a bit larger).
  final TextStyle? title;

  /// Cluster / frame title style.
  final TextStyle? clusterLabel;

  /// Edge label and cardinality style.
  final TextStyle? edgeLabel;

  /// Class member / ER attribute row style (monospace reads best).
  final TextStyle? compartment;

  /// Note body style.
  final TextStyle? note;

  /// Legend, percentage and section label style.
  final TextStyle? legend;

  /// Node fill.
  final Color nodeFill;

  /// Node outline.
  final Color nodeBorder;

  /// Terminal dots, fork bars and other accented solids.
  final Color accent;

  /// Cluster (`subgraph`) fill.
  final Color clusterFill;

  /// Cluster outline.
  final Color clusterBorder;

  /// Note fill.
  final Color noteFill;

  /// Note outline.
  final Color noteBorder;

  /// Edge / lifeline color.
  final Color edgeColor;

  /// Fill painted behind an edge label so the line doesn't cross the text.
  final Color edgeLabelFill;

  /// Sequence activation bar fill.
  final Color activationFill;

  /// Sequence block frame fill.
  final Color frameFill;

  /// Sequence block frame outline.
  final Color frameBorder;

  /// Separator rules (class compartments, sequence dividers).
  final Color dividerColor;

  /// Secondary text color (percentages, cardinalities, muted rows).
  final Color mutedTextColor;

  /// Optional canvas background; null paints nothing (the host's surface shows
  /// through).
  final Color? background;

  /// Categorical palette for pie slices, legends and timeline sections.
  final List<Color> seriesPalette;

  /// Padding between a node's label and its outline.
  final EdgeInsets nodePadding;

  /// Minimum gap between siblings within a rank.
  final double nodeSpacing;

  /// Gap between ranks (the flow axis).
  final double rankSpacing;

  /// Padding between a cluster's outline and its members.
  final double clusterPadding;

  /// Padding around the whole diagram.
  final EdgeInsets canvasPadding;

  /// Edge stroke width.
  final double edgeStrokeWidth;

  /// Stroke width for `==>` thick edges.
  final double thickStrokeWidth;

  /// Dash on/off lengths for dotted edges.
  final List<double> dashPattern;

  /// Arrowhead length along the line.
  final double arrowLength;

  /// Arrowhead width across the line.
  final double arrowWidth;

  /// Node corner rounding.
  final double cornerRadius;

  /// Rounding applied at an edge's interior bends.
  final double edgeCornerRadius;

  /// Extra leading between a label's lines.
  final double lineSpacing;

  /// Largest scale the view will render at (1 = never upscale, which keeps
  /// small diagrams from looking blown up).
  final double maxScale;

  /// Smallest scale before the view stops shrinking and scrolls instead.
  final double minScale;

  /// Resolved title style.
  TextStyle get resolvedTitle =>
      title ??
      label.copyWith(
        fontSize: (label.fontSize ?? 13) + 2,
        fontWeight: FontWeight.w600,
      );

  /// Resolved cluster-title style.
  TextStyle get resolvedClusterLabel =>
      clusterLabel ??
      label.copyWith(
        fontSize: (label.fontSize ?? 13) - 1,
        fontWeight: FontWeight.w600,
        color: mutedTextColor,
      );

  /// Resolved edge-label style.
  TextStyle get resolvedEdgeLabel =>
      edgeLabel ?? label.copyWith(fontSize: (label.fontSize ?? 13) - 1.5);

  /// Resolved compartment-row style.
  TextStyle get resolvedCompartment =>
      compartment ?? label.copyWith(fontSize: (label.fontSize ?? 13) - 1.5);

  /// Resolved note style.
  TextStyle get resolvedNote =>
      note ?? label.copyWith(fontSize: (label.fontSize ?? 13) - 1);

  /// Resolved legend style.
  TextStyle get resolvedLegend =>
      legend ?? label.copyWith(fontSize: (label.fontSize ?? 13) - 1.5);

  /// The palette color for [index], wrapping around.
  Color seriesColor(int index) {
    if (seriesPalette.isEmpty) {
      return accent;
    }
    return seriesPalette[index % seriesPalette.length];
  }

  /// A copy with the given fields replaced.
  CcMermaidStyle copyWith({
    TextStyle? label,
    TextStyle? title,
    TextStyle? clusterLabel,
    TextStyle? edgeLabel,
    TextStyle? compartment,
    TextStyle? note,
    TextStyle? legend,
    Color? nodeFill,
    Color? nodeBorder,
    Color? accent,
    Color? clusterFill,
    Color? clusterBorder,
    Color? noteFill,
    Color? noteBorder,
    Color? edgeColor,
    Color? edgeLabelFill,
    Color? activationFill,
    Color? frameFill,
    Color? frameBorder,
    Color? dividerColor,
    Color? mutedTextColor,
    Color? background,
    List<Color>? seriesPalette,
    EdgeInsets? nodePadding,
    double? nodeSpacing,
    double? rankSpacing,
    double? clusterPadding,
    EdgeInsets? canvasPadding,
    double? edgeStrokeWidth,
    double? thickStrokeWidth,
    List<double>? dashPattern,
    double? arrowLength,
    double? arrowWidth,
    double? cornerRadius,
    double? edgeCornerRadius,
    double? lineSpacing,
    double? maxScale,
    double? minScale,
  }) {
    return CcMermaidStyle(
      label: label ?? this.label,
      title: title ?? this.title,
      clusterLabel: clusterLabel ?? this.clusterLabel,
      edgeLabel: edgeLabel ?? this.edgeLabel,
      compartment: compartment ?? this.compartment,
      note: note ?? this.note,
      legend: legend ?? this.legend,
      nodeFill: nodeFill ?? this.nodeFill,
      nodeBorder: nodeBorder ?? this.nodeBorder,
      accent: accent ?? this.accent,
      clusterFill: clusterFill ?? this.clusterFill,
      clusterBorder: clusterBorder ?? this.clusterBorder,
      noteFill: noteFill ?? this.noteFill,
      noteBorder: noteBorder ?? this.noteBorder,
      edgeColor: edgeColor ?? this.edgeColor,
      edgeLabelFill: edgeLabelFill ?? this.edgeLabelFill,
      activationFill: activationFill ?? this.activationFill,
      frameFill: frameFill ?? this.frameFill,
      frameBorder: frameBorder ?? this.frameBorder,
      dividerColor: dividerColor ?? this.dividerColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      background: background ?? this.background,
      seriesPalette: seriesPalette ?? this.seriesPalette,
      nodePadding: nodePadding ?? this.nodePadding,
      nodeSpacing: nodeSpacing ?? this.nodeSpacing,
      rankSpacing: rankSpacing ?? this.rankSpacing,
      clusterPadding: clusterPadding ?? this.clusterPadding,
      canvasPadding: canvasPadding ?? this.canvasPadding,
      edgeStrokeWidth: edgeStrokeWidth ?? this.edgeStrokeWidth,
      thickStrokeWidth: thickStrokeWidth ?? this.thickStrokeWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      arrowLength: arrowLength ?? this.arrowLength,
      arrowWidth: arrowWidth ?? this.arrowWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      edgeCornerRadius: edgeCornerRadius ?? this.edgeCornerRadius,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CcMermaidStyle &&
        label == other.label &&
        title == other.title &&
        clusterLabel == other.clusterLabel &&
        edgeLabel == other.edgeLabel &&
        compartment == other.compartment &&
        note == other.note &&
        legend == other.legend &&
        nodeFill == other.nodeFill &&
        nodeBorder == other.nodeBorder &&
        accent == other.accent &&
        clusterFill == other.clusterFill &&
        clusterBorder == other.clusterBorder &&
        noteFill == other.noteFill &&
        noteBorder == other.noteBorder &&
        edgeColor == other.edgeColor &&
        edgeLabelFill == other.edgeLabelFill &&
        activationFill == other.activationFill &&
        frameFill == other.frameFill &&
        frameBorder == other.frameBorder &&
        dividerColor == other.dividerColor &&
        mutedTextColor == other.mutedTextColor &&
        background == other.background &&
        _listEquals(seriesPalette, other.seriesPalette) &&
        nodePadding == other.nodePadding &&
        nodeSpacing == other.nodeSpacing &&
        rankSpacing == other.rankSpacing &&
        clusterPadding == other.clusterPadding &&
        canvasPadding == other.canvasPadding &&
        edgeStrokeWidth == other.edgeStrokeWidth &&
        thickStrokeWidth == other.thickStrokeWidth &&
        _listEquals(dashPattern, other.dashPattern) &&
        arrowLength == other.arrowLength &&
        arrowWidth == other.arrowWidth &&
        cornerRadius == other.cornerRadius &&
        edgeCornerRadius == other.edgeCornerRadius &&
        lineSpacing == other.lineSpacing &&
        maxScale == other.maxScale &&
        minScale == other.minScale;
  }

  @override
  int get hashCode => Object.hashAll([
    label,
    title,
    clusterLabel,
    edgeLabel,
    compartment,
    note,
    legend,
    nodeFill,
    nodeBorder,
    accent,
    clusterFill,
    clusterBorder,
    noteFill,
    noteBorder,
    edgeColor,
    edgeLabelFill,
    activationFill,
    frameFill,
    frameBorder,
    dividerColor,
    mutedTextColor,
    background,
    Object.hashAll(seriesPalette),
    nodePadding,
    nodeSpacing,
    rankSpacing,
    clusterPadding,
    canvasPadding,
    edgeStrokeWidth,
    thickStrokeWidth,
    Object.hashAll(dashPattern),
    arrowLength,
    arrowWidth,
    cornerRadius,
    edgeCornerRadius,
    lineSpacing,
    maxScale,
    minScale,
  ]);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// The engine's default categorical palette: six hues that stay distinguishable
/// in both light and dark surfaces and never rely on hue alone (pie slices and
/// legend rows are always labeled).
const List<Color> kCcMermaidDefaultPalette = [
  Color(0xFF4E79A7),
  Color(0xFFF28E2B),
  Color(0xFF59A14F),
  Color(0xFFE15759),
  Color(0xFF9C6ADE),
  Color(0xFF76B7B2),
];
