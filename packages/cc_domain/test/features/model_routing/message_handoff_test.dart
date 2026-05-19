import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2025, 12, 1);

  group('MessageHandoff.transform', () {
    test('cross-provider demotes thinking to tagged text, preserves tools', () {
      final messages = [
        const HandoffMessage(
          role: HandoffRole.user,
          blocks: [HandoffText('do the thing')],
        ),
        const HandoffMessage(
          role: HandoffRole.assistant,
          blocks: [
            HandoffThinking('let me reason', signature: 'sig-abc'),
            HandoffText('here is the answer'),
            HandoffToolCall(id: 't1', name: 'Read', input: {'path': 'a.dart'}),
          ],
        ),
        const HandoffMessage(
          role: HandoffRole.tool,
          blocks: [HandoffToolResult(id: 't1', output: 'file contents')],
        ),
      ];

      final out = MessageHandoff.transform(messages, crossProvider: true);
      final assistant = out[1];
      // Thinking became tagged text; signature dropped.
      expect(assistant.blocks.whereType<HandoffThinking>(), isEmpty);
      final firstText = assistant.blocks.first as HandoffText;
      expect(firstText.text, contains('<thinking>'));
      expect(firstText.text, contains('let me reason'));
      // Tool call preserved.
      expect(assistant.blocks.whereType<HandoffToolCall>().single.id, 't1');
      // Tool result preserved.
      expect(
        out[2].blocks.whereType<HandoffToolResult>().single.output,
        'file contents',
      );
    });

    test('same-provider keeps signed thinking', () {
      final messages = [
        const HandoffMessage(
          role: HandoffRole.assistant,
          blocks: [HandoffThinking('reason', signature: 'sig')],
        ),
      ];
      final out = MessageHandoff.transform(messages, crossProvider: false);
      final thinking = out.first.blocks.whereType<HandoffThinking>().single;
      expect(thinking.signature, 'sig');
    });

    test('synthesizes results for unmatched/aborted tool calls', () {
      final messages = [
        const HandoffMessage(
          role: HandoffRole.assistant,
          aborted: true,
          blocks: [HandoffToolCall(id: 't1', name: 'Bash', input: {})],
        ),
      ];
      final out = MessageHandoff.transform(messages, crossProvider: true);
      expect(out.length, 2);
      final synthetic = out[1].blocks.whereType<HandoffToolResult>().single;
      expect(synthetic.id, 't1');
      expect(synthetic.isError, isTrue);
      expect(synthetic.output, 'aborted');
    });

    test('a matched call gets no synthetic result', () {
      final messages = [
        const HandoffMessage(
          role: HandoffRole.assistant,
          blocks: [HandoffToolCall(id: 't1', name: 'Read')],
        ),
        const HandoffMessage(
          role: HandoffRole.tool,
          blocks: [HandoffToolResult(id: 't1', output: 'ok')],
        ),
      ];
      final out = MessageHandoff.transform(messages, crossProvider: false);
      // No extra synthetic message appended.
      expect(out.length, 2);
    });
  });

  group('MessageHandoff.fromTranscript', () {
    test('maps reasoning/text/tool segments and pairs results', () {
      final segments = <TranscriptSegment>[
        ReasoningSegment(text: 'thinking…', startedAt: t0),
        ToolSegment(
          toolName: 'Read',
          toolCallId: 'c1',
          inputs: const {'path': 'x'},
          outputs: 'data',
          status: ToolSegmentStatus.ok,
          startedAt: t0,
        ),
        TextSegment(text: 'done', startedAt: t0),
      ];
      final msg = MessageHandoff.fromTranscript(segments);
      expect(msg.role, HandoffRole.assistant);
      expect(msg.aborted, isFalse);
      expect(msg.blocks.whereType<HandoffThinking>().single.text, 'thinking…');
      expect(msg.blocks.whereType<HandoffToolCall>().single.name, 'Read');
      expect(msg.blocks.whereType<HandoffToolResult>().single.output, 'data');
      expect(msg.blocks.whereType<HandoffText>().single.text, 'done');
    });

    test('a still-running tool marks the turn aborted (no result)', () {
      final segments = <TranscriptSegment>[
        ToolSegment(
          toolName: 'Bash',
          toolCallId: 'c1',
          status: ToolSegmentStatus.running,
          startedAt: t0,
        ),
      ];
      final msg = MessageHandoff.fromTranscript(segments);
      expect(msg.aborted, isTrue);
      expect(msg.blocks.whereType<HandoffToolResult>(), isEmpty);

      // Carried through transform → synthetic aborted result.
      final out = MessageHandoff.transform([msg], crossProvider: true);
      expect(
        out.last.blocks.whereType<HandoffToolResult>().single.output,
        'aborted',
      );
    });
  });
}
