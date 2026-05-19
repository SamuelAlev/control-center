import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_waterfall.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 1, 1, 12);

PipelineDefinition _definition() => PipelineDefinition(
  templateId: 'tmpl-1',
  workspaceId: 'ws-1',
  name: 'Test pipeline',
  steps: [
    PipelineStepDefinition(
      id: 'step-a',
      kind: StepKind.listen,
      bodyKey: 'body_a',
      config: const PipelineNodeConfig(label: 'Branch A'),
    ),
    PipelineStepDefinition(
      id: 'step-b',
      kind: StepKind.listen,
      bodyKey: 'body_b',
      config: const PipelineNodeConfig(label: 'Branch B'),
    ),
  ],
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('PipelineRunWaterfall', () {
    testWidgets(
      'a stopped run freezes its timeline at finishedAt, so a step row left '
      'open cannot grow the idle gap forever',
      (tester) async {
        // The run was stopped 3s in. Branch B was interrupted and never got a
        // finishedAt — the bug was reading the live clock for it, which grew the
        // wall-clock span (and with it the "idle" chip) without bound.
        final run = PipelineRun(
          id: 'run-1',
          templateId: 'tmpl-1',
          workspaceId: 'ws-1',
          status: PipelineRunStatus.failed,
          startedAt: _start,
          finishedAt: _start.add(const Duration(seconds: 3)),
          activeMs: 3000,
        );
        final steps = [
          PipelineStepRun(
            id: 'sr-a',
            pipelineRunId: 'run-1',
            stepId: 'step-a',
            status: PipelineStepStatus.failed,
            startedAt: _start,
            finishedAt: _start.add(const Duration(seconds: 3)),
          ),
          PipelineStepRun(
            id: 'sr-b',
            pipelineRunId: 'run-1',
            stepId: 'step-b',
            status: PipelineStepStatus.running,
            startedAt: _start,
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            PipelineRunWaterfall(
              run: run,
              stepRuns: steps,
              definition: _definition(),
              // Hours after the run stopped, as when the operator comes back to it.
              now: _start.add(const Duration(hours: 4)),
            ),
          ),
        );

        expect(find.textContaining('Active 3s'), findsOneWidget);
        expect(
          find.textContaining('idle'),
          findsNothing,
          reason: 'wall-clock == active for a stopped run, so there is no gap',
        );

        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();

        // The open row is measured to the run's end, not to `now`.
        expect(find.textContaining('4.0h'), findsNothing);
        expect(find.text('3.0s'), findsNWidgets(2));
      },
    );

    testWidgets('starts collapsed and reveals the bars on tap', (tester) async {
      final run = PipelineRun(
        id: 'run-1',
        templateId: 'tmpl-1',
        workspaceId: 'ws-1',
        status: PipelineRunStatus.completed,
        startedAt: _start,
        finishedAt: _start.add(const Duration(seconds: 3)),
        activeMs: 3000,
      );
      final steps = [
        PipelineStepRun(
          id: 'sr-a',
          pipelineRunId: 'run-1',
          stepId: 'step-a',
          status: PipelineStepStatus.completed,
          startedAt: _start,
          finishedAt: _start.add(const Duration(seconds: 3)),
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PipelineRunWaterfall(
            run: run,
            stepRuns: steps,
            definition: _definition(),
            now: _start.add(const Duration(seconds: 3)),
          ),
        ),
      );

      // Summary only: the step labels/bars must not push the canvas off screen.
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.textContaining('Active 3s'), findsOneWidget);
      expect(find.text('Branch A'), findsNothing);

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.text('Branch A'), findsOneWidget);

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.text('Branch A'), findsNothing);
    });

    testWidgets('a live run still measures open rows against now', (
      tester,
    ) async {
      final run = PipelineRun(
        id: 'run-1',
        templateId: 'tmpl-1',
        workspaceId: 'ws-1',
        status: PipelineRunStatus.running,
        startedAt: _start,
        lastResumedAt: _start,
      );
      final steps = [
        PipelineStepRun(
          id: 'sr-a',
          pipelineRunId: 'run-1',
          stepId: 'step-a',
          status: PipelineStepStatus.running,
          startedAt: _start,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PipelineRunWaterfall(
            run: run,
            stepRuns: steps,
            definition: _definition(),
            now: _start.add(const Duration(seconds: 30)),
            initiallyExpanded: true,
          ),
        ),
      );

      expect(find.text('30.0s'), findsOneWidget);
    });

    testWidgets('the idle chip explains itself on hover', (tester) async {
      // 60s wall clock, 10s of it active → a 50s stop→restart gap.
      final run = PipelineRun(
        id: 'run-1',
        templateId: 'tmpl-1',
        workspaceId: 'ws-1',
        status: PipelineRunStatus.completed,
        startedAt: _start,
        finishedAt: _start.add(const Duration(seconds: 60)),
        activeMs: 10000,
      );
      final steps = [
        PipelineStepRun(
          id: 'sr-a',
          pipelineRunId: 'run-1',
          stepId: 'step-a',
          status: PipelineStepStatus.completed,
          startedAt: _start,
          finishedAt: _start.add(const Duration(seconds: 60)),
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PipelineRunWaterfall(
            run: run,
            stepRuns: steps,
            definition: _definition(),
            now: _start.add(const Duration(hours: 4)),
          ),
        ),
      );

      expect(find.textContaining('idle 50s'), findsOneWidget);
      expect(
        find.byType(CcTooltip),
        findsWidgets,
        reason: '"idle" alone does not say what the number measures',
      );
    });
  });
}
