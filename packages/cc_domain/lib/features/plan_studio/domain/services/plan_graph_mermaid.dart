import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Renders a [PlanGraph] as mermaid flowchart source.
///
/// Pure string production — no rendering, no Flutter — so it can be used
/// anywhere: the plan bubble in the conversation, Plan Studio's overview pane,
/// an artifact block, or a markdown export. The app's mermaid engine
/// (`CcMermaidView`) draws it natively, with no WebView and no JS.
///
/// Why mermaid rather than reusing the DAG canvas: the canvas is an interactive
/// editor bound to Plan Studio's layout and selection state. A conversation
/// bubble wants a small, static, themable picture and mermaid is already a
/// first-class block in this app's markdown pipeline.
///
/// Node shape encodes [PlanNodeType], so the structural frame
/// (research/discussion/synthesis) reads differently from the work nodes at a
/// glance:
///
///  * research   — `[/text/]` (parallelogram)
///  * work       — `[text]` (rectangle)
///  * discussion — `([text])` (stadium)
///  * synthesis  — `{{text}}` (hexagon)
///
/// Theming is deliberately omitted: the engine themes diagrams from app tokens,
/// so author-side `classDef`/`style` would be ignored anyway (and would break
/// the light/dark contrast floor if it were not).
String planGraphToMermaid(
  PlanGraph graph, {

  /// Direction: `TD` (top-down) reads better for deep dependency chains, `LR`
  /// for wide parallel fan-outs.
  String direction = 'TD',

  /// Truncate node titles to this many characters so one long title cannot
  /// stretch the whole diagram.
  int maxTitleChars = 48,
}) {
  if (graph.nodes.isEmpty) {
    return '';
  }
  final ids = <String, String>{};
  for (var i = 0; i < graph.nodes.length; i++) {
    // Mermaid ids must be identifier-safe; plan keys are free-form slugs.
    ids[graph.nodes[i].key] = 'n$i';
  }

  final lines = <String>['flowchart $direction'];
  for (final node in graph.nodes) {
    final id = ids[node.key]!;
    final label = _escapeLabel(node.title, maxTitleChars);
    lines.add('  $id${_shapeFor(node.type, label)}');
  }
  for (final node in graph.nodes) {
    final to = ids[node.key]!;
    for (final dep in node.dependsOn) {
      final from = ids[dep];
      // A dangling dependency is a validation error caught at submit time; skip
      // it here rather than emitting broken source (this renderer never throws).
      if (from != null) {
        lines.add('  $from --> $to');
      }
    }
  }
  return lines.join('\n');
}

String _shapeFor(PlanNodeType type, String label) => switch (type) {
  PlanNodeType.research => '[/"$label"/]',
  PlanNodeType.work => '["$label"]',
  PlanNodeType.discussion => '(["$label"])',
  PlanNodeType.synthesis => '{{"$label"}}',
};

/// Makes [text] safe inside a quoted mermaid label and bounds its length.
String _escapeLabel(String text, int maxChars) {
  var out = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (out.length > maxChars) {
    out = '${out.substring(0, maxChars - 1).trimRight()}…';
  }
  // Quotes would terminate the label; angle brackets and pipes confuse the
  // flowchart tokenizer even inside quotes.
  return out
      .replaceAll('"', "'")
      .replaceAll('<', '(')
      .replaceAll('>', ')')
      .replaceAll('|', '/');
}
