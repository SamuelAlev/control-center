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

    testWidgets('wraps the code run in a styled chip container', (tester) async {
      await tester.pumpWidget(_wrap(const PrTitleText('use `Foo`')));

      final chip = tester.widget<Container>(
        find.ancestor(
          of: find.text('Foo'),
          matching: find.byType(Container),
        ),
      );
      expect(chip.decoration, isA<BoxDecoration>());
    });

    testWidgets('prepends a leading prefix', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrTitleText(
            'Title',
            leading: [TextSpan(text: '#42 ')],
          ),
        ),
      );

      expect(find.text('#42 Title'), findsOneWidget);
    });
  });
}
