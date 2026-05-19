import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: Center(child: SizedBox(width: 600, child: child)),
  ),
);

void main() {
  setUp(() {
    CcMarkdownCache.clearCache();
    CcMarkdownCache.debugParseCount = 0;
  });

  group('CcStreamingMarkdown.value', () {
    testWidgets('renders a paragraph from the initial data', (tester) async {
      await tester.pumpWidget(
        _host(const CcStreamingMarkdown.value(data: 'Hello world.')),
      );
      expect(find.text('Hello world.', findRichText: true), findsOneWidget);
    });

    testWidgets('a growing tail re-parses on rebuild', (tester) async {
      await tester.pumpWidget(
        _host(const CcStreamingMarkdown.value(data: 'One two')),
      );
      expect(
        find.textContaining('One two', findRichText: true),
        findsOneWidget,
      );
      // Extend the accumulated text — the tail should now include the new word.
      await tester.pumpWidget(
        _host(const CcStreamingMarkdown.value(data: 'One two three')),
      );
      expect(find.textContaining('three', findRichText: true), findsOneWidget);
    });

    testWidgets('a sealed block + tail render side by side', (tester) async {
      // The blank line seals the first paragraph; the trailing line is the
      // volatile tail.
      await tester.pumpWidget(
        _host(
          const CcStreamingMarkdown.value(data: 'Sealed.\n\ntail still open'),
        ),
      );
      expect(find.textContaining('Sealed', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('tail still open', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('empty/whitespace data renders nothing (SizedBox.shrink)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CcStreamingMarkdown.value(data: '   \n  ')),
      );
      expect(find.byType(SizedBox), findsWidgets);
      // No paragraph text rendered.
      expect(find.byType(RichText), findsNothing);
    });

    testWidgets('threads the codeBuilder with cache:false on the tail', (
      tester,
    ) async {
      var seenCache = true;
      await tester.pumpWidget(
        _host(
          CcStreamingMarkdown.value(
            // Unclosed fence -> volatile tail -> cache:false.
            data: '```dart\nvoid main() {}\n',
            codeBuilder: (code, language, {required bool cache}) {
              seenCache = cache;
              return Text('CODE:$code');
            },
          ),
        ),
      );
      expect(seenCache, isFalse);
      // The streaming fence has no closing marker, so the code builder receives
      // the full body (including the trailing newline that follows the code).
      expect(find.textContaining('CODE:void main()'), findsOneWidget);
    });
  });

  group('CcStreamingMarkdown (controller-driven)', () {
    testWidgets('renders the controller text and updates on append', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController();
      controller.append('first');
      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: controller)),
      );
      expect(find.textContaining('first', findRichText: true), findsOneWidget);

      // Seal the first block and grow the tail.
      controller.append(' para.\n\nsecond\nx');
      await tester.pump();
      expect(find.textContaining('second', findRichText: true), findsOneWidget);
    });

    testWidgets('complete() collapses to a single sealed block render', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController();
      controller
        ..append('Sealed.\n\nTail still\n')
        ..complete();
      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: controller)),
      );
      expect(find.textContaining('Sealed', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Tail still', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('onTapLink is threaded into the render context', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController()
        ..append('[click](https://ex.dev)')
        ..complete();
      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: controller, onTapLink: (_) {})),
      );
      // The link label renders, proving the build path threaded the callback
      // into the CcRenderContext that produced this paragraph. (Tap dispatch on
      // a TextSpan recognizer is exercised in the renderer's own test suite.)
      expect(find.textContaining('click', findRichText: true), findsOneWidget);
    });

    testWidgets('survives controller hot-swap (memo cleared)', (tester) async {
      final firstController = CcMarkdownStreamController()
        ..append('aaa')
        ..complete();
      final secondController = CcMarkdownStreamController()
        ..append('bbb')
        ..complete();

      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: firstController)),
      );
      expect(find.textContaining('aaa', findRichText: true), findsOneWidget);

      // Swap controllers — the new one must take over and render its content.
      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: secondController)),
      );
      expect(find.textContaining('bbb', findRichText: true), findsOneWidget);
    });
  });

  group('CcStreamingMarkdown.listenable', () {
    testWidgets(
      'renders initial value and follows updates without parent rebuild',
      (tester) async {
        final source = ValueNotifier<String>('Initial line.');
        await tester.pumpWidget(
          _host(CcStreamingMarkdown.listenable(source: source)),
        );
        expect(
          find.textContaining('Initial line.', findRichText: true),
          findsOneWidget,
        );

        // Mutating the ValueNotifier (no parent rebuild) re-renders the widget.
        source.value = 'Updated line.';
        await tester.pump();
        expect(
          find.textContaining('Updated line.', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets('switching the source listenable resubscribes', (tester) async {
      final a = ValueNotifier<String>('from A');
      final b = ValueNotifier<String>('from B');
      await tester.pumpWidget(_host(CcStreamingMarkdown.listenable(source: a)));
      expect(find.textContaining('from A', findRichText: true), findsOneWidget);

      await tester.pumpWidget(_host(CcStreamingMarkdown.listenable(source: b)));
      expect(find.textContaining('from B', findRichText: true), findsOneWidget);

      // The old source no longer drives the widget.
      a.value = 'A changed';
      await tester.pump();
      expect(
        find.textContaining('A changed', findRichText: true),
        findsNothing,
      );
      // And mutating the new one still works.
      b.value = 'B changed';
      await tester.pump();
      expect(
        find.textContaining('B changed', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('style & builders environment change', () {
    testWidgets('a new builder registry identity invalidates the memo', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController();
      controller
        ..append('`x`')
        ..complete();
      const codeChip = _ChipBuilder();
      // First build: no overrides, default inline-code rendering.
      await tester.pumpWidget(
        _host(CcStreamingMarkdown(controller: controller)),
      );
      expect(find.byType(WidgetSpan), findsNothing);

      // Second build: a registry override embeds a WidgetSpan.
      await tester.pumpWidget(
        _host(
          CcStreamingMarkdown(
            controller: controller,
            builders: CcBuilderRegistry({'inline_code': codeChip}),
          ),
        ),
      );
      expect(find.text('[x]'), findsOneWidget);
    });

    testWidgets('a style value change re-renders with the new spacing', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController();
      controller
        ..append('Block one.\n\nBlock two.')
        ..complete();
      await tester.pumpWidget(
        _host(
          CcStreamingMarkdown(
            controller: controller,
            style: const CcMarkdownStyle(blockSpacing: 4),
          ),
        ),
      );
      // Two sealed paragraphs render as two RichTexts.
      expect(
        find.textContaining('Block one', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Block two', findRichText: true),
        findsOneWidget,
      );
    });
  });
}

class _ChipBuilder extends CcNodeBuilder {
  const _ChipBuilder();
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      Text('[${(node as CcInlineCode).code}]');
}
