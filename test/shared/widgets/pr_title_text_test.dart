import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('hasInlineCode', () {
    test('detects a balanced backtick pair', () {
      expect(hasInlineCode('fix `parser` crash'), isTrue);
    });

    test('is false for plain text', () {
      expect(hasInlineCode('no code here'), isFalse);
    });

    test('is false for a lone backtick', () {
      expect(hasInlineCode('an unbalanced ` tick'), isFalse);
    });

    test('is false for an empty backtick pair', () {
      expect(hasInlineCode('empty `` pair'), isFalse);
    });
  });

  group('stripInlineCode', () {
    test('removes the delimiters but keeps the code', () {
      expect(stripInlineCode('fix `parser` crash'), 'fix parser crash');
    });

    test('handles multiple runs', () {
      expect(stripInlineCode('`a` then `b`'), 'a then b');
    });

    test('leaves plain text untouched', () {
      expect(stripInlineCode('no code here'), 'no code here');
    });
  });

  group('PrTitleText', () {
    testWidgets('renders a plain title verbatim', (tester) async {
      await tester.pumpWidget(_wrap(const PrTitleText('Simple title')));

      expect(find.text('Simple title'), findsOneWidget);
    });

    testWidgets('renders the code run without backticks', (tester) async {
      await tester.pumpWidget(_wrap(const PrTitleText('Fix `parser` crash')));

      // The inner code chip renders the code content on its own...
      expect(find.text('parser'), findsOneWidget);
      // ...and no rendered text retains a literal backtick.
      expect(find.textContaining('`'), findsNothing);
      // The unparsed literal title is never shown as a single run.
      expect(find.text('Fix `parser` crash'), findsNothing);
    });

    testWidgets('wraps the code run in a styled chip container', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PrTitleText('use `Foo`')));

      final chip = tester.widget<Container>(
        find.ancestor(of: find.text('Foo'), matching: find.byType(Container)),
      );
      expect(chip.decoration, isA<BoxDecoration>());
    });

    testWidgets('fills the chip with the shared translucent code wash', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PrTitleText('use `Foo`')));

      final chip = tester.widget<Container>(
        find.ancestor(of: find.text('Foo'), matching: find.byType(Container)),
      );
      final fill = (chip.decoration! as BoxDecoration).color!;
      final tokens = DesignSystemTokens.light();

      // Shares the one wash with markdown inline code — never the canvas
      // colour, which is invisible on the white data panel.
      expect(fill, tokens.hoverStrong);
      expect(fill, isNot(tokens.bgSecondary));
      // Translucent, so it steps relative to whatever ground it lands on
      // (white panel, canvas, hovered row, chat bubble).
      expect(fill.a, lessThan(1.0));
    });

    testWidgets('sits the code chip on the surrounding text baseline', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PrTitleText('use `Foo` here')));

      final span = tester.widget<Text>(find.byType(Text).first).textSpan!;
      final chips = <WidgetSpan>[];
      span.visitChildren((child) {
        if (child is WidgetSpan) {
          chips.add(child);
        }
        return true;
      });

      expect(chips, hasLength(1));
      // `middle` would centre the (shorter) chip box on the text's vertical
      // midpoint and lift the code glyphs off the baseline.
      expect(chips.single.alignment, PlaceholderAlignment.baseline);
      expect(chips.single.baseline, TextBaseline.alphabetic);
    });

    testWidgets('does not grow the line box past a plain title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 400,
            child: Column(
              children: [
                PrTitleText('use Foo here', key: Key('plain')),
                PrTitleText('use `Foo` here', key: Key('coded')),
              ],
            ),
          ),
        ),
      );

      final plain = tester.getSize(find.byKey(const Key('plain')));
      final coded = tester.getSize(find.byKey(const Key('coded')));
      expect(coded.height, plain.height);
    });

    testWidgets('prepends a leading prefix', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrTitleText('Title', leading: [TextSpan(text: '#42 ')])),
      );

      expect(find.text('#42 Title'), findsOneWidget);
    });
  });
}
