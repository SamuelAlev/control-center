import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

HarnessImageBlock _img([String data = 'AAA']) =>
    HarnessImageBlock(data: data, mediaType: 'image/png');

HarnessMessage _toolResult(
  String id,
  int imageCount, {
  String content = 'screenshot taken',
}) => HarnessMessage(
  role: HarnessRole.user,
  content: [
    HarnessToolResultBlock(
      toolUseId: id,
      content: content,
      images: [for (var i = 0; i < imageCount; i++) _img('$id-$i')],
    ),
  ],
);

int _countImages(List<HarnessMessage> messages) {
  var total = 0;
  for (final m in messages) {
    for (final b in m.content) {
      if (b is HarnessToolResultBlock) {
        total += b.images.length;
      } else if (b is HarnessImageBlock) {
        total += 1;
      }
    }
  }
  return total;
}

void main() {
  group('providerImageLimitFor', () {
    test('recognises the Anthropic family', () {
      expect(providerImageLimitFor('anthropic'), 90);
      expect(providerImageLimitFor('Claude (OAuth)'), 90);
      expect(providerImageLimitFor('bedrock-us-east'), 90);
    });

    test('recognises the OpenAI and Google families', () {
      expect(providerImageLimitFor('openai'), 200);
      expect(providerImageLimitFor('OpenAI Codex'), 200);
      expect(providerImageLimitFor('google-gemini'), 200);
      expect(providerImageLimitFor('vertex'), 200);
    });

    test('an unknown provider gets the conservative floor', () {
      // A wrong-but-small guess costs visual history; a wrong-but-large one
      // costs the whole turn to a provider 400.
      expect(providerImageLimitFor('some-new-gateway'), 5);
      expect(providerImageLimitFor(null), 5);
      expect(providerImageLimitFor(''), 5);
    });
  });

  group('clampProviderContextImages', () {
    test('returns the same list when it already fits', () {
      final history = [_toolResult('a', 2), _toolResult('b', 1)];
      expect(identical(clampProviderContextImages(history, 10), history), true);
    });

    test('allocates nothing for a history with no images', () {
      final history = [
        HarnessMessage.user('hello'),
        _toolResult('a', 0, content: 'no picture here'),
      ];
      expect(identical(clampProviderContextImages(history, 0), history), true);
    });

    test('drops the OLDEST images first', () {
      final history = [
        _toolResult('old', 2),
        _toolResult('mid', 2),
        _toolResult('new', 2),
      ];
      final clamped = clampProviderContextImages(history, 2);

      expect(_countImages(clamped), 2);
      // The surviving frames must be the newest ones — the old frame is
      // scenery, the latest is what the agent is reasoning about.
      final surviving = <String>[];
      for (final m in clamped) {
        for (final b in m.content) {
          if (b is HarnessToolResultBlock) {
            surviving.addAll(b.images.map((i) => i.data));
          }
        }
      }
      expect(surviving, ['new-0', 'new-1']);
    });

    test('keeps the text of a result whose images were dropped', () {
      final history = [
        _toolResult('old', 1, content: 'clicked the login button'),
        _toolResult('new', 1),
      ];
      final clamped = clampProviderContextImages(history, 1);

      final first =
          clamped.first.content.whereType<HarnessToolResultBlock>().single;
      expect(first.images, isEmpty);
      expect(
        first.content,
        contains('clicked the login button'),
        reason: 'shedding a screenshot must not shed the narrative',
      );
      expect(
        first.content,
        contains(providerImageOmittedMarker),
        reason:
            'the model needs to tell "aged out" from "returned no screenshot"',
      );
    });

    test('an emptied result with no text becomes the marker alone', () {
      final history = [
        _toolResult('old', 1, content: '   '),
        _toolResult('new', 1),
      ];
      final clamped = clampProviderContextImages(history, 1);
      final first =
          clamped.first.content.whereType<HarnessToolResultBlock>().single;
      expect(first.content, providerImageOmittedMarker);
    });

    test('a dropped user-attached image leaves a note, not a gap', () {
      final history = [
        HarnessMessage(
          role: HarnessRole.user,
          content: [const HarnessTextBlock('what is wrong here?'), _img()],
        ),
        _toolResult('new', 1),
      ];
      final clamped = clampProviderContextImages(history, 1);

      expect(_countImages(clamped), 1);
      final texts = clamped.first.content
          .whereType<HarnessTextBlock>()
          .map((b) => b.text)
          .toList();
      expect(texts, contains('what is wrong here?'));
      expect(texts, contains(providerImageOmittedMarker));
    });

    test('a zero limit drops everything but keeps every message', () {
      final history = [_toolResult('a', 3), _toolResult('b', 2)];
      final clamped = clampProviderContextImages(history, 0);
      expect(_countImages(clamped), 0);
      expect(clamped.length, history.length);
    });

    test('untouched messages are reused, not rebuilt', () {
      final tail = _toolResult('new', 1);
      final history = [_toolResult('old', 3), tail];
      final clamped = clampProviderContextImages(history, 1);
      expect(
        identical(clamped.last, tail),
        true,
        reason: 'rebuilding an unchanged message churns the prompt cache',
      );
    });
  });
}
