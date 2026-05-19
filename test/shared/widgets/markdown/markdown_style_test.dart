import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(WidgetBuilder builder) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Builder(builder: builder),
    ),
  );
}

void main() {
  group('codeBlockHasLanguage', () {
    test('is false for null, empty and whitespace', () {
      expect(codeBlockHasLanguage(null), isFalse);
      expect(codeBlockHasLanguage(''), isFalse);
      expect(codeBlockHasLanguage('  '), isFalse);
    });

    test('is true for a real fence info-string', () {
      expect(codeBlockHasLanguage('dart'), isTrue);
      expect(codeBlockHasLanguage(' js '), isTrue);
    });
  });

  group('appMarkdownStyle', () {
    testWidgets('returns a CcMarkdownStyle with the checkbox hook wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final style = appMarkdownStyle(context);
          expect(style, isA<CcMarkdownStyle>());
          // Task-list checkbox hook is wired to the design-system checkbox.
          expect(style.checkbox, isNotNull);
          // Inline code carries the app mono font, no background color (the
          // chip background is drawn by the builder, not the text style).
          expect(style.inlineCode?.fontFamily, contains('Fira'));
          expect(style.inlineCode?.backgroundColor, isNull);
          return const SizedBox.shrink();
        }),
      );
    });

    // Regression: CcTypography carries no fontFamily (a `Text` picks it up from
    // the ambient DefaultTextStyle). A markdown style is handed to
    // RichText/TextSpan trees, which do NOT, so it must name the family. Worse,
    // a null fontFamily combined with `fontFamilyFallback` makes the FALLBACK
    // the primary font list — the emoji font then resolved the space glyph and
    // its wide advance blew every word gap open (text looked justified and
    // selection rects reported emoji metrics).
    testWidgets('every text style names a font family', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final style = appMarkdownStyle(context);
          final named = <String, TextStyle?>{
            'paragraph': style.paragraph,
            'h1': style.h1,
            'h2': style.h2,
            'h3': style.h3,
            'h4': style.h4,
            'h5': style.h5,
            'h6': style.h6,
            'link': style.link,
            'blockquote': style.blockquote,
            'listBullet': style.listBullet,
            'tableHead': style.tableHead,
            'tableBody': style.tableBody,
          };
          named.forEach((name, textStyle) {
            expect(
              textStyle?.fontFamily,
              isNotNull,
              reason:
                  '$name has no fontFamily; with fontFamilyFallback set the '
                  'emoji font becomes primary and spaces render far too wide',
            );
          });
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('compact mode shrinks the heading + body scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final normal = appMarkdownStyle(context);
          final compact = appMarkdownStyle(context, compact: true);
          expect(compact, isA<CcMarkdownStyle>());
          expect(
            compact.h1?.fontSize,
            lessThan(normal.h1?.fontSize ?? double.infinity),
          );
          expect(
            compact.paragraph?.fontSize ?? 0,
            lessThan(normal.paragraph?.fontSize ?? double.infinity),
          );
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('value equality holds for identical builds', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          expect(appMarkdownStyle(context), appMarkdownStyle(context));
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('buildSharedInlineCodeChip', () {
    testWidgets('renders the code text in a chip widget', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedInlineCodeChip('foo', const TextStyle()),
          );
        }),
      );
      expect(find.text('foo'), findsOneWidget);
    });
  });

  group('buildSharedCodeBlock', () {
    testWidgets('renders the language label and a scrollable body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(context, 'print("hi")', 'dart'),
          );
        }),
      );
      expect(find.text('dart'), findsOneWidget);
      expect(find.byKey(kCodeBlockHeaderKey), findsOneWidget);
      // Body is horizontally scrollable.
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('renders dart code tokenized into coloured spans', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(context, 'class A {}', 'dart'),
          );
        }),
      );
      final scroll = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .firstWhere((s) => s.child is Text);
      final span = (scroll.child! as Text).textSpan! as TextSpan;
      expect(span.style?.fontFamily, contains('Fira'));
      expect(span.children, isNotNull);
      expect(span.children!.length, greaterThan(1));
      final coloured = span.children!.whereType<TextSpan>().where(
        (s) => s.style?.color != null,
      );
      expect(coloured, isNotEmpty);
    });

    testWidgets('honours the supplied code font family', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(
              context,
              'const x = 1;',
              'javascript',
              codeFontFamily: 'Fira Code',
            ),
          );
        }),
      );
      final scroll = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .firstWhere((s) => s.child is Text);
      final span = (scroll.child! as Text).textSpan! as TextSpan;
      expect(span.style?.fontFamily, contains('Fira'));
    });

    testWidgets('omits the header row when no language is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(context, 'x = 1', null),
          );
        }),
      );
      expect(find.text('x = 1'), findsOneWidget);
      expect(find.byKey(kCodeBlockHeaderKey), findsNothing);
      // Copy stays available, overlaid on the body (GitHub unlabeled fence).
      expect(find.byType(CcIconButton), findsOneWidget);
    });

    testWidgets('a blank language string is treated as unlabeled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(context, 'x = 1', '  '),
          );
        }),
      );
      expect(find.byKey(kCodeBlockHeaderKey), findsNothing);
      expect(find.byType(CcIconButton), findsOneWidget);
    });

    testWidgets('unlabeled fences are shorter than labeled ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Column(
            children: [
              KeyedSubtree(
                key: const Key('labeled'),
                child: buildSharedCodeBlock(context, 'x = 1', 'python'),
              ),
              KeyedSubtree(
                key: const Key('unlabeled'),
                child: buildSharedCodeBlock(context, 'x = 1', null),
              ),
            ],
          );
        }),
      );
      final labeledHeight = tester
          .getSize(find.byKey(const Key('labeled')))
          .height;
      final unlabeledHeight = tester
          .getSize(find.byKey(const Key('unlabeled')))
          .height;
      expect(unlabeledHeight, lessThan(labeledHeight));
    });

    testWidgets('long blocks collapse behind a Show more / Show less toggle', (
      tester,
    ) async {
      final code = List.generate(
        kSharedCodeBlockCollapseThreshold + 10,
        (i) => 'line$i = $i',
      ).join('\n');
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              child: buildSharedCodeBlock(context, code, null),
            ),
          );
        }),
      );

      // Collapsed: only the leading lines render, behind a Show more toggle.
      expect(find.text('Show more'), findsOneWidget);
      expect(
        find.textContaining('line0 = 0', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'line${kSharedCodeBlockCollapseThreshold + 9}',
          findRichText: true,
        ),
        findsNothing,
      );

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      // Expanded: the tail is visible and the toggle flips to Show less.
      expect(find.text('Show less'), findsOneWidget);
      expect(
        find.textContaining(
          'line${kSharedCodeBlockCollapseThreshold + 9}',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.text('Show more'), findsOneWidget);
    });

    testWidgets('short blocks render fully with no toggle', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: buildSharedCodeBlock(context, 'a = 1\nb = 2', null),
          );
        }),
      );
      expect(find.text('Show more'), findsNothing);
      expect(find.text('Show less'), findsNothing);
    });
  });
}
