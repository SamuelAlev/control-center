import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      expect(chip.padding, kInlineCodeChipPadding);
      expect(chip.decoration, isA<BoxDecoration>());
      expect(
        (chip.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(kInlineCodeChipRadius),
      );
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

    testWidgets('pads ellipsized inline code like a markdown chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 400,
            child: PrTitleText(
              'feat: support `ffy` env',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      // The whole title stays one string (backticks stripped) and the code
      // run is its own chip, not a background painted on the glyphs.
      expect(find.text('feat: support ffy env'), findsOneWidget);
      final code = tester.widget<Text>(find.text('ffy'));
      expect(code.style?.backgroundColor, isNull);
      expect(code.style?.fontFamily, AppFonts.codeFamily);
      expect(code.style?.fontWeight, CcTypography.regularWeight);

      final chip = tester.widget<Container>(
        find.ancestor(of: find.text('ffy'), matching: find.byType(Container)),
      );
      expect(chip.padding, kInlineCodeChipPadding);
      final decoration = chip.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(kInlineCodeChipRadius),
      );
      expect(decoration.color, DesignSystemTokens.light().hoverStrong);
    });

    testWidgets('keeps markdown chip padding in an RTL title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CcTheme(
              data: CcThemeData.light(),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 400,
                    child: PrTitleText(
                      'feat: support `ffy` env',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final chip = tester.widget<Container>(
        find.ancestor(of: find.text('ffy'), matching: find.byType(Container)),
      );
      expect(chip.padding, kInlineCodeChipPadding);
      expect(find.text('feat: support ffy env'), findsOneWidget);
    });

    testWidgets('keeps a leading prefix on an ellipsized coded title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 400,
            child: PrTitleText(
              'use `Foo`',
              leading: [TextSpan(text: '#42 ')],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      expect(find.text('#42 use Foo'), findsOneWidget);
      expect(find.text('Foo'), findsOneWidget);
    });

    testWidgets('keeps a padded chip when an ellipsized title overflows', (
      tester,
    ) async {
      // A long unbreakable code run used to inflate its placeholder to the
      // line's full max width. Ellipsis then dropped the placeholder (null
      // paint offset) and left "refactor: migrate …" followed by dead space.
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 400,
            child: PrTitleText(
              'refactor: migrate `setDocumentTitleByViewTranslationKey` to metadata',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('refactor: migrate'), findsOneWidget);
      expect(find.textContaining('metadata'), findsNothing);

      final chip = find.ancestor(
        of: find.text('setDocumentTitleByViewTranslationKey'),
        matching: find.byType(Container),
      );
      expect(chip, findsOneWidget);
      expect(tester.widget<Container>(chip).padding, kInlineCodeChipPadding);

      final paragraph = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(PrTitleText),
              matching: find.byType(RichText),
            )
            .first,
      );
      final chipBox = paragraph.firstChild!;
      final offset = (chipBox.parentData! as TextParentData).offset;
      expect(offset, isNotNull);
      // The chip sits after the prefix and does not consume the whole line.
      expect(offset!.dx, greaterThan(8));
      expect(chipBox.size.width, lessThan(paragraph.size.width - 8));
      expect(paragraph.size.width, lessThanOrEqualTo(400));
    });

    testWidgets('keeps code at the regular weight inside a semibold title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PrTitleText(
            'cleanup `LIQUID_TO_DASHBOARD_GUIDELINES`',
            style: CcTypography.title.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      );

      final code = tester.widget<Text>(
        find.text('LIQUID_TO_DASHBOARD_GUIDELINES'),
      );
      expect(code.style?.fontWeight, CcTypography.regularWeight);
      expect(code.style?.fontFamily, AppFonts.codeFamily);
    });

    testWidgets('keeps widget chips when not ellipsizing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: PrTitleText(
              'migrate `setDocumentTitleByViewTranslationKey` now',
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      );

      final span = tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byType(PrTitleText),
                  matching: find.byType(Text),
                )
                .first,
          )
          .textSpan!;
      final chips = <WidgetSpan>[];
      span.visitChildren((child) {
        if (child is WidgetSpan) {
          chips.add(child);
        }
        return true;
      });
      expect(chips, hasLength(1));
    });
  });
}
