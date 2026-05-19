import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

void main() {
  group('HarnessMessage', () {
    test('user/system/assistant convenience constructors', () {
      expect(HarnessMessage.user('hi').role, HarnessRole.user);
      expect(HarnessMessage.system('s').role, HarnessRole.system);
      expect(HarnessMessage.assistant('a').role, HarnessRole.assistant);
      expect(HarnessMessage.user('hi').textContent, 'hi');
    });

    test('textContent joins all text blocks', () {
      const msg = HarnessMessage(
        role: HarnessRole.assistant,
        content: [HarnessTextBlock('a'), HarnessTextBlock('b')],
      );
      expect(msg.textContent, 'a\nb');
    });

    test('hasToolUse and toolUses reflect tool-use blocks', () {
      const msg = HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessTextBlock('thinking out loud'),
          HarnessToolUseBlock(id: 't1', name: 'read', input: {'path': 'a'}),
          HarnessToolUseBlock(id: 't2', name: 'bash', input: {'command': 'ls'}),
        ],
      );
      expect(msg.hasToolUse, isTrue);
      expect(msg.toolUses.map((t) => t.name), ['read', 'bash']);
    });

    test('toolResults constructor uses tool role', () {
      final msg = HarnessMessage.toolResults(const [
        HarnessToolResultBlock(toolUseId: 't1', content: 'ok'),
      ]);
      expect(msg.role, HarnessRole.tool);
      expect(msg.content.single, isA<HarnessToolResultBlock>());
    });

    test('blocks serialize to JSON', () {
      expect(const HarnessTextBlock('x').toJson(), {
        'type': 'text',
        'text': 'x',
      });
      expect(
        const HarnessToolUseBlock(id: 'i', name: 'n', input: {'a': 1}).toJson(),
        {
          'type': 'tool_use',
          'id': 'i',
          'name': 'n',
          'input': {'a': 1},
        },
      );
      expect(
        const HarnessToolResultBlock(
          toolUseId: 'i',
          content: 'c',
          isError: true,
        ).toJson(),
        {
          'type': 'tool_result',
          'tool_use_id': 'i',
          'content': 'c',
          'is_error': true,
        },
      );
    });
  });
}
