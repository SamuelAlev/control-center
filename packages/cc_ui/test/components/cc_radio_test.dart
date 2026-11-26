import 'package:cc_ui/src/components/cc_radio.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcRadio', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcRadio<int>(value: 1, groupValue: 2, onChanged: (_) {})),
      );
      expect(find.byType(CcRadio<int>), findsOneWidget);
    });

    testWidgets('selects its value on tap', (tester) async {
      int? selected;
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(value: 1, groupValue: 2, onChanged: (v) => selected = v),
        ),
      );
      await tester.tap(find.byType(CcRadio<int>));
      expect(selected, 1);
    });

    testWidgets('renders the selected state', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcRadio<int>(value: 1, groupValue: 1, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is inert when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcRadio<int>(value: 1, groupValue: 2, onChanged: null)),
      );
      await tester.tap(find.byType(CcRadio<int>));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the selected radio is a no-op', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(value: 1, groupValue: 1, onChanged: (_) => calls++),
        ),
      );
      await tester.tap(find.byType(CcRadio<int>));
      await tester.pump();
      // Already selected — onChanged must not fire.
      expect(calls, 0);
    });

    testWidgets('is announced as a checked radio in an exclusive set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(
            value: 1,
            groupValue: 1,
            semanticLabel: 'Opus',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CcTappable)),
        matchesSemantics(
          label: 'Opus',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('takes a press in the 24px area around the circle', (
      tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcRadio<int>(
              value: 1,
              groupValue: 2,
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      final circle = tester.getRect(find.byType(CcRadio<int>));
      expect(circle.size, const Size(18, 18));
      // 2px outside the circle's top-left corner, inside the 24px target.
      await tester.tapAt(circle.topLeft - const Offset(2, 2));
      expect(selected, 1);

      selected = null;
      await tester.tapAt(circle.bottomRight + const Offset(4, 4));
      expect(selected, isNull);
    });

    testWidgets('renders the disabled selected state without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcRadio<int>(value: 1, groupValue: 1, onChanged: null)),
      );
      await tester.pumpAndSettle();
      // A selected-but-disabled radio still paints its dot.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('CcRadioGroup', () {
    testWidgets('renders every child radio', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          CcRadioGroup<int>(
            groupValue: 1,
            onChanged: (_) {},
            children: const [
              CcRadio<int>(value: 1, groupValue: 1, onChanged: null),
              CcRadio<int>(value: 2, groupValue: 1, onChanged: null),
              CcRadio<int>(value: 3, groupValue: 1, onChanged: null),
            ],
          ),
        ),
      );
      expect(find.byType(CcRadio<int>), findsNWidgets(3));
    });

    testWidgets('arrow down moves selection to the next enabled radio', (
      tester,
    ) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                CcRadio<int>(
                  value: 1,
                  groupValue: selected,
                  autofocus: true,
                  onChanged: (v) => setState(() => selected = v),
                ),
                CcRadio<int>(
                  value: 2,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
                CcRadio<int>(
                  value: 3,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // ArrowDown advances from 1 -> 2.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(selected, 2);
    });

    testWidgets('arrow up moves selection to the previous radio and wraps', (
      tester,
    ) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                CcRadio<int>(
                  value: 1,
                  groupValue: selected,
                  autofocus: true,
                  onChanged: (v) => setState(() => selected = v),
                ),
                CcRadio<int>(
                  value: 2,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // ArrowUp from the first wraps to the last (value 2).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(selected, 2);
    });

    testWidgets('arrow right/left mirror down/up', (tester) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                CcRadio<int>(
                  value: 1,
                  groupValue: selected,
                  autofocus: true,
                  onChanged: (v) => setState(() => selected = v),
                ),
                CcRadio<int>(
                  value: 2,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(selected, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('arrow keys skip disabled radios', (tester) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                CcRadio<int>(
                  value: 1,
                  groupValue: selected,
                  autofocus: true,
                  onChanged: (v) => setState(() => selected = v),
                ),
                // Disabled middle radio is skipped.
                CcRadio<int>(value: 2, groupValue: selected, onChanged: null),
                CcRadio<int>(
                  value: 3,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Skips the disabled value 2 and lands on 3.
      expect(selected, 3);
    });

    testWidgets('non-arrow keys are ignored', (tester) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                CcRadio<int>(
                  value: 1,
                  groupValue: selected,
                  autofocus: true,
                  onChanged: (v) => setState(() => selected = v),
                ),
                CcRadio<int>(
                  value: 2,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, 1);
    });

    testWidgets('the group is one Tab stop: the selected radio', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      final nodes = [for (var i = 0; i < 3; i++) FocusNode()];
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      for (final node in nodes) {
        addTearDown(node.dispose);
      }
      await tester.pumpWidget(
        ccTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox(width: 20, height: 20),
              ),
              CcRadioGroup<int>(
                groupValue: 2,
                onChanged: (_) {},
                children: [
                  for (var i = 0; i < 3; i++)
                    CcRadio<int>(
                      value: i + 1,
                      groupValue: 2,
                      focusNode: nodes[i],
                      onChanged: (_) {},
                    ),
                ],
              ),
              Focus(
                focusNode: after,
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        ),
      );
      before.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(before.hasPrimaryFocus, isTrue);
    });

    testWidgets('with nothing selected the first enabled radio is the stop', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final enabled = FocusNode(debugLabel: 'enabled');
      addTearDown(before.dispose);
      addTearDown(enabled.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox(width: 20, height: 20),
              ),
              CcRadioGroup<int>(
                groupValue: null,
                onChanged: (_) {},
                children: [
                  const CcRadio<int>(
                    value: 1,
                    groupValue: null,
                    onChanged: null,
                  ),
                  CcRadio<int>(
                    value: 2,
                    groupValue: null,
                    focusNode: enabled,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(enabled.hasPrimaryFocus, isTrue);
    });

    testWidgets('arrows move focus with the selection from the focused radio', (
      tester,
    ) async {
      int? selected = 1;
      final nodes = [for (var i = 0; i < 3; i++) FocusNode()];
      for (final node in nodes) {
        addTearDown(node.dispose);
      }
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                for (var i = 0; i < 3; i++)
                  CcRadio<int>(
                    value: i + 1,
                    groupValue: selected,
                    focusNode: nodes[i],
                    onChanged: (v) => setState(() => selected = v),
                  ),
              ],
            ),
          ),
        ),
      );
      // Focus sits on the last radio while the first is selected: the arrow
      // starts from where focus is.
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(selected, 2);
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(selected, 3);
      expect(nodes[2].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(selected, 1);
      expect(nodes[0].hasPrimaryFocus, isTrue);
    });

    testWidgets('left and right follow the reading direction under RTL', (
      tester,
    ) async {
      int? selected = 1;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) => CcRadioGroup<int>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              children: [
                for (var i = 1; i <= 3; i++)
                  CcRadio<int>(
                    value: i,
                    groupValue: selected,
                    autofocus: i == 1,
                    onChanged: (v) => setState(() => selected = v),
                  ),
              ],
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(selected, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected, 1);
    });

    testWidgets('empty group handles keys without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Focus(
            autofocus: true,
            child: CcRadioGroup<int>(
              groupValue: null,
              onChanged: (_) {},
              children: const [],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
