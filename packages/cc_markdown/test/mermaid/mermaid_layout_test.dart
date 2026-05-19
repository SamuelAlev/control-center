import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout invariants, asserted on the SCENE rather than on pixels: boxes must
/// not overlap, edges must land on the outlines they connect, the flow must run
/// the direction the source asked for and labels must sit in free space.
///
/// A deterministic ruler (fixed glyph metrics) keeps the numbers stable across
/// platforms and font versions.
void main() {
  const style = CcMermaidStyle();
  const ruler = _FixedRuler();

  CcMermaidScene layoutOf(String source) {
    final parsed = parseMermaid(source);
    expect(parsed, isA<CcMermaidParsed>(), reason: source);
    final diagram = (parsed as CcMermaidParsed).diagram;
    return switch (diagram) {
      final CcMermaidGraph graph => layoutMermaidGraph(
        graph,
        style: style,
        ruler: ruler,
      ),
      final CcMermaidSequence sequence => layoutMermaidSequence(
        sequence,
        style: style,
        ruler: ruler,
      ),
      final CcMermaidPie pie => layoutMermaidPie(
        pie,
        style: style,
        ruler: ruler,
      ),
      final CcMermaidTimeline timeline => layoutMermaidTimeline(
        timeline,
        style: style,
        ruler: ruler,
      ),
    };
  }

  setUp(clearMermaidParseCache);

  group('flowchart geometry', () {
    test('a two-node graph fits inside its reported canvas', () {
      final scene = layoutOf('flowchart TD\n A[Start] --> B[Stop]');
      expect(scene.size.width, greaterThan(0));
      expect(scene.size.height, greaterThan(0));
      for (final primitive in scene.primitives) {
        final bounds = primitiveBounds(primitive);
        expect(bounds.left, greaterThanOrEqualTo(-0.01));
        expect(bounds.top, greaterThanOrEqualTo(-0.01));
        expect(bounds.right, lessThanOrEqualTo(scene.size.width + 0.01));
        expect(bounds.bottom, lessThanOrEqualTo(scene.size.height + 0.01));
      }
    });

    test('node boxes never overlap, even in a dense graph', () {
      final scene = layoutOf('''
flowchart TD
  A[Ingest] --> B{Valid?}
  B -->|yes| C[Transform]
  B -->|no| D[Reject]
  C --> E[(Store)]
  D --> E
  C --> F[Notify]
  F --> E
  E --> G([Done])
''');
      final boxes = _nodeBoxes(scene);
      expect(boxes, hasLength(7));
      for (var i = 0; i < boxes.length; i++) {
        for (var j = i + 1; j < boxes.length; j++) {
          expect(
            boxes[i].deflate(0.5).overlaps(boxes[j].deflate(0.5)),
            isFalse,
            reason: 'boxes $i and $j overlap: ${boxes[i]} vs ${boxes[j]}',
          );
        }
      }
    });

    test('edge labels sit clear of every node box', () {
      final scene = layoutOf('''
flowchart TD
  A --> B
  B -->|the label| C
  B --> D
''');
      final labels = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.edgeLabel)
          .toList();
      expect(labels, hasLength(1));
      for (final box in _nodeBoxes(scene)) {
        expect(
          labels.single.rect.deflate(0.5).overlaps(box.deflate(0.5)),
          isFalse,
        );
      }
      expect(
        scene.primitives.whereType<CcMermaidTextPrim>().map((t) => t.text),
        contains('the label'),
      );
    });

    test('TD flows downward, BT upward, LR rightward, RL leftward', () {
      Rect boxFor(CcMermaidScene scene, String label) => scene.primitives
          .whereType<CcMermaidTextPrim>()
          .firstWhere((prim) => prim.text == label)
          .rect;

      final td = layoutOf('flowchart TD\n A[AA] --> B[BB]');
      expect(boxFor(td, 'AA').center.dy, lessThan(boxFor(td, 'BB').center.dy));

      final bt = layoutOf('flowchart BT\n A[AA] --> B[BB]');
      expect(
        boxFor(bt, 'AA').center.dy,
        greaterThan(boxFor(bt, 'BB').center.dy),
      );

      final lr = layoutOf('flowchart LR\n A[AA] --> B[BB]');
      expect(boxFor(lr, 'AA').center.dx, lessThan(boxFor(lr, 'BB').center.dx));

      final rl = layoutOf('flowchart RL\n A[AA] --> B[BB]');
      expect(
        boxFor(rl, 'AA').center.dx,
        greaterThan(boxFor(rl, 'BB').center.dx),
      );
    });

    test('an edge starts and ends on the boxes it connects', () {
      final scene = layoutOf('flowchart TD\n A[Start] --> B[Stop]');
      final edge = scene.primitives.whereType<CcMermaidPathPrim>().firstWhere(
        (prim) => prim.endMarker == CcMermaidEdgeMarker.arrow,
      );
      final boxes = _nodeBoxes(scene);
      final source = boxes.reduce((a, b) => a.center.dy < b.center.dy ? a : b);
      final target = boxes.reduce((a, b) => a.center.dy > b.center.dy ? a : b);
      // Endpoints land on the outline: touching the box, not inside it.
      expect((edge.points.first.dy - source.bottom).abs(), lessThan(1.5));
      expect((edge.points.last.dy - target.top).abs(), lessThan(1.5));
      expect(source.inflate(1).contains(edge.points.first), isTrue);
      expect(target.inflate(1).contains(edge.points.last), isTrue);
    });

    test(
      'an edge into a diamond stops on the rhombus, not the bounding box',
      () {
        final scene = layoutOf('flowchart TD\n A[Start] --> B{Check}');
        final diamond = scene.primitives
            .whereType<CcMermaidShapePrim>()
            .firstWhere((prim) => prim.shape == CcMermaidNodeShape.diamond);
        final edge = scene.primitives.whereType<CcMermaidPathPrim>().first;
        final rect = diamond.rect;
        final end = edge.points.last;
        final normalized =
            (end.dx - rect.center.dx).abs() / (rect.width / 2) +
            (end.dy - rect.center.dy).abs() / (rect.height / 2);
        expect(normalized, closeTo(1, 0.05));
      },
    );

    test('a cluster box contains its members and excludes outsiders', () {
      final scene = layoutOf('''
flowchart TB
  subgraph inside [Group]
    A[Alpha] --> B[Beta]
  end
  C[Gamma] --> A
''');
      final cluster = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .firstWhere((prim) => prim.role == CcMermaidPaintRole.cluster);
      Rect textBox(String label) => scene.primitives
          .whereType<CcMermaidTextPrim>()
          .firstWhere((prim) => prim.text == label)
          .rect;
      expect(cluster.rect.contains(textBox('Alpha').center), isTrue);
      expect(cluster.rect.contains(textBox('Beta').center), isTrue);
      expect(cluster.rect.contains(textBox('Gamma').center), isFalse);
    });

    test('a cycle terminates and keeps both edges', () {
      final scene = layoutOf('flowchart LR\n A --> B\n B --> A');
      final edges = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.endMarker != CcMermaidEdgeMarker.none)
          .toList();
      expect(edges, hasLength(2));
    });

    test('a reversed (cycle-breaking) edge still points at its target', () {
      final scene = layoutOf('flowchart TD\n A[Aaa] --> B[Bbb]\n B --> A');
      final boxes = _nodeBoxes(scene);
      final top = boxes.reduce((a, b) => a.center.dy < b.center.dy ? a : b);
      final edges = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.endMarker == CcMermaidEdgeMarker.arrow)
          .toList();
      // Exactly one of the two arrows must point back INTO the upper box.
      final intoTop = edges.where(
        (edge) => top.inflate(2).contains(edge.points.last),
      );
      expect(intoTop, hasLength(1));
    });

    test('a self-loop leaves and re-enters its own node', () {
      final scene = layoutOf('flowchart TD\n A[Retry] --> A');
      final box = _nodeBoxes(scene).single;
      final loop = scene.primitives.whereType<CcMermaidPathPrim>().first;
      expect(loop.points, hasLength(4));
      expect(
        loop.points.map((p) => p.dx).reduce(math.max),
        greaterThan(box.right),
      );
      expect(box.inflate(2).contains(loop.points.first), isTrue);
      expect(box.inflate(2).contains(loop.points.last), isTrue);
    });

    test('a long edge is routed around the intervening rank', () {
      final scene = layoutOf('''
flowchart TD
  A --> B
  B --> C
  A --> C
''');
      final longEdge = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.points.length > 2)
          .toList();
      expect(longEdge, isNotEmpty, reason: 'the A→C edge should bend around B');
    });

    test('node labels stay inside their boxes', () {
      final scene = layoutOf('''
flowchart TD
  A[A reasonably long label here] --> B{Decide}
  B --> C((Circle))
''');
      final shapes = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.node)
          .toList();
      for (final text in scene.primitives.whereType<CcMermaidTextPrim>()) {
        if (text.role != CcMermaidTextRole.label) {
          continue;
        }
        final host = shapes.firstWhere(
          (shape) => shape.rect.contains(text.rect.center),
          orElse: () =>
              throw StateError('label "${text.text}" has no host box'),
        );
        expect(text.rect.width, lessThanOrEqualTo(host.rect.width + 0.01));
        expect(host.rect.top, lessThanOrEqualTo(text.rect.top + 0.01));
        expect(host.rect.bottom, greaterThanOrEqualTo(text.rect.bottom - 0.01));
      }
    });

    test('an invisible link reserves space but paints no line', () {
      final visible = layoutOf('flowchart TD\n A --> B');
      final invisible = layoutOf('flowchart TD\n A ~~~ B');
      expect(
        invisible.primitives.whereType<CcMermaidPathPrim>().where(
          (prim) => prim.endMarker != CcMermaidEdgeMarker.none,
        ),
        isEmpty,
      );
      // The nodes are still ranked apart, so the canvas keeps its height.
      expect(invisible.size.height, closeTo(visible.size.height, 1));
    });

    test('a title is placed above the diagram body', () {
      final scene = layoutOf('''
---
title: The Flow
---
flowchart TD
  A[Node] --> B[Other]
''');
      final title = scene.primitives.whereType<CcMermaidTextPrim>().firstWhere(
        (prim) => prim.role == CcMermaidTextRole.title,
      );
      for (final box in _nodeBoxes(scene)) {
        expect(title.rect.bottom, lessThanOrEqualTo(box.top + 0.01));
      }
    });
  });

  group('class and ER geometry', () {
    test('a class box draws a compartment divider per section', () {
      final scene = layoutOf('''
classDiagram
  class Animal {
    +int age
    +mate()
  }
''');
      final dividers = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.divider)
          .toList();
      expect(dividers, hasLength(2));
      final box = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .firstWhere((prim) => prim.role == CcMermaidPaintRole.node)
          .rect;
      for (final divider in dividers) {
        expect(divider.points.first.dx, closeTo(box.left, 0.01));
        expect(divider.points.last.dx, closeTo(box.right, 0.01));
        expect(divider.points.first.dy, greaterThan(box.top));
        expect(divider.points.first.dy, lessThan(box.bottom));
      }
    });

    test('cardinality labels are placed near their own end of the line', () {
      final scene = layoutOf('classDiagram\n  Customer "1" --> "0..*" Ticket');
      final edge = scene.primitives.whereType<CcMermaidPathPrim>().firstWhere(
        (prim) => prim.endMarker != CcMermaidEdgeMarker.none,
      );
      final one = scene.primitives.whereType<CcMermaidTextPrim>().firstWhere(
        (prim) => prim.text == '1',
      );
      final many = scene.primitives.whereType<CcMermaidTextPrim>().firstWhere(
        (prim) => prim.text == '0..*',
      );
      expect(
        (one.rect.center - edge.points.first).distance,
        lessThan((one.rect.center - edge.points.last).distance),
      );
      expect(
        (many.rect.center - edge.points.last).distance,
        lessThan((many.rect.center - edge.points.first).distance),
      );
    });

    test('an ER entity renders its attribute rows', () {
      final scene = layoutOf('''
erDiagram
  CUSTOMER ||--o{ ORDER : places
  CUSTOMER {
    string name
    string number
  }
''');
      final rows = scene.primitives
          .whereType<CcMermaidTextPrim>()
          .where((prim) => prim.role == CcMermaidTextRole.compartment)
          .map((prim) => prim.text);
      expect(rows, containsAll(['string name', 'string number']));
      final edge = scene.primitives.whereType<CcMermaidPathPrim>().firstWhere(
        (prim) => prim.startMarker == CcMermaidEdgeMarker.erOne,
      );
      expect(edge.endMarker, CcMermaidEdgeMarker.erZeroOrMany);
    });
  });

  group('sequence geometry', () {
    test('lifelines are vertical, in participant order, under their boxes', () {
      final scene = layoutOf('''
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hello
''');
      final lifelines = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.stroke == CcMermaidEdgeStroke.dotted)
          .toList();
      expect(lifelines, hasLength(2));
      for (final lifeline in lifelines) {
        expect(
          lifeline.points.first.dx,
          closeTo(lifeline.points.last.dx, 0.01),
        );
        expect(lifeline.points.first.dy, lessThan(lifeline.points.last.dy));
      }
      expect(
        lifelines.first.points.first.dx,
        lessThan(lifelines.last.points.first.dx),
      );
    });

    test('messages advance down the page in source order', () {
      final scene = layoutOf('''
sequenceDiagram
  A->>B: first
  B-->>A: second
  A->>B: third
''');
      final ys = <double>[];
      for (final text in scene.primitives.whereType<CcMermaidTextPrim>()) {
        if (['first', 'second', 'third'].contains(text.text)) {
          ys.add(text.rect.center.dy);
        }
      }
      expect(ys, hasLength(3));
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));
    });

    test('a message label sits between the two lifelines', () {
      final scene = layoutOf('sequenceDiagram\n  Alice->>Bob: ping');
      final lifelines = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.stroke == CcMermaidEdgeStroke.dotted)
          .toList();
      final label = scene.primitives.whereType<CcMermaidTextPrim>().firstWhere(
        (prim) => prim.text == 'ping',
      );
      final left = lifelines.first.points.first.dx;
      final right = lifelines.last.points.first.dx;
      expect(label.rect.center.dx, greaterThan(left));
      expect(label.rect.center.dx, lessThan(right));
    });

    test('an activation pair becomes a bar on the receiver lifeline', () {
      final scene = layoutOf('''
sequenceDiagram
  A->>+B: call
  B-->>-A: return
''');
      final bars = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.activation)
          .toList();
      expect(bars, hasLength(1));
      expect(bars.single.rect.height, greaterThan(10));
    });

    test('a frame encloses the steps of its block', () {
      final scene = layoutOf('''
sequenceDiagram
  A->>B: outside
  loop retry
    A->>B: inside
  end
''');
      final frame = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.frame)
          .reduce((a, b) => a.rect.height > b.rect.height ? a : b);
      Rect textOf(String label) => scene.primitives
          .whereType<CcMermaidTextPrim>()
          .firstWhere((prim) => prim.text == label)
          .rect;
      expect(frame.rect.contains(textOf('inside').center), isTrue);
      expect(frame.rect.contains(textOf('outside').center), isFalse);
      expect(
        scene.primitives.whereType<CcMermaidTextPrim>().map((t) => t.text),
        containsAll(['loop', '[retry]']),
      );
    });

    test('alt sections get a divider and a label', () {
      final scene = layoutOf('''
sequenceDiagram
  alt ok
    A->>B: yes
  else bad
    A->>B: no
  end
''');
      expect(
        scene.primitives.whereType<CcMermaidTextPrim>().map((t) => t.text),
        containsAll(['alt', '[ok]', '[bad]']),
      );
    });

    test('a self-message loops out to the right of its lifeline', () {
      final scene = layoutOf('sequenceDiagram\n  A->>A: recurse');
      final loop = scene.primitives.whereType<CcMermaidPathPrim>().firstWhere(
        (prim) => prim.endMarker == CcMermaidEdgeMarker.arrow,
      );
      expect(loop.points, hasLength(4));
      expect(loop.points[1].dx, greaterThan(loop.points.first.dx));
      expect(loop.points.last.dy, greaterThan(loop.points.first.dy));
    });

    test('an over-note spans both lifelines', () {
      final scene = layoutOf('''
sequenceDiagram
  A->>B: hi
  Note over A,B: shared context
''');
      final note = scene.primitives.whereType<CcMermaidShapePrim>().firstWhere(
        (prim) => prim.role == CcMermaidPaintRole.note,
      );
      final lifelines = scene.primitives
          .whereType<CcMermaidPathPrim>()
          .where((prim) => prim.stroke == CcMermaidEdgeStroke.dotted)
          .toList();
      expect(note.rect.left, lessThan(lifelines.first.points.first.dx));
      expect(note.rect.right, greaterThan(lifelines.last.points.first.dx));
    });

    test('autonumber prefixes message labels', () {
      final scene = layoutOf('''
sequenceDiagram
  autonumber
  A->>B: first
  B->>A: second
''');
      final texts = scene.primitives.whereType<CcMermaidTextPrim>().map(
        (t) => t.text,
      );
      expect(texts, containsAll(['1. first', '2. second']));
    });

    test('actors are drawn as figures above their box', () {
      final scene = layoutOf('sequenceDiagram\n  actor A\n  A->>A: hi');
      expect(scene.primitives.whereType<CcMermaidActorPrim>(), hasLength(1));
    });
  });

  group('pie geometry', () {
    test('slices sweep a full turn and every slice gets a legend row', () {
      final scene = layoutOf('''
pie title Shares
  "Alpha" : 50
  "Beta" : 30
  "Gamma" : 20
''');
      final arcs = scene.primitives.whereType<CcMermaidArcPrim>().toList();
      expect(arcs, hasLength(3));
      final sweep = arcs.fold<double>(0, (sum, arc) => sum + arc.sweepAngle);
      expect(sweep, closeTo(math.pi * 2, 0.0001));
      expect(arcs.first.startAngle, closeTo(-math.pi / 2, 0.0001));

      final swatches = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.series)
          .toList();
      expect(swatches, hasLength(3));
      expect(swatches.map((prim) => prim.seriesIndex), [0, 1, 2]);
      final legend = scene.primitives
          .whereType<CcMermaidTextPrim>()
          .where((prim) => prim.role == CcMermaidTextRole.legend)
          .map((prim) => prim.text)
          .toList();
      expect(legend, contains('Alpha — 50%'));
      expect(
        legend,
        contains('50%'),
        reason: 'the big slice is labeled in place',
      );
    });

    test('showData reports raw values instead of percentages', () {
      final scene = layoutOf('pie showData\n  "A" : 3\n  "B" : 1');
      final legend = scene.primitives
          .whereType<CcMermaidTextPrim>()
          .map((prim) => prim.text)
          .toList();
      expect(legend, contains('A — 3'));
    });
  });

  group('timeline geometry', () {
    test('periods march rightward with their event cards below the axis', () {
      final scene = layoutOf('''
timeline
  title History
  2002 : LinkedIn
  2004 : Facebook : Google
''');
      Rect textOf(String label) => scene.primitives
          .whereType<CcMermaidTextPrim>()
          .firstWhere((prim) => prim.text == label)
          .rect;
      expect(textOf('2002').center.dx, lessThan(textOf('2004').center.dx));
      expect(
        textOf('LinkedIn').center.dy,
        greaterThan(textOf('2002').center.dy),
      );
      expect(
        textOf('Google').center.dy,
        greaterThan(textOf('Facebook').center.dy),
      );
    });

    test('sections become a labeled band', () {
      final scene = layoutOf('''
timeline
  section Early
    2002 : LinkedIn
  section Late
    2010 : Instagram
''');
      final bands = scene.primitives
          .whereType<CcMermaidShapePrim>()
          .where((prim) => prim.role == CcMermaidPaintRole.series)
          .toList();
      expect(bands, hasLength(2));
      expect(
        scene.primitives.whereType<CcMermaidTextPrim>().map((t) => t.text),
        containsAll(['Early', 'Late']),
      );
    });
  });

  group('scale', () {
    test('a 60-node graph lays out without pathological size', () {
      final source = StringBuffer('flowchart TD\n');
      for (var i = 0; i < 60; i++) {
        source.writeln('  n$i[Node $i] --> n${i + 1}[Node ${i + 1}]');
      }
      final scene = layoutOf(source.toString());
      expect(scene.primitives, isNotEmpty);
      expect(scene.size.height, lessThan(20000));
      expect(scene.size.width, lessThan(20000));
    });

    test('a wide fan-out stays inside sane bounds', () {
      final source = StringBuffer('flowchart TD\n');
      for (var i = 0; i < 40; i++) {
        source.writeln('  root --> leaf$i');
      }
      final scene = layoutOf(source.toString());
      final boxes = _nodeBoxes(scene);
      expect(boxes, hasLength(41));
      for (var i = 0; i < boxes.length; i++) {
        for (var j = i + 1; j < boxes.length; j++) {
          expect(
            boxes[i].deflate(0.5).overlaps(boxes[j].deflate(0.5)),
            isFalse,
          );
        }
      }
    });
  });
}

/// Node (and note/compartment) boxes in a scene — everything a reader would
/// call "a box", excluding clusters, frames, labels chips and bars.
List<Rect> _nodeBoxes(CcMermaidScene scene) => [
  for (final prim in scene.primitives.whereType<CcMermaidShapePrim>())
    if (prim.role == CcMermaidPaintRole.node ||
        prim.role == CcMermaidPaintRole.note ||
        (prim.role == CcMermaidPaintRole.accent &&
            prim.shape != CcMermaidNodeShape.bar))
      prim.rect,
];

/// A ruler with fixed, platform-independent metrics.
class _FixedRuler extends CcMermaidTextRuler {
  const _FixedRuler();

  @override
  Size measure(String text, CcMermaidTextRole role) =>
      Size(text.length * 7.0, _height(role));

  @override
  double lineHeight(CcMermaidTextRole role) => _height(role);

  static double _height(CcMermaidTextRole role) =>
      role == CcMermaidTextRole.title ? 18 : 14;
}
