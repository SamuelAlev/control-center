import 'package:control_center/features/messaging/presentation/widgets/feed/feed_text_measure.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const TextStyle _body = TextStyle(fontSize: 14, height: 1.6);
const TextStyle _code = TextStyle(fontSize: 12, height: 1.5);

/// Line height of [_code] (12 × 1.5).
const double _codeLine = 18;

FeedTextMeasurer _measurer({TextScaler textScaler = TextScaler.noScaling}) =>
    FeedTextMeasurer(
      textScaler: textScaler,
      bodyStyle: _body,
      codeStyle: _code,
    );

String _words(int count) => List.filled(count, 'word').join(' ');

String _fence(int lines, {String language = '', int width = 40}) {
  final line = 'x' * width;
  return '```$language\n${List.filled(lines, line).join('\n')}\n```';
}

/// Chat-like filler: paragraphs, a list and the odd fence, repeated.
String _transcript(int targetChars) {
  const unit =
      'The quick **brown** fox jumps over the [lazy](https://example.com) '
      'dog, then `inspects` the result and writes it down.\n\n'
      '- first point about the change\n'
      '- second point, a little longer than the first one\n\n'
      '```dart\nfinal x = 1;\nfinal y = 2;\n```\n\n';
  final buffer = StringBuffer();
  while (buffer.length < targetChars) {
    buffer.write(unit);
  }
  return buffer.toString();
}

void main() {
  testWidgets('empty or blank input measures 0', (tester) async {
    final m = _measurer();
    expect(m.proseHeight('', 400), 0);
    expect(m.proseHeight('   \n\n  \n', 400), 0);
    expect(m.plainTextHeight('', 400), 0);
    // A degenerate width must not throw either.
    expect(m.proseHeight('hello', 0), greaterThan(0));
    expect(m.proseHeight('hello', -20), greaterThan(0));
  });

  testWidgets('height grows monotonically with content', (tester) async {
    final m = _measurer();
    var previous = 0.0;
    for (var n = 1; n <= 400; n += 13) {
      final height = m.proseHeight(_words(n), 300);
      expect(height, greaterThanOrEqualTo(previous), reason: '$n words');
      previous = height;
    }
    expect(
      m.proseHeight(_words(400), 300),
      greaterThan(m.proseHeight(_words(1), 300)),
    );

    // More paragraphs, more height (block spacing included).
    final one = m.proseHeight('Alpha', 300);
    final two = m.proseHeight('Alpha\n\nBeta', 300);
    expect(two, closeTo(2 * one + 10, 0.01));
  });

  testWidgets('a narrower column is taller', (tester) async {
    final m = _measurer();
    final text = _words(120);
    final wide = m.proseHeight(text, 800);
    final medium = m.proseHeight(text, 400);
    final narrow = m.proseHeight(text, 160);
    expect(medium, greaterThan(wide));
    expect(narrow, greaterThan(medium));
  });

  testWidgets('soft line breaks render as lines', (tester) async {
    final m = _measurer();
    final oneLine = m.proseHeight('a', 400);
    expect(m.proseHeight('a\nb\nc', 400), closeTo(3 * oneLine, 0.01));
  });

  testWidgets('inline markers and link targets do not add width', (
    tester,
  ) async {
    final m = _measurer();
    // At this width the bare words fit one line; the raw markdown would not.
    const plain = 'see docs here now';
    const marked =
        'see **[docs](https://example.com/a/very/long/path/that/would/wrap)** '
        '`here` __now__';
    const width = 260.0;
    expect(m.proseHeight(plain, width), m.plainTextHeight(plain, 1000));
    expect(m.proseHeight(marked, width), m.proseHeight(plain, width));
  });

  testWidgets('a code fence adds chrome and never wraps', (tester) async {
    final m = _measurer();
    final chrome = kCodeBlockContentPadding.vertical + 2;
    final header = kCodeBlockHeaderPadding.vertical + 32 + 1;

    final unlabeled = _fence(10, width: 400);
    expect(
      m.proseHeight(unlabeled, 200),
      closeTo(10 * _codeLine + chrome, 0.01),
    );
    // Long lines scroll sideways: width does not change the height.
    expect(m.proseHeight(unlabeled, 80), m.proseHeight(unlabeled, 900));

    final labeled = _fence(10, language: 'dart', width: 400);
    expect(
      m.proseHeight(labeled, 200),
      closeTo(10 * _codeLine + chrome + header, 0.01),
    );

    // The same characters as prose wrap into far more height.
    final prose = List.filled(10, 'x' * 400).join('\n');
    expect(
      m.proseHeight(prose, 200),
      greaterThan(m.proseHeight(unlabeled, 200) * 3),
    );

    // A one-line fence is still taller than one line of prose.
    expect(m.proseHeight(_fence(1), 400), greaterThan(m.proseHeight('x', 400)));
  });

  testWidgets('a long fence collapses like the shared code block', (
    tester,
  ) async {
    final m = _measurer();
    final collapsed = m.proseHeight(_fence(25), 400);
    // 16 visible lines plus the "Show more" row, however long the fence.
    expect(m.proseHeight(_fence(400), 400), collapsed);
    expect(collapsed, lessThan(m.proseHeight(_fence(24), 400) + 40));
    expect(collapsed, greaterThan(m.proseHeight(_fence(16), 400)));
  });

  testWidgets('headings, lists, quotes and tables measure as blocks', (
    tester,
  ) async {
    final m = _measurer();
    const width = 300.0;
    final line = m.proseHeight('Title', width);

    // A heading is bigger type plus top padding.
    expect(m.proseHeight('# Title', width), greaterThan(line));
    expect(
      m.proseHeight('# Title', width),
      greaterThan(m.proseHeight('### Title', width)),
    );
    // `#hashtag` is a paragraph, not a heading.
    expect(m.proseHeight('#Title', width), m.proseHeight('Title#', width));

    // A list item wraps in the indented column, so it runs taller.
    // At 280px four test-font words fit a line; the 28px marker column
    // leaves room for three.
    final long = _words(60);
    expect(
      m.proseHeight('- $long', 280),
      greaterThan(m.proseHeight(long, 280)),
    );
    // Three tight items: three lines and two small gaps.
    expect(
      m.proseHeight('- a\n- b\n- c', width),
      closeTo(3 * line + 2 * 4, 0.01),
    );
    // A loose list spaces items like blocks.
    expect(m.proseHeight('- a\n\n- b', width), closeTo(2 * line + 10, 0.01));

    // A quote is inset and padded.
    expect(m.proseHeight('> Title', width), closeTo(line + 4, 0.01));

    // A table: one row per line, the separator row draws nothing.
    final table = m.proseHeight('| a | b |\n|---|---|\n| c | d |', width);
    expect(table, closeTo(2 * (line + 12), 0.01));

    // A thematic break is a thin rule, not a line of text.
    expect(m.proseHeight('---', width), lessThan(line));
  });

  testWidgets('text scaling grows prose but not chrome', (tester) async {
    final plain = _measurer();
    final scaled = _measurer(textScaler: const TextScaler.linear(2));
    // Within a pixel or so: the engine rounds line metrics per scale.
    expect(
      scaled.proseHeight('Hello there', 800),
      closeTo(plain.proseHeight('Hello there', 800) * 2, 1.5),
    );
    final chrome = kCodeBlockContentPadding.vertical + 2;
    expect(
      scaled.proseHeight(_fence(4), 800),
      closeTo(4 * _codeLine * 2 + chrome, 4),
    );
  });

  testWidgets('huge input finishes fast and scales linearly', (tester) async {
    final m = _measurer();
    // Warm the text engine so the timing below measures the measurer.
    m.proseHeight(_transcript(4000), 500);

    final big = _transcript(1000000);
    final stopwatch = Stopwatch()..start();
    final height = m.proseHeight(big, 500);
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(50));

    final bigger = _transcript(2000000);
    final ratio = m.proseHeight(bigger, 500) / height;
    expect(ratio, closeTo(bigger.length / big.length, 0.05));

    // Below the budget the measurement is exact, and it agrees with the
    // extrapolation per character.
    final small = _transcript(10000);
    final perChar = m.proseHeight(small, 500) / small.length;
    expect(height / big.length, closeTo(perChar, perChar * 0.05));

    // One giant line with no breaks at all is bounded too.
    final line = 'word ' * 200000;
    final lineWatch = Stopwatch()..start();
    expect(m.proseHeight(line, 500), greaterThan(0));
    expect(lineWatch.elapsedMilliseconds, lessThan(50));
  });

  testWidgets('of(context) resolves the chat styles', (tester) async {
    late FeedTextMeasurer measurer;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) {
              measurer = FeedTextMeasurer.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(measurer.textDirection, TextDirection.rtl);
    expect(measurer.textScaler, const TextScaler.linear(1.5));
    expect(measurer.bodyStyle.fontSize, 14);
    expect(measurer.bodyStyle.height, 1.6);
    expect(measurer.blockSpacing, 10);
    expect(measurer.listIndent, 28);
    expect(measurer.proseHeight('# Hello\n\nWorld', 300), greaterThan(0));
  });
}
