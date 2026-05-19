import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// Unit tests for the pure helpers behind `agent_run_log.getTranscript` /
/// `.watchRunTranscript`. Both are per-viewer / per-crash transforms whose
/// mistakes would either leak repo content or present a dead run as live, so
/// they are pinned here rather than only exercised through the ops.
void main() {
  final t0 = DateTime.utc(2026, 7, 26);

  group('redactRunTranscriptFrame', () {
    test('redacts every segment body in a seed frame, keeping structure', () {
      final frame = redactRunTranscriptFrame({
        'kind': 'seed',
        'live': true,
        'segments': encodeTranscript([
          TextSegment(text: 'secret prose', startedAt: t0),
          ToolSegment(
            toolName: 'Read',
            toolCallId: 'c1',
            inputs: const {'path': '/private/a.dart'},
            outputs: 'file contents',
            status: ToolSegmentStatus.ok,
            startedAt: t0,
          ),
        ]),
      });

      final segments = (frame['segments'] as List).cast<Map<String, dynamic>>();
      expect(frame['live'], isTrue, reason: 'structure survives redaction');
      expect(segments[0]['text'], isNot('secret prose'));
      // WHAT happened stays visible; the bodies do not.
      expect(segments[1]['toolName'], 'Read');
      expect(segments[1]['status'], 'ok');
      expect(segments[1]['inputs'], isEmpty);
      expect(segments[1]['outputs'], isNot('file contents'));
    });

    test('suppresses delta text and redacts open/close payloads', () {
      final frame = redactRunTranscriptFrame({
        'kind': 'updates',
        'updates': [
          {'t': 'delta', 'i': 0, 'd': 'streamed repo content'},
          {
            't': 'open',
            'i': 1,
            'seg': ToolSegment(
              toolName: 'Grep',
              toolCallId: 'c2',
              inputs: const {'pattern': 'secret'},
              startedAt: t0,
            ).toJson(),
          },
        ],
      });

      final updates = (frame['updates'] as List).cast<Map<String, dynamic>>();
      expect(updates[0]['d'], isEmpty);
      expect((updates[1]['seg'] as Map)['inputs'], isEmpty);
      expect((updates[1]['seg'] as Map)['toolName'], 'Grep');
    });

    test('passes a finish update through untouched', () {
      final frame = redactRunTranscriptFrame({
        'kind': 'updates',
        'updates': [
          {'t': 'finish', 'i': 3, 'outcome': 'completed'},
        ],
      });

      expect((frame['updates'] as List).single, {
        't': 'finish',
        'i': 3,
        'outcome': 'completed',
      });
    });

    test('leaves an unknown frame kind alone', () {
      final frame = redactRunTranscriptFrame({'kind': 'future', 'x': 1});

      expect(frame, {'kind': 'future', 'x': 1});
    });

    test('tolerates a malformed frame rather than throwing', () {
      expect(
        () => redactRunTranscriptFrame({'kind': 'seed', 'segments': 'nope'}),
        returnsNormally,
      );
      expect(
        () => redactRunTranscriptFrame({'kind': 'updates'}),
        returnsNormally,
      );
    });
  });

  group('normalizeInterrupted', () {
    test('presents a still-running tool as interrupted', () {
      final normalized = normalizeInterrupted([
        ToolSegment(toolName: 'Bash', toolCallId: 'c1', startedAt: t0),
      ]);

      expect(
        (normalized.single as ToolSegment).status,
        ToolSegmentStatus.interrupted,
      );
    });

    test('leaves settled tools and other segments untouched', () {
      final ok = ToolSegment(
        toolName: 'Read',
        toolCallId: 'c1',
        status: ToolSegmentStatus.ok,
        startedAt: t0,
      );
      final text = TextSegment(text: 'done', startedAt: t0);

      final normalized = normalizeInterrupted([ok, text]);

      expect(normalized[0], same(ok));
      expect(normalized[1], same(text));
    });

    test('keeps whatever partial output the tool had produced', () {
      final normalized = normalizeInterrupted([
        ToolSegment(
          toolName: 'Bash',
          toolCallId: 'c1',
          outputs: 'half the log',
          startedAt: t0,
        ),
      ]);

      expect((normalized.single as ToolSegment).outputs, 'half the log');
    });
  });
}
