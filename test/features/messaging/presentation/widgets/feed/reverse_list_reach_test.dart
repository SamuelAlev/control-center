import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// The feed's list as the feed drives it: reverse (index 0 is the newest row),
/// keyed rows found again by key, per-row estimates that are often wrong, rows
/// landing and leaving at the newest end, re-estimates and idle
/// precalculation.
///
/// Guards `patches/super_sliver_list@0.4.1.patch`. Unpatched, a preceding row
/// placed by an estimate larger than the room before the first child landed
/// at a negative offset and layout stopped there: at offset 0 the newer rows
/// were never built and could not be scrolled to (a chat stuck above its
/// newest messages until it was reopened). About a quarter of these seeded
/// runs ended in that state.
void main() {
  for (var seed = 0; seed < 60; seed++) {
    testWidgets('seed $seed: the newest row is reachable at the live edge', (
      tester,
    ) async {
      final rnd = math.Random(seed);
      final list = _ReachList(
        physics: seed.isEven
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics(),
      );
      var next = 0;
      String add(int at) {
        final key = 'r${next++}';
        list.keys.insert(at, key);
        list.heights[key] = 20.0 + rnd.nextInt(500);
        list.estimates[key] = 20.0 + rnd.nextInt(600);
        return key;
      }

      for (var i = 0; i < 40; i++) {
        add(0);
      }
      await tester.pumpWidget(_ReachHarness(list: list));
      await tester.pump();

      final log = <String>[];
      for (var step = 0; step < 40; step++) {
        final position = list.scroll.position;
        switch (rnd.nextInt(9)) {
          case 0:
            final n = 1 + rnd.nextInt(3);
            for (var j = 0; j < n; j++) {
              add(0);
            }
            for (var j = 0; j < n; j++) {
              list.controller.addItem(j);
            }
            log.add('land $n');
          case 1:
            add(1);
            list.controller.addItem(1);
            log.add('land @1');
          case 2:
            final i = rnd.nextInt(math.min(4, list.keys.length));
            list.heights[list.keys[i]] = 20.0 + rnd.nextInt(800);
            log.add('resize $i');
          case 3:
            final to =
                rnd.nextDouble() * math.min(position.maxScrollExtent, 4000);
            list.scroll.jumpTo(to);
            log.add('jump ${to.round()}');
          case 6:
            list.policy.flip();
            log.add('precalc ${list.policy.on}');
          case 7:
            final i = rnd.nextInt(list.keys.length);
            list.estimates[list.keys[i]] = 20.0 + rnd.nextInt(600);
            if (list.controller.extentForIndex(i).$2) {
              list.controller
                ..removeItem(i)
                ..addItem(i);
            }
            log.add('re-estimate $i');
          case 8:
            if (list.keys.length > 5) {
              final i = rnd.nextInt(3);
              list.keys.removeAt(i);
              list.controller.removeItem(i);
              log.add('leave $i');
            }
          default:
            final steps = 1 + rnd.nextInt(10);
            for (var j = 0; j < steps; j++) {
              final pixels = list.scroll.position.pixels;
              list.scroll.jumpTo(math.max(0, pixels - 50 - rnd.nextInt(300)));
              await tester.pump();
            }
            log.add('scroll down x$steps');
        }
        list.rebuild();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
      }

      // The reader scrolls all the way down.
      for (var j = 0; j < 200 && list.scroll.position.pixels > 0; j++) {
        list.scroll.jumpTo(math.max(0, list.scroll.position.pixels - 120));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final newest = find.byKey(ValueKey<String>(list.keys.first));
      expect(newest, findsOneWidget, reason: log.join(', '));
      final viewportBottom = tester.getBottomLeft(find.byType(Scrollable)).dy;
      expect(
        tester.getBottomLeft(newest).dy,
        moreOrLessEquals(viewportBottom - _padding),
        reason: log.join(', '),
      );
    });
  }
}

const double _padding = 16;

class _ReachList {
  _ReachList({required this.physics});

  final ScrollPhysics physics;
  final scroll = ScrollController();
  final controller = ListController();
  final policy = _TogglePolicy();

  /// Row keys, index 0 newest.
  final keys = <String>[];
  final heights = <String, double>{};
  final estimates = <String, double>{};

  VoidCallback rebuild = () {};

  double estimate(int? index) => index == null || index >= keys.length
      ? 100
      : estimates[keys[index]] ?? 100;
}

class _ReachHarness extends StatefulWidget {
  const _ReachHarness({required this.list});

  final _ReachList list;

  @override
  State<_ReachHarness> createState() => _ReachHarnessState();
}

class _ReachHarnessState extends State<_ReachHarness> {
  @override
  void initState() {
    super.initState();
    widget.list.rebuild = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final indexByKey = {
      for (var i = 0; i < list.keys.length; i++) list.keys[i]: i,
    };
    // RTL carve-out: test viewport geometry only.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 400,
          height: 600,
          child: SuperListView.builder(
            controller: list.scroll,
            listController: list.controller,
            reverse: true,
            delayPopulatingCacheArea: true,
            extentEstimation: (index, _) => list.estimate(index),
            extentPrecalculationPolicy: list.policy,
            physics: list.physics,
            padding: const EdgeInsets.all(_padding),
            itemCount: list.keys.length,
            findChildIndexCallback: (key) =>
                key is ValueKey<String> ? indexByKey[key.value] : null,
            itemBuilder: (context, index) {
              final key = list.keys[index];
              return SizedBox(
                key: ValueKey<String>(key),
                height: list.heights[key],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TogglePolicy extends ExtentPrecalculationPolicy {
  bool on = false;

  void flip() {
    on = !on;
    valueDidChange();
  }

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) => on;
}
