import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
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

  group('takeChangedSegments', () {
    test('hands out only new or changed segments across flushes', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'out'));
      final first = folder.takeChangedSegments();

      folder.add(ToolCallEvent(toolName: 'Grep', toolCallId: 'b'));
      final second = folder.takeChangedSegments();
      final third = folder.takeChangedSegments();

      expect(first.keys, [0]);
      expect(second.keys, [1]);
      expect(third, isEmpty);
    });

    test('an open segment comes back each time its buffer grows', () {
      folder
        ..add(TextEvent(content: 'a'))
        ..add(TextEvent(content: 'b'));
      expect(folder.takeChangedSegments()[0]?['text'], 'ab');
      expect(folder.takeChangedSegments(), isEmpty);

      folder.add(TextEvent(content: 'c'));
      expect(folder.takeChangedSegments()[0]?['text'], 'abc');
    });

    test('a long turn costs each flush only what it touched', () {
      var handedOut = 0;
      for (var i = 0; i < 200; i++) {
        folder
          ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'c$i'))
          ..add(ToolResultEvent(toolCallId: 'c$i', outputs: 'out $i'));
        final changed = folder.takeChangedSegments();
        expect(changed.keys, [i]);
        handedOut += changed.length;
      }

      expect(folder.length, 200);
      expect(handedOut, 200);
    });

    test('forgetFlushed hands everything out again', () {
      folder
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'out'))
        ..add(TextEvent(content: 'done'));
      folder.takeChangedSegments();

      folder.forgetFlushed();

      expect(folder.takeChangedSegments().keys, [0, 1]);
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

  group('text retraction (a discarded model attempt)', () {
    test('trims the open text segment and reports the trimmed snapshot', () {
      folder
        ..add(TextEvent(content: 'Final answer: '))
        ..add(TextEvent(content: 'half an ans'));
      final charsBefore = folder.transcriptChars;
      updates.clear();

      folder.add(TextRetractedEvent(text: 'half an ans'));

      expect(folder.snapshot().single, isA<TextSegment>());
      expect((folder.snapshot().single as TextSegment).text, 'Final answer: ');
      // Closing the open segment, then the trimmed snapshot that replaces it.
      final closed = updates.last.update as SegmentClosed;
      expect((closed.segment as TextSegment).text, 'Final answer: ');
      expect(updates.last.structural, isTrue);
      expect(folder.transcriptChars, charsBefore - 'half an ans'.length);
      // The retried attempt then streams into a fresh segment.
      folder.add(TextEvent(content: 'the full answer'));
      expect(folder.currentText(), 'Final answer:\n\nthe full answer');
    });

    test('withdraws thinking and text across their own segments', () {
      folder
        ..add(ThinkingEvent(content: 'let me think'))
        ..add(TextEvent(content: 'partial'));

      folder.add(TextRetractedEvent(text: 'partial', thinking: 'let me think'));

      final segments = folder.snapshot();
      expect((segments[0] as ReasoningSegment).text, isEmpty);
      expect((segments[1] as TextSegment).text, isEmpty);
      expect(folder.currentText(), isEmpty);
    });

    test('stops at a tool segment: earlier turns are never touched', () {
      folder
        ..add(TextEvent(content: 'before the tool'))
        ..add(ToolCallEvent(toolName: 'Read', toolCallId: 'a'))
        ..add(ToolResultEvent(toolCallId: 'a', outputs: 'ok'))
        ..add(TextEvent(content: 'abc'));

      // Over-long retraction (a provider envelope the extractor shortened)
      // clamps at the attempt's own text.
      folder.add(TextRetractedEvent(text: 'xxabc'));

      expect((folder.segments[0] as TextSegment).text, 'before the tool');
      expect((folder.segments[1] as ToolSegment).outputs, 'ok');
      expect((folder.segments[2] as TextSegment).text, isEmpty);
    });

    test('round-trips through the wire codec', () {
      final wire = AgentProcessEventCodec.toWire(
        TextRetractedEvent(text: 'a', thinking: 'b'),
      );
      final back = AgentProcessEventCodec.fromWire(wire) as TextRetractedEvent;
      expect(back.text, 'a');
      expect(back.thinking, 'b');
      expect(back.type, AgentProcessEventType.textRetracted);
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

  group('nested calls (a code mode script)', () {
    test('fold under their parent in call order with the parent id', () {
      folder
        ..add(ToolCallEvent(toolName: 'repl', toolCallId: 'r'))
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/1',
            inputs: const {'path': 'a.dart'},
            parentToolCallId: 'r',
          ),
        )
        ..add(
          ToolCallEvent(
            toolName: 'search',
            toolCallId: 'r/2',
            parentToolCallId: 'r',
          ),
        )
        ..add(
          ToolResultEvent(
            toolCallId: 'r/1',
            outputs: 'body',
            parentToolCallId: 'r',
          ),
        )
        ..add(
          ToolResultEvent(
            toolCallId: 'r/2',
            outputs: 'hits',
            parentToolCallId: 'r',
          ),
        )
        ..add(ToolResultEvent(toolCallId: 'r', outputs: 'script done'));

      final tools = folder.segments.cast<ToolSegment>();
      expect([for (final t in tools) t.toolCallId], ['r', 'r/1', 'r/2']);
      expect([for (final t in tools) t.parentToolCallId], [null, 'r', 'r']);
      expect(
        [for (final t in tools) t.outputs],
        ['script done', 'body', 'hits'],
      );
      expect(tools.every((t) => t.status == ToolSegmentStatus.ok), isTrue);
    });

    test('pair each result with its own call when results interleave', () {
      folder
        ..add(ToolCallEvent(toolName: 'repl', toolCallId: 'r'))
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/1',
            parentToolCallId: 'r',
          ),
        )
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/2',
            parentToolCallId: 'r',
          ),
        )
        // The second call settles first, then the script fails before the
        // first one does.
        ..add(
          ToolResultEvent(
            toolCallId: 'r/2',
            outputs: 'second',
            parentToolCallId: 'r',
          ),
        )
        ..add(ToolResultEvent(toolCallId: 'r', outputs: 'boom', isError: true))
        ..add(
          ToolResultEvent(
            toolCallId: 'r/1',
            outputs: 'first',
            isError: true,
            parentToolCallId: 'r',
          ),
        );

      final byId = {
        for (final t in folder.segments.cast<ToolSegment>()) t.toolCallId: t,
      };
      expect(byId['r']!.outputs, 'boom');
      expect(byId['r']!.status, ToolSegmentStatus.error);
      expect(byId['r/1']!.outputs, 'first');
      expect(byId['r/1']!.status, ToolSegmentStatus.error);
      expect(byId['r/2']!.outputs, 'second');
      expect(byId['r/2']!.status, ToolSegmentStatus.ok);
      expect(folder.segments, hasLength(3));
    });

    test('an unknown nested result never closes the parent', () {
      folder
        ..add(ToolCallEvent(toolName: 'repl', toolCallId: 'r'))
        ..add(
          ToolResultEvent(
            toolCallId: 'r/9',
            outputs: 'stray',
            toolName: 'read',
            parentToolCallId: 'r',
          ),
        );

      final parent = folder.segments.first as ToolSegment;
      expect(parent.status, ToolSegmentStatus.running);
      final orphan = folder.segments.last as ToolSegment;
      expect(orphan.toolCallId, 'r/9');
      expect(orphan.parentToolCallId, 'r');
    });

    test('an id-less result still closes the model\'s own call', () {
      folder
        ..add(ToolCallEvent(toolName: 'repl', toolCallId: 'r'))
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/1',
            parentToolCallId: 'r',
          ),
        )
        ..add(ToolResultEvent(toolCallId: '', outputs: 'parent out'));

      expect((folder.segments[0] as ToolSegment).outputs, 'parent out');
      expect(
        (folder.segments[1] as ToolSegment).status,
        ToolSegmentStatus.running,
      );
    });

    test('nested arguments never blank the text before the parent', () {
      folder
        ..add(TextEvent(content: 'lib/a.dart'))
        ..add(
          ToolCallEvent(
            toolName: 'repl',
            toolCallId: 'r',
            inputs: const {'code': 'await tools.read({path})'},
          ),
        )
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/1',
            inputs: const {'path': 'lib/a.dart'},
            parentToolCallId: 'r',
          ),
        );

      expect((folder.segments.first as TextSegment).text, 'lib/a.dart');
    });

    test('the parent id survives the persisted form', () {
      folder
        ..add(ToolCallEvent(toolName: 'repl', toolCallId: 'r'))
        ..add(
          ToolCallEvent(
            toolName: 'read',
            toolCallId: 'r/1',
            parentToolCallId: 'r',
          ),
        );

      final restored = TranscriptSegment.fromJson(
        folder.takeChangedSegments()[1]!,
      );
      expect((restored as ToolSegment).parentToolCallId, 'r');
    });
  });
}
