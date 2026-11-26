import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// Its own file: [FocusModality] registers its key handler once per isolate,
// and the test binding drops key handlers after each test, so only the first
// test of a file sees key modality.
void main() {
  testWidgets('a keyboard-driven scroll does not hand the highlight to the '
      'row under a resting pointer', (tester) async {
    final reported = <int?>[];
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            height: 72,
            child: SingleChildScrollView(
              child: CcFluidHover(
                itemCount: 8,
                onActiveIndexChanged: reported.add,
                itemBuilder: (context, index) =>
                    SizedBox(key: ValueKey('kb-item-$index'), height: 24),
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

    // A click first, so the pointer is the last input.
    final rowThree = tester.getCenter(find.byKey(const ValueKey('kb-item-2')));
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: rowThree);
    await pointer.down(rowThree);
    await pointer.up();
    await tester.pump();
    await tester.pump();
    expect(reported.last, 2);

    // An arrow key scrolls the list (what a panel's reveal does).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(48);
    await tester.pump();
    await tester.pump();
    expect(
      reported.where((index) => index != null && index != 2),
      isEmpty,
      reason: 'the row that slid under the pointer must not take over',
    );

    // Real pointer movement takes over again at once.
    await pointer.moveBy(const Offset(0, 2));
    await tester.pump();
    await tester.pump();
    expect(reported.last, 4);

    await pointer.down(tester.getCenter(find.byType(Scrollable)));
    await pointer.up();
  });
}
