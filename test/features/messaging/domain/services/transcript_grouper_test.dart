import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/services/transcript_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptGrouper', () {
    test('returns empty list for empty input', () async {
      final blocks = TranscriptGrouper.group([]);
      expect(blocks, isEmpty);
    });

    group('thinking events', () {
      test('groups consecutive thinking events into a single block', () async {
        final events = [
          ThinkingEvent(content: 'step 1'),
          ThinkingEvent(content: 'step 2'),
          ThinkingEvent(content: 'step 3'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.thinking);
        expect(blocks.first.eventCount, 3);
        expect(blocks.first.summary, 'Thought for 3 entries');
        expect(blocks.first.firstContent, 'step 1');
      });

      test('single thinking event still forms a block', () async {
        final events = [ThinkingEvent(content: 'hmm')];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.thinking);
        expect(blocks.first.eventCount, 1);
      });
    });

    group('error events', () {
      test('groups >= threshold errors into a single stderrGroup', () async {
        final events = [
          ErrorEvent(content: 'err1'),
          ErrorEvent(content: 'err2'),
          ErrorEvent(content: 'err3'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.stderrGroup);
        expect(blocks.first.eventCount, 3);
        expect(blocks.first.isGroup, isTrue);
        expect(blocks.first.summary, '3 error messages');
      });

      test('splits errors below threshold into individual blocks', () async {
        final events = [ErrorEvent(content: 'single err')];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.stderrGroup);
        expect(blocks.first.eventCount, 1);
        expect(blocks.first.isGroup, isTrue);
        expect(blocks.first.summary, isNull);
      });

      test('exactly threshold errors form a group', () async {
        final events = [
          ErrorEvent(content: 'err1'),
          ErrorEvent(content: 'err2'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.eventCount, 2);
        expect(blocks.first.isGroup, isTrue);
      });
    });

    group('tool events', () {
      test('groups >= threshold tool calls into a toolGroup', () async {
        final events = [
          ToolCallEvent(toolName: 'read', toolCallId: '1'),
          ToolCallEvent(toolName: 'write', toolCallId: '2'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.toolGroup);
        expect(blocks.first.eventCount, 2);
        expect(blocks.first.isGroup, isTrue);
        expect(blocks.first.summary, '2 tool operations');
      });

      test('groups mixed toolCall + toolResult into a toolGroup', () async {
        final events = [
          ToolCallEvent(toolName: 'read', toolCallId: '1'),
          ToolResultEvent(toolCallId: '1', outputs: 'file contents'),
          ToolCallEvent(toolName: 'write', toolCallId: '2'),
          ToolResultEvent(toolCallId: '2', outputs: 'ok'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.toolGroup);
        expect(blocks.first.eventCount, 4);
      });

      test('single tool call gets individual tool block (not group)', () async {
        final events = [
          ToolCallEvent(toolName: 'read', toolCallId: '1'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.tool);
        expect(blocks.first.eventCount, 1);
        expect(blocks.first.isGroup, isFalse);
      });

      test('single tool result gets individual tool block', () async {
        final events = [
          ToolResultEvent(toolCallId: '1', outputs: 'result'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.tool);
        expect(blocks.first.eventCount, 1);
      });
    });

    group('debug events', () {
      test('groups >= threshold debug events into a systemGroup', () async {
        final events = [
          DebugEvent(content: 'launching pi'),
          DebugEvent(content: 'exited cleanly'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.systemGroup);
        expect(blocks.first.eventCount, 2);
        expect(blocks.first.summary, '2 system messages');
      });

      test('single debug event still forms a systemGroup', () async {
        final events = [DebugEvent(content: 'debug')];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.systemGroup);
        expect(blocks.first.eventCount, 1);
      });
    });

    group('text and other events', () {
      test('wraps a text event in a message block', () async {
        final events = [TextEvent(content: 'Hello!')];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.message);
        expect(blocks.first.eventCount, 1);
        expect(blocks.first.firstContent, 'Hello!');
      });

      test('wraps usage event in a message block', () async {
        final events = [
          UsageEvent(
            usage: const RunUsage(
              inputTokens: 100,
              outputTokens: 50,
              thoughtTokens: 0,
              cachedReadTokens: 0,
              cachedWriteTokens: 0,
              estimatedCostCents: 1,
            ),
          ),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.message);
      });

      test('wraps done event in a message block', () async {
        final events = [DoneEvent()];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.message);
      });

      test('wraps sandbox violation in a message block', () async {
        final events = [
          SandboxViolationEvent(
            content: 'denied',
            action: 'file-read',
            target: '/etc/passwd',
          ),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 1);
        expect(blocks.first.type, TranscriptBlockType.message);
      });
    });

    group('mixed sequences', () {
      test('groups each contiguous run independently', () async {
        final events = <AgentProcessEvent>[
          // thinking run
          ThinkingEvent(content: 't1'),
          ThinkingEvent(content: 't2'),
          // text (non-groupable)
          TextEvent(content: 'msg'),
          // tool run
          ToolCallEvent(toolName: 'read', toolCallId: '1'),
          ToolResultEvent(toolCallId: '1', outputs: 'data'),
          ToolCallEvent(toolName: 'write', toolCallId: '2'),
          ToolResultEvent(toolCallId: '2', outputs: 'ok'),
          // error run
          ErrorEvent(content: 'e1'),
          ErrorEvent(content: 'e2'),
        ];

        final blocks = TranscriptGrouper.group(events);

        // 0: thinking group
        expect(blocks[0].type, TranscriptBlockType.thinking);
        expect(blocks[0].eventCount, 2);
        // 1: text message
        expect(blocks[1].type, TranscriptBlockType.message);
        // 2: tool group
        expect(blocks[2].type, TranscriptBlockType.toolGroup);
        expect(blocks[2].eventCount, 4);
        // 3: error group
        expect(blocks[3].type, TranscriptBlockType.stderrGroup);
        expect(blocks[3].eventCount, 2);
      });

      test('separates thinking blocks interrupted by other types', () async {
        final events = <AgentProcessEvent>[
          ThinkingEvent(content: 'think1'),
          TextEvent(content: 'interrupt'),
          ThinkingEvent(content: 'think2'),
        ];
        final blocks = TranscriptGrouper.group(events);

        expect(blocks.length, 3);
        expect(blocks[0].type, TranscriptBlockType.thinking);
        expect(blocks[1].type, TranscriptBlockType.message);
        expect(blocks[2].type, TranscriptBlockType.thinking);
      });
    });

    group('TranscriptBlock', () {
      test('firstContent returns empty string for empty events list', () async {
        // Direct construction — grouper never produces empty-event blocks,
        // but the getter should still be safe.
        const block = TranscriptBlock(
          type: TranscriptBlockType.message,
          events: [],
        );
        expect(block.firstContent, '');
        expect(block.eventCount, 0);
      });

      test('isGroup is true for group types only', () async {
        expect(
          TranscriptBlock(
            type: TranscriptBlockType.stderrGroup,
            events: [ErrorEvent(content: 'e')],
          ).isGroup,
          isTrue,
        );
        expect(
          TranscriptBlock(
            type: TranscriptBlockType.toolGroup,
            events: [ToolCallEvent(toolName: 'a', toolCallId: '1')],
          ).isGroup,
          isTrue,
        );
        expect(
          const TranscriptBlock(
            type: TranscriptBlockType.commandGroup,
            events: [],
          ).isGroup,
          isTrue,
        );
        expect(
          TranscriptBlock(
            type: TranscriptBlockType.tool,
            events: [ToolCallEvent(toolName: 'a', toolCallId: '1')],
          ).isGroup,
          isFalse,
        );
        expect(
          TranscriptBlock(
            type: TranscriptBlockType.message,
            events: [TextEvent(content: 'x')],
          ).isGroup,
          isFalse,
        );
        expect(
          TranscriptBlock(
            type: TranscriptBlockType.thinking,
            events: [ThinkingEvent(content: 'x')],
          ).isGroup,
          isFalse,
        );
      });

      test('summary is preserved when explicitly provided', () async {
        const block = TranscriptBlock(
          type: TranscriptBlockType.message,
          events: [],
          summary: 'custom summary',
        );
        expect(block.summary, 'custom summary');
      });

      test('summary is null when not provided', () async {
        const block = TranscriptBlock(
          type: TranscriptBlockType.message,
          events: [],
        );
        expect(block.summary, isNull);
      });

      test('event type has eventCount and isGroup is false', () async {
        const block = TranscriptBlock(
          type: TranscriptBlockType.event,
          events: [],
        );
        expect(block.type, TranscriptBlockType.event);
        expect(block.isGroup, isFalse);
        expect(block.eventCount, 0);
      });
    });
  });
}
