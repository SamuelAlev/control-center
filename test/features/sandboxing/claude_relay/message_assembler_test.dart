import 'package:cc_infra/src/sandboxing/message_assembler.dart';
import 'package:cc_infra/src/sandboxing/sse.dart';
import 'package:flutter_test/flutter_test.dart';

SseEvent _evt(Map<String, Object?> json) {
  return SseEvent(data: '', parsed: json);
}

void main() {
  group('MessageAssembler', () {
    test('assembles a text block from deltas', () {
      final messages = <AssembledMessage>[];
      final assembler = MessageAssembler(messages.add)
        ..processSse(_evt({
          'type': 'message_start',
          'message': {
            'id': 'msg_1',
            'model': 'claude-sonnet-4-6',
            'usage': {'input_tokens': 10, 'output_tokens': 1},
          },
        }))
        ..processSse(_evt({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }))
        ..processSse(_evt({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'Hello, '},
        }))
        ..processSse(_evt({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'world'},
        }))
        ..processSse(_evt({'type': 'content_block_stop', 'index': 0}));

      expect(messages, hasLength(1));
      final block = messages.single.content.single;
      expect(block, isA<TextBlock>());
      expect((block as TextBlock).text, 'Hello, world');
      expect(messages.single.model, 'claude-sonnet-4-6');
      expect(assembler.contextUsage.inputTokens, 10);
    });

    test('assembles a tool_use block and decodes streamed input JSON', () {
      final messages = <AssembledMessage>[];
      final assembler = MessageAssembler(messages.add)
        ..processSse(_evt({
          'type': 'message_start',
          'message': {'id': 'msg_2', 'model': 'm'},
        }))
        ..processSse(_evt({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'Bash',
          },
        }))
        ..processSse(_evt({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"command":'},
        }))
        ..processSse(_evt({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '"ls -la"}'},
        }))
        ..processSse(_evt({'type': 'content_block_stop', 'index': 0}));

      expect(messages, hasLength(1));
      final block = messages.single.content.single as ToolUseBlock;
      expect(block.id, 'toolu_1');
      expect(block.name, 'Bash');
      expect(block.input, {'command': 'ls -la'});

      final last = assembler.lastToolUse;
      expect(last, isNotNull);
      expect(last!.name, 'Bash');
      expect(last.input, {'command': 'ls -la'});
    });

    test('tracks output tokens from message_delta', () {
      final assembler = MessageAssembler((_) {})
        ..processSse(_evt({
          'type': 'message_start',
          'message': {'id': 'm', 'model': 'm'},
        }))
        ..processSse(_evt({
          'type': 'message_delta',
          'delta': {'stop_reason': 'end_turn'},
          'usage': {'output_tokens': 42},
        }));
      expect(assembler.contextUsage.outputTokens, 42);
    });

    test('ignores events with no current message', () {
      var called = false;
      MessageAssembler((_) => called = true)
          .processSse(_evt({'type': 'content_block_stop', 'index': 0}));
      expect(called, isFalse);
    });

    test('reset clears tool and usage state', () {
      final assembler = MessageAssembler((_) {})
        ..processSse(_evt({
          'type': 'message_start',
          'message': {
            'id': 'm',
            'model': 'm',
            'usage': {'input_tokens': 5},
          },
        }))
        ..reset();
      expect(assembler.lastToolUse, isNull);
      expect(assembler.contextUsage.inputTokens, 0);
    });
  });
}
