import 'package:cc_ui/src/components/cc_radio.dart';
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
