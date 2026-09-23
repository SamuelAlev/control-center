import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

Future<void> _settlePointerFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Rect _highlightRect(WidgetTester tester) {
  return tester.getRect(
    find.descendant(
      of: find.byKey(const ValueKey<String>('cc-fluid-hover-transform')),
      matching: find.byType(DecoratedBox),
    ),
  );
}

void main() {
  testWidgets('nearest vertical item stays active through inter-item gaps', (
    tester,
  ) async {
    final changes = <int?>[];
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 160,
            child: CcFluidHover(
              itemCount: 3,
              onActiveIndexChanged: changes.add,
              itemBuilder: (context, index) => CcTappable(
                onPressed: () {},
                builder: (context, states) => SizedBox(
                  key: ValueKey(
                    'row-$index-${states.contains(WidgetState.hovered)}',
                  ),
                  height: 20,
                ),
              ),
              layoutBuilder: (context, items) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    items[0],
                    const SizedBox(height: 20),
                    items[1],
                    const SizedBox(height: 20),
                    items[2],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final first = tester.getRect(find.byKey(const ValueKey('row-0-false')));
    await pointer.addPointer(location: first.center);
    await _settlePointerFrame(tester);
    expect(changes.last, 0);
    expect(find.byKey(const ValueKey('row-0-true')), findsOneWidget);

    final activeFirst = tester.getRect(
      find.byKey(const ValueKey('row-0-true')),
    );
    await pointer.moveTo(Offset(activeFirst.center.dx, activeFirst.bottom + 4));
    await _settlePointerFrame(tester);
    expect(
      changes.last,
      0,
      reason: 'The near side of the gap belongs to row 0.',
    );
    expect(find.byKey(const ValueKey('row-0-true')), findsOneWidget);

    await pointer.moveTo(
      Offset(activeFirst.center.dx, activeFirst.bottom + 16),
    );
    await _settlePointerFrame(tester);
    expect(
      changes.last,
      1,
      reason: 'The far side of the gap belongs to row 1.',
    );
    expect(find.byKey(const ValueKey('row-1-true')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cc-fluid-hover-highlight')),
      findsOneWidget,
      reason: 'One shared highlight paints the whole group.',
    );

    await pointer.moveTo(const Offset(1, 1));
    await _settlePointerFrame(tester);
    expect(changes.last, isNull);
  });

  testWidgets('an item containing the pointer wins over a nearer center', (
    tester,
  ) async {
    int? active;
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 2,
              onActiveIndexChanged: (index) => active = index,
              itemBuilder: (context, index) => SizedBox(
                key: ValueKey('item-$index'),
                height: index == 0 ? 100 : 20,
              ),
              layoutBuilder: (context, items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getRect(find.byKey(const ValueKey('item-0')));
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: Offset(first.center.dx, first.bottom - 2),
    );
    await _settlePointerFrame(tester);

    expect(active, 0);
  });

  testWidgets('disabled items are skipped by nearest-target selection', (
    tester,
  ) async {
    int? active;
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 3,
              isItemDisabled: (index) => index == 1,
              onActiveIndexChanged: (index) => active = index,
              itemBuilder: (context, index) =>
                  SizedBox(key: ValueKey('disabled-item-$index'), height: 24),
              layoutBuilder: (context, items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final disabled = tester.getRect(
      find.byKey(const ValueKey('disabled-item-1')),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: Offset(disabled.center.dx, disabled.bottom - 2),
    );
    await _settlePointerFrame(tester);

    expect(active, 2);
  });

  testWidgets('boundary items split independent hover groups', (tester) async {
    final changes = <int?>[];
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 3,
              isItemBoundary: (index) => index == 1,
              onActiveIndexChanged: changes.add,
              itemBuilder: (context, index) =>
                  SizedBox(key: ValueKey('boundary-item-$index'), height: 24),
              layoutBuilder: (context, items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester
          .getRect(find.byKey(const ValueKey('boundary-item-0')))
          .center,
    );
    await _settlePointerFrame(tester);
    expect(changes.last, 0);

    await pointer.moveTo(
      tester.getRect(find.byKey(const ValueKey('boundary-item-1'))).center,
    );
    await _settlePointerFrame(tester);
    expect(changes.last, isNull);
  });

  testWidgets('x and xy axes choose the nearest center on their geometry', (
    tester,
  ) async {
    final active = <String, int?>{};
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcFluidHover(
                axis: CcFluidHoverAxis.x,
                itemCount: 3,
                onActiveIndexChanged: (index) => active['x'] = index,
                itemBuilder: (context, index) =>
                    SizedBox(key: ValueKey('x-$index'), width: 20, height: 20),
                layoutBuilder: (context, items) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    items[0],
                    const SizedBox(width: 20),
                    items[1],
                    const SizedBox(width: 20),
                    items[2],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CcFluidHover(
                axis: CcFluidHoverAxis.xy,
                itemCount: 4,
                onActiveIndexChanged: (index) => active['xy'] = index,
                itemBuilder: (context, index) =>
                    SizedBox(key: ValueKey('xy-$index')),
                layoutBuilder: (context, items) => SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 20,
                        height: 20,
                        child: items[0],
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        width: 20,
                        height: 20,
                        child: items[1],
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        width: 20,
                        height: 20,
                        child: items[2],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: 20,
                        height: 20,
                        child: items[3],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final lastX = tester.getRect(find.byKey(const ValueKey('x-2')));
    await pointer.addPointer(location: lastX.center);
    await _settlePointerFrame(tester);
    expect(active['x'], 2);

    final lastGrid = tester.getRect(find.byKey(const ValueKey('xy-3')));
    await pointer.moveTo(lastGrid.center);
    await _settlePointerFrame(tester);
    expect(active['xy'], 3);
  });

  testWidgets('reduced motion snaps highlight travel', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcFluidHover(
            itemCount: 2,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey('reduced-$index'),
              width: 80,
              height: 24,
            ),
            layoutBuilder: (context, items) =>
                Column(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
        theme: CcThemeData.light(reducedMotion: true),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester.getCenter(find.byKey(const ValueKey('reduced-0'))),
    );
    await _settlePointerFrame(tester);

    final animation = tester.widget<TweenAnimationBuilder<Rect>>(
      find.byType(TweenAnimationBuilder<Rect>),
    );
    expect(animation.duration, Duration.zero);
    final fade = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('cc-fluid-hover-highlight')),
    );
    expect(fade.duration, CcMotion.fade);
  });

  testWidgets('ancestor scroll retargets under a still pointer', (
    tester,
  ) async {
    int? active;
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            height: 24,
            child: SingleChildScrollView(
              child: CcFluidHover(
                itemCount: 3,
                onActiveIndexChanged: (index) => active = index,
                itemBuilder: (context, index) =>
                    SizedBox(key: ValueKey('scroll-item-$index'), height: 24),
                layoutBuilder: (context, items) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final stayAt = tester.getCenter(
      find.byKey(const ValueKey('scroll-item-0')),
    );
    await pointer.addPointer(location: stayAt);
    await _settlePointerFrame(tester);
    expect(active, 0);

    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(24);
    await tester.pump();
    await tester.pump();

    expect(active, 1, reason: 'Row 1 scrolled under the still pointer.');
    expect(
      tester
          .widget<TweenAnimationBuilder<Rect>>(
            find.byType(TweenAnimationBuilder<Rect>),
          )
          .duration,
      CcMotion.fast,
      reason: 'A new row under the pointer still travels.',
    );
  });

  testWidgets('descendant list scroll retargets after layout', (tester) async {
    int? active;
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcFluidHover(
            itemCount: 6,
            onActiveIndexChanged: (index) => active = index,
            itemBuilder: (context, index) =>
                SizedBox(key: ValueKey('list-item-$index'), height: 24),
            layoutBuilder: (context, items) => SizedBox(
              width: 120,
              height: 24,
              child: ListView(padding: EdgeInsets.zero, children: items),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester.getCenter(find.byKey(const ValueKey('list-item-0'))),
    );
    await _settlePointerFrame(tester);
    expect(active, 0);

    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(24);
    await tester.pump();
    await tester.pump();

    expect(active, 1);
  });

  testWidgets('tappable inside a boundary item keeps its own hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 160,
            child: CcFluidHover(
              itemCount: 3,
              isItemBoundary: (index) => index == 1,
              itemBuilder: (context, index) => CcTappable(
                onPressed: () {},
                builder: (context, states) => SizedBox(
                  key: ValueKey(
                    'boundary-tap-$index-${states.contains(WidgetState.hovered)}',
                  ),
                  height: 24,
                ),
              ),
              layoutBuilder: (context, items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester
          .getRect(find.byKey(const ValueKey('boundary-tap-1-false')))
          .center,
    );
    await _settlePointerFrame(tester);

    expect(find.byKey(const ValueKey('boundary-tap-1-true')), findsOneWidget);
    expect(find.byKey(const ValueKey('boundary-tap-0-true')), findsNothing);
    expect(find.byKey(const ValueKey('boundary-tap-2-true')), findsNothing);
  });

  testWidgets('a growing hovered item keeps the wash on its new bounds', (
    tester,
  ) async {
    final height = ValueNotifier<double>(48);
    addTearDown(height.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 1,
              itemBuilder: (context, index) => ValueListenableBuilder<double>(
                valueListenable: height,
                builder: (context, value, _) =>
                    SizedBox(key: const ValueKey('grow'), height: value),
              ),
              layoutBuilder: (context, items) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final before = tester.getRect(find.byKey(const ValueKey('grow')));
    await pointer.addPointer(location: before.center);
    await _settlePointerFrame(tester);
    expect(_highlightRect(tester), before);

    // The row grows under a still pointer, the way a space expands into its
    // conversations after a click.
    height.value = 160;
    await tester.pump();
    await tester.pump();

    final after = tester.getRect(find.byKey(const ValueKey('grow')));
    expect(after.height, 160);
    expect(_highlightRect(tester), after);
    expect(
      tester
          .widget<TweenAnimationBuilder<Rect>>(
            find.byType(TweenAnimationBuilder<Rect>),
          )
          .duration,
      Duration.zero,
      reason: 'Same item, new geometry snaps instead of travelling.',
    );
  });

  testWidgets('a growing item does not rebuild the rest of the group', (
    tester,
  ) async {
    final height = ValueNotifier<double>(40);
    addTearDown(height.dispose);
    var builds = 0;
    await tester.pumpWidget(
      ccTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 2,
              itemBuilder: (context, index) {
                builds++;
                if (index == 0) {
                  return ValueListenableBuilder<double>(
                    valueListenable: height,
                    builder: (context, value, _) =>
                        SizedBox(key: const ValueKey('grow'), height: value),
                  );
                }
                return const SizedBox(key: ValueKey('other'), height: 40);
              },
              layoutBuilder: (context, items) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester.getCenter(find.byKey(const ValueKey('grow'))),
    );
    await _settlePointerFrame(tester);
    final afterHover = builds;

    // A space opening under the pointer. The wash has to track the new
    // bounds, and the other rows must not be built again to do it.
    height.value = 120;
    await tester.pump();
    await tester.pump();

    expect(builds, afterHover);
    expect(
      _highlightRect(tester).height,
      tester.getRect(find.byKey(const ValueKey('grow'))).height,
    );
  });

  testWidgets('a layout shift retargets the row under a still pointer', (
    tester,
  ) async {
    final heights = ValueNotifier<List<double>>(const [40, 40, 40]);
    addTearDown(heights.dispose);
    int? active;
    await tester.pumpWidget(
      ccTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 120,
            child: CcFluidHover(
              itemCount: 3,
              onActiveIndexChanged: (index) => active = index,
              itemBuilder: (context, index) =>
                  ValueListenableBuilder<List<double>>(
                    valueListenable: heights,
                    builder: (context, value, _) => SizedBox(
                      key: ValueKey('shift-$index'),
                      height: value[index],
                    ),
                  ),
              layoutBuilder: (context, items) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester.getCenter(find.byKey(const ValueKey('shift-1'))),
    );
    await _settlePointerFrame(tester);
    expect(active, 1);

    // The row above grows by more than the gap to the pointer, so the
    // pointer is now inside row 0. No pointer event is sent.
    heights.value = const [100, 40, 40];
    await tester.pump();
    await tester.pump();

    expect(active, 0);
    await tester.pump(CcMotion.fast);
    expect(
      _highlightRect(tester),
      tester.getRect(find.byKey(const ValueKey('shift-0'))),
    );
  });
}
