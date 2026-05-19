import 'dart:convert';

import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';

/// Renders an [ArtifactDocument] as readable plain text / markdown.
///
/// Two consumers, one implementation:
///
///  * the client's "copy" action, so an operator can paste an artifact
///    somewhere that has no block renderer;
///  * the harness `read` tool's `artifact://<id>` resolution, so one agent can
///    read another's published artifact as text.
///
/// Every kind degrades to something a model can parse without knowing the block
/// schema: markdown verbatim, tables as pipe tables, mermaid and code as fenced
/// blocks, charts as a labelled series listing (a chart's *numbers* are the
/// part that survives being read rather than seen), and data as pretty JSON.
String artifactDocumentToPlainText(ArtifactDocument document) {
  final parts = <String>[];
  for (final block in document.blocks) {
    final rendered = _renderBlock(block);
    if (rendered.trim().isNotEmpty) {
      parts.add(rendered.trimRight());
    }
  }
  return parts.join('\n\n');
}

String _renderBlock(ArtifactBlock block) => switch (block) {
  ArtifactMarkdownBlock(:final text) => text,
  ArtifactTableBlock(:final columns, :final rows) => _renderTable(
    columns,
    rows,
  ),
  final ArtifactChartBlock chart => _renderChart(chart),
  ArtifactMermaidBlock(:final source) => '```mermaid\n$source\n```',
  ArtifactCodeBlock(:final code, :final language, :final title) => [
    if (title != null && title.isNotEmpty) '**$title**',
    '```${language ?? ''}\n$code\n```',
  ].join('\n'),
  ArtifactDataBlock(:final json) =>
    '```json\n${const JsonEncoder.withIndent('  ').convert(json)}\n```',
};

/// A GitHub-flavored pipe table. Alignment is encoded in the separator row so a
/// markdown renderer downstream reproduces the intent.
String _renderTable(List<ArtifactColumn> columns, List<List<String>> rows) {
  if (columns.isEmpty) {
    return '';
  }
  String cell(String v) => v.replaceAll('|', r'\|').replaceAll('\n', ' ');
  final header = '| ${columns.map((c) => cell(c.label)).join(' | ')} |';
  final sep =
      '| ${columns.map((c) => switch (c.align) {
        ArtifactColumnAlign.center => ':---:',
        ArtifactColumnAlign.right => '---:',
        ArtifactColumnAlign.left => ':---',
        null => '---',
      }).join(' | ')} |';
  final body = [
    for (final row in rows)
      '| ${[for (var i = 0; i < columns.length; i++) cell(i < row.length ? row[i] : '')].join(' | ')} |',
  ];
  return [header, sep, ...body].join('\n');
}

String _renderChart(ArtifactChartBlock chart) {
  final lines = <String>[
    if (chart.title != null && chart.title!.isNotEmpty)
      '**${chart.title}** (${chart.chartKind.name} chart)'
    else
      '${chart.chartKind.name} chart',
  ];
  for (final series in chart.series) {
    final points = series.points
        .map((p) => '${p.x}: ${_number(p.y)}')
        .join(', ');
    lines.add('- ${series.label}: $points');
  }
  if (chart.xLabel != null && chart.xLabel!.isNotEmpty) {
    lines.add('- x axis: ${chart.xLabel}');
  }
  if (chart.yLabel != null && chart.yLabel!.isNotEmpty) {
    lines.add('- y axis: ${chart.yLabel}');
  }
  return lines.join('\n');
}

String _number(double v) =>
    v == v.roundToDouble() && v.abs() < 1e15 ? '${v.round()}' : '$v';
