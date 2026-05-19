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
  const style = CcMarkdownStyle();

  group('one Text.rich per paragraph (the hard contract)', () {
    testWidgets('a mixed-inline paragraph is a single rich text run', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(
            data: 'This has **bold** and *italic* and `code` together.',
            style: style,
          ),
        ),
      );
      // The whole paragraph text matches ONE RichText (findRichText).
      expect(
        find.text(
          'This has bold and italic and code together.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('an inline builder override embeds a WidgetSpan in the run', (
      tester,
    ) async {
      final builders = CcBuilderRegistry(const {'inline_code': _ChipBuilder()});
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: 'before `x` after',
            style: style,
            builders: builders,
          ),
        ),
      );
      // The chip renders...
      expect(find.text('[x]'), findsOneWidget);
      // ...and the surrounding prose is still one paragraph RichText.
      expect(find.textContaining('before', findRichText: true), findsOneWidget);
    });
  });

  group('core block rendering', () {
    testWidgets('code block routes through the codeBuilder with cache flag', (
      tester,
    ) async {
      String? seenLang;
      var seenCache = false;
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '```dart\nvoid main() {}\n```',
            style: style,
            codeBuilder: (code, language, {required bool cache}) {
              seenLang = language;
              seenCache = cache;
              return Text('CODE:$code');
            },
          ),
        ),
      );
      expect(seenLang, 'dart');
      expect(seenCache, isTrue);
      expect(find.text('CODE:void main() {}'), findsOneWidget);
    });

    testWidgets('task-list checkbox hook receives the checked state', (
      tester,
    ) async {
      final seen = <bool>[];
      final styled = style.copyWith(
        checkbox: (checked) {
          seen.add(checked);
          return Text(checked ? '[x]' : '[ ]');
        },
      );
      await tester.pumpWidget(
        _host(CcMarkdown(data: '- [x] done\n- [ ] todo', style: styled)),
      );
      expect(seen, containsAll(<bool>[true, false]));
    });

    testWidgets('footnotes render a definitions section after the content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CcMarkdown(data: 'Body[^1].\n\n[^1]: The note.', style: style),
        ),
      );
      expect(
        find.textContaining('The note', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('details renders summary and toggles the body', (tester) async {
      await tester.pumpWidget(
        _host(
          const MaterialApp(
            home: Scaffold(
              body: CcMarkdown(
                data:
                    '<details>\n<summary>Show</summary>\n\nHidden body.\n'
                    '\n</details>',
                style: style,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Show', findRichText: true), findsOneWidget);
      // Collapsed by default — body not shown.
      expect(
        find.textContaining('Hidden body', findRichText: true),
        findsNothing,
      );
      await tester.tap(find.textContaining('Show', findRichText: true));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Hidden body', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('builder overrides', () {
    testWidgets('canBuild fall-through: override claims some links, not others', (
      tester,
    ) async {
      final tapped = <String>[];
      final builders = CcBuilderRegistry(const {'link': _CcOnlyLinkBuilder()});
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '[app](control-center://x) and [web](https://ex.dev)',
            style: style,
            builders: builders,
            onTapLink: tapped.add,
          ),
        ),
      );
      // The control-center link was claimed by the override (custom chip text).
      expect(find.text('APPCHIP'), findsOneWidget);
      // The web link fell through to the default renderer (still in the run).
      expect(find.textContaining('web', findRichText: true), findsOneWidget);
    });

    testWidgets('an unregistered custom node shows the debug missing marker', (
      tester,
    ) async {
      final builders = CcBuilderRegistry(const {});
      final plugins = CcPluginSet(const [_WidgetlessBlockPlugin()]);
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '@@custom\n',
            style: style,
            plugins: plugins,
            builders: builders,
          ),
        ),
      );
      expect(find.textContaining('missing builder'), findsOneWidget);
    });
  });
}

class _ChipBuilder extends CcNodeBuilder {
  const _ChipBuilder();
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      Text('[${(node as CcInlineCode).code}]');
}

class _CcOnlyLinkBuilder extends CcNodeBuilder {
  const _CcOnlyLinkBuilder();
  @override
  bool canBuild(CcNode node) =>
      node is CcLink && node.url.startsWith('control-center://');
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      const Text('APPCHIP');
}

/// A block node with no registered builder, to exercise the missing-builder
/// debug fallback.
class _CustomNode extends CcCustomBlock {
  const _CustomNode();
  @override
  String get nodeType => 'widgetless';
  @override
  bool operator ==(Object other) => other is _CustomNode;
  @override
  int get hashCode => nodeType.hashCode;
}

class _WidgetlessBlockPlugin extends CcBlockPlugin {
  const _WidgetlessBlockPlugin();
  @override
  String get id => 'widgetless';
  @override
  bool canParse(String line, List<String> lines, int index) =>
      line.startsWith('@@custom');
  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) =>
      const CcBlockParseResult(_CustomNode(), 1);
}
