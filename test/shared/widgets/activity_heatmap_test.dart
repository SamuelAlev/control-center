import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/charts/activity_heatmap.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The heatmap used to draw its own tooltip into a local Stack, so a cell in
  // the last columns pushed the panel past the right edge of the window. It
  // now uses [CcTooltip], which anchors into the app overlay and is clamped
  // to it.
  testWidgets('a cell tooltip near the right edge stays on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: ActivityHeatmap(
              weeks: 52,
              data: {day: const ActivityCell(runsCompleted: 3)},
              tooltipBuilder: (date, cell) => 'cell ${cell.runsCompleted}',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Sweep the RIGHTMOST column — the cells whose tooltip used to run off
    // the right edge of the window.
    final rect = tester.getRect(find.byType(ActivityHeatmap));
    var found = false;
    for (var y = rect.top + 14; y < rect.bottom && !found; y += 4) {
      await gesture.moveTo(Offset(rect.right - 4, y));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      found = find.textContaining('cell ').evaluate().isNotEmpty;
    }
    expect(found, isTrue, reason: 'no cell tooltip appeared on hover');
    expect(rect.right, greaterThan(1150), reason: 'heatmap must hug the edge');

    // Whatever cell it was, the panel must be fully inside the window.
    final panel = tester.getRect(find.textContaining('cell ').first);
    expect(panel.right, lessThanOrEqualTo(1200));
    expect(panel.left, greaterThanOrEqualTo(0));
  });
}
