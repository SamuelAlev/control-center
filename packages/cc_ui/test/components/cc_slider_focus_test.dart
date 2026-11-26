import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// Its own file: [FocusModality] registers its key handler once per isolate and
// the test binding drops key handlers after each test, so only the first test
// of a file sees keyboard modality.
void main() {
  testWidgets('keyboard focus shows the ring', (tester) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox(width: 10, height: 10),
              ),
              SizedBox(
                width: 240,
                child: CcSlider(value: 0.5, onChanged: (_) {}),
              ),
            ],
          ),
        ),
      ),
    );
    final ring = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle,
    );
    before.requestFocus();
    await tester.pump();
    expect(ring, findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ring, findsOneWidget);
  });
}
