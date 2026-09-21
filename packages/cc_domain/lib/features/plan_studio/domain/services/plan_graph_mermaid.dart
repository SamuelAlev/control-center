import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Renders a [PlanGraph] as mermaid flowchart source (pure string; no Flutter).
///
/// For static bubbles/exports — not the interactive DAG canvas. Node shapes by
/// [PlanNodeType]: research `[/text/]`, work `[text]`, discussion `([text])`,
/// synthesis `{{text}}`. No author theming — engine uses app tokens.
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
