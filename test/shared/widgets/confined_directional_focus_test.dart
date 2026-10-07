import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/confined_directional_focus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';

Widget _button(String label) => CcTappable(
  onPressed: () {},
  builder: (_, _) => SizedBox(width: 120, height: 32, child: Text(label)),
);

/// Two panes side by side; the right one starts lower, so ↓ from the bottom
/// of the left pane geometrically "finds" the right pane's last button.
Widget _panes() => testWrap(
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ConfinedDirectionalFocus(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_button('L1'), _button('L2')],
        ),
      ),
      ConfinedDirectionalFocus(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_button('R1'), _button('R2')],
          ),
        ),
      ),
    ],
  ),
);

FocusNode _node(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label)));

void main() {
  testWidgets('arrows move inside the pane', (tester) async {
    await tester.pumpWidget(_panes());
    _node(tester, 'L1').requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_node(tester, 'L2').hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_node(tester, 'L1').hasPrimaryFocus, isTrue);
  });

  testWidgets('arrows stop at the pane edge instead of leaking', (
    tester,
  ) async {
    await tester.pumpWidget(_panes());
    _node(tester, 'L2').requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_node(tester, 'L2').hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_node(tester, 'L2').hasPrimaryFocus, isTrue);
  });

  testWidgets('Tab finishes a pane before the next', (tester) async {
    await tester.pumpWidget(_panes());
    _node(tester, 'L1').requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_node(tester, 'L2').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_node(tester, 'R1').hasPrimaryFocus, isTrue);
  });
}
