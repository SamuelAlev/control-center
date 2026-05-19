import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/usage/usage_trend_chart.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One series carrying the given daily token totals, one point per day.
UsageTrendSeries _series(String model, List<int> tokensPerDay) =>
    UsageTrendSeries(
      model: model,
      points: [
        for (var i = 0; i < tokensPerDay.length; i++)
          UsageDay(
            day: DateTime(2026, 8, i + 1),
            tokens: tokensPerDay[i],
            runs: tokensPerDay[i] > 0 ? 1 : 0,
          ),
      ],
    );

Future<void> _pump(WidgetTester tester, List<UsageTrendSeries> series) async {
  tester.view.physicalSize = const Size(900, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData(
          tokens: DesignSystemTokens.light(),
          brightness: CcBrightness.light,
        ),
        child: Scaffold(body: UsageTrendChart(series: series)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('y labels land on round steps, never on the raw data peak', (
    tester,
  ) async {
    // Peak 25.5M is the case that printed "25.5M" over "25M": fl_chart labels
    // the data max AND its own interval steps.
    await _pump(tester, [
      _series('opus', [1000000, 25500000, 12000000, 20000000]),
    ]);

    expect(find.text('25.5M'), findsNothing);
    expect(find.text('10M'), findsOneWidget);
    expect(find.text('20M'), findsOneWidget);
    expect(find.text('30M'), findsOneWidget);
  });

  testWidgets('every rendered y label is unique (nothing overlaps)', (
    tester,
  ) async {
    await _pump(tester, [
      _series('opus', [3300, 47800, 12100, 25500]),
    ]);

    // Collect the axis labels: the y labels are the ones that parse as a
    // token figure, and a duplicate is the signature of two labels stacked.
    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .whereType<String>()
        .where((s) => RegExp(r'^\d+(\.\d+)?[kMB]?$').hasMatch(s))
        .toList();

    expect(rendered, isNotEmpty);
    expect(rendered.toSet(), hasLength(rendered.length));
  });

  testWidgets('lines are curved, and curved WITHOUT overshooting', (
    tester,
  ) async {
    await _pump(tester, [
      // A hard spike from a flat baseline: the shape that swings a naive
      // spline below zero on the way back down.
      _series('opus', [0, 0, 25000000, 0, 0]),
    ]);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final bar = chart.data.lineBarsData.single;

    expect(bar.isCurved, isTrue);
    expect(
      bar.preventCurveOverShooting,
      isTrue,
      reason: 'a spike back to zero would otherwise dip into negative tokens',
    );
    // The plot floor stays pinned at zero, so any overshoot would be visible
    // rather than quietly rescaling the axis.
    expect(chart.data.minY, 0);
  });

  testWidgets('an all-zero window still renders a baseline', (tester) async {
    await _pump(tester, [
      _series('opus', [0, 0, 0]),
    ]);

    expect(find.byType(UsageTrendChart), findsOneWidget);
    // The empty state is for "no series at all", not "a series of zeroes".
    expect(find.text('No token usage recorded yet'), findsNothing);
  });

  testWidgets('no series at all falls back to the empty state', (tester) async {
    await _pump(tester, const []);

    expect(find.text('No token usage recorded yet'), findsOneWidget);
  });
}
