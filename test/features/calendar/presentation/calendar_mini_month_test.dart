import 'package:control_center/features/calendar/presentation/widgets/calendar_mini_month.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  // A month far from today, so "today" never takes the Tab stop.
  final selected = DateTime(2031, 3, 12);

  Future<List<DateTime>> pumpGrid(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      testWrap(
        Scaffold(
          body: Directionality(
            textDirection: direction,
            child: SizedBox(
              width: 280,
              child: CalendarMonthGrid(
                selected: selected,
                onSelect: picked.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return picked;
  }

  FocusNode dayNode(WidgetTester tester, int day) =>
      Focus.of(tester.element(find.text('$day').first));

  testWidgets('the grid is one Tab stop, on the selected day', (tester) async {
    await pumpGrid(tester);
    final stops = [
      for (var day = 1; day <= 31; day++)
        if (!dayNode(tester, day).skipTraversal) day,
    ];
    expect(stops, [12]);
  });

  testWidgets('arrows move between days and Enter selects', (tester) async {
    final picked = await pumpGrid(tester);
    dayNode(tester, 12).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(dayNode(tester, 13).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(dayNode(tester, 20).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, [DateTime(2031, 3, 20)]);
  });

  testWidgets('Right moves back a day in RTL', (tester) async {
    await pumpGrid(tester, direction: TextDirection.rtl);
    dayNode(tester, 12).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(dayNode(tester, 11).hasPrimaryFocus, isTrue);
  });

  testWidgets('a day is a selectable button named by its date', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGrid(tester);
    expect(
      tester.getSemantics(find.text('12').first),
      isSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        label: 'Wednesday, March 12, 2031',
      ),
    );
    handle.dispose();
  });
}
