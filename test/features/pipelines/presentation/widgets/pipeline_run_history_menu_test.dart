import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_history_menu.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineRun _run({
  required String id,
  String templateId = 'pr_review',
  PipelineRunStatus status = PipelineRunStatus.completed,
  required DateTime startedAt,
  DateTime? attemptStartedAt,
  int activeMs = 3000,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: 'ws-1',
    status: status,
    startedAt: startedAt,
    attemptStartedAt: attemptStartedAt,
    finishedAt: startedAt.add(const Duration(seconds: 3)),
    activeMs: activeMs,
  );
}

Widget _wrap(List<PipelineRun> runs, PipelineRun current) {
  return ProviderScope(
    overrides: [
      workspacePipelineRunsProvider(
        'ws-1',
      ).overrideWith((ref) => Stream.value(runs)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: PipelineRunHistoryMenu(run: current)),
      ),
    ),
  );
}

void main() {
  group('PipelineRunHistoryMenu', () {
    testWidgets('lists the other runs of the same pipeline, newest first', (
      tester,
    ) async {
      final current = _run(id: 'run-now', startedAt: DateTime.now());
      final older = _run(
        id: 'run-older',
        status: PipelineRunStatus.failed,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final oldest = _run(
        id: 'run-oldest',
        startedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      // A different template's run must not leak in: comparing this run
      // against an unrelated pipeline's is exactly the confusion the menu
      // exists to remove.
      final foreign = _run(
        id: 'run-foreign',
        templateId: 'index_code',
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        _wrap([current, older, oldest, foreign], current),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CcTooltip));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed · 2 hours ago'), findsOneWidget);
      expect(find.textContaining('Completed · 5 hours ago'), findsOneWidget);
      expect(find.textContaining('1 hour ago'), findsNothing);
      // The open run is not one of its own alternatives.
      expect(find.textContaining('just now'), findsNothing);
    });

    testWidgets('says so when the pipeline has only ever run once', (
      tester,
    ) async {
      final only = _run(id: 'run-1', startedAt: DateTime.now());

      await tester.pumpWidget(_wrap([only], only));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CcTooltip));
      await tester.pumpAndSettle();

      expect(find.text('No other runs yet'), findsOneWidget);
    });

    testWidgets('orders a rerun by the attempt it is on', (tester) async {
      // A run whose first attempt is old but which was rerun a minute ago is
      // the most recent thing that happened; ordering it by `startedAt` would
      // bury it under runs nobody has touched since.
      final current = _run(
        id: 'run-now',
        startedAt: DateTime.now().subtract(const Duration(hours: 9)),
      );
      final rerun = _run(
        id: 'run-rerun',
        startedAt: DateTime.now().subtract(const Duration(hours: 6)),
        attemptStartedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      final recentish = _run(
        id: 'run-recentish',
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(_wrap([current, rerun, recentish], current));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CcTooltip));
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((s) => s.contains(' · '))
          .toList();
      expect(labels.first, contains('2 min ago'));
      expect(labels[1], contains('1 hour ago'));
    });
  });
}
