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
}
