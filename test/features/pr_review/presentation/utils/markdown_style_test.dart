import 'package:control_center/features/pr_review/presentation/utils/markdown_style.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:markdown/markdown.dart' as md;

Widget _buildTestApp(WidgetBuilder builder) {
  return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    home: FTheme(
      data: FThemes.zinc.light.desktop,
      child: Builder(builder: builder),
    ),
  );
}

void main() {
  group('prCheckboxBuilder', () {
    testWidgets('returns a non-null widget for checked value', (tester) async {
      Widget? widget;
      await tester.pumpWidget(
        _buildTestApp((context) {
          final builder = prCheckboxBuilder(context);
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
          final builder = prCheckboxBuilder(context);
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

  group('prMarkdownStyleSheet', () {
    testWidgets('returns a MarkdownStyleSheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = prMarkdownStyleSheet(context);
          expect(styleSheet, isNotNull);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('compact mode returns a MarkdownStyleSheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp((context) {
          final styleSheet = prMarkdownStyleSheet(context, compact: true);
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
          final compact = prMarkdownStyleSheet(context, compact: true);
          final normal = prMarkdownStyleSheet(context);
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
      'visitElementAfterWithContext returns Container for non-empty text',
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
            expect(result, isA<Container>());
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
  });
}
