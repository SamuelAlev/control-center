import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/pipeline_mappers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pipelineRunToCompanion / pipelineRunFromRow', () {
    final now = DateTime(2025, 1, 1);
    final finished = DateTime(2025, 1, 1, 0, 5);

    PipelineRun run0({
      PipelineRunStatus status = PipelineRunStatus.completed,
      Map<String, dynamic>? state,
      Map<String, dynamic>? triggerPayload,
      String? errorMessage,
      String? errorStackTrace,
      String? dedupKey,
      DateTime? finishedAt,
      int totalCostCents = 0,
      int totalTokens = 0,
      bool dryRun = false,
    }) =>
        PipelineRun(
          id: 'run-1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: status,
          state: state,
          triggerEventType: 'ExternalPrDetected',
          triggerPayload: triggerPayload,
          dedupKey: dedupKey,
          startedAt: now,
          finishedAt: finishedAt,
          errorMessage: errorMessage,
          errorStackTrace: errorStackTrace,
          totalCostCents: totalCostCents,
          totalTokens: totalTokens,
          dryRun: dryRun,
        );

    PipelineRunsTableData row0({
      String status = 'completed',
      String stateJson = '{}',
      String? triggerPayloadJson,
      String? errorMessage,
      String? errorStackTrace,
      String? dedupKey,
      DateTime? finishedAt,
      int totalCostCents = 0,
      int totalTokens = 0,
      bool dryRun = false,
    }) =>
        PipelineRunsTableData(
          id: 'run-1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: status,
          stateJson: stateJson,
          triggerEventType: 'ExternalPrDetected',
          triggerPayloadJson: triggerPayloadJson,
          startedAt: now,
          finishedAt: finishedAt,
          errorMessage: errorMessage,
          errorStackTrace: errorStackTrace,
          dedupKey: dedupKey,
          parentPipelineRunId: null,
          parentStepId: null,
          templateVersion: 1,
          totalCostCents: totalCostCents,
          totalTokens: totalTokens,
          dryRun: dryRun,
        );

    test('pipelineRunToCompanion maps all fields', timeout: const Timeout.factor(2), () {
      final run = run0(
        state: {'a': 1},
        triggerPayload: {'pr': 42},
        dedupKey: 'dk',
        finishedAt: finished,
        errorMessage: 'err',
        errorStackTrace: 'trace',
        totalCostCents: 100,
        totalTokens: 500,
        dryRun: true,
      );
      final companion = pipelineRunToCompanion(run);

      expect(companion.id.value, 'run-1');
      expect(companion.templateId.value, 'tpl');
      expect(companion.workspaceId.value, 'ws');
      expect(companion.status.value, 'completed');
      expect(companion.stateJson.value, '{"a":1}');
      expect(companion.triggerEventType.value, 'ExternalPrDetected');
      expect(companion.triggerPayloadJson.value, '{"pr":42}');
      expect(companion.dedupKey.value, 'dk');
      expect(companion.startedAt.value, now);
      expect(companion.finishedAt.value, finished);
      expect(companion.errorMessage.value, 'err');
      expect(companion.errorStackTrace.value, 'trace');
      expect(companion.totalCostCents.value, 100);
      expect(companion.totalTokens.value, 500);
      expect(companion.dryRun.value, isTrue);
    });

    test('pipelineRunToCompanion uses absent for null triggerPayload',
        timeout: const Timeout.factor(2), () {
      final run = run0(triggerPayload: null);
      final companion = pipelineRunToCompanion(run);
      expect(companion.triggerPayloadJson, const Value.absent());
    });

    test('pipelineRunFromRow maps all fields', timeout: const Timeout.factor(2), () {
      final row = row0(
        status: 'failed',
        stateJson: '{"x":2}',
        triggerPayloadJson: '{"k":"v"}',
        errorMessage: 'boom',
        errorStackTrace: 'stack',
        dedupKey: 'dk',
        finishedAt: finished,
        totalCostCents: 200,
        totalTokens: 1000,
        dryRun: true,
      );
      final run = pipelineRunFromRow(row);

      expect(run.id, 'run-1');
      expect(run.templateId, 'tpl');
      expect(run.workspaceId, 'ws');
      expect(run.status, PipelineRunStatus.failed);
      expect(run.state, {'x': 2});
      expect(run.triggerEventType, 'ExternalPrDetected');
      expect(run.triggerPayload, {'k': 'v'});
      expect(run.dedupKey, 'dk');
      expect(run.startedAt, now);
      expect(run.finishedAt, finished);
      expect(run.errorMessage, 'boom');
      expect(run.errorStackTrace, 'stack');
      expect(run.totalCostCents, 200);
      expect(run.totalTokens, 1000);
      expect(run.dryRun, isTrue);
    });

    test('pipelineRunFromRow handles empty stateJson', timeout: const Timeout.factor(2), () {
      final row = row0(stateJson: '');
      final run = pipelineRunFromRow(row);
      expect(run.state, isEmpty);
    });

    test('pipelineRunFromRow handles null triggerPayloadJson', timeout: const Timeout.factor(2), () {
      final row = row0(triggerPayloadJson: null);
      final run = pipelineRunFromRow(row);
      expect(run.triggerPayload, isNull);
    });

    test('round-trip: run to companion reconstructs correctly', timeout: const Timeout.factor(2), () {
      final original = run0(
        state: {'key': 'value'},
        triggerPayload: {'prNumber': 42},
        dedupKey: 'dk',
        finishedAt: finished,
      );
      final companion = pipelineRunToCompanion(original);

      // Reconstruct a row from the companion (simulating what Drift would store)
      final row = PipelineRunsTableData(
        id: companion.id.value,
        templateId: companion.templateId.value,
        workspaceId: companion.workspaceId.value,
        status: companion.status.value,
        stateJson: companion.stateJson.value,
        triggerEventType: companion.triggerEventType.value,
        triggerPayloadJson: companion.triggerPayloadJson.present
            ? companion.triggerPayloadJson.value
            : null,
        startedAt: companion.startedAt.value,
        finishedAt: companion.finishedAt.value,
        errorMessage: companion.errorMessage.value,
        errorStackTrace: companion.errorStackTrace.value,
        dedupKey: companion.dedupKey.value,
        parentPipelineRunId: companion.parentPipelineRunId.value,
        parentStepId: companion.parentStepId.value,
        templateVersion: companion.templateVersion.value,
        totalCostCents: companion.totalCostCents.value,
        totalTokens: companion.totalTokens.value,
        dryRun: companion.dryRun.value,
      );

      final restored = pipelineRunFromRow(row);
      expect(restored.id, original.id);
      expect(restored.templateId, original.templateId);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.status, original.status);
      expect(restored.state, original.state);
      expect(restored.triggerPayload, original.triggerPayload);
    });
  });

  group('stepRunToCompanion / stepRunFromRow', () {
    final now = DateTime(2025, 1, 1);

    test('stepRunToCompanion maps fields', timeout: const Timeout.factor(2), () {
      final stepRun = PipelineStepRun(
        id: 'sr-1',
        pipelineRunId: 'pr-1',
        stepId: 'review',
        status: PipelineStepStatus.completed,
        inputJson: '{"a":1}',
        outputJson: '{"b":2}',
        errorMessage: null,
        branchIndex: 3,
        attemptCount: 2,
        startedAt: now,
        finishedAt: now.add(const Duration(seconds: 5)),
      );
      final companion = stepRunToCompanion(stepRun);

      expect(companion.id.value, 'sr-1');
      expect(companion.pipelineRunId.value, 'pr-1');
      expect(companion.stepId.value, 'review');
      expect(companion.status.value, 'completed');
      expect(companion.inputJson.value, '{"a":1}');
      expect(companion.branchIndex.value, 3);
      expect(companion.startedAt.value, now);
    });

    test('stepRunFromRow maps fields', timeout: const Timeout.factor(2), () {
      final row = PipelineStepRunsTableData(
        id: 'sr-1',
        pipelineRunId: 'pr-1',
        stepId: 'review',
        status: 'failed',
        inputJson: '{"a":1}',
        outputJson: null,
        errorMessage: 'boom',
        errorStackTrace: null,
        branchIndex: null,
        attemptCount: 3,
        startedAt: now,
        finishedAt: now,
      );
      final stepRun = stepRunFromRow(row);

      expect(stepRun.id, 'sr-1');
      expect(stepRun.pipelineRunId, 'pr-1');
      expect(stepRun.stepId, 'review');
      expect(stepRun.status, PipelineStepStatus.failed);
      expect(stepRun.inputJson, '{"a":1}');
      expect(stepRun.outputJson, isNull);
      expect(stepRun.errorMessage, 'boom');
      expect(stepRun.branchIndex, isNull);
      expect(stepRun.attemptCount, 3);
    });
  });
}
