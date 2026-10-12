/// [CcMermaidView]: the widget that turns mermaid source into a drawn diagram.
///
/// It owns three things and nothing else:
///
///  * **memoization** — parse + layout are cached by `(source, style, text
///    scale)`, so scroll recycling, theme rebuilds and streaming re-renders
///    cost a map lookup rather than a re-layout;
///  * **fit** — the diagram scales DOWN to the available width (never up, so a
///    small diagram isn't blown up) and starts scrolling horizontally once it
///    would shrink past legibility ([CcMermaidStyle.minScale]);
///  * **failure** — an unsupported dialect or unparseable body renders the
///    caller's fallback (normally the code block), never an exception or an
///    empty hole.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/graph_layout.dart';
import 'package:cc_markdown/src/mermaid/layout/pie_layout.dart';
import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/sequence_layout.dart';
import 'package:cc_markdown/src/mermaid/layout/timeline_layout.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/mermaid_parser.dart';
import 'package:cc_markdown/src/mermaid/render/mermaid_painter.dart';
import 'package:cc_markdown/src/mermaid/render/mermaid_viewport.dart';
import 'package:cc_markdown/src/mermaid/render/text_ruler.dart';
import 'package:flutter/widgets.dart';

/// Builds the replacement widget when a diagram cannot be drawn. [reason] is a
/// short user-facing message such as `unsupported diagram type: gantt`.
typedef CcMermaidFallbackBuilder =
    Widget Function(String source, String reason);

/// Renders a mermaid diagram from its source.
class CcMermaidView extends StatelessWidget {
  /// Creates a [CcMermaidView].
  const CcMermaidView({
    required this.source,
    super.key,
    this.style = const CcMermaidStyle(),
    this.fallbackBuilder,
    this.onTapNode,
    this.interactive = false,
    this.controller,
    this.semanticsEnabled = true,
  });

  /// The mermaid source (the body of a ```` ```mermaid ```` fence).
  final String source;

  /// Colors, text styles and layout metrics.
  final CcMermaidStyle style;

  /// Replacement widget for an undrawable diagram; null renders the source as
  /// plain preformatted text with a muted reason line.
  final CcMermaidFallbackBuilder? fallbackBuilder;

  /// Invoked when a node with a flowchart `click` binding is tapped.
  final void Function(String nodeId, String? href)? onTapNode;

  /// Whether to allow pinch/drag pan-zoom. Off by default: inside a scrolling
  /// feed a zoomable child competes with the scroll gesture.
  final bool interactive;

  /// Optional pan/zoom and fit controller; used only in interactive mode.
  final CcMermaidViewportController? controller;

  /// Whether to expose a generated text alternative to screen readers.
  final bool semanticsEnabled;

  @override
  Widget build(BuildContext context) {
    final laidOut = _resolveScene(
      source: source,
      style: style,
      textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
    );

    if (laidOut.reason != null) {
      return fallbackBuilder?.call(source, laidOut.reason!) ??
          _DefaultMermaidFallback(
            source: source,
            reason: laidOut.reason!,
            style: style,
          );
    }

    final scene = laidOut.scene!;
    final diagram = laidOut.diagram!;
    Widget content;
    if (interactive) {
      content = CcMermaidViewport(
        scene: scene,
        controller: controller,
        child: _MermaidCanvas(
          scene: scene,
          style: style,
          ruler: laidOut.ruler!,
          scale: 1,
          size: scene.size,
          onTapNode: onTapNode,
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : scene.size.width;
          final raw = scene.size.width <= 0
              ? 1.0
              : available / scene.size.width;
          final scale = raw.clamp(style.minScale, style.maxScale).toDouble();
          final scaled = Size(
            scene.size.width * scale,
            scene.size.height * scale,
          );
          final canvas = _MermaidCanvas(
            scene: scene,
            style: style,
            ruler: laidOut.ruler!,
            scale: scale,
            size: scaled,
            onTapNode: onTapNode,
          );
          // Inline diagrams scroll below their legibility floor; an expanded
          // viewport instead owns the entire unscaled scene and its gestures.
          if (scaled.width > available + 0.5) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: canvas,
            );
          }
          return canvas;
        },
      );
    }

    if (!semanticsEnabled) {
      return content;
    }
    return Semantics(
      label: mermaidSemanticLabel(diagram),
      container: true,
      child: ExcludeSemantics(child: content),
    );
  }
}

/// The painted canvas plus its tap handling.
class _MermaidCanvas extends StatelessWidget {
  const _MermaidCanvas({
    required this.scene,
    required this.style,
    required this.ruler,
    required this.scale,
    required this.size,
    required this.onTapNode,
  });

  final CcMermaidScene scene;
  final CcMermaidStyle style;
  final CcMermaidTextPainterRuler ruler;
  final double scale;
  final Size size;
  final void Function(String nodeId, String? href)? onTapNode;

  @override
  Widget build(BuildContext context) {
    Widget canvas = CustomPaint(
      size: size,
      painter: CcMermaidScenePainter(
        scene: scene,
        style: style,
        ruler: ruler,
        scale: scale,
      ),
      isComplex: scene.primitives.length > 40,
      willChange: false,
    );
    canvas = SizedBox(width: size.width, height: size.height, child: canvas);

    final handler = onTapNode;
    if (handler == null || scene.hitTargets.isEmpty) {
      return RepaintBoundary(child: canvas);
    }
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          final local = details.localPosition / scale;
          for (final target in scene.hitTargets) {
            if (target.rect.contains(local)) {
              handler(target.nodeId, target.href);
              return;
            }
          }
        },
        child: canvas,
      ),
    );
  }
}

/// The built-in fallback: the source as preformatted text under a muted reason.
class _DefaultMermaidFallback extends StatelessWidget {
  const _DefaultMermaidFallback({
    required this.source,
    required this.reason,
    required this.style,
  });

  final String source;
  final String reason;
  final CcMermaidStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.nodeFill,
        borderRadius: BorderRadius.circular(style.cornerRadius),
        border: Border.all(color: style.nodeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reason,
            style: style.resolvedLegend.copyWith(color: style.mutedTextColor),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(source, style: style.resolvedCompartment),
          ),
        ],
      ),
    );
  }
}

/// A parsed + laid-out diagram, or the reason there isn't one.
class CcMermaidRenderPlan {
  /// Creates a [CcMermaidRenderPlan].
  const CcMermaidRenderPlan({
    this.diagram,
    this.scene,
    this.ruler,
    this.reason,
  });

  /// The parsed diagram, when parsing succeeded.
  final CcMermaidDiagram? diagram;

  /// The laid-out scene, when there is something to draw.
  final CcMermaidScene? scene;

  /// The ruler the scene was measured with (the painter must reuse it).
  final CcMermaidTextPainterRuler? ruler;

  /// Why nothing can be drawn, or null on success.
  final String? reason;
}

/// Parses and lays out [source], memoized by `(source, style, text scale)`.
///
/// A style change that cannot move a primitive — colors, decorations, the
/// view's fit scale — reuses the memoized GEOMETRY and only rebuilds the
/// ruler, so a light/dark flip or a live highlight repaints instead of
/// repeating layout. Anything that changes what text measures or how much room
/// a shape needs (fonts, leading, spacing, corner rounding, text scale) is a
/// different geometry and does lay out again.
///
/// Exposed so hosts can pre-warm a diagram (or ask whether a fence is drawable)
/// without mounting a widget.
CcMermaidRenderPlan resolveMermaidRenderPlan({
  required String source,
  required CcMermaidStyle style,
  TextScaler textScaler = TextScaler.noScaling,
}) => _resolveScene(source: source, style: style, textScaler: textScaler);

/// Drops every memoized scene and render plan (tests; a host that swaps fonts
/// wholesale).
void clearMermaidSceneCache() {
  _sceneCache.clear();
  _planCache.clear();
}

CcMermaidRenderPlan _resolveScene({
  required String source,
  required CcMermaidStyle style,
  required TextScaler textScaler,
}) {
  final key = _PlanKey(source: source, style: style, textScaler: textScaler);
  final memoized = _planCache.get(key);
  if (memoized != null) {
    return memoized;
  }

  final plan = _buildPlan(source: source, style: style, textScaler: textScaler);
  _planCache.put(key, plan);
  return plan;
}

/// Parses and lays out [source] — unless an identical GEOMETRY is already
/// memoized, in which case the layout stands and only the ruler is rebuilt.
///
/// The rebuilt ruler is built from the CURRENT [style]: it is the one place
/// glyphs are measured and painted, so restoring the old ruler here is exactly
/// how reused geometry ends up drawing last theme's text colors.
CcMermaidRenderPlan _buildPlan({
  required String source,
  required CcMermaidStyle style,
  required TextScaler textScaler,
}) {
  final geometryKey = _SceneKey(
    source: source,
    style: style,
    textScaler: textScaler,
  );
  final geometry = _sceneCache.get(geometryKey);
  if (geometry != null) {
    return CcMermaidRenderPlan(
      diagram: geometry.diagram,
      scene: geometry.scene,
      ruler: CcMermaidTextPainterRuler(style: style, textScaler: textScaler),
    );
  }

  final parsed = parseMermaid(source);
  switch (parsed) {
    case CcMermaidUnsupported(:final message):
      return CcMermaidRenderPlan(reason: message);
    case CcMermaidParsed(:final diagram):
      final ruler = CcMermaidTextPainterRuler(
        style: style,
        textScaler: textScaler,
      );
      final scene = _layout(diagram, style: style, ruler: ruler);
      if (!isMermaidSceneDrawable(scene)) {
        // Nothing worth reusing: an empty or runaway scene is never memoized.
        return CcMermaidRenderPlan(
          diagram: diagram,
          reason: scene.isEmpty
              ? 'diagram is empty'
              : 'diagram is too large to draw',
        );
      }
      _sceneCache.put(
        geometryKey,
        _SceneGeometry(diagram: diagram, scene: scene),
      );
      return CcMermaidRenderPlan(diagram: diagram, scene: scene, ruler: ruler);
  }
}

CcMermaidScene _layout(
  CcMermaidDiagram diagram, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  return switch (diagram) {
    final CcMermaidGraph graph => layoutMermaidGraph(
      graph,
      style: style,
      ruler: ruler,
    ),
    final CcMermaidSequence sequence => layoutMermaidSequence(
      sequence,
      style: style,
      ruler: ruler,
    ),
    final CcMermaidPie pie => layoutMermaidPie(pie, style: style, ruler: ruler),
    final CcMermaidTimeline timeline => layoutMermaidTimeline(
      timeline,
      style: style,
      ruler: ruler,
    ),
  };
}

/// A text alternative for screen readers: what the diagram IS, plus its
/// entities in reading order. A drawn diagram is otherwise invisible to
/// assistive tech and the source is not a usable substitute.
String mermaidSemanticLabel(CcMermaidDiagram diagram) {
  final buffer = StringBuffer();
  final title = diagram.title;
  if (title != null && title.trim().isNotEmpty) {
    buffer.write('$title. ');
  }
  switch (diagram) {
    case final CcMermaidGraph graph:
      final drawable = graph.nodes
          .where(
            (node) =>
                node.shape != CcMermaidNodeShape.startPoint &&
                node.shape != CcMermaidNodeShape.endPoint,
          )
          .toList();
      buffer.write(
        '${graph.kindLabel}, ${drawable.length} nodes, ${graph.edges.length} '
        'connections. ',
      );
      final names = drawable
          .take(12)
          .map((node) => node.displayLines.join(' '));
      buffer.write('Nodes: ${names.join(', ')}.');
      final labeled = graph.edges
          .where((edge) => edge.label.isNotEmpty)
          .take(8);
      if (labeled.isNotEmpty) {
        buffer.write(
          ' Connections: ${labeled.map((edge) => '${_nodeName(graph, edge.fromId)} '
              'to ${_nodeName(graph, edge.toId)} labeled ${edge.label}').join('; ')}.',
        );
      }
    case final CcMermaidSequence sequence:
      buffer.write(
        'sequence diagram between '
        '${sequence.participants.map((p) => p.displayLines.join(' ')).join(', ')}. ',
      );
      final messages = _flattenMessages(sequence.steps).take(12);
      if (messages.isNotEmpty) {
        buffer.write(
          'Messages: ${messages.map((m) => '${m.fromId} to ${m.toId}'
              '${m.lines.isEmpty ? '' : ': ${m.lines.join(' ')}'}').join('; ')}.',
        );
      }
    case final CcMermaidPie pie:
      final total = pie.total;
      buffer.write('pie chart. ');
      buffer.write(
        pie.slices
            .map(
              (slice) =>
                  '${slice.label} '
                  '${(slice.value / total * 100).toStringAsFixed(0)}%',
            )
            .join(', '),
      );
    case final CcMermaidTimeline timeline:
      buffer.write('timeline. ');
      buffer.write(
        timeline.entries
            .take(12)
            .map(
              (entry) =>
                  '${entry.period}'
                  '${entry.events.isEmpty ? '' : ': ${entry.events.join(', ')}'}',
            )
            .join('; '),
      );
  }
  return buffer.toString().trim();
}

String _nodeName(CcMermaidGraph graph, String id) =>
    graph.nodeById(id)?.displayLines.join(' ') ?? id;

List<CcMermaidMessage> _flattenMessages(List<CcMermaidSequenceStep> steps) {
  final out = <CcMermaidMessage>[];
  for (final step in steps) {
    switch (step) {
      case final CcMermaidMessage message:
        out.add(message);
      case final CcMermaidBlock block:
        for (final section in block.sections) {
          out.addAll(_flattenMessages(section.steps));
        }
      default:
        continue;
    }
  }
  return out;
}

/// Full render identity: the memo key for a whole [CcMermaidRenderPlan].
///
/// A plan is rebuilt when the source, the WHOLE stylesheet or the text scale
/// changes — including paint-only changes, which get a fresh plan (and so a
/// fresh paint-side ruler) over the reused geometry.
class _PlanKey {
  const _PlanKey({
    required this.source,
    required this.style,
    required this.textScaler,
  });

  final String source;
  final CcMermaidStyle style;
  final TextScaler textScaler;

  @override
  bool operator ==(Object other) =>
      other is _PlanKey &&
      source == other.source &&
      style == other.style &&
      textScaler == other.textScaler;

  @override
  int get hashCode => Object.hash(source, style, textScaler);
}

/// GEOMETRY identity of a laid-out scene: the source, the text scale, every
/// text style's METRICS and the spacing/rounding values layout reads.
///
/// The full stylesheet is retained, but only its geometry participates. Two
/// styles that differ in color, decoration or the view's fit scale compare
/// equal here — so a recolor reuses the scene — while a font, leading, spacing
/// or radius change is a different geometry and lays out again. Reused geometry
/// is still painted through a ruler built from the CURRENT styles, never the
/// one it was measured with.
class _SceneKey {
  const _SceneKey({
    required this.source,
    required this.style,
    required this.textScaler,
  });

  final String source;
  final CcMermaidStyle style;
  final TextScaler textScaler;

  @override
  bool operator ==(Object other) =>
      other is _SceneKey &&
      source == other.source &&
      textScaler == other.textScaler &&
      _sameTextMetrics(style.label, other.style.label) &&
      _sameTextMetrics(style.title, other.style.title) &&
      _sameTextMetrics(style.clusterLabel, other.style.clusterLabel) &&
      _sameTextMetrics(style.edgeLabel, other.style.edgeLabel) &&
      _sameTextMetrics(style.compartment, other.style.compartment) &&
      _sameTextMetrics(style.note, other.style.note) &&
      _sameTextMetrics(style.legend, other.style.legend) &&
      style.nodePadding == other.style.nodePadding &&
      style.nodeSpacing == other.style.nodeSpacing &&
      style.rankSpacing == other.style.rankSpacing &&
      style.clusterPadding == other.style.clusterPadding &&
      style.canvasPadding == other.style.canvasPadding &&
      style.cornerRadius == other.style.cornerRadius &&
      style.edgeCornerRadius == other.style.edgeCornerRadius &&
      style.lineSpacing == other.style.lineSpacing;

  // Carries neither the text styles nor the colors: [==] calls two text styles
  // equal whenever their METRICS match, so folding their paint into the hash
  // would break the "equal objects hash equally" contract. The memos hold 16
  // entries, so a bucket mixing a handful of paint variants costs a couple of
  // extra comparisons and nothing else.
  @override
  int get hashCode => Object.hash(
    source,
    textScaler,
    style.nodePadding,
    style.nodeSpacing,
    style.rankSpacing,
    style.clusterPadding,
    style.canvasPadding,
    style.cornerRadius,
    style.edgeCornerRadius,
    style.lineSpacing,
  );
}

/// Whether two text styles measure identically — Flutter's own answer.
///
/// [TextStyle.compareTo] reports [RenderComparison.layout] exactly when a
/// difference can move glyphs or change a line box, so the memo follows the
/// framework's notion of "same metrics" instead of keeping a parallel field
/// list that could drift from it. A paint-only difference reports
/// [RenderComparison.paint] (or `identical`) and reuses the geometry. Flutter
/// groups `foreground`, `background`, `shadows` and `overflow` with the
/// layout-affecting fields; those therefore re-lay out too, which is a
/// conservative miss rather than a wrong reuse.
///
/// A null optional style only matches another null one: an implicit style is
/// never assumed equal to an explicitly resolved one, because that equality
/// would have to be maintained by hand.
bool _sameTextMetrics(TextStyle? a, TextStyle? b) {
  if (a == null || b == null) {
    return a == b;
  }
  return a.compareTo(b) != RenderComparison.layout;
}

/// A laid-out diagram, reusable across paint-only style changes.
class _SceneGeometry {
  const _SceneGeometry({required this.diagram, required this.scene});

  final CcMermaidDiagram diagram;
  final CcMermaidScene scene;
}

/// Small insertion-ordered LRU of non-null values.
class _LruCache<K, V> {
  _LruCache(this.capacity);

  final int capacity;
  final Map<K, V> _entries = {};

  V? get(K key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

// Sized for "the diagrams on screen plus a scrollback", not for a whole
// session: a scene holds its primitives and a plan holds its ruler's laid-out
// TextPainters, so an unbounded memo would quietly hold megabytes.
//
// Two memos, not one: scenes are keyed by METRICS and plans by the whole
// stylesheet, so paint churn (theme flips, live highlighting) adds and evicts
// plans without ever evicting the geometry a new paint style needs.
final _LruCache<_SceneKey, _SceneGeometry> _sceneCache = _LruCache(16);
final _LruCache<_PlanKey, CcMermaidRenderPlan> _planCache = _LruCache(16);

/// Largest logical dimension a scene may reach before the view stops trying to
/// fit it on one screen (a runaway diagram scrolls instead).
const double kCcMermaidMaxLogicalExtent = 20000;

/// Whether [scene] is within sane drawing limits.
bool isMermaidSceneDrawable(CcMermaidScene scene) =>
    !scene.isEmpty &&
    scene.size.width.isFinite &&
    scene.size.height.isFinite &&
    math.max(scene.size.width, scene.size.height) <= kCcMermaidMaxLogicalExtent;
