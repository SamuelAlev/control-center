import 'dart:async';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _ws = 'ws1';

/// One fact list, re-emitted as a NEW list identity — what a live server
/// subscription does every time anything writes a memory fact.
final _facts = [
  _fact('f1', 'prefs', 'editor'),
  _fact('f2', 'prefs', 'shell'),
  _fact('f3', 'codebase', 'router'),
  _fact('f4', 'codebase', 'db'),
];

MemoryFact _fact(String id, String domain, String topic) => MemoryFact(
  id: id,
  workspaceId: _ws,
  domain: domain,
  topic: topic,
  content: 'content $id',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _wrap({Stream<List<MemoryFact>>? facts}) => ProviderScope(
  overrides: [
    memoryFactsProvider(
      _ws,
    ).overrideWith((ref) => facts ?? Stream.value(_facts)),
    memoryPoliciesProvider(_ws).overrideWith(
      (ref) => Stream.value([
        MemoryPolicy(
          id: 'p1',
          workspaceId: _ws,
          domain: 'prefs',
          rule: 'never guess',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
    ),
    memoryDomainsProvider(_ws).overrideWith(
      (ref) => Stream.value([
        MemoryDomain(
          id: 'd1',
          workspaceId: _ws,
          name: 'prefs',
          label: 'Preferences',
          createdAt: DateTime(2026),
          createdByRole: 'ceo',
        ),
      ]),
    ),
  ],
  child: testWrap(const KnowledgeGraph(workspaceId: _ws)),
);

/// cc_ui buttons carry a [CcTooltip], not a Material one, so `find.byTooltip`
/// never sees them — match the button's own property instead.
Finder _control(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

TransformationController _transformOf(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!;

double _scaleOf(WidgetTester tester) =>
    _transformOf(tester).value.getMaxScaleOnAxis();

Offset _translationOf(WidgetTester tester) {
  final t = _transformOf(tester).value.getTranslation();
  return Offset(t.x, t.y);
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  Stream<List<MemoryFact>>? facts,
  Size view = const Size(1200, 800),
}) async {
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(facts: facts));
  await tester.pumpAndSettle();
}

/// Enough domains that the graph cannot fit a small viewport at 1:1, so the
/// opening fit has to scale DOWN — the only case in which a fit transform's
/// scale is observable at all.
final _wideFacts = [
  for (var d = 0; d < 8; d++)
    for (var t = 0; t < 2; t++) _fact('f$d$t', 'domain$d', 'topic$d$t'),
];

/// The shape of a real workspace, and the shape that broke the old layout: one
/// large domain carrying most of the topics, one small one beside it.
final _denseFacts = [
  for (var t = 0; t < 22; t++) _fact('a$t', 'architecture', 'arch topic $t'),
  for (var t = 0; t < 5; t++) _fact('b$t', 'features', 'feature topic $t'),
];

/// The expand/collapse control on one specific topic card. Addressed through
/// the node's key rather than by position, since clusters are ordered by domain
/// label and every toggle carries the same tooltip.
Finder _topicToggle(String domain, String topic, String label) =>
    find.descendant(
      of: find.byKey(ValueKey('topic:$domain/$topic')),
      matching: find.byWidgetPredicate(
        (w) => w is CcTooltip && w.message == label,
      ),
    );

void main() {
  testWidgets('zoom buttons scale the canvas', (tester) async {
    await _pumpGraph(tester);

    // Regression: the controls were handed the viewport SIZE, which the canvas
    // only measures during layout — so they captured Size.zero on the single
    // build this graph gets and both buttons silently did nothing.
    final opening = _scaleOf(tester);
    await tester.tap(_control('Zoom in'));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), greaterThan(opening));

    await tester.tap(_control('Zoom out'));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), closeTo(opening, 1e-6));
  });

  testWidgets('the opening fit reports the scale it actually drew at', (
    tester,
  ) async {
    await _pumpGraph(
      tester,
      facts: Stream.value(_wideFacts),
      view: const Size(600, 400),
    );

    // The fit had to scale down, and the matrix must SAY so on every axis:
    // getMaxScaleOnAxis takes the largest column norm, so leaving z at 1
    // reported 1.0 to everything that reads the zoom back.
    final drawn = _transformOf(tester).value.getColumn(0).length;
    expect(drawn, lessThan(1.0));
    expect(_scaleOf(tester), closeTo(drawn, 1e-9));
  });

  testWidgets('the first zoom press is one step, not a leap', (tester) async {
    await _pumpGraph(
      tester,
      facts: Stream.value(_wideFacts),
      view: const Size(600, 400),
    );

    final fitted = _scaleOf(tester);
    expect(fitted, lessThan(1.0), reason: 'this graph had to be scaled to fit');

    await tester.tap(_control('Zoom in'));
    await tester.pumpAndSettle();

    // One press is one 1.25× step. It used to read the zoom as 1.0 and jump
    // straight to 1.25 — five times bigger from a 0.25 fit.
    expect(_scaleOf(tester), closeTo(fitted * 1.25, 1e-6));
  });

  testWidgets('a plain mouse wheel pans instead of zooming', (tester) async {
    await _pumpGraph(tester);

    final scale = _scaleOf(tester);
    final before = _translationOf(tester);

    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(wheel.hover(const Offset(600, 400)));
    await tester.sendEventToBinding(wheel.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();

    // A wheel is how a mouse crosses a graph. Zooming on it collapsed the whole
    // canvas toward the cursor at exp(-dy/200) per notch and left nothing to
    // scroll with.
    expect(_scaleOf(tester), closeTo(scale, 1e-9));
    expect(_translationOf(tester).dy, lessThan(before.dy));
  });

  testWidgets('⌘ + wheel still zooms', (tester) async {
    await _pumpGraph(tester);

    final scale = _scaleOf(tester);
    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(wheel.hover(const Offset(600, 400)));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendEventToBinding(wheel.scroll(const Offset(0, -120)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(_scaleOf(tester), greaterThan(scale));
  });

  testWidgets('dragging empty canvas pans it freely in both directions', (
    tester,
  ) async {
    await _pumpGraph(tester);

    final before = _translationOf(tester);
    await tester.dragFrom(const Offset(30, 700), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(_translationOf(tester).dy, closeTo(before.dy - 120, 0.01));

    await tester.dragFrom(const Offset(30, 700), const Offset(0, 240));
    await tester.pumpAndSettle();
    expect(_translationOf(tester).dy, closeTo(before.dy + 120, 0.01));
  });

  testWidgets('a trackpad scroll over a node pans the canvas, not the node', (
    tester,
  ) async {
    await _pumpGraph(tester);

    final node = find.text('Preferences');
    expect(node, findsOneWidget);
    final nodeCentre = tester.getCenter(node);
    final before = _translationOf(tester);

    final pad = TestPointer(2, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(pad.panZoomStart(nodeCentre));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.sendEventToBinding(
      pad.panZoomUpdate(nodeCentre, pan: const Offset(0, -80)),
    );
    await tester.pumpAndSettle();
    await tester.sendEventToBinding(pad.panZoomEnd());
    await tester.pumpAndSettle();

    // The pan recogniser on a node accepts pan-zoom events and, being inner,
    // wins the arena — so a two-finger scroll that started over a card used to
    // drag the card instead of moving the view.
    expect(_translationOf(tester).dy, lessThan(before.dy));
    expect(
      tester.getCenter(node).dy - nodeCentre.dy,
      closeTo(_translationOf(tester).dy - before.dy, 0.01),
      reason: 'the node moved only because the whole canvas did',
    );
  });

  testWidgets('a data refresh keeps a node the operator moved', (tester) async {
    final refreshes = StreamController<List<MemoryFact>>();
    addTearDown(refreshes.close);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Not pumpAndSettle: with nothing emitted yet the graph shows a spinner,
    // which never settles.
    await tester.pumpWidget(_wrap(facts: refreshes.stream));
    await tester.pump();
    refreshes.add(_facts);
    await tester.pumpAndSettle();

    final node = find.text('Preferences');
    final placed = tester.getCenter(node);
    final view = _translationOf(tester);
    final pan = await tester.startGesture(placed);
    // Stepped, so the first move is spent on the touch slop rather than the
    // whole drag being swallowed by it.
    for (var i = 0; i < 4; i++) {
      await pan.moveBy(const Offset(0, 40));
      await tester.pump();
    }
    await pan.up();
    await tester.pumpAndSettle();

    final moved = tester.getCenter(node);
    expect(moved.dy, greaterThan(placed.dy));
    expect(
      _translationOf(tester),
      view,
      reason: 'the card moved, not the view',
    );

    // Any agent writing a fact re-emits the whole list; re-flowing the layout
    // used to snap every moved card back into its row.
    refreshes.add([..._facts]);
    await tester.pumpAndSettle();
    expect(tester.getCenter(node).dy, closeTo(moved.dy, 0.01));
  });

  testWidgets('a workspace-sized graph opens at a legible scale', (
    tester,
  ) async {
    await _pumpGraph(tester, facts: Stream.value(_denseFacts));

    // The complaint this layout answers. Laid out as one row per level, 27
    // topics made a canvas roughly 5,500 x 550 — a 10:1 band, which "fit to
    // view" solves at about 0.2 and renders as unreadable specks. Clustered and
    // packed toward a landscape aspect, the same data opens above half size.
    expect(_scaleOf(tester), greaterThan(0.5));
  });

  testWidgets('facts stay off the canvas until their topic is expanded', (
    tester,
  ) async {
    await _pumpGraph(tester);

    // The overview is domains and topics. Rendering every fact up front is what
    // made the tab a wall of cards.
    expect(find.text('content f1'), findsNothing);
    expect(find.text('editor'), findsOneWidget);

    await tester.tap(_topicToggle('prefs', 'editor', 'Show facts'));
    await tester.pumpAndSettle();

    expect(find.text('content f1'), findsOneWidget);
    // Only the topic that was asked about opens.
    expect(find.text('content f3'), findsNothing);

    await tester.tap(_topicToggle('prefs', 'editor', 'Hide facts'));
    await tester.pumpAndSettle();
    expect(find.text('content f1'), findsNothing);
  });

  testWidgets('the canvas control expands and collapses every topic', (
    tester,
  ) async {
    await _pumpGraph(tester);

    await tester.tap(_control('Expand all facts'));
    await tester.pumpAndSettle();
    for (final fact in _facts) {
      expect(find.text('content ${fact.id}'), findsOneWidget);
    }

    await tester.tap(_control('Collapse all facts'));
    await tester.pumpAndSettle();
    for (final fact in _facts) {
      expect(find.text('content ${fact.id}'), findsNothing);
    }
  });

  testWidgets('two domains sharing a topic name keep separate nodes', (
    tester,
  ) async {
    await _pumpGraph(
      tester,
      facts: Stream.value([
        _fact('x1', 'prefs', 'shared'),
        _fact('x2', 'codebase', 'shared'),
      ]),
    );

    // Keyed on the bare topic name these collapsed into one node owned by
    // whichever domain got there first, which put an edge across two clusters.
    expect(find.text('shared'), findsNWidgets(2));
  });

  testWidgets('each domain is drawn as its own cluster, not one long row', (
    tester,
  ) async {
    await _pumpGraph(tester, facts: Stream.value(_wideFacts));

    final domains = [
      for (var d = 0; d < 8; d++) tester.getTopLeft(find.text('domain$d')),
    ];
    final rows = domains.map((o) => o.dy.round()).toSet();
    expect(
      rows.length,
      greaterThan(1),
      reason: 'eight domains on one row is the 12:1 band this replaced',
    );
  });

  testWidgets('fit to view puts a panned canvas back', (tester) async {
    await _pumpGraph(tester);

    final fitted = _translationOf(tester);
    await tester.dragFrom(const Offset(30, 700), const Offset(-300, -300));
    await tester.pumpAndSettle();
    expect(_translationOf(tester), isNot(fitted));

    await tester.tap(_control('Fit to view'));
    await tester.pumpAndSettle();
    expect(_translationOf(tester).dx, closeTo(fitted.dx, 0.5));
    expect(_translationOf(tester).dy, closeTo(fitted.dy, 0.5));
  });
}
