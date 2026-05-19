import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
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
  DateTime? startedAt,
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
    startedAt: start,
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
  });
}
