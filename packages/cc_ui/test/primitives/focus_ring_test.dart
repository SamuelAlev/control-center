import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

// Two framework realities shape this file's order:
//
// 1. FocusModality is a process-wide singleton that binds its key handler to
//    the FIRST binding it sees — key events only reach it inside one test.
//    The first focused test arms it, and `isKeyboard` then stays true for the
//    rest of the file (nothing sends pointer events here).
// 2. Focus does not re-attach a swapped-in focusNode on element reuse, so
//    each case pumps its own fresh tree instead of repumping one host.
void main() {
  // The node must be attached to the focus tree by a Focus widget — the ring
  // only listens to it (in production CcTappable's own Focus does this).
  Widget host(FocusNode node, double offset) => ccTestApp(
    Center(
      child: FocusRing(
        focusNode: node,
        offset: offset,
        child: Focus(
          focusNode: node,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    ),
  );

  testWidgets('ring paints on the child edge at offset 0', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(host(node, 0));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    node.requestFocus();
    await tester.pump();
    await tester.pump();

    // The ring box coincides with the child — a border overpainting its edge.
    final ring = find.descendant(
      of: find.byType(FocusRing),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getRect(ring), const Rect.fromLTWH(350, 280, 100, 40));
    expect(
      tester.getRect(find.byType(SizedBox)),
      const Rect.fromLTWH(350, 280, 100, 40),
    );
    node.dispose();
  });

  testWidgets('ring strokes outside the child with a gap beyond', (
    tester,
  ) async {
    // FocusModality is already armed "keyboard" by the test above; a fresh
    // tree + requestFocus is all this case needs.
    final node = FocusNode();
    await tester.pumpWidget(host(node, 2));
    node.requestFocus();
    await tester.pump();
    await tester.pump();

    // The gap ring is a painter: its overlay box still coincides with the
    // child (pure paint, zero layout footprint) while the stroke lands
    // outside — centerline at gap + width/2, so exactly 2px of clear space
    // sit between the child's edge and the ring.
    expect(
      tester.getRect(find.byType(CustomPaint)),
      const Rect.fromLTWH(350, 280, 100, 40),
    );
    expect(
      tester.getRect(find.byType(SizedBox)),
      const Rect.fromLTWH(350, 280, 100, 40),
    );
    final painter =
        tester.widget<CustomPaint>(find.byType(CustomPaint)).foregroundPainter
            as RingPainter;
    expect(painter.gap, 2);
    expect(painter.width, 2);
    expect(painter.color, DesignSystemTokens.light().focusRing);
    node.dispose();
  });

  testWidgets('ring stays hidden without keyboard focus', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(host(node, 0));
    expect(
      find.descendant(
        of: find.byType(FocusRing),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    node.dispose();
  });
}
