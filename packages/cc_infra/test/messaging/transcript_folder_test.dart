import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';
import 'package:test/test.dart';

void main() {
  late List<({TranscriptUpdate update, bool structural})> updates;
  late TranscriptFolder folder;

  setUp(() {
    updates = [];
    folder = TranscriptFolder(
      onUpdate: (update, {required structural}) =>
          updates.add((update: update, structural: structural)),
    );
  });

  group('tool pairing', () {
    test('pairs a result to its call by tool-call id', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolCallEvent(toolName: 'Grep', toolCallId: 'b'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'first'));

      expect((folder.segments[0] as ToolSegment).outputs, 'first');
      expect((folder.segments[0] as ToolSegment).status, ToolSegmentStatus.ok);
      expect(
        (folder.segments[1] as ToolSegment).status,
        ToolSegmentStatus.running,
      );
    });

    test('falls back to the last open tool when the result id is empty', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: '', outputs: 'out'));

      expect((folder.segments.single as ToolSegment).outputs, 'out');
    });

    test('an orphan result becomes its own terminal segment', () {
      folder.add(
        ToolResultEvent(
          toolCallId: 'ghost',
          outputs: 'out',
          toolName: 'Read',
          isError: true,
        ),
      );

      final seg = folder.segments.single as ToolSegment;
      expect(seg.toolName, 'Read');
      expect(seg.status, ToolSegmentStatus.error);
    });

    test('a partial result buffers without materializing the segment', () {
      folder
        ..add(ToolCallEvent(toolName: 'Bash', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'x', isPartial: true))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'y', isPartial: true));

      // The stale entry keeps the pre-delta text; materialization is on read.
      expect((folder.segments.single as ToolSegment).outputs, isEmpty);
      expect((folder.materialized(0) as ToolSegment).outputs, 'xy');
    });

    test('the final result replaces partial accumulation', () {
      folder
        ..add(ToolCallEvent(toolName: 'Bash', toolCallId: 'a'))
        ..add(
          ToolResultEvent(toolCallId: 'a', outputs: 'partial', isPartial: true),
        )
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'final'));

      expect((folder.segments.single as ToolSegment).outputs, 'final');
    });
  });

  group('text accumulation', () {
    test('consecutive deltas grow one segment and report non-structurally', () {
      folder
        ..add(TextEvent(content: 'a'))
        ..add(TextEvent(content: 'b'));

      expect(folder.segments, hasLength(1));
      expect((folder.materialized(0) as TextSegment).text, 'ab');
      expect(updates.map((u) => u.structural), [true, false]);
    });

    test('switching between text and reasoning closes the open segment', () {
      folder
        ..add(TextEvent(content: 'answer'))
        ..add(ThinkingEvent(content: 'hmm'));

      expect(folder.segments, hasLength(2));
      expect(folder.segments[0], isA<TextSegment>());
      expect(folder.segments[1], isA<ReasoningSegment>());
    });

    test('a tool call closes the open text segment first', () {
      folder
        ..add(TextEvent(content: 'about to read'))
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'));

      expect((folder.segments[0] as TextSegment).text, 'about to read');
      expect(folder.segments[1], isA<ToolSegment>());
    });

    test('currentText joins only non-blank text segments', () {
      folder
        ..add(TextEvent(content: 'one'))
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(TextEvent(content: 'two'));

      expect(folder.currentText(), 'one\n\ntwo');
    });
  });

  group('tool-argument echo guard', () {
    test('blanks a text segment that only echoed the tool arguments', () {
      folder
        ..add(TextEvent(content: 'ls -la'))
        ..add(
          ToolCallEvent(
            toolName: 'bash',
            toolCallId: 'a',
            inputs: const {'command': 'ls -la'},
          ),
        );

      expect((folder.segments[0] as TextSegment).text, isEmpty);
    });

    test('leaves a text segment that carried real prose fully intact', () {
      folder
        ..add(TextEvent(content: 'Let me list the files with ls -la'))
        ..add(
          ToolCallEvent(
            toolName: 'bash',
            toolCallId: 'a',
            inputs: const {'command': 'ls -la'},
          ),
        );

      // The residue is non-empty, so the segment is protected outright — the
      // subtraction only decides whether to blank, it never edits the prose.
      expect(
        (folder.segments[0] as TextSegment).text,
        'Let me list the files with ls -la',
      );
    });

    test('an ordinarily-empty text segment is not mistaken for an echo', () {
      folder
        ..add(TextEvent(content: 'prose'))
        ..add(
          ToolCallEvent(
            toolName: 'bash',
            toolCallId: 'a',
            inputs: const {'command': 'unrelated'},
          ),
        );

      expect((folder.segments[0] as TextSegment).text, 'prose');
    });
  });

  group('encodeForFlush', () {
    test('re-encodes only changed segments across flushes', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'out'));
      final first = folder.encodeForFlush();

      folder.add(ToolCallEvent(toolName: 'Grep', toolCallId: 'b'));
      final second = folder.encodeForFlush();

      expect(first, hasLength(1));
      expect(second, hasLength(2));
      // The untouched closed segment keeps its identical cached entry.
      expect(second[0], same(first[0]));
    });

    test('encodes open segments with their buffered text', () {
      folder
        ..add(TextEvent(content: 'a'))
        ..add(TextEvent(content: 'b'));

      expect(folder.encodeForFlush().single['text'], 'ab');
    });
  });

  group('finalization', () {
    test('interruptRunningTools keeps partial output', () {
      folder
        ..add(ToolCallEvent(toolName: 'Bash', toolCallId: 'a'))
        ..add(
          ToolResultEvent(toolCallId: 'a', outputs: 'so far', isPartial: true),
        );

      folder.interruptRunningTools(DateTime.utc(2026, 7, 26, 1));

      final seg = folder.segments.single as ToolSegment;
      expect(seg.status, ToolSegmentStatus.interrupted);
      expect(seg.outputs, 'so far');
    });

    test('terminalFailure reports a trailing error with no answer', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ErrorEvent(content: 'no credential'));

      expect(folder.terminalFailure(), 'no credential');
    });

    test('terminalFailure ignores an error the run recovered from', () {
      folder
        ..add(ErrorEvent(content: 'transient'))
        ..add(TextEvent(content: 'recovered and answered'));
      folder.closeOpenText(DateTime.utc(2026, 7, 26, 1));

      expect(folder.terminalFailure(), isNull);
    });

    test('appendUnreported lands in the transcript without an update', () {
      final before = updates.length;

      folder.appendUnreported(
        ErrorSegment(
          message: 'stream died',
          startedAt: DateTime.utc(2026, 7, 26),
        ),
      );

      expect(folder.segments, hasLength(1));
      expect(updates, hasLength(before));
    });
  });

  group('transcriptChars', () {
    test('accumulates text, tool and error content', () {
      folder
        ..add(TextEvent(content: 'abc'))
        ..add(ErrorEvent(content: 'de'));

      expect(folder.transcriptChars, greaterThanOrEqualTo(5));
    });

    test('never goes negative when an echo is subtracted', () {
      folder
        ..add(TextEvent(content: 'ls'))
        ..add(
          ToolCallEvent(
            toolName: 'bash',
            toolCallId: 'a',
            inputs: const {'command': 'ls'},
          ),
        );

      expect(folder.transcriptChars, greaterThanOrEqualTo(0));
    });
  });
}
