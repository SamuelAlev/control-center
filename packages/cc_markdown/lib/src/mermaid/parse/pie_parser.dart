/// The `pie` parser: an optional title plus `"label" : value` slices.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

final RegExp _sliceStatement = RegExp(
  r'''^"?([^":]+?)"?\s*:\s*([0-9]*\.?[0-9]+)\s*$''',
);
final RegExp _titleStatement = RegExp(
  r'^title(?:\s+|\s*:\s*)(.*)$',
  caseSensitive: false,
);

/// Parses a `pie` source. Negative and non-numeric values are dropped rather
/// than throwing; a chart with no usable slice still parses (the view then
/// renders its empty state).
CcMermaidPie parseMermaidPie(CcMermaidSource source) {
  final showData = source.header.toLowerCase().contains('showdata');
  String? title = source.title;

  // `pie title Key elements` puts the title on the header line.
  final headerTitle = RegExp(
    r'\btitle\s+(.*)$',
    caseSensitive: false,
  ).firstMatch(source.header);
  if (headerTitle != null) {
    title = stripMermaidQuotes(headerTitle.group(1)!);
  }

  final slices = <CcMermaidSlice>[];
  for (final raw in source.statements) {
    final statement = raw.trim();
    if (statement.isEmpty) {
      continue;
    }
    final titleMatch = _titleStatement.firstMatch(statement);
    if (titleMatch != null) {
      title = stripMermaidQuotes(titleMatch.group(1)!);
      continue;
    }
    final slice = _sliceStatement.firstMatch(statement);
    if (slice == null) {
      continue;
    }
    final value = double.tryParse(slice.group(2)!);
    if (value == null || value < 0) {
      continue;
    }
    slices.add(
      CcMermaidSlice(
        label: decodeMermaidEntities(slice.group(1)!.trim()),
        value: value,
      ),
    );
  }

  return CcMermaidPie(
    slices: List.unmodifiable(slices),
    showData: showData,
    title: title,
  );
}
