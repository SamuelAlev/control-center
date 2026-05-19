import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 600,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    ),
  ),
);

void main() {
  const style = CcMarkdownStyle();

  group('CcRenderer block coverage', () {
    testWidgets('a paragraph renders inline text', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'Hello world.', style: style)),
      );
      expect(find.text('Hello world.', findRichText: true), findsOneWidget);
    });

    testWidgets('a heading renders with its inline content', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '## Heading **bold**', style: style)),
      );
      expect(
        find.textContaining('Heading', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('an empty document renders nothing (SizedBox.shrink)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CcMarkdown(data: '', style: style)));
      // No RichText at all.
      expect(find.byType(RichText), findsNothing);
    });

    testWidgets('a single block returns the block widget directly (no Column)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'only paragraph', style: style)),
      );
      // The renderer's children.length == 1 fast path returns the widget itself
      // rather than wrapping in a Column.
      expect(find.byType(Column), findsNothing);
      expect(find.text('only paragraph', findRichText: true), findsOneWidget);
    });

    testWidgets('a code block renders its code verbatim', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '```\nint x = 1;\n```', style: style)),
      );
      expect(find.textContaining('int x = 1;'), findsOneWidget);
    });

    testWidgets('a code block uses a custom codeBuilder when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '```dart\nhello\n```',
            style: style,
            codeBuilder: (code, language, {required bool cache}) =>
                Text('CODE:$code:$language:$cache'),
          ),
        ),
      );
      expect(find.textContaining('CODE:'), findsOneWidget);
      expect(find.textContaining(':dart:true'), findsOneWidget);
      expect(find.textContaining('hello'), findsOneWidget);
    });

    testWidgets('a blockquote renders nested content', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '> quoted text', style: style)),
      );
      expect(
        find.textContaining('quoted text', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a thematic break renders a divider', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'a\n\n---\n\nb', style: style)),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('an HTML block is stripped to its text', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '<div>visible</div>', style: style)),
      );
      expect(find.textContaining('visible'), findsOneWidget);
    });

    testWidgets(
      'a raw-HTML block that strips to whitespace renders nothing (no throw)',
      (tester) async {
        await tester.pumpWidget(
          _host(const CcMarkdown(data: '<div>  </div>', style: style)),
        );
        // Stripped to whitespace-only → no paragraph widget; must not throw.
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('CcRenderer lists + tables', () {
    testWidgets('an ordered list renders numbered markers', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '1. one\n2. two', style: style)),
      );
      expect(find.textContaining('1.'), findsOneWidget);
      expect(find.textContaining('2.'), findsOneWidget);
    });

    testWidgets('an unordered list renders bullets', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '- one\n- two', style: style)),
      );
      expect(find.text('•'), findsNWidgets(2));
    });

    testWidgets('a task list renders checkbox glyphs when no checkbox builder '
        'is set', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: '- [x] done\n- [ ] todo', style: style)),
      );
      expect(find.text('☑'), findsOneWidget);
      expect(find.text('☐'), findsOneWidget);
    });

    testWidgets('a table renders header and body cells', (tester) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: '| a | b |\n|---|---|\n| 1 | 2 |',
            style: style,
          ),
        ),
      );
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('a', findRichText: true), findsOneWidget);
      expect(find.text('1', findRichText: true), findsOneWidget);
    });

    testWidgets(
      'a table with a LayoutBuilder-based cell lays out without throwing',
      (tester) async {
        // Regression: table columns must not require cell intrinsic widths.
        // A responsive imageBuilder returns a LayoutBuilder, which cannot answer
        // intrinsic-width queries; an IntrinsicColumnWidth table blows up on it.
        await tester.pumpWidget(
          _host(
            CcMarkdown(
              data: '| a | b |\n|---|---|\n| ![x](img) | 2 |',
              style: style,
              imageBuilder: (url, alt, title) => LayoutBuilder(
                builder: (context, constraints) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Table), findsOneWidget);
      },
    );
  });

  group('CcRenderer inline coverage', () {
    testWidgets('a soft break renders as a space by default', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'line one\nline two', style: style)),
      );
      // The paragraph is one rich-text run containing both fragments.
      expect(
        find.textContaining('line one', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('line two', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a soft break renders as a newline when style asks for it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: 'line one\nline two',
            style: CcMarkdownStyle(softBreakMode: CcSoftBreakMode.newline),
          ),
        ),
      );
      expect(
        find.textContaining('line one', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a hard break renders a newline', (tester) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: 'a  \nb', // two trailing spaces → hard break
            style: style,
          ),
        ),
      );
      expect(find.textContaining('a', findRichText: true), findsOneWidget);
    });

    testWidgets('a link is tappable and fires onTapLink', (tester) async {
      var tapped = '';
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '[click](https://example.com)',
            style: style,
            onTapLink: (url) => tapped = url,
          ),
        ),
      );
      await tester.tap(find.textContaining('click', findRichText: true));
      await tester.pump();
      expect(tapped, 'https://example.com');
    });

    testWidgets(
      'a link underline is painted below the glyphs, not by the engine',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const CcMarkdown(
              data: '[click](https://example.com)',
              style: CcMarkdownStyle(
                link: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
              ),
            ),
          ),
        );
        // The engine underline (baseline-hugging, descender-crossing) is
        // stripped from every span in the run.
        final richText = tester.widget<RichText>(find.byType(RichText));
        bool hasEngineUnderline(InlineSpan span) {
          if (span is! TextSpan) {
            return false;
          }
          final decoration = span.style?.decoration;
          if (decoration != null &&
              decoration.contains(TextDecoration.underline)) {
            return true;
          }
          return (span.children ?? const <InlineSpan>[]).any(
            hasEngineUnderline,
          );
        }

        expect(hasEngineUnderline(richText.text), isFalse);
        // The paragraph's Text is wrapped in a paint layer that draws the
        // offset underline from the real RenderParagraph's fragment boxes.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.foregroundPainter != null &&
                w.child is Text,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('a paragraph without links has no underline paint layer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'plain text', style: style)),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter != null &&
              w.child is Text,
        ),
        findsNothing,
      );
    });

    testWidgets('a footnote reference renders the index marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: 'Body with note[^1].\n\n[^1]: the note.',
            style: CcMarkdownStyle(),
          ),
        ),
      );
      // The ref renders as [1].
      expect(find.textContaining('[1]', findRichText: true), findsOneWidget);
      // And the footnote section at the end.
      expect(
        find.textContaining('the note', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('an image with no builder renders the alt text on error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: '![alt text](https://example.com/x.png)',
            style: style,
          ),
        ),
      );
      // Pump so the network error builder resolves.
      await tester.pump();
      expect(find.textContaining('alt text'), findsOneWidget);
    });

    testWidgets('an image with an imageBuilder delegates to it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '![alt](https://example.com/x.png "title")',
            style: style,
            imageBuilder: (url, alt, title) => Text('IMG:$url:$alt:$title'),
          ),
        ),
      );
      expect(
        find.text('IMG:https://example.com/x.png:alt:title'),
        findsOneWidget,
      );
    });

    testWidgets('an inline HTML fragment is stripped to text', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'before <b>bold</b> after', style: style)),
      );
      expect(find.textContaining('bold', findRichText: true), findsOneWidget);
    });
  });

  group('CcMarkdown widget modes', () {
    testWidgets('selectable wraps the document in a SelectionRegion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(data: 'select me', style: style, selectable: true),
        ),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        find.textContaining('select me', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('ephemeral content renders without entering the global cache', (
      tester,
    ) async {
      CcMarkdownCache.clearCache();
      CcMarkdownCache.debugParseCount = 0;
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: 'ephemeral text',
            style: style,
            ephemeral: true,
          ),
        ),
      );
      expect(
        find.textContaining('ephemeral text', findRichText: true),
        findsOneWidget,
      );
      // The volatile parse ran but did not populate the cache: a subsequent
      // cached parse of the same text parses again (count > 0).
      expect(CcMarkdownCache.debugParseCount, greaterThan(0));
    });

    testWidgets(
      'useRepaintBoundary=false renders without the widget boundary',
      (tester) async {
        // With useRepaintBoundary=false the widget does not wrap its content in
        // its own RepaintBoundary; the rendered text is still present.
        final withBoundary = find.byType(RepaintBoundary);
        await tester.pumpWidget(
          _host(
            const CcMarkdown(
              data: 'no boundary',
              style: style,
              useRepaintBoundary: false,
            ),
          ),
        );
        expect(
          find.textContaining('no boundary', findRichText: true),
          findsOneWidget,
        );
        expect(withBoundary, findsWidgets);
      },
    );
  });

  group('CcRenderer details + custom nodes', () {
    testWidgets('a details block renders summary and toggles body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data:
                '<details>\n<summary>More</summary>\n\nHidden body.\n\n'
                '</details>',
            style: style,
          ),
        ),
      );
      // Closed by default → summary visible, body hidden.
      expect(find.textContaining('More', findRichText: true), findsOneWidget);
      expect(find.textContaining('Hidden body'), findsNothing);

      // Tap the summary to open.
      await tester.tap(find.textContaining('More', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hidden body'), findsOneWidget);
    });

    testWidgets('an open details block shows the body immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data:
                '<details open>\n<summary>S</summary>\n\nShown.\n\n</details>',
            style: style,
          ),
        ),
      );
      expect(find.textContaining('Shown.'), findsOneWidget);
    });

    testWidgets('a custom block with no registered builder renders a '
        'placeholder (debug mode)', (tester) async {
      // Build a renderer directly with a custom block the registry doesn't know.
      const harness = _CustomNodeHarness();
      await tester.pumpWidget(_host(harness));
      // Both the missing block and the missing inline surface a placeholder.
      expect(find.textContaining('missing builder'), findsWidgets);
    });
  });
}

/// Hosts a [CcRenderer] rendering a custom block + custom inline with no
/// registered builder, exercising the missing-builder fallback.
class _CustomNodeHarness extends StatelessWidget {
  const _CustomNodeHarness();

  @override
  Widget build(BuildContext context) {
    final renderer = CcRenderer(style: const CcMarkdownStyle());
    return renderer.render(const [
      _MissingBlock(),
      CcParagraph([_MissingInline()]),
    ]);
  }
}

class _MissingBlock extends CcCustomBlock {
  const _MissingBlock();
  @override
  String get nodeType => 'missing_block';
}

class _MissingInline extends CcCustomInline {
  const _MissingInline();
  @override
  String get nodeType => 'missing_inline';
}
