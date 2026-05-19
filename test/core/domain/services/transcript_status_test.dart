import 'package:control_center/core/domain/services/transcript_status.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  ToolSegment tool(String name, {ToolSegmentStatus status = ToolSegmentStatus.running}) =>
      ToolSegment(toolName: name, toolCallId: 'c', status: status, startedAt: ts);

  group('normalizeToolName', () {
    test('lowercases and strips mcp prefix', () {
      expect(normalizeToolName('Read'), 'read');
      expect(normalizeToolName('mcp__control-center__create_ticket'), 'create_ticket');
      expect(normalizeToolName('mcp__srv__search_memory'), 'search_memory');
    });
  });

  group('statusLineFor', () {
    test('null on empty', () {
      expect(statusLineFor(const []), isNull);
    });

    test('open reasoning -> thinking', () {
      expect(
        statusLineFor([ReasoningSegment(text: 'x', startedAt: ts)]),
        const TranscriptStatus(TranscriptStatusKind.thinking),
      );
    });

    test('closed reasoning -> null', () {
      expect(
        statusLineFor([ReasoningSegment(text: 'x', startedAt: ts, durationMs: 5)]),
        isNull,
      );
    });

    test('open text -> responding', () {
      expect(
        statusLineFor([TextSegment(text: 'x', startedAt: ts)]),
        const TranscriptStatus(TranscriptStatusKind.responding),
      );
    });

    test('running edit -> making edits', () {
      expect(statusLineFor([tool('Edit')])?.kind, TranscriptStatusKind.makingEdits);
      expect(statusLineFor([tool('Write')])?.kind, TranscriptStatusKind.makingEdits);
    });

    test('running read -> reading files', () {
      expect(statusLineFor([tool('Read')])?.kind, TranscriptStatusKind.readingFiles);
    });

    test('running grep/glob/ls -> searching', () {
      expect(statusLineFor([tool('Grep')])?.kind, TranscriptStatusKind.searching);
      expect(statusLineFor([tool('Glob')])?.kind, TranscriptStatusKind.searching);
      expect(statusLineFor([tool('ls')])?.kind, TranscriptStatusKind.searching);
    });

    test('running bash -> running commands', () {
      expect(statusLineFor([tool('Bash')])?.kind, TranscriptStatusKind.runningCommands);
    });

    test('running mcp tool -> runningTool with name', () {
      final status = statusLineFor([tool('mcp__cc__propose_fact')]);
      expect(status?.kind, TranscriptStatusKind.runningTool);
      expect(status?.toolName, 'mcp__cc__propose_fact');
    });

    test('completed tool -> null', () {
      expect(statusLineFor([tool('Read', status: ToolSegmentStatus.ok)]), isNull);
    });

    test('reads the last segment', () {
      expect(
        statusLineFor([
          ReasoningSegment(text: 'x', startedAt: ts, durationMs: 5),
          tool('Bash'),
        ])?.kind,
        TranscriptStatusKind.runningCommands,
      );
    });
  });
}
