import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Renders a conversation as a self-contained HTML page.
///
/// **Why HTML and not markdown.** The thing worth exporting is not the words —
/// those already copy fine — it is the STRUCTURE: which tool ran, what it was
/// given, what it returned, which turns errored. A markdown dump flattens all
/// of that into prose, and the reader has to reconstruct it. Collapsible tool
/// cards keep the shape while staying readable in any browser with no server.
///
/// **Self-contained by construction.** Everything is inlined: no stylesheet, no
/// script, no font, no image host. An export that needs the network is one that
/// stops working the moment it leaves the machine it was made on, which is the
/// only situation anyone exports for.
String renderConversationHtml({
  required String title,
  required List<Message> messages,
  DateTime? exportedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en"><head><meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width,'
        'initial-scale=1">')
    ..writeln('<title>${_escape(title)}</title>')
    ..writeln('<style>$_css</style>')
    ..writeln('</head><body>')
    ..writeln('<header><h1>${_escape(title)}</h1>')
    ..writeln(
      '<p class="meta">${messages.length} messages'
      '${exportedAt == null ? '' : ' · exported '
                '${_escape(exportedAt.toIso8601String())}'}</p></header>',
    )
    ..writeln('<main>');

  for (final message in messages) {
    final who = message.isUser
        ? 'You'
        : message.isAgentTurn
        ? (message.metadata?['agentName'] as String? ?? 'Agent')
        : 'System';
    final role = message.isUser
        ? 'user'
        : message.isAgentTurn
        ? 'agent'
        : 'system';
    buffer
      ..writeln('<article class="msg $role">')
      ..writeln(
        '<div class="who">${_escape(who)}'
        '<span class="ts">${_escape(message.createdAt.toIso8601String())}'
        '</span></div>',
      );

    if (message.content.trim().isNotEmpty) {
      buffer.writeln('<div class="body">${_escape(message.content)}</div>');
    }
    for (final segment in message.transcript) {
      buffer.write(_renderSegment(segment));
    }
    buffer.writeln('</article>');
  }

  buffer
    ..writeln('</main>')
    ..writeln('</body></html>');
  return buffer.toString();
}

String _renderSegment(TranscriptSegment segment) => switch (segment) {
  TextSegment(:final text) when text.trim().isNotEmpty =>
    '<div class="body">${_escape(text)}</div>\n',
  TextSegment() => '',
  // Collapsed by default: a transcript is read for its narrative, and forty
  // expanded tool bodies bury it. The detail is one click away, which is what
  // an export is FOR — the argument nobody kept and the output nobody read.
  ToolSegment(:final toolName, :final inputs, :final outputs, :final status) =>
    '<details class="tool${status == ToolSegmentStatus.error ? ' err' : ''}">'
        '<summary>${_escape(toolName)}'
        '${status == ToolSegmentStatus.error ? ' — failed' : ''}</summary>'
        '${inputs == null ? '' : '<pre>${_escape(_pretty(inputs))}</pre>'}'
        '${outputs.isEmpty ? '' : '<pre>${_escape(outputs)}</pre>'}'
        '</details>\n',
  ReasoningSegment(:final text) =>
    '<details class="think"><summary>thinking</summary>'
        '<pre>${_escape(text)}</pre></details>\n',
  ErrorSegment(:final message) =>
    '<div class="error">${_escape(message)}</div>\n',
  ViolationSegment(:final message) =>
    '<div class="error">rule fired: ${_escape(message)}</div>\n',
};

String _pretty(Map<String, dynamic> value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } on Object {
    return '$value';
  }
}

/// HTML-escapes [value], including quotes.
///
/// A transcript is full of model output, tool arguments and file contents —
/// which is to say, arbitrary text that regularly contains `<` and `&`. Getting
/// this wrong does not produce a security hole in a local file so much as an
/// export that silently loses half a diff to the parser.
String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Renders a conversation as plain markdown, for `/dump`.
///
/// The clipboard companion to the HTML export: what you paste into an issue.
String renderConversationMarkdown({
  required String title,
  required List<Message> messages,
}) {
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln();
  for (final message in messages) {
    final who = message.isUser
        ? 'You'
        : message.isAgentTurn
        ? (message.metadata?['agentName'] as String? ?? 'Agent')
        : 'System';
    buffer.writeln('## $who — ${message.createdAt.toIso8601String()}');
    if (message.content.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(message.content.trim());
    }
    for (final segment in message.transcript) {
      switch (segment) {
        case TextSegment(:final text) when text.trim().isNotEmpty:
          buffer
            ..writeln()
            ..writeln(text.trim());
        case ToolSegment(:final toolName, :final inputs, :final outputs):
          buffer
            ..writeln()
            ..writeln('<details><summary>$toolName</summary>')
            ..writeln()
            ..writeln('```json');
          if (inputs != null) {
            buffer.writeln(_pretty(inputs));
          }
          buffer.writeln('```');
          if (outputs.isNotEmpty) {
            buffer
              ..writeln()
              ..writeln('```')
              ..writeln(outputs)
              ..writeln('```');
          }
          buffer
            ..writeln()
            ..writeln('</details>');
        case ErrorSegment(:final message):
          buffer
            ..writeln()
            ..writeln('> error: $message');
        case TextSegment():
        case ReasoningSegment():
        case ViolationSegment():
          break;
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

const String _css = '''
:root { color-scheme: light dark; }
body { margin: 0 auto; max-width: 46rem; padding: 2rem 1rem;
  font: 15px/1.6 ui-sans-serif, system-ui, -apple-system, sans-serif;
  background: #fff; color: #16181d; }
@media (prefers-color-scheme: dark) {
  body { background: #101216; color: #e6e8ec; }
  .msg { border-color: #262a31; }
  .tool > summary { background: #181b21; }
  pre { background: #0b0d10; }
}
h1 { font-size: 1.35rem; margin: 0 0 .25rem; }
.meta { color: #6b7280; font-size: .85rem; margin: 0 0 2rem; }
.msg { border: 1px solid #e5e7eb; border-radius: 10px;
  padding: .75rem .9rem; margin: 0 0 .75rem; }
.msg.user { background: rgba(99,102,241,.06); }
.msg.system { opacity: .8; font-size: .9rem; }
.who { font-weight: 600; font-size: .85rem; margin-bottom: .35rem; }
.ts { font-weight: 400; color: #6b7280; margin-left: .5rem;
  font-size: .78rem; }
.body { white-space: pre-wrap; overflow-wrap: anywhere; }
.tool, .think { margin: .5rem 0 0; }
.tool > summary, .think > summary { cursor: pointer; font-size: .82rem;
  color: #4b5563; background: #f3f4f6; border-radius: 6px;
  padding: .2rem .5rem; display: inline-block; }
.tool.err > summary { color: #b91c1c; }
pre { white-space: pre-wrap; overflow-wrap: anywhere; background: #f8fafc;
  border-radius: 8px; padding: .6rem .7rem; font-size: .8rem;
  margin: .4rem 0 0; }
.error { color: #b91c1c; font-size: .88rem; margin-top: .4rem; }
''';
