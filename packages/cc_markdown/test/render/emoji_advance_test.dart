import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_markdown/src/render/emoji_advance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 14);
  const scaler = TextScaler.noScaling;

  tearDown(() {
    debugEmojiTrailingGap = null;
    debugResetEmojiAdvanceCache();
  });

  TextSpan spanOf(String text) =>
      textSpansTighteningEmoji(text, style: style, textScaler: scaler).single;

  group('textSpansTighteningEmoji', () {
    test('prose without emoji stays one span', () {
      debugEmojiTrailingGap = (_, _) => 5;
      final span = spanOf('Agreed, feels right');
      expect(span.text, 'Agreed, feels right');
      expect(span.style, isNull);
    });

    test('a measured surplus pulls only the emoji run in', () {
      debugEmojiTrailingGap = (_, _) => 5;
      final spans = textSpansTighteningEmoji(
        'Agreed 😁 feel',
        style: style,
        textScaler: scaler,
      );
      expect(spans.map((s) => s.text).toList(), ['Agreed ', '😁', ' feel']);
      expect(spans[0].style, isNull);
      expect(spans[1].style?.letterSpacing, -5);
      expect(spans[2].style, isNull);
      expect(spans.map((s) => s.text).join(), 'Agreed 😁 feel');
    });

    test('a run of emoji shares one correction', () {
      debugEmojiTrailingGap = (_, _) => 4;
      final spans = textSpansTighteningEmoji(
        'go 😁👍 now',
        style: style,
        textScaler: scaler,
      );
      expect(spans.map((s) => s.text).toList(), ['go ', '😁👍', ' now']);
      expect(spans[1].style?.letterSpacing, -4);
    });

    test('a family sequence stays one cluster inside the run', () {
      debugEmojiTrailingGap = (_, _) => 4;
      const family = '👨‍👩‍👧‍👦';
      final spans = textSpansTighteningEmoji(
        'hi $family!',
        style: style,
        textScaler: scaler,
      );
      expect(spans.map((s) => s.text).toList(), ['hi ', family, '!']);
      expect(spans[1].style?.letterSpacing, -4);
    });

    test('a keycap is emoji, a check mark is not', () {
      debugEmojiTrailingGap = (_, _) => 3;
      final keycap = textSpansTighteningEmoji(
        'no 1️⃣',
        style: style,
        textScaler: scaler,
      );
      expect(keycap.last.text, '1️⃣');
      expect(keycap.last.style?.letterSpacing, -3);

      final mark = spanOf('done ✓');
      expect(mark.text, 'done ✓');
      expect(mark.style, isNull);
    });

    test('no surplus leaves the paragraph as one span', () {
      debugEmojiTrailingGap = (_, _) => 0;
      final span = spanOf('Agreed 😁 feel');
      expect(span.text, 'Agreed 😁 feel');
      expect(span.style, isNull);
    });
  });

  testWidgets('the test font reports no trailing surplus', (tester) async {
    expect(
      emojiTrailingGap(
        const TextStyle(
          fontSize: 14,
          fontFamilyFallback: ['Apple Color Emoji'],
        ),
        scaler,
      ),
      isNull,
    );
  });

  testWidgets('markdown wires the correction into the paragraph', (
    tester,
  ) async {
    debugEmojiTrailingGap = (_, _) => 5;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: Center(
            child: SizedBox(
              width: 600,
              child: CcMarkdown(data: 'Agreed 😁 feel'),
            ),
          ),
        ),
      ),
    );

    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('😁'),
      ),
    );
    TextSpan? emoji;
    void walk(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == '😁') {
          emoji = span;
        }
        span.children?.forEach(walk);
      }
    }

    walk(rich.text);
    expect(emoji?.style?.letterSpacing, -5);
    expect(rich.text.toPlainText(), 'Agreed 😁 feel');
  });
}
