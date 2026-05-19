import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/insights_tab.dart';
import 'package:control_center/features/observability/providers/friction_providers.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Neuters the workspace-id lookup (whose upstream graph pulls in
/// shared_preferences and Drift) so the run-log override below is the ONLY
/// data source; with no workspace id the per-agent name maps fall back to raw
/// agent ids, which is what the assertions use.
class _NoWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

AgentRunLog _run({
  required String id,
  required String agentId,
  required DateTime startedAt,
  RunStatus status = RunStatus.completed,
  int costCents = 0,
  int outputTokens = 0,
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: 'ws1',
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(minutes: 1)),
    status: status,
    modelId: 'opus',
    cost: RunCost(
      outputTokens: outputTokens,
      estimatedCostCents: costCents,
      durationMs: 60000,
    ),
  );
}

void main() {
  final now = DateTime.now();
  final runs = [
    _run(
      id: 'r1',
      agentId: 'ceo',
      startedAt: now.subtract(const Duration(hours: 1)),
      costCents: 150,
      outputTokens: 1000,
    ),
    _run(
      id: 'r2',
      agentId: 'ceo',
      startedAt: now.subtract(const Duration(hours: 2)),
      status: RunStatus.error,
      costCents: 50,
      outputTokens: 500,
    ),
    _run(
      id: 'r3',
      agentId: 'reviewer',
      startedAt: now.subtract(const Duration(hours: 26)),
      costCents: 100,
      outputTokens: 800,
    ),
  ];

  Future<void> pumpInsights(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The single data source for every Insights surface.
          workspaceRunLogsProvider.overrideWith((ref) => runs),
          activeWorkspaceIdProvider.overrideWith(_NoWorkspace.new),
          workspaceFrictionProvider.overrideWith(
            (ref) => WorkspaceFrictionReport.empty,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: const Scaffold(body: InsightsTab()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the KPI strip and section titles over the 7-day range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpInsights(tester);

    // KPI strip (default range: last 7 days → all three runs).
    expect(find.text('Total runs'), findsOneWidget);
    expect(find.text('Total cost'), findsOneWidget);
    expect(find.text('Error rate'), findsOneWidget);
    expect(find.text('Cache rate'), findsOneWidget);
    expect(find.text('3'), findsWidgets); // total runs
    expect(find.text(r'$3.00'), findsWidgets); // total cost

    // Sections in the Insights order (top of the scroll).
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Cost over time'), findsOneWidget);
    expect(find.text('Cost by role'), findsOneWidget);

    // The rest lives below the fold of the lazily-built ListView.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Agents'), findsWidgets);
    expect(find.text('Runs'), findsWidgets);

    // The run log lists the agents by raw id (no roster in the test).
    expect(find.text('ceo'), findsWidgets);
    expect(find.text('reviewer'), findsWidgets);
  });

  testWidgets(
    'switching to the 24h range redraws the chart with hour buckets',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpInsights(tester);

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      expect(find.text('Last 24 hours'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('All time'), findsOneWidget);

      await tester.tap(find.text('Last 24 hours'));
      await tester.pumpAndSettle();

      // The range chip now shows the active preset and the 26h-old run has
      // fallen out of scope (3 runs → 2).
      expect(find.text('Last 24 hours'), findsOneWidget);
      expect(find.text('2'), findsWidgets);

      // Hour-bucket axis labels (e.g. "14:00") appear.
      expect(find.textContaining(RegExp(r'\d{2}:00')), findsWidgets);
    },
  );
}
