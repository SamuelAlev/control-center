import 'package:cc_ui/src/components/cc_resizable.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  List<CcResizableRegion> regions() => [
    CcResizableRegion.child(
      child: const Text('left'),
      initialExtent: 200,
      minExtent: 100,
      maxExtent: 280,
    ),
    CcResizableRegion.child(
      child: const Text('right'),
      initialExtent: 200,
      minExtent: 100,
      maxExtent: 280,
    ),
  ];

  // Center gives the SizedBox loose constraints; placed bare as an Overlay entry
  // it would receive tight full-screen constraints and ignore its own size.
  // Width 400 holds both regions at their [200, 200] initial extents — the
  // divider floats on top of the seam and consumes no layout space.
  Widget harness(Widget child) =>
      ccTestApp(Center(child: SizedBox(width: 400, height: 200, child: child)));

  testWidgets('renders every region', (tester) async {
    await tester.pumpWidget(
      harness(CcResizable(axis: Axis.horizontal, regions: regions())),
    );
    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
  });

  testWidgets('horizontal divider line fills the cross axis and is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        CcResizable(
          axis: Axis.horizontal,
          dividerThickness: 1,
          regions: regions(),
        ),
      ),
    );
    // The visible line is the AnimatedContainer inside the divider's MouseRegion.
    final line = find.descendant(
      of: find.byType(MouseRegion).first,
      matching: find.byType(AnimatedContainer),
    );
    expect(line, findsOneWidget);
    // 1px thick on the main axis, full 200px height on the cross axis — never
    // collapsed to zero (regression: the line used to render at height 0).
    expect(tester.getSize(line), const Size(1, 200));
  });

  testWidgets('vertical divider line fills the cross axis and is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 200,
            height: 400,
            child: CcResizable(
              axis: Axis.vertical,
              dividerThickness: 1,
              regions: regions(),
            ),
          ),
        ),
      ),
    );
    final line = find.descendant(
      of: find.byType(MouseRegion).first,
      matching: find.byType(AnimatedContainer),
    );
    expect(line, findsOneWidget);
    expect(tester.getSize(line), const Size(200, 1));
  });

  Finder lineOf(WidgetTester tester) => find.descendant(
    of: find.byType(MouseRegion).first,
    matching: find.byType(AnimatedContainer),
  );

  testWidgets(
    'a sustained hover thickens the line and applies the brand color',
    (tester) async {
      await tester.pumpWidget(
        harness(
          CcResizable(
            axis: Axis.horizontal,
            dividerThickness: 1,
            regions: regions(),
          ),
        ),
      );
      final line = lineOf(tester);
      expect(tester.getSize(line).width, 1); // idle hairline

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MouseRegion).first));
      await tester.pump(); // onEnter — the hover-intent timer starts

      // Before the intent delay elapses the line stays a resting hairline.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(line).width, 1);

      // After the delay (+ the highlight animation) it is thick and branded.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSize(line).width, 3);
      expect(
        (tester.widget<AnimatedContainer>(line).decoration! as BoxDecoration)
            .color,
        DesignSystemTokens.light().fgBrandPrimary,
      );
    },
  );

  testWidgets('dragging thickens the line immediately and resets on release', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        CcResizable(
          axis: Axis.horizontal,
          dividerThickness: 1,
          regions: regions(),
        ),
      ),
    );
    final line = lineOf(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MouseRegion).first),
    );
    await tester.pump(); // onPointerDown — dragging is active at once
    await tester.pump(const Duration(milliseconds: 150)); // settle animation
    expect(tester.getSize(line).width, 3);
    expect(
      (tester.widget<AnimatedContainer>(line).decoration! as BoxDecoration)
          .color,
      DesignSystemTokens.light().fgBrandPrimary,
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getSize(line).width, 1); // back to the resting hairline
  });

  testWidgets('dragging the divider transfers extent and fires onResize', (
    tester,
  ) async {
    List<double>? reported;
    final controller = CcResizableController(regions());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      harness(
        CcResizable(
          axis: Axis.horizontal,
          controller: controller,
          regions: regions(),
          onResize: (extents) => reported = extents,
        ),
      ),
    );

    // Drag the divider 40px to the right: left grows, right shrinks.
    final divider = find.byType(MouseRegion).first;
    final gesture = await tester.startGesture(tester.getCenter(divider));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.up();
    await tester.pump();

    expect(reported, isNotNull);
    expect(controller.extents[0], 240);
    expect(controller.extents[1], 160);
    expect(reported![0], 240);
    expect(reported![1], 160);
  });

  testWidgets('drag is clamped to the region max/min', (tester) async {
    final controller = CcResizableController(regions());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      harness(
        CcResizable(
          axis: Axis.horizontal,
          controller: controller,
          regions: regions(),
        ),
      ),
    );

    // Drag far past the left region's max (280) / right region's min (100).
    final divider = find.byType(MouseRegion).first;
    final gesture = await tester.startGesture(tester.getCenter(divider));
    await gesture.moveBy(const Offset(500, 0));
    await gesture.up();
    await tester.pump();

    expect(controller.extents[0], 280);
    expect(controller.extents[1], 120);
  });

  testWidgets('controller.resizeBy preserves the pair total', (tester) async {
    final controller = CcResizableController(regions());
    addTearDown(controller.dispose);
    controller.setAvailable(400);

    controller.resizeBy(0, 30);
    expect(controller.extents[0] + controller.extents[1], 400);
    expect(controller.extents[0], 230);
    expect(controller.extents[1], 170);
  });

  group('CcResizableController', () {
    test('available starts null and is recorded by setAvailable', () {
      final c = CcResizableController(regions());
      addTearDown(c.dispose);
      expect(c.available, isNull);
      // Initial extents [200, 200] already sum to 400: normalizing is a no-op.
      expect(c.setAvailable(400), isFalse);
      expect(c.available, 400);
      // A repeat with the same value is also a no-op.
      expect(c.setAvailable(400), isFalse);
    });

    test('setAvailable rescales extents when the available space changes', () {
      final c = CcResizableController(regions());
      addTearDown(c.dispose);
      // Shrink the space below the initial 200+200=400: the extents re-fit.
      expect(c.setAvailable(300), isTrue);
      expect(c.extents[0] + c.extents[1], 300);
      expect(c.available, 300);
    });

    test('setExtents clamps to per-region bounds and re-fits the total', () {
      final c = CcResizableController(regions());
      addTearDown(c.dispose);
      c.setAvailable(400);

      // 1000 and -50 each clamp to [100, 280]; the last region absorbs slack.
      c.setExtents([1000, -50]);
      expect(c.extents[0], 280);
      expect(c.extents[1], 120);
      // The total still fills the available space.
      expect(c.extents[0] + c.extents[1], 400);
    });

    test('resizeBy ignores out-of-range indices and zero deltas', () {
      final c = CcResizableController(regions());
      addTearDown(c.dispose);
      c.setAvailable(400);
      final before = c.extents.toList();

      expect(c.resizeBy(-1, 50), isFalse);
      expect(c.resizeBy(5, 50), isFalse); // past the last divider
      expect(c.resizeBy(0, 0), isFalse);
      expect(c.extents, before);
    });

    test('resizeBy returns false when the pair cannot absorb any delta', () {
      // Two regions both clamped at their min so no transfer is possible.
      final c = CcResizableController([
        CcResizableRegion.child(
          child: const Text('a'),
          initialExtent: 100,
          minExtent: 100,
          maxExtent: 100,
        ),
        CcResizableRegion.child(
          child: const Text('b'),
          initialExtent: 100,
          minExtent: 100,
          maxExtent: 100,
        ),
      ]);
      addTearDown(c.dispose);
      c.setAvailable(200);

      // Both fixed at 100: a delta that would break bounds is absorbed as 0.
      expect(c.resizeBy(0, 50), isFalse);
    });

    test('extents is unmodifiable', () {
      final c = CcResizableController(regions());
      addTearDown(c.dispose);
      expect(() => c.extents[0] = 999, throwsUnsupportedError);
    });

    test('normalize ripples residual slack backwards across clamped bounds', () {
      // Region 0 capped at 50, region 1 capped at 50, but available is 400 — the
      // 300px slack cannot fit in either, so residual stays after rippling.
      final c = CcResizableController([
        CcResizableRegion.child(
          child: const Text('a'),
          initialExtent: 50,
          minExtent: 0,
          maxExtent: 50,
        ),
        CcResizableRegion.child(
          child: const Text('b'),
          initialExtent: 50,
          minExtent: 0,
          maxExtent: 50,
        ),
      ]);
      addTearDown(c.dispose);
      // setAvailable triggers normalize; the last region absorbs what it can.
      c.setAvailable(400);
      expect(c.extents[0], 50);
      expect(c.extents[1], 50);
    });
  });

  testWidgets(
    'rebuilding with a different region count rebuilds the controller',
    (tester) async {
      var count = 2;
      late void Function(void Function()) setStateOf;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setStateOf = setState;
              return CcResizable(
                axis: Axis.horizontal,
                regions: [
                  for (var i = 0; i < count; i++)
                    CcResizableRegion.child(
                      child: Text('r$i'),
                      initialExtent: 200,
                    ),
                ],
              );
            },
          ),
        ),
      );
      expect(find.text('r2'), findsNothing);

      // Growing the region count under an internal controller rebuilds it.
      setStateOf(() => count = 3);
      await tester.pumpAndSettle();
      expect(find.text('r2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hovering then leaving before the intent delay keeps the hairline',
    (tester) async {
      await tester.pumpWidget(
        harness(CcResizable(axis: Axis.horizontal, regions: regions())),
      );
      final line = lineOf(tester);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MouseRegion).first));
      await tester.pump(); // onEnter starts the hover-intent timer
      await tester.pump(const Duration(milliseconds: 100));

      // Exit before the 250ms intent elapses — the highlight must not latch.
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.getSize(line).width, 1);
    },
  );

  testWidgets('a cancelled pointer drag resets the active state', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(CcResizable(axis: Axis.horizontal, regions: regions())),
    );
    final line = lineOf(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MouseRegion).first),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getSize(line).width, 3); // dragging thickens the line

    await gesture.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getSize(line).width, 1); // back to the resting hairline
  });

  testWidgets('a drag that outlives the widget tree is ignored', (
    tester,
  ) async {
    var visible = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return visible
                ? CcResizable(axis: Axis.horizontal, regions: regions())
                : const SizedBox.shrink();
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MouseRegion).first),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    // The splitter goes away mid-drag (a pane closes, a tab switches). The
    // pointer is still down, so its hit-test path — captured at pointer-down —
    // keeps delivering moves to the now-disposed divider.
    setOuter(() => visible = false);
    await tester.pump();

    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await tester.pump();

    // Neither a use-after-dispose on the controller nor a setState on the
    // defunct divider state.
    expect(tester.takeException(), isNull);
  });

  test('a disposed controller ignores mutations instead of asserting', () {
    final c = CcResizableController(regions());
    c.setAvailable(400);
    final before = c.extents.toList();
    c.dispose();

    expect(c.isDisposed, isTrue);
    expect(c.resizeBy(0, 40), isFalse);
    expect(c.setAvailable(300), isFalse);
    c.setExtents([300, 100]);
    expect(c.extents, before);
  });

  testWidgets('CcResizableRegion.child builds a fixed child', (tester) async {
    final region = CcResizableRegion.child(
      child: const Text('fixed'),
      initialExtent: 100,
    );
    expect(region.initialExtent, 100);
    expect(region.minExtent, 0);
    expect(region.maxExtent, isNull);
    // The builder renders the fixed child.
    final builderWidget = region.builder(nullBuilderContext());
    expect(builderWidget, isA<Text>());
  });
}

// A throwaway BuildContext for exercising plain region builders off-widget.
BuildContext nullBuilderContext() {
  return _NullContext();
}

class _NullContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) {} // ignore: no_runtime_type_toString
}
