import 'package:cc_ui/src/components/cc_resizable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// Its own file: [FocusModality] registers its key handler once per isolate and
// the test binding drops key handlers after each test, so only the first test
// of a file sees keyboard modality.
void main() {
  testWidgets('keyboard focus thickens the hairline like hover', (
    tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 400,
            height: 200,
            child: CcResizable(
              axis: Axis.horizontal,
              regions: [
                CcResizableRegion.child(
                  child: Focus(
                    focusNode: before,
                    child: const SizedBox(width: 10, height: 10),
                  ),
                  initialExtent: 200,
                ),
                CcResizableRegion.child(
                  child: const SizedBox(),
                  initialExtent: 200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final line = find.descendant(
      of: find.byType(CcResizableDivider),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(line).width, 1);

    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.getSize(line).width, 3);
  });
}
