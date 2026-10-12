import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the shared mermaid source prepass: multiline
/// `%%{init}%%` directives, labels written over several lines inside quotes,
/// and entity decoding.
///
/// Every case asserts the shape a consumer sees (node ids, label lines, edges)
/// rather than that parsing merely does not throw, so a regression fails with a
/// readable diff and a malformed source provably keeps its valid statements.
void main() {
  setUp(clearMermaidParseCache);

  CcMermaidGraph graph(String source) {
    final result = parseMermaid(source);
    expect(result, isA<CcMermaidParsed>(), reason: source);
    return (result as CcMermaidParsed).diagram as CcMermaidGraph;
  }

  List<String> nodeIds(CcMermaidGraph g) => [
    for (final node in g.nodes) node.id,
  ];

  List<String> edgeShapes(CcMermaidGraph g) => [
    for (final edge in g.edges) '${edge.fromId}->${edge.toId}',
  ];

  group('multiline init directives', () {
    test('a directive above the header does not become the header', () {
      final g = graph('''
%%{init: {
  "theme": "base",
  "themeVariables": {"primaryColor": "#ff0000"}
}}%%
flowchart LR
  A[Start] --> B[Done]
''');
      expect(g.direction, CcMermaidDirection.leftRight);
      expect(nodeIds(g), ['A', 'B']);
      expect(g.nodeById('A')!.lines, ['Start']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('directive body lines do not become nodes', () {
      final g = graph('''
flowchart TD
%%{init: {
  theme: base,
  flowchart: { curve: basis }
}}%%
A --> B
''');
      expect(g.direction, CcMermaidDirection.topDown);
      expect(nodeIds(g), ['A', 'B']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('a directive between statements is dropped', () {
      final g = graph('''
flowchart TD
  A --> B
%%{init: {
  "flowchart": {"curve": "basis"}
}}%%
  B --> C
''');
      expect(nodeIds(g), ['A', 'B', 'C']);
      expect(edgeShapes(g), ['A->B', 'B->C']);
    });

    test('a single-line directive still selects the same diagram', () {
      final g = graph('%%{init: {"theme": "forest"}}%%\nflowchart LR\nA --> B');

      expect(g.direction, CcMermaidDirection.leftRight);
      expect(nodeIds(g), ['A', 'B']);
    });

    test('an unterminated directive keeps the statements below it', () {
      final g = graph('''
flowchart TD
%%{init: {
A --> B
B --> C
''');
      expect(nodeIds(g), ['A', 'B', 'C']);
      expect(edgeShapes(g), ['A->B', 'B->C']);
    });
  });

  group('multiline quoted labels', () {
    test('a quoted label keeps its lines and the edge after it', () {
      final g = graph('''
flowchart TD
  A["first line
second line"] --> B[Done]
  B --> C
''');
      expect(nodeIds(g), ['A', 'B', 'C']);
      expect(g.nodeById('A')!.lines, ['first line', 'second line']);
      expect(g.nodeById('B')!.lines, ['Done']);
      expect(edgeShapes(g), ['A->B', 'B->C']);
    });

    test('quoted lines keep their semicolons and percent signs', () {
      final g = graph('''
flowchart LR
  A["one; two
50%% done
three"] --> B
''');
      expect(g.nodeById('A')!.lines, ['one; two', '50%% done', 'three']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('a two-line pipe label lands on the edge', () {
      final g = graph('flowchart LR\nA -->|"yes\nno"| B');

      final edge = g.edges.single;
      expect(edge.toId, 'B');
      expect(edge.labelLines, ['yes', 'no']);
      expect(edge.label, 'yes no');
    });

    test('a stray quote keeps the statements below it', () {
      final g = graph('''
flowchart TD
A["oops
B --> C
C --> D
''');
      expect(nodeIds(g), ['A', 'B', 'C', 'D']);
      expect(edgeShapes(g), ['B->C', 'C->D']);
    });

    test('single-line quoted labels are unchanged', () {
      final g = graph('''
flowchart TD
  A["a; b"] --> B
  B["<b>bold</b><br>next"] --> C
''');
      expect(nodeIds(g), ['A', 'B', 'C']);
      expect(g.nodeById('A')!.lines, ['a; b']);
      expect(g.nodeById('B')!.lines, ['bold', 'next']);
      expect(edgeShapes(g), ['A->B', 'B->C']);
    });
  });

  group('entity decoding', () {
    test('numeric mermaid and HTML escapes decode to their characters', () {
      final g = graph('''
flowchart TD
  A["#35; card #59; #colon; #quot;q#quot;"] --> B["&#x2764; &#9829;"]
''');
      expect(g.nodeById('A')!.lines, ['# card ; : "q"']);
      expect(g.nodeById('B')!.lines, ['\u2764 \u2665']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('escaped markup is shown instead of stripped as markup', () {
      final g = graph('''
flowchart TD
  A["#lt;b#gt;bold#lt;/b#gt; and &#60;br&#62;"] --> B
''');
      expect(g.nodeById('A')!.lines, ['<b>bold</b> and <br>']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('an escaped ampersand decodes exactly once', () {
      final g = graph('''
flowchart TD
  A["&amp;lt;"] --> B
''');
      expect(g.nodeById('A')!.lines, ['&lt;']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('unknown names and invalid code points pass through untouched', () {
      final g = graph('''
flowchart TD
  A["&copy; &bogus; &#x110000; &#0; &#xD800; &#x1F600;"] --> B
''');
      expect(g.nodeById('A')!.lines, [
        '&copy; &bogus; &#x110000; &#0; &#xD800; \u{1F600}',
      ]);
      expect(edgeShapes(g), ['A->B']);
    });
  });

  group('degenerate sources stay lenient', () {
    test('a lone separator is an empty diagram, not a throw', () {
      final result = parseMermaid(';');

      expect(result, isA<CcMermaidUnsupported>());
      expect((result as CcMermaidUnsupported).message, 'empty diagram');
    });

    test('statements after leading separators still parse', () {
      final g = graph(';\n;flowchart TD\nA --> B');

      expect(nodeIds(g), ['A', 'B']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('trailing separators do not drop the last statement', () {
      final g = graph('flowchart TD\nA --> B;;;');

      expect(nodeIds(g), ['A', 'B']);
      expect(edgeShapes(g), ['A->B']);
    });

    test('a trailing statement without a newline is kept', () {
      final g = graph('flowchart TD\nA --> B\nZ');

      expect(nodeIds(g), ['A', 'B', 'Z']);
      expect(edgeShapes(g), ['A->B']);
    });
  });
}
