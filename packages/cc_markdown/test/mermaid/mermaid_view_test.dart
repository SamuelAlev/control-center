import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level behavior of [CcMermaidView] and its integration with the
/// markdown renderer: a fence becomes a drawn diagram, an undrawable one becomes
/// the code block it would otherwise have been and the diagram carries a text
/// alternative for assistive tech.
void main() {
  const style = CcMermaidStyle();

  setUp(() {
    clearMermaidParseCache();
    clearMermaidSceneCache();
  });

  Widget host(Widget child, {double width = 400}) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  testWidgets('draws a flowchart with no exceptions', (tester) async {
    await tester.pumpWidget(
      host(
        const CcMermaidView(
          source: 'flowchart TD\n A[Start] -->|go| B{Choice}\n B --> C((End))',
          style: style,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('draws every supported dialect without exceptions', (
    tester,
  ) async {
    // Adjacent string literals here are line CONTINUATIONS of one diagram
    // source, not separate entries — the lint's usual "you forgot a comma"
    // reading is wrong for a wrapped multi-line fixture.
    // ignore_for_file: no_adjacent_strings_in_list
    const sources = <String>[
      'flowchart LR\n subgraph s [Group]\n A --> B\n end\n B -.-> C',
      'stateDiagram-v2\n [*] --> Idle\n Idle --> Busy: work\n Busy --> [*]\n'
          ' note right of Idle : waiting',
      'classDiagram\n class A {\n +int x\n +go()\n }\n A <|-- B : extends',
      'erDiagram\n A ||--o{ B : has\n A {\n string name\n }',
      'sequenceDiagram\n autonumber\n actor U\n U->>+S: req\n S-->>-U: res\n'
          ' loop retry\n U->>S: again\n end\n Note over U,S: done',
      'pie showData\n title Split\n "A" : 3\n "B" : 1',
      'timeline\n title T\n section One\n 2020 : a : b\n section Two\n 2021 : c',
    ];
    for (final source in sources) {
      await tester.pumpWidget(
        host(CcMermaidView(source: source, style: style), width: 600),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: source);
    }
  });

  testWidgets('an unsupported dialect renders the fallback with a reason', (
    tester,
  ) async {
    String? seenReason;
    await tester.pumpWidget(
      host(
        CcMermaidView(
          source: 'gantt\n title Roadmap',
          style: style,
          fallbackBuilder: (source, reason) {
            seenReason = reason;
            return Text(source, textDirection: TextDirection.ltr);
          },
        ),
      ),
    );
    expect(seenReason, contains('gantt'));
    expect(find.textContaining('Roadmap'), findsOneWidget);
  });

  testWidgets('the built-in fallback shows the source when no builder is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const CcMermaidView(source: 'mindmap\n root', style: style)),
    );
    expect(tester.takeException(), isNull);
    // Both the reason line ("unsupported diagram type: mindmap") and the source
    // are shown, so the author can still read what they wrote.
    expect(find.textContaining('mindmap'), findsNWidgets(2));
  });

  testWidgets('exposes a text alternative to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const CcMermaidView(
          source: 'flowchart TD\n A[Fetch] -->|ok| B[Store]',
          style: style,
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('flowchart.*Fetch.*Store')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a click binding is tappable', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      host(
        CcMermaidView(
          source:
              'flowchart TD\n A[Open] --> B[Other]\n'
              ' click A "https://example.com"',
          style: style,
          onTapNode: (nodeId, href) => taps.add('$nodeId:$href'),
        ),
      ),
    );
    final plan = resolveMermaidRenderPlan(
      source:
          'flowchart TD\n A[Open] --> B[Other]\n click A "https://example.com"',
      style: style,
    );
    expect(plan.scene!.hitTargets, hasLength(1));
    final target = plan.scene!.hitTargets.single;
    final canvas = tester.getTopLeft(find.byType(CustomPaint).last);
    await tester.tapAt(canvas + target.rect.center);
    expect(taps, ['A:https://example.com']);
  });

  testWidgets('a wide diagram scrolls instead of shrinking past legibility', (
    tester,
  ) async {
    final source = StringBuffer('flowchart LR\n');
    for (var i = 0; i < 12; i++) {
      source.writeln(
        '  n$i[Node number $i] --> n${i + 1}[Node number ${i + 1}]',
      );
    }
    await tester.pumpWidget(
      host(CcMermaidView(source: source.toString(), style: style), width: 300),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('interactive mode wraps the canvas in a viewer', (tester) async {
    await tester.pumpWidget(
      host(
        const CcMermaidView(
          source: 'flowchart TD\n A --> B',
          style: style,
          interactive: true,
        ),
      ),
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  group('markdown integration', () {
    testWidgets('a closed mermaid fence renders a diagram', (tester) async {
      await tester.pumpWidget(
        host(
          const CcMarkdown(
            data:
                'Before\n\n```mermaid\nflowchart TD\n  A[One] --> B[Two]\n```\n\nAfter',
          ),
        ),
      );
      expect(find.byType(CcMermaidView), findsOneWidget);
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an undrawable fence falls back to the host code builder', (
      tester,
    ) async {
      var codeCalls = 0;
      await tester.pumpWidget(
        host(
          CcMarkdown(
            data: '```mermaid\ngantt\n  title Roadmap\n```',
            codeBuilder: (code, language, {required bool cache}) {
              codeCalls++;
              expect(language, 'mermaid');
              return Text(code, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      expect(codeCalls, 1);
      expect(find.textContaining('gantt'), findsOneWidget);
    });

    testWidgets('an app builder can override the mermaid node entirely', (
      tester,
    ) async {
      final builders = CcBuilderRegistry(const {
        'mermaid': _StubMermaidBuilder(),
      });
      await tester.pumpWidget(
        host(
          CcMarkdown(
            data: '```mermaid\nflowchart TD\n A --> B\n```',
            builders: builders,
          ),
        ),
      );
      expect(find.text('stub'), findsOneWidget);
      expect(find.byType(CcMermaidView), findsNothing);
    });

    testWidgets('mermaid: false leaves the fence as a code block', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const CcMarkdown(
            data: '```mermaid\nflowchart TD\n A --> B\n```',
            options: CcParseOptions(mermaid: false),
          ),
        ),
      );
      expect(find.byType(CcMermaidView), findsNothing);
      expect(find.textContaining('flowchart TD'), findsOneWidget);
    });

    testWidgets('a streaming (unclosed) fence stays code until it closes', (
      tester,
    ) async {
      final controller = CcMarkdownStreamController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(CcStreamingMarkdown(controller: controller)),
      );

      controller.append('```mermaid\nflowchart TD\n  A[One] --> B');
      await tester.pump();
      expect(find.byType(CcMermaidView), findsNothing);

      controller.append('[Two]\n```\n');
      controller.complete();
      await tester.pump();
      expect(find.byType(CcMermaidView), findsOneWidget);
    });
  });

  group('render plan', () {
    test('is memoized by source, style and text scale', () {
      const source = 'flowchart TD\n A --> B';
      final first = resolveMermaidRenderPlan(source: source, style: style);
      final second = resolveMermaidRenderPlan(source: source, style: style);
      expect(identical(first, second), isTrue);

      final scaled = resolveMermaidRenderPlan(
        source: source,
        style: style,
        textScaler: const TextScaler.linear(2),
      );
      expect(identical(first, scaled), isFalse);
      expect(scaled.scene!.size.width, greaterThan(first.scene!.size.width));
    });

    test('reports a reason instead of a scene when nothing can be drawn', () {
      final plan = resolveMermaidRenderPlan(source: 'gantt\n x', style: style);
      expect(plan.scene, isNull);
      expect(plan.reason, contains('gantt'));
    });

    test('a semantic label summarizes each dialect', () {
      String labelOf(String source) => mermaidSemanticLabel(
        (parseMermaid(source) as CcMermaidParsed).diagram,
      );
      expect(labelOf('flowchart TD\n A[Fetch] --> B[Save]'), contains('Fetch'));
      expect(
        labelOf('sequenceDiagram\n A->>B: ping'),
        contains('sequence diagram'),
      );
      expect(labelOf('pie\n "A" : 1\n "B" : 1'), contains('50%'));
      expect(labelOf('timeline\n 2020 : launch'), contains('launch'));
    });
  });
}

class _StubMermaidBuilder extends CcNodeBuilder {
  const _StubMermaidBuilder();

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    expect(node, isA<CcMermaid>());
    return const Text('stub', textDirection: TextDirection.ltr);
  }
}
