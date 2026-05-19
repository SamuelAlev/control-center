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
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : scene.size.width;
        final raw = scene.size.width <= 0 ? 1.0 : available / scene.size.width;
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
        // Once the diagram would have to shrink past the legibility floor, stop
        // scaling and let it scroll — squinting at a 0.2× flowchart is worse
        // than swiping one.
        if (scaled.width > available + 0.5) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: canvas,
          );
        }
        return canvas;
      },
    );

    if (interactive) {
      content = InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(80),
        clipBehavior: Clip.hardEdge,
        child: content,
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
/// Exposed so hosts can pre-warm a diagram (or ask whether a fence is drawable)
/// without mounting a widget.
CcMermaidRenderPlan resolveMermaidRenderPlan({
  required String source,
  required CcMermaidStyle style,
  TextScaler textScaler = TextScaler.noScaling,
}) => _resolveScene(source: source, style: style, textScaler: textScaler);

/// Drops every memoized scene (tests; a host that swaps fonts wholesale).
void clearMermaidSceneCache() => _sceneCache.clear();

CcMermaidRenderPlan _resolveScene({
  required String source,
  required CcMermaidStyle style,
  required TextScaler textScaler,
}) {
  final key = _SceneKey(source: source, style: style, textScaler: textScaler);
  final cached = _sceneCache.get(key);
  if (cached != null) {
    return cached;
  }

  final CcMermaidRenderPlan plan;
  final parsed = parseMermaid(source);
  switch (parsed) {
    case CcMermaidUnsupported(:final message):
      plan = CcMermaidRenderPlan(reason: message);
    case CcMermaidParsed(:final diagram):
      final ruler = CcMermaidTextPainterRuler(
        style: style,
        textScaler: textScaler,
      );
      final scene = _layout(diagram, style: style, ruler: ruler);
      plan = isMermaidSceneDrawable(scene)
          ? CcMermaidRenderPlan(diagram: diagram, scene: scene, ruler: ruler)
          : CcMermaidRenderPlan(
              diagram: diagram,
              reason: scene.isEmpty
                  ? 'diagram is empty'
                  : 'diagram is too large to draw',
            );
  }
  _sceneCache.put(key, plan);
  return plan;
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
      style == other.style &&
      textScaler == other.textScaler;

  @override
  int get hashCode => Object.hash(source, style, textScaler);
}

/// Small insertion-ordered LRU of laid-out scenes.
class _SceneCache {
  _SceneCache(this.capacity);

  final int capacity;
  final Map<_SceneKey, CcMermaidRenderPlan> _entries = {};

  CcMermaidRenderPlan? get(_SceneKey key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  void put(_SceneKey key, CcMermaidRenderPlan value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

// Sized for "the diagrams on screen plus a scrollback", not for a whole
// session: each entry holds a scene's primitives AND the ruler's laid-out
// TextPainters, so an unbounded cache would quietly hold megabytes.
final _SceneCache _sceneCache = _SceneCache(16);

/// Largest logical dimension a scene may reach before the view stops trying to
/// fit it on one screen (a runaway diagram scrolls instead).
const double kCcMermaidMaxLogicalExtent = 20000;

/// Whether [scene] is within sane drawing limits.
bool isMermaidSceneDrawable(CcMermaidScene scene) =>
    !scene.isEmpty &&
    scene.size.width.isFinite &&
    scene.size.height.isFinite &&
    math.max(scene.size.width, scene.size.height) <= kCcMermaidMaxLogicalExtent;
