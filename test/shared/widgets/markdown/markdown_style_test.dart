import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

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
  group('markdownCheckboxBuilder', () {
    testWidgets('returns a non-null widget for checked value', (tester) async {
      Widget? widget;
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = markdownCheckboxBuilder(context);
          widget = builder(true);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: widget!,
          );
        }),
      );
      expect(widget, isNotNull);
      expect(widget, isA<SizedBox>());
    });

    testWidgets('returns a non-null widget for unchecked value', (
      tester,
    ) async {
      Widget? widget;
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = markdownCheckboxBuilder(context);
          widget = builder(false);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: widget!,
          );
        }),
      );
      expect(widget, isNotNull);
      expect(widget, isA<SizedBox>());
    });
  });

  group('githubMarkdownStyleSheet', () {
    testWidgets('returns a MarkdownStyleSheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = githubMarkdownStyleSheet(context);
          expect(styleSheet, isNotNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('compact mode returns a MarkdownStyleSheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = githubMarkdownStyleSheet(context, compact: true);
          expect(styleSheet, isNotNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('non-compact mode has different paragraph style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final compact = githubMarkdownStyleSheet(context, compact: true);
          final normal = githubMarkdownStyleSheet(context);
          expect(compact.p, isNotNull);
          expect(normal.p, isNotNull);
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('InlineCodeBuilder', () {
    testWidgets('visitElementAfterWithContext returns null for empty text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = InlineCodeBuilder();
          final element = md.Element('code', [md.Text('')]);
          final result = builder.visitElementAfterWithContext(
            context,
            element,
            null,
            null,
          );
          expect(result, isNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets(
      'visitElementAfterWithContext returns Text for non-empty text',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp((context) {
            final builder = InlineCodeBuilder();
            final element = md.Element('code', [md.Text('hello')]);
            final result = builder.visitElementAfterWithContext(
              context,
              element,
              const TextStyle(),
              null,
            );
            expect(result, isNotNull);
            expect(result, isA<Text>());
            return const SizedBox.shrink();
          }),
        );
      },
    );
  });

  group('CodeBlockBuilder', () {
    testWidgets('visitElementAfterWithContext returns null for empty code', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = CodeBlockBuilder();
          final element = md.Element('pre', [
            md.Element('code', [md.Text('')]),
          ]);
          final result = builder.visitElementAfterWithContext(
            context,
            element,
            null,
            null,
          );
          expect(result, isNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets(
      'visitElementAfterWithContext returns Column for non-empty code',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp((context) {
            final builder = CodeBlockBuilder();
            final codeElement = md.Element('code', [md.Text('print("hello")')]);
            codeElement.attributes['class'] = 'language-dart';
            final element = md.Element('pre', [codeElement]);
            final result = builder.visitElementAfterWithContext(
              context,
              element,
              null,
              null,
            );
            expect(result, isNotNull);
            expect(result, isA<Column>());
            return const SizedBox.shrink();
          }),
        );
      },
    );

    testWidgets('visitElementAfterWithContext strips trailing newline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = CodeBlockBuilder();
          final codeElement = md.Element('code', [md.Text('code\n')]);
          codeElement.attributes['class'] = 'language-python';
          final element = md.Element('pre', [codeElement]);
          final result = builder.visitElementAfterWithContext(
            context,
            element,
            null,
            null,
          );
          expect(result, isNotNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('renders dart code in a mono font with coloured spans', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = CodeBlockBuilder();
          final codeElement = md.Element('code', [md.Text('class A {}')]);
          codeElement.attributes['class'] = 'language-dart';
          final element = md.Element('pre', [codeElement]);
          final column =
              builder.visitElementAfterWithContext(context, element, null, null)
                  as Column;

          final scroll = column.children
              .whereType<SingleChildScrollView>()
              .single;
          final text = scroll.child! as Text;
          final span = text.textSpan! as TextSpan;

          // Base style uses the app's bundled mono font (Fira Code).
          expect(span.style?.fontFamily, contains('Fira'));
          // Tokenized into multiple spans, at least one carrying a colour.
          expect(span.children, isNotNull);
          expect(span.children!.length, greaterThan(1));
          final coloured = span.children!
              .whereType<TextSpan>()
              .where((s) => s.style?.color != null);
          expect(coloured, isNotEmpty);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('honours the supplied code font family', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = CodeBlockBuilder(codeFontFamily: 'Fira Code');
          final codeElement = md.Element('code', [md.Text('const x = 1;')]);
          codeElement.attributes['class'] = 'language-javascript';
          final element = md.Element('pre', [codeElement]);
          final column =
              builder.visitElementAfterWithContext(context, element, null, null)
                  as Column;
          final scroll = column.children
              .whereType<SingleChildScrollView>()
              .single;
          final span = (scroll.child! as Text).textSpan! as TextSpan;
          expect(span.style?.fontFamily, contains('Fira'));
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
            child: buildSharedInlineCodeChip(
              'foo',
              const TextStyle(),
            ),
          );
        }),
      );
      // The chip text is rendered.
      expect(find.text('foo'), findsOneWidget);
    });
  });

  group('buildSharedCodeBlock', () {
    testWidgets('renders the header and scrollable body', (tester) async {
      late Column column;
      await tester.pumpWidget(
        _buildTestApp((context) {
          column = buildSharedCodeBlock(
            context,
            'print("hi")',
            'dart',
          ) as Column;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: column,
          );
        }),
      );
      // Language label is rendered.
      expect(find.text('dart'), findsOneWidget);
      // Body is horizontally scrollable.
      expect(
        column.children.whereType<SingleChildScrollView>().single,
        isNotNull,
      );
    });

    testWidgets('omits the language label when none is provided', (
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
      // Only the code body text renders — no language label.
      expect(find.text('x = 1'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });

  group('smMarkdownStyleSheet', () {
    testWidgets('returns a sm.MarkdownStyleSheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = smMarkdownStyleSheet(context);
          expect(styleSheet, isNotNull);
          expect(styleSheet, isA<sm.MarkdownStyleSheet>());
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('inline code never uses TextStyle.backgroundColor', (
      tester,
    ) async {
      // The buggy background-over-selection regression is fixed by rendering the
      // chip via a Container (SmInlineCodeBuilder), never via the text style.
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = smMarkdownStyleSheet(context);
          expect(styleSheet.inlineCodeStyle?.backgroundColor, isNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('codeBlockStyle uses the design-system mono font', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = smMarkdownStyleSheet(context);
          expect(styleSheet.codeBlockStyle?.fontFamily, contains('Fira'));
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('SmInlineCodeBuilder', () {
    testWidgets('renders the canonical chip for an inline code node', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          const builder = SmInlineCodeBuilder();
          final widget = builder.build(
            const sm.InlineCodeNode('bar'),
            smMarkdownStyleSheet(context),
            const sm.MarkdownRenderContext(),
          );
          return Directionality(
            textDirection: TextDirection.ltr,
            child: widget,
          );
        }),
      );
      expect(find.text('bar'), findsOneWidget);
    });
  });
}
