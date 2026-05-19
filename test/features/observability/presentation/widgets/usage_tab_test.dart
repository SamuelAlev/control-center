import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/usage_tab.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Neuters the workspace-id lookup (whose upstream graph pulls in
/// shared_preferences and Drift) so the run-log override below is the ONLY
/// data source.
class _NoWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

AgentRunLog _run({
  required String id,
  required DateTime startedAt,
  required String modelId,
  int tokens = 0,
  int? durationMs,
}) {
  return AgentRunLog(
    id: id,
    agentId: 'ceo',
    workspaceId: 'ws1',
    startedAt: startedAt,
    status: RunStatus.completed,
    modelId: modelId,
    cost: RunCost(outputTokens: tokens, durationMs: durationMs),
  );
}

void main() {
  // Anchored to local midnight so a run placed "yesterday" cannot drift into
  // today when the suite runs just after midnight.
  final today = DateTime.now();
  final midnight = DateTime(today.year, today.month, today.day);

  final runs = [
    _run(
      id: 'r1',
      startedAt: midnight.add(const Duration(hours: 9)),
      modelId: 'opus',
      tokens: 3000,
      durationMs: 150000,
    ),
    _run(
      id: 'r2',
      startedAt: midnight.subtract(const Duration(hours: 3)),
      modelId: 'opus',
      tokens: 1000,
    ),
    _run(
      id: 'r3',
      startedAt: midnight.subtract(const Duration(hours: 5)),
      modelId: 'haiku',
      tokens: 1000,
    ),
  ];

  Future<void> pumpUsage(
    WidgetTester tester, {
    List<AgentRunLog>? withRuns,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceRunLogsProvider.overrideWith((ref) => withRuns ?? runs),
          activeWorkspaceIdProvider.overrideWith(_NoWorkspace.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: const Scaffold(body: UsageTab()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the headline strip, the calendar and both breakdowns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUsage(tester);

    // Headline strip: 5k tokens across the three runs, peak day 3k (today).
    expect(find.text('Total tokens'), findsOneWidget);
    expect(find.text('Peak tokens'), findsOneWidget);
    expect(find.text('Longest session'), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Longest streak'), findsOneWidget);
    expect(find.text('5k'), findsWidgets); // total tokens
    expect(find.text('3k'), findsWidgets); // peak day
    expect(find.text('2m 30s'), findsWidgets); // longest session
    expect(find.text('2 days'), findsWidgets); // today + yesterday

    // Sections.
    expect(find.text('Token activity'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Cumulative'), findsOneWidget);
    expect(find.text('Time range'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Daily token trend'), findsOneWidget);
    expect(find.text('Model usage'), findsOneWidget);
    // The donut legend names both models with their share.
    expect(find.text('opus'), findsWidgets);
    expect(find.text('haiku'), findsWidgets);
    expect(find.text('80%'), findsWidgets);
    expect(find.text('20%'), findsWidgets);
  });

  testWidgets('the activity mode toggle switches the grid mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUsage(tester);

    await tester.tap(find.text('Cumulative'));
    await tester.pumpAndSettle();

    // The selection survives the rebuild (the mode provider is not
    // auto-dispose, so a tab switch cannot silently reset it).
    expect(find.text('Cumulative'), findsOneWidget);
    expect(find.text('Token activity'), findsOneWidget);
  });

  testWidgets('the time range narrows the model split', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUsage(
      tester,
      withRuns: [
        ...runs,
        // Twelve days back: inside the 30-day window, outside the 7-day one.
        _run(
          id: 'old',
          startedAt: midnight.subtract(const Duration(days: 12)),
          modelId: 'sonnet',
          tokens: 9000,
        ),
      ],
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('sonnet'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('sonnet'), findsNothing);
    expect(find.text('opus'), findsWidgets);
  });

  testWidgets('an empty workspace reports no usage rather than a blank card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUsage(tester, withRuns: const []);

    // The strip still renders its labels, zeroed.
    expect(find.text('Total tokens'), findsOneWidget);
    expect(find.text('0 days'), findsWidgets);
    // The calendar still draws (a year of empty cells); the two range-scoped
    // breakdowns have nothing to plot and say so.
    expect(find.text('Token activity'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('No token usage recorded yet'), findsWidgets);
  });
}
