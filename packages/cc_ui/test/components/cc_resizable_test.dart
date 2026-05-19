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

  testWidgets('horizontal divider line fills the cross axis and is visible',
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

  testWidgets('vertical divider line fills the cross axis and is visible',
      (tester) async {
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

  testWidgets('a sustained hover thickens the line and applies the brand color',
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
  });

  testWidgets('dragging thickens the line immediately and resets on release',
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

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(MouseRegion).first));
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

  testWidgets('dragging the divider transfers extent and fires onResize',
      (tester) async {
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
}
