import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

/// Coverage for the provider-agnostic harness message model: every block
/// type's `==`/`hashCode`/`toJson` and the [HarnessMessage] convenience
/// constructors + derived views (textContent, hasToolUse, toolUses).
void main() {
  group('HarnessTextBlock', () {
    test('round-trips through toJson', () {
      const block = HarnessTextBlock('hello');
      expect(block.toJson(), {'type': 'text', 'text': 'hello'});
    });

    test('equality is by text', () {
      expect(const HarnessTextBlock('a'), const HarnessTextBlock('a'));
      expect(
        const HarnessTextBlock('a') == const HarnessTextBlock('b'),
        isFalse,
      );
      expect(
        const HarnessTextBlock('a').hashCode,
        const HarnessTextBlock('a').hashCode,
      );
    });

    test('is not equal to an unrelated type', () {
      expect(const HarnessTextBlock('a') == Object(), isFalse);
    });
  });

  group('HarnessToolUseBlock', () {
    const block = HarnessToolUseBlock(
      id: 'tu1',
      name: 'search',
      input: {'q': 'x'},
    );

    test('round-trips through toJson', () {
      expect(block.toJson(), {
        'type': 'tool_use',
        'id': 'tu1',
        'name': 'search',
        'input': {'q': 'x'},
      });
    });

    test('equality covers id, name AND the arguments', () {
      // This used to compare id + name only, which is backwards for anything
      // built on it: a dedupe would collapse two distinct calls to one tool,
      // and a diff over a rewritten history would report no change when the
      // arguments were the only thing that changed.
      const same = HarnessToolUseBlock(
        id: 'tu1',
        name: 'search',
        input: {'q': 'x'},
      );
      expect(block, same);
      expect(block.hashCode, same.hashCode);

      const otherArgs = HarnessToolUseBlock(
        id: 'tu1',
        name: 'search',
        input: {'q': 'DIFFERENT'},
      );
      expect(
        block == otherArgs,
        isFalse,
        reason:
            'same tool, same call id, different arguments — not the same '
            'call',
      );

      const otherId = HarnessToolUseBlock(
        id: 'tu2',
        name: 'search',
        input: {'q': 'x'},
      );
      expect(block == otherId, isFalse);
      const otherName = HarnessToolUseBlock(
        id: 'tu1',
        name: 'other',
        input: {'q': 'x'},
      );
      expect(block == otherName, isFalse);
    });
  });

  group('HarnessToolResultBlock', () {
    test('round-trips through toJson', () {
      const block = HarnessToolResultBlock(
        toolUseId: 'tu1',
        content: 'ok',
        isError: true,
      );
      expect(block.toJson(), {
        'type': 'tool_result',
        'tool_use_id': 'tu1',
        'content': 'ok',
        'is_error': true,
      });
    });

    test('equality uses toolUseId + content + isError', () {
      const a = HarnessToolResultBlock(
        toolUseId: 'tu1',
        content: 'ok',
        isError: true,
      );
      const b = HarnessToolResultBlock(
        toolUseId: 'tu1',
        content: 'ok',
        isError: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == const HarnessToolResultBlock(toolUseId: 'tu1', content: 'other'),
        isFalse,
      );
    });
  });

  group('HarnessImageBlock', () {
    const block = HarnessImageBlock(data: 'b64', mediaType: 'image/png');

    test('round-trips through toJson', () {
      expect(block.toJson(), {
        'type': 'image',
        'media_type': 'image/png',
        'data': 'b64',
      });
    });

    test('equality is by data + mediaType', () {
      const same = HarnessImageBlock(data: 'b64', mediaType: 'image/png');
      expect(block, same);
      expect(block.hashCode, same.hashCode);
      expect(
        block == const HarnessImageBlock(data: 'diff', mediaType: 'image/png'),
        isFalse,
      );
    });
  });

  group('HarnessThinkingBlock', () {
    test('round-trips through toJson, omitting a null signature', () {
      const block = HarnessThinkingBlock('hmm');
      expect(block.toJson(), {'type': 'thinking', 'thinking': 'hmm'});
    });

    test('round-trips through toJson, including a signature', () {
      const block = HarnessThinkingBlock('hmm', signature: 'sig');
      expect(block.toJson(), {
        'type': 'thinking',
        'thinking': 'hmm',
        'signature': 'sig',
      });
    });

    test('equality uses thinking + signature', () {
      const a = HarnessThinkingBlock('hmm', signature: 'sig');
      const b = HarnessThinkingBlock('hmm', signature: 'sig');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const HarnessThinkingBlock('hmm'), isFalse);
    });
  });

  group('HarnessMessage convenience constructors', () {
    test('.user builds a single-text user turn', () {
      final msg = HarnessMessage.user('hi');
      expect(msg.role, HarnessRole.user);
      expect(msg.content, [isA<HarnessTextBlock>()]);
      expect((msg.content.single as HarnessTextBlock).text, 'hi');
    });

    test('.system builds a single-text system turn', () {
      final msg = HarnessMessage.system('rules');
      expect(msg.role, HarnessRole.system);
      expect((msg.content.single as HarnessTextBlock).text, 'rules');
    });

    test('.assistant builds a single-text assistant turn', () {
      final msg = HarnessMessage.assistant('answer');
      expect(msg.role, HarnessRole.assistant);
      expect((msg.content.single as HarnessTextBlock).text, 'answer');
    });

    test('.toolResults carries role tool + result blocks', () {
      final msg = HarnessMessage.toolResults(const [
        HarnessToolResultBlock(toolUseId: 'tu1', content: 'r1'),
      ]);
      expect(msg.role, HarnessRole.tool);
      expect(msg.content.single, isA<HarnessToolResultBlock>());
    });
  });

  group('HarnessMessage derived views', () {
    test('textContent concatenates only text blocks with newlines', () {
      const msg = HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessTextBlock('a'),
          HarnessToolUseBlock(id: 'tu1', name: 'n', input: {}),
          HarnessTextBlock('b'),
        ],
      );
      expect(msg.textContent, 'a\nb');
    });

    test('textContent is empty when there are no text blocks', () {
      const msg = HarnessMessage(
        role: HarnessRole.tool,
        content: [HarnessToolResultBlock(toolUseId: 'tu1', content: 'r')],
      );
      expect(msg.textContent, '');
    });

    test('hasToolUse reports any tool-use block', () {
      const withUse = HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessTextBlock('a'),
          HarnessToolUseBlock(id: 'tu1', name: 'n', input: {}),
        ],
      );
      expect(withUse.hasToolUse, isTrue);
      final without = HarnessMessage.user('plain');
      expect(without.hasToolUse, isFalse);
    });

    test('toolUses returns only tool-use blocks in order', () {
      const msg = HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessToolUseBlock(id: 'tu1', name: 'a', input: {}),
          HarnessTextBlock('x'),
          HarnessToolUseBlock(id: 'tu2', name: 'b', input: {}),
        ],
      );
      expect(msg.toolUses.map((t) => t.id).toList(), ['tu1', 'tu2']);
    });
  });

  group('HarnessMessage toJson', () {
    test('serializes role + content blocks', () {
      final msg = HarnessMessage.user('hi');
      expect(msg.toJson(), {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'hi'},
        ],
      });
    });
  });

  group('HarnessRole', () {
    test('covers system / user / assistant / tool', () {
      expect(HarnessRole.values.toSet(), {
        HarnessRole.system,
        HarnessRole.user,
        HarnessRole.assistant,
        HarnessRole.tool,
      });
    });
  });

  group('JSON round-trips (fromJson)', () {
    // The model had a serializer and no parser, so a persisted history was
    // write-only: every host storing one hand-rolled the read back, and each
    // hand-rolled reader is a place the `type` discriminator can drift from
    // messages.dart.
    void roundTrips(HarnessContentBlock block) {
      expect(HarnessContentBlock.fromJson(block.toJson()), block);
    }

    test('every block type survives a round trip', () {
      roundTrips(const HarnessTextBlock('hello'));
      roundTrips(
        const HarnessToolUseBlock(
          id: 'tu1',
          name: 'search',
          input: {'q': 'x', 'n': 3},
        ),
      );
      roundTrips(
        const HarnessToolResultBlock(
          toolUseId: 'tu1',
          content: 'found',
          isError: true,
          images: [HarnessImageBlock(data: 'AAAA', mediaType: 'image/png')],
        ),
      );
      roundTrips(const HarnessImageBlock(data: 'AAAA', mediaType: 'image/png'));
      roundTrips(const HarnessThinkingBlock('reasoning', signature: 'sig'));
      roundTrips(const HarnessThinkingBlock('reasoning'));
    });

    test('a whole message survives a round trip', () {
      const message = HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessTextBlock('thinking about it'),
          HarnessToolUseBlock(id: 'tu1', name: 'search', input: {'q': 'x'}),
        ],
      );
      expect(HarnessMessage.fromJson(message.toJson()), message);
    });

    test('an unknown block type degrades instead of throwing', () {
      // A history that cannot be fully understood is still worth more than one
      // that cannot be loaded at all.
      final block = HarnessContentBlock.fromJson({
        'type': 'from_the_future',
        'payload': 42,
      });
      expect(block, isA<HarnessTextBlock>());
      expect((block as HarnessTextBlock).text, contains('from_the_future'));
    });

    test(
      'an unknown role falls back to user rather than dropping the turn',
      () {
        final message = HarnessMessage.fromJson({
          'role': 'oracle',
          'content': [
            {'type': 'text', 'text': 'hi'},
          ],
        });
        expect(message.role, HarnessRole.user);
        expect(message.textContent, 'hi');
      },
    );
  });

  group('HarnessMessage equality', () {
    test('two identical turns are equal', () {
      const a = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('hi')],
      );
      const b = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('hi')],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('role, block order and block content all matter', () {
      const base = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('a'), HarnessTextBlock('b')],
      );
      expect(
        base ==
            const HarnessMessage(
              role: HarnessRole.assistant,
              content: [HarnessTextBlock('a'), HarnessTextBlock('b')],
            ),
        isFalse,
      );
      expect(
        base ==
            const HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock('b'), HarnessTextBlock('a')],
            ),
        isFalse,
      );
      expect(
        base ==
            const HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock('a')],
            ),
        isFalse,
      );
    });
  });
}
