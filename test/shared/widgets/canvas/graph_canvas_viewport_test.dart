import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/canvas/graph_canvas_viewport.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

Finder _control(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is CcIconButton && widget.tooltip == tooltip,
);

void main() {
  const first = Key('first-node');
  const last = Key('last-node');
  var selected = '';

  Widget graph({double width = 600, double height = 400, double left = -120}) {
    final bounds = Rect.fromLTRB(left, -60, 720, 120);
    return testWrap(
      Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: width,
          height: height,
          child: GraphCanvasViewport(
            bounds: bounds,
            sceneBuilder: (shift) => Stack(
              children: [
                for (final entry in [
                  (first, const Offset(-120, -60)),
                  (last, const Offset(600, 60)),
                ])
                  Positioned(
                    left: entry.$2.dx + shift.dx,
                    top: entry.$2.dy + shift.dy,
                    width: 120,
                    height: 60,
                    child: GestureDetector(
                      key: entry.$1,
                      onTap: () =>
                          selected = entry.$1 == first ? 'first' : 'last',
                      child: const ColoredBox(color: Color(0xFF555555)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pan and zoom preserve node picking; fit restores all nodes', (
    tester,
  ) async {
    await tester.pumpWidget(graph());
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(find.byKey(first));
    await tester.dragFrom(const Offset(300, 350), const Offset(-100, -40));
    await tester.pumpAndSettle();
    final panned = tester.getTopLeft(find.byKey(first));
    expect(panned.dx, lessThan(origin.dx - 50));
    expect(panned.dy, lessThan(origin.dy));

    await tester.tap(_control('Fit to view'));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(GraphCanvasViewport));
    for (final key in [first, last]) {
      expect(viewport.contains(tester.getTopLeft(find.byKey(key))), isTrue);
      expect(viewport.contains(tester.getBottomRight(find.byKey(key))), isTrue);
    }
    selected = '';
    await tester.tap(find.byKey(last));
    expect(selected, 'last');

    await tester.tap(_control('Zoom in'));
    await tester.pumpAndSettle();
    selected = '';
    await tester.tap(find.byKey(first));
    expect(selected, 'first');
  });

  testWidgets('plain wheel pans without scaling or rebuilding the scene', (
    tester,
  ) async {
    await tester.pumpWidget(graph());
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(first));
    final extent = tester.getBottomRight(find.byKey(first)) - before;
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(300, 200),
        scrollDelta: Offset(80, 20),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byKey(first));
    expect(after.dx, closeTo(before.dx - 80, 0.01));
    expect(after.dy, closeTo(before.dy - 20, 0.01));
    expect(tester.getBottomRight(find.byKey(first)) - after, extent);
  });

  testWidgets('geometry-origin changes preserve a navigated graph point', (
    tester,
  ) async {
    await tester.pumpWidget(graph());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(300, 350), const Offset(70, 20));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(first));
    await tester.pumpWidget(graph(left: -360));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byKey(first));
    expect(after.dx, closeTo(before.dx, 0.01));
    expect(after.dy, closeTo(before.dy, 0.01));
    selected = '';
    await tester.tap(find.byKey(first));
    expect(selected, 'first');
  });

  testWidgets('resize keeps the navigated scene centered on the same point', (
    tester,
  ) async {
    await tester.pumpWidget(graph());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(300, 350), const Offset(50, 20));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(first));
    await tester.pumpWidget(graph(width: 500, height: 300));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byKey(first));
    expect(after.dx, closeTo(before.dx - 50, 0.01));
    expect(after.dy, closeTo(before.dy - 50, 0.01));
  });
}
