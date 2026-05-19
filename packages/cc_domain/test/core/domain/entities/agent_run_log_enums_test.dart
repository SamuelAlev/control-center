import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:test/test.dart';

/// Covers the RunErrorFamily / RunLiveness tryParse fallbacks and the
/// AgentRunLog value equality + hashCode across a fully-populated instance.
void main() {
  group('RunErrorFamily.tryParse', () {
    test('parses known values case-insensitively', () {
      expect(
        RunErrorFamily.tryParse('transientUpstream'),
        RunErrorFamily.transientUpstream,
      );
      expect(
        RunErrorFamily.tryParse('BUDGETEXCEEDED'),
        RunErrorFamily.budgetExceeded,
      );
      expect(
        RunErrorFamily.tryParse('sandboxinfrastructure'),
        RunErrorFamily.sandboxInfrastructure,
      );
      expect(
        RunErrorFamily.tryParse('processLost'),
        RunErrorFamily.processLost,
      );
      expect(RunErrorFamily.tryParse('silentRun'), RunErrorFamily.silentRun);
      expect(RunErrorFamily.tryParse('unknown'), RunErrorFamily.unknown);
    });

    test('null + unknown default to unknown', () {
      expect(RunErrorFamily.tryParse(null), RunErrorFamily.unknown);
      expect(RunErrorFamily.tryParse('nope'), RunErrorFamily.unknown);
    });
  });

  group('RunLiveness.tryParse', () {
    test('parses known values (lowercased compare)', () {
      expect(RunLiveness.tryParse('alive'), RunLiveness.alive);
      expect(RunLiveness.tryParse('productive'), RunLiveness.productive);
      expect(RunLiveness.tryParse('completed'), RunLiveness.completed);
      expect(RunLiveness.tryParse('blocked'), RunLiveness.blocked);
      expect(RunLiveness.tryParse('empty'), RunLiveness.empty);
      expect(RunLiveness.tryParse('looping'), RunLiveness.looping);
      expect(RunLiveness.tryParse('failed'), RunLiveness.failed);
      expect(RunLiveness.tryParse('stalled'), RunLiveness.stalled);
      expect(RunLiveness.tryParse('dead'), RunLiveness.dead);
    });

    test('null + unknown default to empty', () {
      expect(RunLiveness.tryParse(null), RunLiveness.empty);
      expect(RunLiveness.tryParse('nope'), RunLiveness.empty);
    });
  });

  group('AgentRunLog value equality', () {
    AgentRunLog full() => AgentRunLog(
      id: 'r1',
      agentId: 'a1',
      workspaceId: 'ws',
      conversationId: 'c',
      ticketId: 't',
      channelId: 'ch',
      startedAt: DateTime(2025, 6, 1),
      completedAt: DateTime(2025, 6, 2),
      status: RunStatus.completed,
      summary: 'sum',
      adapter: 'ad',
      modelId: 'm',
      pid: 7,
      logPath: '/p',
      cost: const RunCost(
        inputTokens: 1,
        outputTokens: 2,
        estimatedCostCents: 3,
      ),
      liveness: RunLiveness.productive,
      errorFamily: RunErrorFamily.budgetExceeded,
      lastOutputAt: DateTime(2025, 6, 1, 12),
      continuationSummary: 'cs',
      contextSnapshotJson: '{}',
      pipelineRunId: 'pr',
      pipelineStepRunId: 'psr',
      errorCode: 'E1',
      expectedOutputSchema: const {'type': 'object'},
      outputContractMode: OutputContractMode.permissive,
      outputJson: const {'k': 'v'},
      outputRejections: 1,
      retry: const RetryMeta(),
      role: AgentRunRole.sub,
      childCostCents: 9,
      parentRunId: 'pr2',
    );

    test('identical-field instances are equal with matching hashCode', () {
      final a = full();
      final b = full();
      expect(a, isNot(same(b)));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs by id', () {
      expect(full(), isNot(full().copyWith(id: 'other')));
    });

    test('differs by status', () {
      expect(full(), isNot(full().copyWith(status: RunStatus.error)));
    });

    test('status convenience getters', () {
      expect(full().isCompleted, isTrue);
      expect(full().isError, isFalse);
      expect(full().copyWith(status: RunStatus.running).isRunning, isTrue);
      expect(full().copyWith(status: RunStatus.pending).isActive, isTrue);
      expect(full().totalCostCentsWithChildren, 12); // 3 + 9
    });

    test('copyWith remove flags clear nullable fields', () {
      final base = full();
      expect(base.copyWith(removeSummary: true).summary, isNull);
      expect(base.copyWith(removeCompletedAt: true).completedAt, isNull);
      expect(base.copyWith(removeAdapter: true).adapter, isNull);
      expect(base.copyWith(removeModelId: true).modelId, isNull);
      expect(base.copyWith(removePid: true).pid, isNull);
      expect(base.copyWith(removeLogPath: true).logPath, isNull);
      expect(base.copyWith(removeLiveness: true).liveness, isNull);
      expect(base.copyWith(removeErrorFamily: true).errorFamily, isNull);
      expect(base.copyWith(removeLastOutputAt: true).lastOutputAt, isNull);
      expect(
        base.copyWith(removeContinuationSummary: true).continuationSummary,
        isNull,
      );
      expect(
        base.copyWith(removeContextSnapshotJson: true).contextSnapshotJson,
        isNull,
      );
      expect(base.copyWith(removeErrorCode: true).errorCode, isNull);
      expect(base.copyWith(removeOutputJson: true).outputJson, isNull);
    });
  });
}
