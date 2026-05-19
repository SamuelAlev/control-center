/// The `timeline` parser: `section` groups over `period : event : event` rows.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

final RegExp _sectionStatement = RegExp(
  r'^section\s+(.*)$',
  caseSensitive: false,
);
final RegExp _titleStatement = RegExp(
  r'^title(?:\s+|\s*:\s*)(.*)$',
  caseSensitive: false,
);

/// Parses a `timeline` source.
CcMermaidTimeline parseMermaidTimeline(CcMermaidSource source) {
  String? title = source.title;
  final headerTitle = RegExp(
    r'\btitle\s+(.*)$',
    caseSensitive: false,
  ).firstMatch(source.header);
  if (headerTitle != null) {
    title = stripMermaidQuotes(headerTitle.group(1)!);
  }

  final entries = <CcMermaidTimelineEntry>[];
  String? section;
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
    final sectionMatch = _sectionStatement.firstMatch(statement);
    if (sectionMatch != null) {
      section = stripMermaidQuotes(sectionMatch.group(1)!);
      continue;
    }
    final parts = statement.split(':');
    if (parts.length < 2) {
      // A bare period with no events still marks a point on the axis.
      entries.add(
        CcMermaidTimelineEntry(
          period: stripMermaidQuotes(statement),
          events: const [],
          section: section,
        ),
      );
      continue;
    }
    final events = <String>[];
    for (final part in parts.skip(1)) {
      final event = decodeMermaidEntities(stripMermaidQuotes(part.trim()));
      if (event.isNotEmpty) {
        events.add(event);
      }
    }
    entries.add(
      CcMermaidTimelineEntry(
        period: decodeMermaidEntities(stripMermaidQuotes(parts.first.trim())),
        events: events,
        section: section,
      ),
    );
  }

  return CcMermaidTimeline(entries: List.unmodifiable(entries), title: title);
}
