import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

HarnessImageBlock _img([String data = 'AAAA']) =>
    HarnessImageBlock(data: data, mediaType: 'image/png');

HarnessMessage _toolResult(String id, String content, {int images = 0}) =>
    HarnessMessage(
      role: HarnessRole.user,
      content: [
        HarnessToolResultBlock(
          toolUseId: id,
          content: content,
          images: [for (var i = 0; i < images; i++) _img('$id-$i')],
        ),
      ],
    );

int _imagesIn(List<HarnessMessage> messages) {
  var n = 0;
  for (final m in messages) {
    for (final b in m.content) {
      if (b is HarnessToolResultBlock) {
        n += b.images.length;
      } else if (b is HarnessImageBlock) {
        n++;
      }
    }
  }
  return n;
}

void main() {
  group('buildContextBreakdown', () {
    test('splits cost into actionable categories', () {
      final breakdown = buildContextBreakdown(
        history: [
          HarnessMessage.user('a question'),
          HarnessMessage.assistant('an answer'),
          _toolResult('t1', 'x' * 4000, images: 2),
        ],
        contextWindow: 100000,
        systemPrompt: 'y' * 400,
        toolSchemas: const [
          LlmToolSchema(
            name: 'read',
            description: 'reads',
            inputSchema: {'type': 'object'},
          ),
        ],
      );

      final byLabel = {
        for (final c in breakdown.categories) c.label.split(' (').first: c,
      };
      expect(byLabel['System prompt']!.tokens, greaterThan(0));
      expect(byLabel['Tool schemas']!.count, 1);
      expect(byLabel['Tool results']!.tokens, greaterThan(500));
      expect(byLabel['Images']!.count, 2);
      // Two images cost far more than the flat text estimate would suggest;
      // that is the whole reason they get their own line.
      expect(byLabel['Images']!.tokens, 2 * kImageTokenCost);
      expect(breakdown.totalTokens, greaterThan(0));
    });

    test('is sorted largest first, so the culprit is the first line', () {
      final breakdown = buildContextBreakdown(
        history: [_toolResult('t1', 'x' * 40000)],
        contextWindow: 100000,
      );
      final tokens = <int>[for (final c in breakdown.categories) c.tokens];
      final descending = <int>[...tokens]..sort((a, b) => b.compareTo(a));
      expect(tokens, orderedEquals(descending));
      expect(breakdown.categories.first.label, startsWith('Tool results'));
    });

    test('counts a summary separately from user text', () {
      final breakdown = buildContextBreakdown(
        history: [
          HarnessMessage.user('[conversation-summary] earlier work'),
          HarnessMessage.user('a real question'),
        ],
        contextWindow: 100000,
      );
      final byLabel = {for (final c in breakdown.categories) c.label: c};
      expect(byLabel['Summaries']!.tokens, greaterThan(0));
      expect(
        byLabel['User messages']!.count,
        1,
        reason: 'a summary is not something the user said',
      );
    });

    test('names how many results are already elided', () {
      final breakdown = buildContextBreakdown(
        history: [_toolResult('t1', elidedResultMarker)],
        contextWindow: 100000,
      );
      expect(
        breakdown.categories.any((c) => c.label.contains('already elided')),
        isTrue,
        reason: 'otherwise a second /shake looks like it should help',
      );
    });

    test('percent reflects the window', () {
      final breakdown = buildContextBreakdown(
        history: [HarnessMessage.user('x' * 3800)],
        contextWindow: 10000,
      );
      expect(breakdown.percent, greaterThan(5));
      expect(breakdown.render(), contains('%'));
    });

    test('an empty conversation is zero, not a crash', () {
      final breakdown = buildContextBreakdown(
        history: const [],
        contextWindow: 0,
      );
      expect(breakdown.totalTokens, 0);
      expect(breakdown.percent, 0);
    });
  });

  group('shakeHistory', () {
    List<HarnessMessage> conversation() => [
      HarnessMessage.user('first'),
      _toolResult('old', 'x' * 8000, images: 2),
      HarnessMessage.user('second'),
      _toolResult('mid', 'y' * 8000, images: 1),
      HarnessMessage.user('third'),
      _toolResult('new', 'z' * 8000, images: 1),
    ];

    test('elide blanks old tool results and keeps their call', () {
      final result = shakeHistory(conversation(), keepRecentTurns: 1);
      expect(result.toolResultsElided, greaterThan(0));
      expect(result.tokensReclaimed, greaterThan(1000));
      final blanked = result.messages
          .expand((m) => m.content)
          .whereType<HarnessToolResultBlock>()
          .where((b) => b.content == shakenResultMarker);
      expect(blanked, isNotEmpty);
      expect(
        result.messages.length,
        conversation().length,
        reason: 'blanked in place — removing the pair would break call/result '
            'pairing and provider replay',
      );
    });

    test('protects the most recent turns', () {
      final result = shakeHistory(conversation(), keepRecentTurns: 1);
      final last = result.messages.last.content
          .whereType<HarnessToolResultBlock>()
          .single;
      expect(
        last.content.startsWith('z'),
        isTrue,
        reason: 'the newest result is what the agent is reasoning about',
      );
    });

    test('images mode keeps every word', () {
      final result = shakeHistory(
        conversation(),
        mode: ShakeMode.images,
        keepRecentTurns: 1,
      );
      expect(result.toolResultsElided, 0);
      expect(result.imagesDropped, greaterThan(0));
      final texts = result.messages
          .expand((m) => m.content)
          .whereType<HarnessToolResultBlock>()
          .map((b) => b.content);
      expect(
        texts.every((t) => t != shakenResultMarker),
        isTrue,
        reason: 'images mode must not touch text',
      );
    });

    test('all mode drops both', () {
      final before = _imagesIn(conversation());
      final result = shakeHistory(
        conversation(),
        mode: ShakeMode.all,
        keepRecentTurns: 1,
      );
      expect(result.toolResultsElided, greaterThan(0));
      expect(_imagesIn(result.messages), lessThan(before));
    });

    test('skips results too small to be worth a placeholder', () {
      // Blanking a 20-token result to insert an 8-token marker churns the
      // prompt cache for nothing.
      final result = shakeHistory([
        HarnessMessage.user('a'),
        _toolResult('tiny', 'ok'),
        HarnessMessage.user('b'),
        HarnessMessage.user('c'),
      ], keepRecentTurns: 1);
      expect(result.toolResultsElided, 0);
      expect(result.isEmpty, isTrue);
      expect(result.render(), contains('Nothing to shake'));
    });

    test('never double-blanks an already-elided result', () {
      final result = shakeHistory([
        HarnessMessage.user('a'),
        _toolResult('x', elidedResultMarker),
        HarnessMessage.user('b'),
        HarnessMessage.user('c'),
      ], keepRecentTurns: 1, minTokens: 1);
      expect(result.toolResultsElided, 0);
    });

    test('a dropped user image leaves a marker, not a gap', () {
      final result = shakeHistory([
        HarnessMessage(
          role: HarnessRole.user,
          content: [const HarnessTextBlock('look at this'), _img()],
        ),
        HarnessMessage.user('b'),
        HarnessMessage.user('c'),
      ], mode: ShakeMode.images, keepRecentTurns: 1);
      expect(result.imagesDropped, 1);
      final texts = result.messages.first.content
          .whereType<HarnessTextBlock>()
          .map((b) => b.text);
      expect(texts, contains('look at this'));
      expect(texts, contains(shakenImageMarker));
    });

    test('untouched messages are reused, not rebuilt', () {
      final history = conversation();
      final result = shakeHistory(history, keepRecentTurns: 1);
      expect(
        identical(result.messages.first, history.first),
        isTrue,
        reason: 'rebuilding an unchanged message churns the prompt cache',
      );
    });

    test('render names what it did', () {
      final result = shakeHistory(conversation(), keepRecentTurns: 1);
      expect(result.render(), contains('tool result'));
      expect(result.render(), contains('tokens'));
    });
  });
}
