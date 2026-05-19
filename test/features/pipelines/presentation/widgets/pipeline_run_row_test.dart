import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_row.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineRun _run({
  String id = 'run-1',
  String templateId = 'tmpl-1',
  PipelineRunStatus status = PipelineRunStatus.completed,
  String? triggerEventType,
  Map<String, dynamic>? triggerPayload,
  DateTime? startedAt,
  DateTime? attemptStartedAt,
  DateTime? finishedAt,
  int? activeMs,
}) {
  final start = startedAt ?? DateTime(2026, 1, 1, 12);
  final end = finishedAt ?? DateTime(2026, 1, 1, 12, 0, 3);
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: 'ws-1',
    status: status,
    triggerEventType: triggerEventType,
    triggerPayload: triggerPayload,
    startedAt: start,
    attemptStartedAt: attemptStartedAt,
    finishedAt: end,
    // The row renders `activeDurationAt`, driven by `activeMs` (accumulated
    // active time), NOT wall-clock finishedAt−startedAt — that would inflate the
    // duration with overnight stops.
    activeMs: activeMs ?? end.difference(start).inMilliseconds,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PipelineRunRow', () {
    testWidgets('renders the resolved title and opens the run when tapped', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Index repository code',
            onOpen: () => opened++,
          ),
        ),
      );

      expect(find.text('Index repository code'), findsOneWidget);

      await tester.tap(find.text('Index repository code'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('falls back to the template id when no title resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(templateId: 'code_index'),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            onOpen: () {},
          ),
        ),
      );

      expect(find.text('code_index'), findsOneWidget);
    });

    testWidgets('the relative time carries no copy-timestamp gesture — the '
        'row tap belongs to the run', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(
              startedAt: DateTime(2026, 1, 1, 11, 55),
              finishedAt: DateTime(2026, 1, 1, 11, 55, 3),
            ),
            now: DateTime(2026, 1, 1, 12),
            title: 'Run',
            onOpen: () => opened++,
          ),
        ),
      );

      expect(find.byType(AppTimestamp), findsNothing);
      expect(find.text('5 min ago'), findsOneWidget);

      await tester.tap(find.text('5 min ago'));
      await tester.pumpAndSettle();
      expect(
        opened,
        1,
        reason: 'the tap must reach the row, not a copy handler',
      );
    });

    testWidgets('shows the status badge and the active duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(
              status: PipelineRunStatus.failed,
              startedAt: DateTime(2026, 1, 1, 12),
              finishedAt: DateTime(2026, 1, 1, 12, 0, 33),
            ),
            now: DateTime(2026, 1, 1, 12, 0, 45),
            title: 'Run',
            onOpen: () {},
          ),
        ),
      );

      expect(find.byType(PipelineStatusBadge), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('33s'), findsOneWidget);
    });

    testWidgets('shows <1s rather than 0ms for an instant run', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(activeMs: 0),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onOpen: () {},
          ),
        ),
      );

      expect(find.text('<1s'), findsOneWidget);
    });

    testWidgets('a manual run reads with the play glyph, an automatic one '
        'with the zap glyph', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onOpen: () {},
          ),
        ),
      );
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(triggerEventType: 'PullRequestPublished'),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Run',
            onOpen: () {},
          ),
        ),
      );
      expect(find.byIcon(AppIcons.zap), findsOneWidget);
    });

    testWidgets('a background reindex names its trigger and the file that '
        'caused it', (tester) async {
      // The glyph used to say "Automatic" for every non-manual run. A watcher
      // reindex fired by a save and a pipeline fired by a merged PR looked
      // identical, and neither said why — which made a run of 77 identical
      // index rows unattributable.
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(
              triggerEventType: IndexCodeTemplate.watchTriggerEventType,
              triggerPayload: const {
                'repo_local_path': '/repos/control-center',
                'cause': 'changes',
                'changed_paths': ['lib/foo.dart'],
                'changed_count': 1,
              },
            ),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Index repository code',
            onOpen: () {},
          ),
        ),
      );

      expect(find.byIcon(AppIcons.filePen), findsOneWidget);
      final tooltip = tester.widget<CcTooltip>(find.byType(CcTooltip));
      expect(tooltip.message, 'File change · 1 changed file · lib/foo.dart');
    });

    testWidgets('a capped change set counts the paths it does not name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(
              triggerEventType: IndexCodeTemplate.watchTriggerEventType,
              triggerPayload: const {
                'cause': 'changes',
                'changed_paths': ['lib/a.dart', 'lib/b.dart'],
                'changed_count': 2000,
              },
            ),
            now: DateTime(2026, 1, 1, 12, 0, 5),
            title: 'Index repository code',
            onOpen: () {},
          ),
        ),
      );

      final tooltip = tester.widget<CcTooltip>(find.byType(CcTooltip));
      expect(
        tooltip.message,
        'File change · 2000 changed files · lib/a.dart, lib/b.dart +1998 more',
        reason: 'the capped list must not imply it was the whole change set',
      );
    });

    testWidgets('buckets the start time from just now up to days', (
      tester,
    ) async {
      Future<void> pumpStartedAt(DateTime startedAt, DateTime now) async {
        await tester.pumpWidget(
          _wrap(
            PipelineRunRow(
              run: _run(startedAt: startedAt, finishedAt: startedAt),
              now: now,
              title: 'Run',
              onOpen: () {},
            ),
          ),
        );
      }

      await pumpStartedAt(
        DateTime(2026, 1, 1, 12),
        DateTime(2026, 1, 1, 12, 0, 30),
      );
      expect(find.textContaining('just now'), findsOneWidget);

      await pumpStartedAt(DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 12));
      expect(find.text('3 hours ago'), findsOneWidget);

      await pumpStartedAt(DateTime(2026, 1, 1, 12), DateTime(2026, 1, 3, 12));
      expect(find.text('2 days ago'), findsOneWidget);
    });

    testWidgets('a rerun row reads from the attempt it is on', (tester) async {
      // The run first started days ago and was rerun five minutes ago. A row
      // still saying "2 days ago" for work that went again this afternoon is
      // the row nobody trusts — and it is what sent the operator looking for a
      // second run that does not exist.
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(
              startedAt: DateTime(2026, 1, 1, 12),
              attemptStartedAt: DateTime(2026, 1, 3, 11, 55),
            ),
            now: DateTime(2026, 1, 3, 12),
            title: 'Run',
            onOpen: () {},
          ),
        ),
      );

      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('2 days ago'), findsNothing);
    });

    // A queued run has done no work, so the duration cell used to read a
    // hard-coded `<1s`: six repos waiting to be indexed showed up under two
    // running rows looking like six runs that had already finished instantly.
    testWidgets('a queued row carries its queue position, not a duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              PipelineRunRow(
                run: _run(id: 'a', status: PipelineRunStatus.queued),
                now: DateTime(2026, 1, 1, 12),
                title: 'Index repository code',
                queuePosition: 1,
                onOpen: () {},
              ),
              PipelineRunRow(
                run: _run(id: 'b', status: PipelineRunStatus.queued),
                now: DateTime(2026, 1, 1, 12),
                title: 'Index repository code',
                queuePosition: 3,
                onOpen: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('3 in queue'), findsOneWidget);
      expect(find.text('<1s'), findsNothing);
      expect(find.text('3s'), findsNothing);
    });

    testWidgets('a running row still shows its duration', (tester) async {
      // The position only ever replaces a duration for a run that is waiting;
      // anything with a clock keeps it.
      await tester.pumpWidget(
        _wrap(
          PipelineRunRow(
            run: _run(status: PipelineRunStatus.running),
            now: DateTime(2026, 1, 1, 12),
            title: 'Index repository code',
            queuePosition: 2,
            onOpen: () {},
          ),
        ),
      );

      expect(find.text('3s'), findsOneWidget);
      expect(find.text('2 in queue'), findsNothing);
    });
  });
}
