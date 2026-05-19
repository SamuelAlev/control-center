import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/run_activity_stats.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    RunCost? cost,
    int toolCount = 0,
    int childCostCents = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData(
            tokens: DesignSystemTokens.light(),
            brightness: CcBrightness.light,
          ),
          child: Scaffold(
            body: RunActivityStatBar(
              cost: cost,
              toolCount: toolCount,
              childCostCents: childCostCents,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reports tokens, cost, tools and duration', (tester) async {
    await pump(
      tester,
      cost: const RunCost(
        inputTokens: 1000,
        outputTokens: 500,
        estimatedCostCents: 250,
        durationMs: 9000,
      ),
      toolCount: 3,
    );

    expect(find.text('tokens'), findsOneWidget);
    expect(find.text('cost'), findsOneWidget);
    expect(find.text('tools'), findsOneWidget);
    expect(find.text('duration'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows NO context-window gauge', (tester) async {
    // `RunCost.inputTokens` is the SUM over the run's turns and every turn
    // re-sends the conversation, so a gauge built from it pegs past 100% on any
    // multi-turn run ("700.2k of ~200k"). The metric is a billing total, not
    // context occupancy — so the bar must not claim otherwise.
    await pump(
      tester,
      cost: const RunCost(inputTokens: 700000, estimatedCostCents: 10),
    );

    expect(find.text('context window'), findsNothing);
    expect(find.textContaining('of ~'), findsNothing);
  });

  testWidgets('an unpriced run reports unknown cost, not free', (tester) async {
    await pump(
      tester,
      cost: const RunCost(inputTokens: 705900, estimatedCostCents: 0),
    );

    // 705.9k tokens for "$0.00" reads as broken; the model's pricing simply
    // was not resolvable.
    expect(find.text(r'$0.00'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('a genuinely free (token-less) run still reads zero', (
    tester,
  ) async {
    await pump(tester, cost: const RunCost());

    expect(find.text(r'$0.00'), findsOneWidget);
  });

  testWidgets('a run with no duration reports a dash', (tester) async {
    await pump(tester, cost: const RunCost(inputTokens: 10));

    expect(find.text('—'), findsWidgets);
  });

  testWidgets('delegated spend is surfaced on the cost tile', (tester) async {
    await pump(
      tester,
      cost: const RunCost(estimatedCostCents: 100),
      childCostCents: 250,
    );

    expect(find.textContaining('delegated'), findsOneWidget);
  });

  testWidgets('a run with no cost row at all still renders', (tester) async {
    await pump(tester);

    expect(find.text('tokens'), findsOneWidget);
    expect(find.text('duration'), findsOneWidget);
  });
}
