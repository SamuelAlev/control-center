import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grammar coverage for the mermaid dialects the engine draws. Every case here
/// is a shape the parser must recognize from real-world mermaid (LLM output, PR
/// bodies), plus the non-throwing degradation contract.
void main() {
  setUp(clearMermaidParseCache);

  CcMermaidGraph graph(String source) {
    final result = parseMermaid(source);
    expect(result, isA<CcMermaidParsed>(), reason: source);
    return (result as CcMermaidParsed).diagram as CcMermaidGraph;
  }

  group('flowchart', () {
    test('reads direction, nodes, and a labeled edge', () {
      final g = graph('''
flowchart LR
  A[Start] -->|go| B(Stop)
''');
      expect(g.kind, CcMermaidGraphKind.flowchart);
      expect(g.direction, CcMermaidDirection.leftRight);
      expect(g.nodes.map((n) => n.id), ['A', 'B']);
      expect(g.nodeById('A')!.lines, ['Start']);
      expect(g.nodeById('A')!.shape, CcMermaidNodeShape.rect);
      expect(g.nodeById('B')!.shape, CcMermaidNodeShape.roundRect);
      final edge = g.edges.single;
      expect(edge.fromId, 'A');
      expect(edge.toId, 'B');
      expect(edge.label, 'go');
      expect(edge.endMarker, CcMermaidEdgeMarker.arrow);
    });

    test('graph TD is the same dialect', () {
      final g = graph('graph TD\n A --> B');
      expect(g.direction, CcMermaidDirection.topDown);
      expect(g.edges.single.toId, 'B');
    });

    test('every vertex shape maps to its outline', () {
      final g = graph('''
flowchart TD
  a[rect]
  b(round)
  c([stadium])
  d[[subroutine]]
  e[(cylinder)]
  f((circle))
  g(((double)))
  h{diamond}
  i{{hexagon}}
  j[/parallelogram/]
  k[\\parallelogramAlt\\]
  l[/trapezoid\\]
  m[\\trapezoidAlt/]
  n>asymmetric]
''');
      Matcher shapeOf(CcMermaidNodeShape shape) => equals(shape);
      expect(g.nodeById('a')!.shape, shapeOf(CcMermaidNodeShape.rect));
      expect(g.nodeById('b')!.shape, shapeOf(CcMermaidNodeShape.roundRect));
      expect(g.nodeById('c')!.shape, shapeOf(CcMermaidNodeShape.stadium));
      expect(g.nodeById('d')!.shape, shapeOf(CcMermaidNodeShape.subroutine));
      expect(g.nodeById('e')!.shape, shapeOf(CcMermaidNodeShape.cylinder));
      expect(g.nodeById('f')!.shape, shapeOf(CcMermaidNodeShape.circle));
      expect(g.nodeById('g')!.shape, shapeOf(CcMermaidNodeShape.doubleCircle));
      expect(g.nodeById('h')!.shape, shapeOf(CcMermaidNodeShape.diamond));
      expect(g.nodeById('i')!.shape, shapeOf(CcMermaidNodeShape.hexagon));
      expect(g.nodeById('j')!.shape, shapeOf(CcMermaidNodeShape.parallelogram));
      expect(
        g.nodeById('k')!.shape,
        shapeOf(CcMermaidNodeShape.parallelogramAlt),
      );
      expect(g.nodeById('l')!.shape, shapeOf(CcMermaidNodeShape.trapezoid));
      expect(g.nodeById('m')!.shape, shapeOf(CcMermaidNodeShape.trapezoidAlt));
      expect(g.nodeById('n')!.shape, shapeOf(CcMermaidNodeShape.asymmetric));
    });

    test('link strokes, markers, and lengths', () {
      final g = graph('''
flowchart TD
  A --- B
  A -.-> C
  A ==> D
  A --x E
  A --o F
  A <--> G
  A ---> H
  A ~~~ I
''');
      final byTarget = {for (final edge in g.edges) edge.toId: edge};
      expect(byTarget['B']!.stroke, CcMermaidEdgeStroke.solid);
      expect(byTarget['B']!.endMarker, CcMermaidEdgeMarker.none);
      expect(byTarget['C']!.stroke, CcMermaidEdgeStroke.dotted);
      expect(byTarget['C']!.endMarker, CcMermaidEdgeMarker.arrow);
      expect(byTarget['D']!.stroke, CcMermaidEdgeStroke.thick);
      expect(byTarget['E']!.endMarker, CcMermaidEdgeMarker.cross);
      expect(byTarget['F']!.endMarker, CcMermaidEdgeMarker.circle);
      expect(byTarget['G']!.startMarker, CcMermaidEdgeMarker.arrow);
      expect(byTarget['G']!.endMarker, CcMermaidEdgeMarker.arrow);
      expect(byTarget['H']!.minRankSpan, 2);
      expect(byTarget['I']!.stroke, CcMermaidEdgeStroke.invisible);
    });

    test('inline edge text (-- text -->) is a label', () {
      final g = graph('flowchart TD\n A -- yes please --> B');
      expect(g.edges.single.label, 'yes please');
    });

    test('dotted inline edge text (-. text .->) is a label', () {
      final g = graph('flowchart TD\n A -. maybe .-> B');
      final edge = g.edges.single;
      expect(edge.label, 'maybe');
      expect(edge.stroke, CcMermaidEdgeStroke.dotted);
    });

    test('chained links and & groups fan out', () {
      final g = graph('''
flowchart LR
  A --> B --> C
  D & E --> F
''');
      final pairs = g.edges.map((e) => '${e.fromId}${e.toId}').toList();
      expect(pairs, containsAll(['AB', 'BC', 'DF', 'EF']));
    });

    test('quoted labels keep their brackets and <br> splits lines', () {
      final g = graph('flowchart TD\n A["one [two]<br/>three"] --> B');
      expect(g.nodeById('A')!.lines, ['one [two]', 'three']);
    });

    test('subgraphs become clusters and own their members', () {
      final g = graph('''
flowchart TB
  subgraph one [First]
    A --> B
  end
  subgraph two
    C
  end
  B --> C
''');
      expect(g.clusters.map((c) => c.id), ['one', 'two']);
      expect(g.clusters.first.lines, ['First']);
      expect(g.nodeById('A')!.clusterId, 'one');
      expect(g.nodeById('C')!.clusterId, 'two');
    });

    test('nested subgraphs record their parent', () {
      final g = graph('''
flowchart TB
  subgraph outer
    subgraph inner
      A
    end
    B
  end
''');
      expect(g.clusters.firstWhere((c) => c.id == 'inner').parentId, 'outer');
      expect(g.nodeById('A')!.clusterId, 'inner');
      expect(g.nodeById('B')!.clusterId, 'outer');
    });

    test('class assignment and click bindings attach to the node', () {
      final g = graph('''
flowchart TD
  A[Node]:::warn --> B
  class B highlight
  click A "https://example.com" "Open"
''');
      expect(g.nodeById('A')!.styleClasses, contains('warn'));
      expect(g.nodeById('B')!.styleClasses, contains('highlight'));
      expect(g.nodeById('A')!.href, 'https://example.com');
      expect(g.nodeById('A')!.tooltip, 'Open');
    });

    test('comments, init directives, and front matter are stripped', () {
      final g = graph('''
---
title: My flow
---
%%{init: {'theme': 'dark'}}%%
flowchart TD
  %% a comment
  A --> B %% trailing comment
''');
      expect(g.title, 'My flow');
      expect(g.nodes.map((n) => n.id), ['A', 'B']);
      expect(g.edges, hasLength(1));
    });

    test('semicolon-separated statements split', () {
      final g = graph('flowchart TD; A-->B; B-->C;');
      expect(g.edges, hasLength(2));
    });

    test('a node keeps the label from its first definition', () {
      final g = graph('flowchart TD\n A[Label] --> B\n A --> C');
      expect(g.nodeById('A')!.lines, ['Label']);
    });
  });

  group('state diagram', () {
    test('start and end markers get their own nodes', () {
      final g = graph('''
stateDiagram-v2
  [*] --> Idle
  Idle --> Running: start
  Running --> [*]
''');
      expect(g.kind, CcMermaidGraphKind.state);
      final shapes = g.nodes.map((n) => n.shape).toList();
      expect(shapes, contains(CcMermaidNodeShape.startPoint));
      expect(shapes, contains(CcMermaidNodeShape.endPoint));
      expect(g.nodeById('Idle')!.shape, CcMermaidNodeShape.roundRect);
      final labeled = g.edges.firstWhere((e) => e.label == 'start');
      expect(labeled.fromId, 'Idle');
      expect(labeled.toId, 'Running');
    });

    test('aliases, descriptions, and stereotypes', () {
      final g = graph('''
stateDiagram-v2
  state "Waiting for input" as wait
  wait --> Choice
  Choice <<choice>>
  Forked <<fork>>
  wait : still waiting
''');
      expect(g.nodeById('wait')!.lines, ['still waiting']);
      expect(g.nodeById('Choice')!.shape, CcMermaidNodeShape.choice);
      expect(g.nodeById('Forked')!.shape, CcMermaidNodeShape.bar);
    });

    test('composite states become clusters', () {
      final g = graph('''
stateDiagram-v2
  state Outer {
    [*] --> inner
  }
''');
      expect(g.clusters.single.id, 'Outer');
      expect(g.nodeById('inner')!.clusterId, 'Outer');
    });

    test('notes attach with a dotted connector', () {
      final g = graph('''
stateDiagram-v2
  A --> B
  note right of A : remember this
''');
      final note = g.nodes.firstWhere(
        (n) => n.shape == CcMermaidNodeShape.note,
      );
      expect(note.lines, ['remember this']);
      final connector = g.edges.firstWhere((e) => e.toId == note.id);
      expect(connector.stroke, CcMermaidEdgeStroke.dotted);
      expect(connector.endMarker, CcMermaidEdgeMarker.none);
    });
  });

  group('class diagram', () {
    test('members split into attribute and method compartments', () {
      final g = graph('''
classDiagram
  class Animal {
    +int age
    +String gender
    +isMammal() bool
    +mate()
  }
''');
      final animal = g.nodeById('Animal')!;
      expect(animal.shape, CcMermaidNodeShape.compartments);
      expect(animal.compartments, hasLength(2));
      expect(animal.compartments.first, ['+int age', '+String gender']);
      expect(animal.compartments.last, ['+isMammal() bool', '+mate()']);
    });

    test(
      'relations keep declaration order and put markers on the right end',
      () {
        final g = graph('''
classDiagram
  Animal <|-- Duck
  Order *-- LineItem
  Library o-- Book
  Client ..> Service
''');
        final byPair = {for (final e in g.edges) '${e.fromId}>${e.toId}': e};
        expect(
          byPair['Animal>Duck']!.startMarker,
          CcMermaidEdgeMarker.triangleHollow,
        );
        expect(
          byPair['Order>LineItem']!.startMarker,
          CcMermaidEdgeMarker.diamondFilled,
        );
        expect(
          byPair['Library>Book']!.startMarker,
          CcMermaidEdgeMarker.diamondHollow,
        );
        expect(byPair['Client>Service']!.stroke, CcMermaidEdgeStroke.dotted);
        expect(
          byPair['Client>Service']!.endMarker,
          CcMermaidEdgeMarker.openArrow,
        );
      },
    );

    test(
      'a class name containing "o" does not lex as an aggregation marker',
      () {
        final g = graph('classDiagram\n  Order o-- Item');
        final edge = g.edges.single;
        expect(edge.fromId, 'Order');
        expect(edge.toId, 'Item');
        expect(edge.startMarker, CcMermaidEdgeMarker.diamondHollow);
      },
    );

    test('cardinalities and labels', () {
      final g = graph(
        'classDiagram\n  Customer "1" --> "0..*" Ticket : raises',
      );
      final edge = g.edges.single;
      expect(edge.startCardinality, '1');
      expect(edge.endCardinality, '0..*');
      expect(edge.label, 'raises');
    });

    test('stereotypes and the inline member form', () {
      final g = graph('''
classDiagram
  class Shape {
    <<interface>>
  }
  Shape : +draw()
''');
      final shape = g.nodeById('Shape')!;
      expect(shape.stereotype, 'interface');
      expect(shape.compartments.single, ['+draw()']);
    });
  });

  group('ER diagram', () {
    test('crow\'s-foot cardinalities map to both ends', () {
      final g = graph('''
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ LINE_ITEM : contains
''');
      expect(g.kind, CcMermaidGraphKind.er);
      final places = g.edges.first;
      expect(places.fromId, 'CUSTOMER');
      expect(places.toId, 'ORDER');
      expect(places.startMarker, CcMermaidEdgeMarker.erOne);
      expect(places.endMarker, CcMermaidEdgeMarker.erZeroOrMany);
      expect(places.label, 'places');
      expect(g.edges.last.endMarker, CcMermaidEdgeMarker.erOneOrMany);
    });

    test('attribute blocks become compartment rows', () {
      final g = graph('''
erDiagram
  CUSTOMER {
    string name
    string custNumber PK "the number"
  }
''');
      final customer = g.nodeById('CUSTOMER')!;
      expect(customer.compartments.single, [
        'string name',
        'string custNumber PK',
      ]);
    });
  });

  group('sequence diagram', () {
    CcMermaidSequence sequence(String source) {
      final result = parseMermaid(source);
      expect(result, isA<CcMermaidParsed>(), reason: source);
      return (result as CcMermaidParsed).diagram as CcMermaidSequence;
    }

    test('participants come from declaration then first use', () {
      final s = sequence('''
sequenceDiagram
  participant A as Alice
  actor Bob
  A->>Bob: Hello
  Carol-->>A: Hi
''');
      expect(s.participants.map((p) => p.id), ['A', 'Bob', 'Carol']);
      expect(s.participants.first.displayLines, ['Alice']);
      expect(s.participants[1].isActor, isTrue);
    });

    test('arrow forms carry stroke and head', () {
      final s = sequence('''
sequenceDiagram
  A->B: plain
  A-->B: dotted plain
  A->>B: solid arrow
  A-->>B: dotted arrow
  A-xB: cross
  A-)B: async
''');
      final messages = s.steps.whereType<CcMermaidMessage>().toList();
      expect(messages[0].marker, CcMermaidEdgeMarker.none);
      expect(messages[0].stroke, CcMermaidEdgeStroke.solid);
      expect(messages[1].stroke, CcMermaidEdgeStroke.dotted);
      expect(messages[2].marker, CcMermaidEdgeMarker.arrow);
      expect(messages[3].stroke, CcMermaidEdgeStroke.dotted);
      expect(messages[4].marker, CcMermaidEdgeMarker.cross);
      expect(messages[5].marker, CcMermaidEdgeMarker.openArrow);
    });

    test('activation suffixes are recorded', () {
      final s = sequence('''
sequenceDiagram
  A->>+B: call
  B-->>-A: return
''');
      final messages = s.steps.whereType<CcMermaidMessage>().toList();
      expect(messages.first.activates, isTrue);
      expect(messages.last.deactivates, isTrue);
    });

    test('notes with placement', () {
      final s = sequence('''
sequenceDiagram
  A->>B: hi
  Note right of B: thinking
  Note over A,B: shared
''');
      final notes = s.steps.whereType<CcMermaidNote>().toList();
      expect(notes.first.placement, CcMermaidNotePlacement.right);
      expect(notes.first.lines, ['thinking']);
      expect(notes.last.placement, CcMermaidNotePlacement.over);
      expect(notes.last.participantIds, ['A', 'B']);
    });

    test('nested blocks with sections', () {
      final s = sequence('''
sequenceDiagram
  autonumber
  A->>B: start
  loop every minute
    alt is up
      B-->>A: ok
    else is down
      B-->>A: error
    end
  end
''');
      expect(s.autonumber, isTrue);
      final loop = s.steps.whereType<CcMermaidBlock>().single;
      expect(loop.kind, CcMermaidBlockKind.loop);
      expect(loop.label, 'every minute');
      final alt = loop.sections.single.steps.whereType<CcMermaidBlock>().single;
      expect(alt.kind, CcMermaidBlockKind.alt);
      expect(alt.sections.map((s) => s.label), ['is up', 'is down']);
      expect(alt.sections.first.steps, hasLength(1));
      expect(alt.sections.last.steps, hasLength(1));
    });

    test('dividers, explicit activation, and a title', () {
      final s = sequence('''
sequenceDiagram
  title Handshake
  == setup ==
  activate A
  A->>B: syn
  deactivate A
''');
      expect(s.title, 'Handshake');
      expect(s.steps.whereType<CcMermaidDivider>().single.label, 'setup');
      final activations = s.steps.whereType<CcMermaidActivation>().toList();
      expect(activations.first.active, isTrue);
      expect(activations.last.active, isFalse);
    });

    test('a self-message keeps one participant', () {
      final s = sequence('sequenceDiagram\n  A->>A: think');
      expect(s.participants, hasLength(1));
      final message = s.steps.whereType<CcMermaidMessage>().single;
      expect(message.fromId, message.toId);
    });
  });

  group('pie', () {
    test('title and slices', () {
      final result = parseMermaid('''
pie showData
  title Key elements
  "Calcium" : 42.96
  "Potassium" : 50.05
  Other : 7
''');
      final pie = (result as CcMermaidParsed).diagram as CcMermaidPie;
      expect(pie.title, 'Key elements');
      expect(pie.showData, isTrue);
      expect(pie.slices.map((s) => s.label), ['Calcium', 'Potassium', 'Other']);
      expect(pie.total, closeTo(100.01, 0.001));
    });

    test('a title on the header line is honored', () {
      final result = parseMermaid('pie title Votes\n  "Yes" : 1\n  "No" : 2');
      expect(
        ((result as CcMermaidParsed).diagram as CcMermaidPie).title,
        'Votes',
      );
    });

    test('a chart with no usable slices is unsupported, not a crash', () {
      expect(parseMermaid('pie\n  title Nothing'), isA<CcMermaidUnsupported>());
      expect(parseMermaid('pie\n  "A" : 0'), isA<CcMermaidUnsupported>());
    });
  });

  group('timeline', () {
    test('sections group periods and events', () {
      final result = parseMermaid('''
timeline
  title History
  section Early
    2002 : LinkedIn
    2004 : Facebook : Google
  section Later
    2006 : Twitter
''');
      final timeline = (result as CcMermaidParsed).diagram as CcMermaidTimeline;
      expect(timeline.title, 'History');
      expect(timeline.entries.map((e) => e.period), ['2002', '2004', '2006']);
      expect(timeline.entries[1].events, ['Facebook', 'Google']);
      expect(timeline.entries.first.section, 'Early');
      expect(timeline.entries.last.section, 'Later');
    });
  });

  group('degradation contract', () {
    test('an unsupported dialect names itself', () {
      final result = parseMermaid('gantt\n  title A Gantt');
      expect(result, isA<CcMermaidUnsupported>());
      expect((result as CcMermaidUnsupported).message, contains('gantt'));
      expect(result.dialect, 'gantt');
    });

    test('an unrecognized header is reported, not thrown', () {
      final result = parseMermaid('bananas\n  A --> B');
      expect(result, isA<CcMermaidUnsupported>());
      expect((result as CcMermaidUnsupported).message, contains('bananas'));
    });

    test('an empty source is unsupported', () {
      expect(parseMermaid('   \n\n'), isA<CcMermaidUnsupported>());
    });

    test('a header with no statements has nothing to draw', () {
      expect(parseMermaid('flowchart TD'), isA<CcMermaidUnsupported>());
    });

    test('truncated and malformed bodies never throw', () {
      const sources = [
        'flowchart TD\n  A[unclosed --> B',
        'flowchart TD\n  A -->',
        'flowchart TD\n  --> B',
        'sequenceDiagram\n  A->>',
        'sequenceDiagram\n  loop forever',
        'classDiagram\n  class {',
        'erDiagram\n  A ||--',
        'stateDiagram-v2\n  [*] -->',
        'pie\n  "A" : abc',
        'flowchart TD\n  A --> B\n  subgraph never closed',
      ];
      for (final source in sources) {
        expect(() => parseMermaid(source), returnsNormally, reason: source);
      }
    });

    test('a pathologically large diagram is refused, not drawn', () {
      final huge = StringBuffer('flowchart TD\n');
      for (var i = 0; i < kCcMermaidMaxNodes + 10; i++) {
        huge.writeln('  n$i');
      }
      final result = parseMermaid(huge.toString());
      expect(result, isA<CcMermaidUnsupported>());
      expect((result as CcMermaidUnsupported).message, contains('too large'));
    });

    test('a sequence with too many steps is refused', () {
      final huge = StringBuffer('sequenceDiagram\n');
      for (var i = 0; i < kCcMermaidMaxSteps + 10; i++) {
        huge.writeln('  A->>B: step $i');
      }
      expect(parseMermaid(huge.toString()), isA<CcMermaidUnsupported>());
    });

    test('a participant whose name starts with "title" is not a title', () {
      final result = parseMermaid('sequenceDiagram\n  titleService->>B: ping');
      final sequence = (result as CcMermaidParsed).diagram as CcMermaidSequence;
      expect(sequence.title, isNull);
      expect(sequence.participants.map((p) => p.id), ['titleService', 'B']);
    });

    test('a pie slice whose label starts with "title" is not a title', () {
      final result = parseMermaid('pie\n  titleCase : 3\n  other : 1');
      final pie = (result as CcMermaidParsed).diagram as CcMermaidPie;
      expect(pie.title, isNull);
      expect(pie.slices.map((s) => s.label), ['titleCase', 'other']);
    });

    test('results are memoized by source', () {
      const source = 'flowchart TD\n A --> B';
      expect(identical(parseMermaid(source), parseMermaid(source)), isTrue);
      clearMermaidParseCache();
      expect(identical(parseMermaid(source), parseMermaid(source)), isTrue);
    });
  });
}
