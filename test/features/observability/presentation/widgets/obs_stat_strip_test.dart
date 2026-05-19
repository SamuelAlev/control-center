import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  ObsStatStripEntry(label: 'Total runs', value: '47'),
  ObsStatStripEntry(label: 'Total cost', value: r'$30.09', tone: ObsTone.brand),
  ObsStatStripEntry(
    label: 'Error rate',
    value: '40%',
    tone: ObsTone.danger,
    detail: 'vs previous +12%',
    detailTone: ObsTone.danger,
  ),
  ObsStatStripEntry(label: 'Cache rate', value: '100%', tone: ObsTone.success),
];

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width + 200, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CcTheme(
        data: CcThemeData(
          tokens: DesignSystemTokens.light(),
          brightness: CcBrightness.light,
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const ObsStatStrip(entries: _entries),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a wide strip divides the figures, one hairline per gap', (
    tester,
  ) async {
    await _pump(tester, 900);

    for (final entry in _entries) {
      expect(find.text(entry.label), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
    // Four figures → three dividers.
    expect(find.byType(CcDivider), findsNWidgets(_entries.length - 1));
  });

  testWidgets('the value is rendered above its label', (tester) async {
    await _pump(tester, 900);

    final label = tester.getCenter(find.text('Total runs'));
    final value = tester.getCenter(find.text('47'));
    expect(
      value.dy,
      lessThan(label.dy),
      reason: 'the figure leads; the label explains it underneath',
    );
  });

  testWidgets('a detail line rides under its figure', (tester) async {
    await _pump(tester, 900);

    expect(find.text('vs previous +12%'), findsOneWidget);
    expect(
      tester.getCenter(find.text('vs previous +12%')).dy,
      greaterThan(tester.getCenter(find.text('Error rate')).dy),
    );
  });

  testWidgets('a narrow strip drops the dividers and wraps instead', (
    tester,
  ) async {
    // Under 4 × 120 the row cannot give every figure its minimum width.
    await _pump(tester, 320);

    expect(find.byType(CcDivider), findsNothing);
    // Nothing is dropped in the fallback — every figure still reports.
    for (final entry in _entries) {
      expect(find.text(entry.label), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('an empty strip renders nothing at all', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CcTheme(
          data: CcThemeData(
            tokens: DesignSystemTokens.light(),
            brightness: CcBrightness.light,
          ),
          child: const Scaffold(body: ObsStatStrip(entries: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CcCard), findsNothing);
  });
}
