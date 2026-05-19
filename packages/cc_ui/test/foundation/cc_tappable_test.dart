import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  Widget box(BuildContext context, Set<WidgetState> states) =>
      const SizedBox(width: 60, height: 40);

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(CcTappable(onPressed: () => taps++, builder: box)),
    );
    await tester.tap(find.byType(CcTappable));
    expect(taps, 1);
  });

  testWidgets('reports disabled state when onPressed is null', (tester) async {
    late Set<WidgetState> seen;
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(
          onPressed: null,
          builder: (context, states) {
            seen = states;
            return box(context, states);
          },
        ),
      ),
    );
    await tester.tap(find.byType(CcTappable), warnIfMissed: false);
    expect(seen, contains(WidgetState.disabled));
  });

  testWidgets('activates via the keyboard (Enter) when focused', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(autofocus: true, onPressed: () => taps++, builder: box),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('reports hovered state', (tester) async {
    var hovered = false;
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(
          onPressed: () {},
          builder: (context, states) {
            hovered = states.contains(WidgetState.hovered);
            return box(context, states);
          },
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(CcTappable)));
    await tester.pump();
    expect(hovered, isTrue);
  });
}
