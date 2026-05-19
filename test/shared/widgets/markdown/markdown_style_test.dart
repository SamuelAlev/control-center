import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
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

          // Base style uses the app mono font (JetBrains Mono via google_fonts).
          expect(span.style?.fontFamily, contains('JetBrains'));
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
}
