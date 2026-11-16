import 'package:control_center/features/messaging/presentation/widgets/feed/anchor_follow_physics.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_row_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Row heights like the real feed: one-liners mixed with very tall transcripts.
List<double> _heights(int count) => List<double>.generate(
  count,
  (i) => switch (i % 5) {
    0 => 44.0,
    1 => 900.0,
    2 => 44.0,
    3 => 620.0,
    _ => 120.0,
  },
);

class _ArmablePolicy extends ExtentPrecalculationPolicy {
  bool armed = false;

  void arm() {
    armed = true;
    valueDidChange();
  }

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) => armed;
}

class _Harness {
  _Harness(int count) : heights = _heights(count);

  final List<double> heights;
  final scroll = ScrollController();
  final list = ListController();
  final policy = _ArmablePolicy();
  DateTime now = DateTime(2026);
  late final state = FollowState(now: () => now);
  late final geometry = FeedRowGeometry(list);

  String keyOf(int index) => 'row:$index';

  int? indexOf(String key) => int.tryParse(key.substring(4));

  void dispose() {
    scroll.dispose();
    list.dispose();
  }

  Widget build({ScrollPhysics? physics}) {
    state.probe = (key) {
      final index = indexOf(key);
      return index == null ? null : geometry.placementOf(index)?.trailingEdge;
    };
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) {
            if (n.depth == 0) {
              state.noteUserScroll();
            }
            return false;
          },
          child: SuperListView.builder(
            controller: scroll,
            listController: list,
            reverse: true,
            extentPrecalculationPolicy: policy,
            // Deliberately wrong estimates: every unbuilt row guesses 100px.
            extentEstimation: (_, _) => 100,
            physics:
                physics ??
                AnchorFollowPhysics(
                  state: state,
                ).applyTo(const ClampingScrollPhysics()),
            itemCount: heights.length,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey(keyOf(index)),
              height: heights[index],
              child: Text('row $index'),
            ),
          ),
        ),
      ),
    );
  }

  /// What the feed does after each frame: remember the row under the top edge.
  void record(WidgetTester tester) {
    geometry.attach(tester.element(find.byType(SuperListView)));
    state.anchor = geometry.anchorAtTop(scroll.position, keyOf);
  }

  Future<void> pumpAndRecord(WidgetTester tester, {int frames = 1}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump();
      record(tester);
    }
  }

  /// Screen y of the anchored row's top edge.
  double anchoredRowTop(WidgetTester tester) {
    final key = state.anchor!.rowKey;
    return tester.getTopLeft(find.byKey(ValueKey(key))).dy;
  }
}

/// Lets the user-scroll hold lapse so the physics acts again.
Future<void> _settle(WidgetTester tester, _Harness h) async {
  h.now = h.now.add(kUserScrollCompensationHold * 2);
  await tester.pump();
}

void main() {
  testWidgets('measuring older rows above the viewport does not move the '
      'reader', (tester) async {
    final h = _Harness(300);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    h.scroll.jumpTo(6000);
    h.state.mode = FeedFollowMode.free;
    await _settle(tester, h);
    await h.pumpAndRecord(tester);
    final before = h.anchoredRowTop(tester);
    final maxBefore = h.scroll.position.maxScrollExtent;

    // The idle precalculation builds rows nobody is looking at and replaces
    // their 100px guesses with real extents.
    h.policy.arm();
    await h.pumpAndRecord(tester, frames: 30);

    expect(
      h.scroll.position.maxScrollExtent,
      isNot(closeTo(maxBefore, 1)),
      reason: 'the precalculation must have changed the list extent',
    );
    expect(h.anchoredRowTop(tester), closeTo(before, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a newer row growing below the viewport holds the reader', (
    tester,
  ) async {
    final h = _Harness(60);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    h.scroll.jumpTo(400);
    h.state.mode = FeedFollowMode.free;
    await _settle(tester, h);
    await h.pumpAndRecord(tester);
    final before = h.anchoredRowTop(tester);

    // The streaming answer (index 0, newest) grows twice.
    h.heights[0] += 500;
    await tester.pumpWidget(h.build());
    h.record(tester);
    h.heights[0] += 300;
    await tester.pumpWidget(h.build());
    h.record(tester);

    expect(h.anchoredRowTop(tester), closeTo(before, 0.5));
  });

  testWidgets('a row opening below the top edge keeps the top row in place', (
    tester,
  ) async {
    final h = _Harness(60);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    h.scroll.jumpTo(1500);
    h.state.mode = FeedFollowMode.free;
    await _settle(tester, h);
    await h.pumpAndRecord(tester);
    final before = h.anchoredRowTop(tester);
    final anchorIndex = h.indexOf(h.state.anchor!.rowKey)!;

    // A tool body below the anchored row opens, then closes again.
    h.heights[anchorIndex - 1] += 400;
    await tester.pumpWidget(h.build());
    h.record(tester);
    expect(h.anchoredRowTop(tester), closeTo(before, 0.5));

    h.heights[anchorIndex - 1] -= 400;
    await tester.pumpWidget(h.build());
    h.record(tester);
    expect(h.anchoredRowTop(tester), closeTo(before, 0.5));
  });

  testWidgets('following the live edge lets growth push the view', (
    tester,
  ) async {
    final h = _Harness(60);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    await h.pumpAndRecord(tester);
    expect(h.state.mode, FeedFollowMode.following);

    h.heights[0] += 500;
    await tester.pumpWidget(h.build());
    expect(h.scroll.position.pixels, 0);
    // The newest row's bottom stays on the viewport's bottom edge.
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('row:0'))).dy,
      closeTo(tester.getBottomLeft(find.byType(SuperListView)).dy, 0.5),
    );
  });

  testWidgets('the anchor is released while the user drives the position', (
    tester,
  ) async {
    final h = _Harness(60);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    h.scroll.jumpTo(400);
    h.state.mode = FeedFollowMode.free;
    await _settle(tester, h);
    await h.pumpAndRecord(tester);
    final pixels = h.scroll.position.pixels;

    h.state.noteUserScroll();
    h.heights[0] += 500;
    await tester.pumpWidget(h.build());

    expect(h.scroll.position.pixels, pixels);
  });

  testWidgets('dragging and flinging through variable-height history while '
      'the precalculation runs throws no layout-cycle errors', (tester) async {
    final h = _Harness(300);
    addTearDown(h.dispose);
    await tester.pumpWidget(h.build());
    h.state.mode = FeedFollowMode.free;
    h.policy.arm();
    await h.pumpAndRecord(tester);
    final list = find.byType(SuperListView);
    for (var i = 0; i < 8; i++) {
      await tester.drag(list, const Offset(0, 400));
      await h.pumpAndRecord(tester);
      await _settle(tester, h);
      // Content changes while idle between gestures: the anchor acts.
      h.heights[0] += 30;
      await tester.pumpWidget(h.build());
      h.record(tester);
      await tester.fling(list, const Offset(0, 600), 1200);
      await h.pumpAndRecord(tester, frames: 3);
      expect(tester.takeException(), isNull);
      await tester.fling(list, const Offset(0, -500), 1000);
      await h.pumpAndRecord(tester, frames: 3);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('heldPixels is residual: same answer however often it is asked', () {
    final state = FollowState()
      ..anchor = (rowKey: 'a', trailingEdge: 1000, pixels: 400)
      ..probe = (_) => 1250;
    expect(state.heldPixels(), 650);
    expect(state.heldPixels(), 650);
    state.probe = (_) => null;
    expect(state.heldPixels(), isNull);
  });
}
