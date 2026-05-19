import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('shows and hides the overlay via the controller', (tester) async {
    final controller = CcOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcOverlayAnchor(
            controller: controller,
            target: const SizedBox(width: 120, height: 40),
            overlayBuilder: (context, size) => const Text('menu content'),
          ),
        ),
      ),
    );

    expect(find.text('menu content'), findsNothing);

    controller.show();
    await tester.pump();
    expect(find.text('menu content'), findsOneWidget);

    controller.hide();
    await tester.pump();
    expect(find.text('menu content'), findsNothing);
  });

  testWidgets('outside tap dismisses the overlay', (tester) async {
    final controller = CcOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcOverlayAnchor(
            controller: controller,
            target: const SizedBox(width: 120, height: 40),
            overlayBuilder: (context, size) => const Text('menu content'),
          ),
        ),
      ),
    );

    controller.show();
    await tester.pump();
    expect(find.text('menu content'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('menu content'), findsNothing);
  });

  testWidgets('flips above the target when there is no room below', (tester) async {
    final controller = CcOverlayController();
    addTearDown(controller.dispose);
    const contentKey = Key('overlay-content');
    await tester.pumpWidget(
      ccTestApp(
        Align(
          // Pin the trigger to the very bottom edge so opening downward would
          // overflow off-screen.
          alignment: Alignment.bottomCenter,
          child: CcOverlayAnchor(
            controller: controller,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            target: const SizedBox(width: 120, height: 40),
            overlayBuilder: (context, size) =>
                const SizedBox(key: contentKey, width: 200, height: 120),
          ),
        ),
      ),
    );

    controller.show();
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(Overlay).first);
    final rect = tester.getRect(find.byKey(contentKey));
    // Stays fully on-screen (clamped within the margin) and is placed above the
    // bottom-pinned trigger rather than spilling past the bottom edge.
    expect(rect.top, greaterThanOrEqualTo(kCcOverlayMargin - 0.5));
    expect(rect.bottom, lessThanOrEqualTo(screen.height - kCcOverlayMargin + 0.5));
    expect(rect.bottom, lessThanOrEqualTo(screen.height - 40));
  });

  testWidgets('caps an over-tall overlay to the viewport so it can scroll',
      (tester) async {
    final controller = CcOverlayController();
    addTearDown(controller.dispose);
    const contentKey = Key('tall-content');
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcOverlayAnchor(
            controller: controller,
            target: const SizedBox(width: 120, height: 40),
            // Far taller than the 600px test surface.
            overlayBuilder: (context, size) =>
                const SizedBox(key: contentKey, width: 200, height: 2000),
          ),
        ),
      ),
    );

    controller.show();
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(Overlay).first);
    final rect = tester.getRect(find.byKey(contentKey));
    expect(rect.top, greaterThanOrEqualTo(kCcOverlayMargin - 0.5));
    expect(rect.bottom, lessThanOrEqualTo(screen.height - kCcOverlayMargin + 0.5));
    expect(rect.height, lessThanOrEqualTo(screen.height - kCcOverlayMargin * 2 + 0.5));
  });
}
