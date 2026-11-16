import 'package:control_center/features/messaging/presentation/widgets/feed/list_extent_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Real row heights by key. Every height is distinct, and none is
/// [_estimate], so a kept measurement is told apart from a fresh estimate.
const Map<String, double> _heights = {
  'a': 20,
  'b': 22,
  'c': 24,
  'd': 26,
  'e': 28,
  'f': 30,
  'g': 32,
  'd1': 34,
  'd2': 36,
  'd3': 38,
  'z': 40,
};

/// What the list's estimator answers for every row.
const double _estimate = 100;

Widget _feed(ListController controller, List<String> keys) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: SuperListView.builder(
        listController: controller,
        reverse: true,
        extentEstimation: (index, crossAxisExtent) => _estimate,
        itemCount: keys.length,
        itemBuilder: (context, index) => SizedBox(
          key: ValueKey<String>(keys[index]),
          height: _heights[keys[index]],
        ),
      ),
    ),
  );
}

/// Asserts the controller holds one extent per key: the real height for
/// every key not in [fresh], an estimate for every key in it.
void _expectExtents(
  ListController controller,
  List<String> keys, {
  Set<String> fresh = const {},
}) {
  expect(controller.numberOfItems, keys.length);
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final (extent, isEstimated) = controller.extentForIndex(i);
    if (fresh.contains(key)) {
      expect(isEstimated, isTrue, reason: '$key at $i should be estimated');
      expect(extent, _estimate, reason: '$key at $i');
    } else {
      expect(isEstimated, isFalse, reason: '$key at $i should be measured');
      expect(extent, _heights[key], reason: '$key at $i');
    }
  }
}

/// Pumps [keys] and checks every row laid out at its real height.
Future<void> _pumpAndVerify(
  WidgetTester tester,
  ListController controller,
  List<String> keys,
) async {
  await tester.pumpWidget(_feed(controller, keys));
  for (final key in keys) {
    expect(
      tester.getSize(find.byKey(ValueKey<String>(key))).height,
      _heights[key],
    );
  }
  _expectExtents(controller, keys);
  expect(
    controller.totalExtent,
    keys.fold<double>(0, (sum, key) => sum + _heights[key]!),
  );
}

void main() {
  // Index order: index 0 is the newest row of the reverse feed.
  const initial = ['f', 'e', 'd', 'c', 'b', 'a'];

  testWidgets('keeps measured extents through inserts and removals', (
    tester,
  ) async {
    final controller = ListController();
    addTearDown(controller.dispose);
    await _pumpAndVerify(tester, controller, initial);

    // A new message lands at the newest end.
    const prepended = ['g', 'f', 'e', 'd', 'c', 'b', 'a'];
    expect(syncListExtents(controller, initial, prepended), isTrue);
    _expectExtents(controller, prepended, fresh: {'g'});
    await _pumpAndVerify(tester, controller, prepended);

    // One row in the middle becomes three (a turn split into segments).
    const split = ['g', 'f', 'e', 'd1', 'd2', 'd3', 'c', 'b', 'a'];
    expect(syncListExtents(controller, prepended, split), isTrue);
    _expectExtents(controller, split, fresh: {'d1', 'd2', 'd3'});
    await _pumpAndVerify(tester, controller, split);

    // A row is deleted.
    const removed = ['g', 'f', 'd1', 'd2', 'd3', 'c', 'b', 'a'];
    expect(syncListExtents(controller, split, removed), isTrue);
    _expectExtents(controller, removed);
    await _pumpAndVerify(tester, controller, removed);

    // Older history arrives at the oldest end.
    const appended = ['g', 'f', 'd1', 'd2', 'd3', 'c', 'b', 'a', 'z'];
    expect(syncListExtents(controller, removed, appended), isTrue);
    _expectExtents(controller, appended, fresh: {'z'});
    await _pumpAndVerify(tester, controller, appended);

    // Nothing changed.
    expect(syncListExtents(controller, appended, List.of(appended)), isTrue);
    _expectExtents(controller, appended);
  });

  testWidgets('three rows collapsing back into one', (tester) async {
    final controller = ListController();
    addTearDown(controller.dispose);
    const before = ['g', 'd1', 'd2', 'd3', 'a'];
    const after = ['g', 'd', 'a'];
    await _pumpAndVerify(tester, controller, before);

    expect(syncListExtents(controller, before, after), isTrue);
    _expectExtents(controller, after, fresh: {'d'});
    await _pumpAndVerify(tester, controller, after);
  });

  testWidgets('a full replacement re-estimates every row', (tester) async {
    final controller = ListController();
    addTearDown(controller.dispose);
    const before = ['c', 'b', 'a'];
    const after = ['g', 'f'];
    await _pumpAndVerify(tester, controller, before);

    expect(syncListExtents(controller, before, after), isTrue);
    _expectExtents(controller, after, fresh: {'g', 'f'});
    await _pumpAndVerify(tester, controller, after);
  });

  testWidgets('inserts between a kept prefix and suffix', (tester) async {
    final controller = ListController();
    addTearDown(controller.dispose);
    const before = ['b', 'a'];
    const after = ['b', 'c', 'a'];
    await _pumpAndVerify(tester, controller, before);

    expect(syncListExtents(controller, before, after), isTrue);
    _expectExtents(controller, after, fresh: {'c'});
    await _pumpAndVerify(tester, controller, after);

    // Shrinking to the shared prefix: only the tail goes.
    const shrunk = ['b'];
    expect(syncListExtents(controller, after, shrunk), isTrue);
    _expectExtents(controller, shrunk);
  });

  testWidgets('refuses when the count does not match the old keys', (
    tester,
  ) async {
    final controller = ListController();
    addTearDown(controller.dispose);
    await _pumpAndVerify(tester, controller, initial);

    expect(
      syncListExtents(controller, const ['x', 'y'], const ['w', 'x', 'y']),
      isFalse,
    );
    _expectExtents(controller, initial);
  });

  test('refuses on a detached controller', () {
    final controller = ListController();
    addTearDown(controller.dispose);
    expect(controller.isAttached, isFalse);
    expect(syncListExtents(controller, const ['a'], const ['b', 'a']), isFalse);
  });
}
