import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

    testWidgets('buildSpan embeds a TextSpan instead of a WidgetSpan', (
      tester,
    ) async {
      final builders = CcBuilderRegistry(const {
        'inline_code': _SpanCodeBuilder(),
      });
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: 'before `x` after',
            style: style,
            builders: builders,
          ),
        ),
      );
      expect(find.byType(RichText), findsOneWidget);
      expect(find.text('[x]'), findsNothing);
      expect(find.text('before x after', findRichText: true), findsOneWidget);
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
        checkbox: (checked, {onChanged}) {
          seen.add(checked);
          return Text(checked ? '[x]' : '[ ]');
        },
      );
      await tester.pumpWidget(
        _host(CcMarkdown(data: '- [x] done\n- [ ] todo', style: styled)),
      );
      expect(seen, containsAll(<bool>[true, false]));
    });

    testWidgets('tapping a task-list checkbox reports document-order index', (
      tester,
    ) async {
      final toggled = <(int, bool)>[];
      final styled = style.copyWith(
        checkbox: (checked, {onChanged}) {
          return GestureDetector(
            onTap: onChanged == null ? null : () => onChanged(!checked),
            child: Text(checked ? 'checked' : 'unchecked'),
          );
        },
      );
      await tester.pumpWidget(
        _host(
          CcMarkdown(
            data: '- [ ] first\n- [x] second',
            style: styled,
            onTaskCheckboxChanged: (index, checked) =>
                toggled.add((index, checked)),
          ),
        ),
      );
      await tester.tap(find.text('unchecked'));
      await tester.tap(find.text('checked'));
      expect(toggled, [(0, true), (1, false)]);
    });

    testWidgets('tapping still works when the document is selectable', (
      tester,
    ) async {
      final toggled = <(int, bool)>[];
      final styled = style.copyWith(
        checkbox: (checked, {onChanged}) {
          return GestureDetector(
            onTap: onChanged == null ? null : () => onChanged(!checked),
            child: Text(checked ? 'checked' : 'unchecked'),
          );
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 600,
                child: CcMarkdown(
                  data: '- [ ] first\n- [x] second',
                  style: styled,
                  selectable: true,
                  onTaskCheckboxChanged: (index, checked) =>
                      toggled.add((index, checked)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('unchecked'));
      await tester.tap(find.text('checked'));
      expect(toggled, [(0, true), (1, false)]);
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

  group('CcMarkdown render memo', () {
    testWidgets('a rebuild with unchanged inputs does not re-render', (
      tester,
    ) async {
      var codeRenders = 0;
      Widget code(String code, String? language, {required bool cache}) {
        codeRenders++;
        return Text(code);
      }

      Widget doc(CcCodeBuilder builder) => _host(
        CcMarkdown(
          data: 'Intro.\n\n```\nprint(1)\n```',
          style: style,
          codeBuilder: builder,
        ),
      );

      await tester.pumpWidget(doc(code));
      expect(codeRenders, 1);
      // A parent rebuild handing over value-equal inputs: the memoized
      // subtree is returned as-is, so nothing below it re-renders.
      await tester.pumpWidget(doc(code));
      expect(codeRenders, 1);

      // A different builder instance must take effect (it is held by
      // identity), or the memo would keep rendering with a stale callback.
      Widget other(String c, String? l, {required bool cache}) {
        codeRenders++;
        return Text('other $c');
      }

      await tester.pumpWidget(doc(other));
      expect(codeRenders, 2);
      expect(find.textContaining('other print(1)'), findsOneWidget);
    });

    testWidgets('new data re-renders', (tester) async {
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'First.', style: style)),
      );
      await tester.pumpWidget(
        _host(const CcMarkdown(data: 'Second.', style: style)),
      );
      expect(find.text('Second.', findRichText: true), findsOneWidget);
      expect(find.text('First.', findRichText: true), findsNothing);
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

class _SpanCodeBuilder extends CcNodeBuilder {
  const _SpanCodeBuilder();
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      Text('[${(node as CcInlineCode).code}]');

  @override
  InlineSpan? buildSpan(
    CcNode node,
    TextStyle? base,
    CcMarkdownStyle style,
    CcRenderContext context,
    BuildContext buildContext,
  ) => TextSpan(text: (node as CcInlineCode).code);
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
