import 'package:control_center/features/memory/presentation/widgets/memory_excerpt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('memoryPlainExcerpt', () {
    test('drops emphasis and code syntax but keeps the words', () {
      expect(
        memoryPlainExcerpt('**In `acme/shop-ui`**, code MUST _not_ break.'),
        'In acme/shop-ui, code MUST not break.',
      );
    });

    test('reads lists and headings as one line', () {
      expect(
        memoryPlainExcerpt('# Fetch\n\n- first\n- second'),
        'Fetch first second',
      );
    });

    test('keeps a link\'s text and drops its target', () {
      expect(
        memoryPlainExcerpt('See [the docs](https://example.com) first.'),
        'See the docs first.',
      );
    });
  });

  group('memoryExcerptParts', () {
    test('marks machine values apart from words', () {
      expect(memoryExcerptParts('Use `getUrl` here'), [
        (text: 'Use ', code: false),
        (text: 'getUrl', code: true),
        (text: ' here', code: false),
      ]);
    });

    test('reads only the head of a long record', () {
      final parts = memoryExcerptParts('word ' * 2000);
      expect(parts.single.text.length, lessThan(1000));
    });
  });

  group('MemoryExcerpt', () {
    testWidgets('skips what another line already shows', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const MemoryExcerpt(
            markdown: 'Keep `it` short. Then `explain`.',
            skip: 15,
          ),
        ),
      );

      expect(find.text('Then explain.'), findsOneWidget);
    });
  });

  group('memoryLeadSentence', () {
    test('splits after the first sentence', () {
      final split = memoryLeadSentence('Keep it short. Then explain why.');
      expect(split.lead, 'Keep it short.');
      expect(split.rest, 'Then explain why.');
    });

    test('leaves a dotted path whole', () {
      final split = memoryLeadSentence('Edit config.yaml by hand');
      expect(split.lead, 'Edit config.yaml by hand');
      expect(split.rest, '');
    });
  });
}
