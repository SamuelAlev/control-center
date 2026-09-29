import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_server_core/src/demo/demo_pipeline_fixtures.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:test/test.dart';

void main() {
  final templates = <String, PipelineDefinition>{
    for (final def in builtInTemplateSeeds(
      workspaceId: 'ws',
      agentIds: const BuiltInAgentIds(
        qa: 'qa',
        architect: 'architect',
        engineer: 'engineer',
        librarian: 'librarian',
        ceo: 'ceo',
      ),
    ))
      def.templateId: def,
    kDemoReleaseChecksTemplateId: demoReleaseChecksTemplate('ws'),
  };

  test('release checks is a valid demo template the prune keeps', () {
    expect(kDemoPipelineTemplateIds, contains(kDemoReleaseChecksTemplateId));
    final issues = const PipelineValidator().errors(
      templates[kDemoReleaseChecksTemplateId]!,
    );
    expect(issues, isEmpty, reason: issues.map((i) => i.message).join('\n'));
  });

  test('seeded runs cover visible nodes and fail a real step', () {
    final runs = demoPipelineRuns();
    expect(runs.map((r) => r.runId).toSet(), hasLength(runs.length));
    expect(runs, hasLength(greaterThan(2)));

    for (final run in runs) {
      final template = templates[run.templateId];
      expect(template, isNotNull, reason: run.templateId);
      final visible = template!.steps
          .where((s) => s.kind != StepKind.terminal)
          .map((s) => s.id)
          .toSet();
      final seeded = run.steps.map((s) => s.stepId).toSet();
      expect(seeded, visible, reason: '${run.runId} step ids');

      for (final step in run.steps) {
        final def = template.step(step.stepId)!;
        expect(def.kind, isNot(StepKind.terminal));
        if (def.bodyKey == BuiltInBodyKeys.bashScript &&
            step.status != PipelineStepStatus.skipped) {
          expect(step.input?['script'], isA<String>());
          final transcript = step.output?['output'];
          expect(transcript, isA<String>());
          expect((transcript as String).trim(), isNotEmpty);
        }
      }

      if (run.status != PipelineRunStatus.failed) {
        expect(
          run.steps.any((s) => s.status == PipelineStepStatus.failed),
          isFalse,
        );
        continue;
      }

      final failed = run.steps
          .where((s) => s.status == PipelineStepStatus.failed)
          .toList();
      expect(failed, hasLength(1), reason: run.runId);
      expect(failed.single.error, isNotNull);
      expect(failed.single.error!.trim(), isNotEmpty);
      final transcript = failed.single.output?['output'];
      expect(transcript, isA<String>());
      expect((transcript as String).trim(), isNotEmpty);
      expect(
        run.steps.where((s) => s.status == PipelineStepStatus.completed),
        isNotEmpty,
        reason: 'steps before the failure still succeeded',
      );
      expect(
        run.steps.where((s) => s.status == PipelineStepStatus.skipped),
        isNotEmpty,
        reason: 'steps after the failure are not painted green',
      );
    }
  });

  test('the ticket failure is the draft-PR shell step', () {
    final run = demoPipelineRuns().firstWhere(
      (r) => r.runId == 'demo-pipeline-run-1',
    );
    final open = run.steps.firstWhere((s) => s.stepId == 'open_pr');
    expect(run.status, PipelineRunStatus.failed);
    expect(open.status, PipelineStepStatus.failed);
    expect(open.input?['script'], contains('gh pr create'));
    expect(open.output?['exitCode'], 1);
    expect(
      run.steps.firstWhere((s) => s.stepId == 'comment').status,
      PipelineStepStatus.skipped,
    );
    expect(
      run.steps.firstWhere((s) => s.stepId == 'self_review').status,
      PipelineStepStatus.completed,
    );
  });
}
