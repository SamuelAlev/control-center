import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Images in tool results are the most expensive thing a tool can put in a
/// transcript: ~1200 tokens each, and compaction can shrink text but cannot
/// shrink a screenshot. These pin the budget and the shedding.
void main() {
  const image = HarnessImageBlock(data: 'AAAA', mediaType: 'image/jpeg');

  group('tool result', () {
    test('a result carries no images by default', () {
      expect(HarnessToolResult.success('done').images, isEmpty);
      expect(HarnessToolResult.error('nope').images, isEmpty);
    });

    test('images ride alongside the text', () {
      final result = HarnessToolResult.success('shot', images: const [image]);
      expect(result.content, 'shot');
      expect(result.images, hasLength(1));
    });
  });

  group('image budget', () {
    test('the default budget is one image per result', () {
      final capped = capToolImages(
        const [image, image, image],
        ToolOutputLimits.standard,
      );
      expect(capped, hasLength(1));
    });

    test('the earliest images are kept', () {
      const first = HarnessImageBlock(data: 'first', mediaType: 'image/png');
      const second = HarnessImageBlock(data: 'second', mediaType: 'image/png');
      final capped = capToolImages(
        const [first, second],
        ToolOutputLimits.standard,
      );
      // For a screenshot sequence the first frame is the one the request
      // asked for; the rest are follow-ups.
      expect(capped.single, first);
    });

    test('a zero budget drops images entirely', () {
      final capped = capToolImages(
        const [image],
        const ToolOutputLimits(maxImages: 0),
      );
      expect(capped, isEmpty);
    });

    test('a fitting list is returned unchanged', () {
      const list = [image];
      expect(identical(capToolImages(list, ToolOutputLimits.standard), list),
          isTrue);
    });

    test('the rig tools get a tightened text cap', () {
      // The image is the payload for these; a DOM or UI dump has no business
      // filling the window alongside it.
      for (final tool in ['computer_use', 'browser_use', 'mobile_use']) {
        final limits = ToolOutputLimitTable.defaults.forTool(tool);
        expect(limits.characterLimit, lessThan(ToolOutputLimits.standard.characterLimit));
        expect(limits.maxImages, 1);
      }
    });
  });

  group('wire form', () {
    test('a text-only result block omits the images key', () {
      const block = HarnessToolResultBlock(toolUseId: 't1', content: 'ok');
      expect(block.toJson().containsKey('images'), isFalse);
    });

    test('an image-bearing block serializes them', () {
      const block = HarnessToolResultBlock(
        toolUseId: 't1',
        content: 'ok',
        images: [image],
      );
      final json = block.toJson();
      expect(json['images'], hasLength(1));
      expect((json['images']! as List).first, containsPair('type', 'image'));
    });

    test('equality accounts for images', () {
      const a = HarnessToolResultBlock(toolUseId: 't', content: 'x');
      const b = HarnessToolResultBlock(
        toolUseId: 't',
        content: 'x',
        images: [image],
      );
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('token accounting', () {
    test('images are counted on top of the result text', () {
      const withoutImage = HarnessToolResultBlock(
        toolUseId: 't',
        content: 'a short result',
      );
      const withImage = HarnessToolResultBlock(
        toolUseId: 't',
        content: 'a short result',
        images: [image],
      );
      expect(
        estimateHarnessBlock(withImage),
        greaterThan(estimateHarnessBlock(withoutImage) + 1000),
        reason:
            'An uncounted image lets a screenshotting run overrun the context '
            'window while the estimate says it is fine.',
      );
    });
  });

  group('compaction', () {
    test('a stale tool result sheds its image but keeps its words', () {
      const compactor = DefaultHarnessCompactor();
      final history = <HarnessMessage>[
        HarnessMessage.user('go'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 't1', name: 'computer_use', input: {}),
          ],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'The login form is visible with an empty email field.',
            images: [image],
          ),
        ]),
        HarnessMessage.user('and now'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 't2', name: 'computer_use', input: {}),
          ],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't2',
            content: 'The form is now filled in.',
            images: [image],
          ),
        ]),
      ];

      // `force` because this asserts the SHEDDING rule (image out, words in),
      // not the batching policy that decides when a rewrite earns the cached
      // prefix it costs. One stale frame is under that threshold; two are not,
      // which `harness_compaction_test.dart` covers unforced.
      compactor.pruneToolResults(history, force: true);

      final older = history[2].content.first as HarnessToolResultBlock;
      expect(
        older.images,
        isEmpty,
        reason:
            'Summarization shrinks text but cannot shrink an image, so a run '
            'that screenshots every turn would accumulate frames forever.',
      );
      expect(
        older.content,
        contains('login form'),
        reason: 'The words are what carry the finding past this point.',
      );

      final newest = history[5].content.first as HarnessToolResultBlock;
      expect(
        newest.images,
        hasLength(1),
        reason: 'The newest tool turn is the one still worth looking at.',
      );
    });
  });
}
