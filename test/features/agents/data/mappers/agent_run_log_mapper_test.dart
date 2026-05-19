import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/agent_run_log_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

AgentRunLogsTableData _makeRow({
  String id = 'log-1',
  String agentId = 'agent-1',
  String? workspaceId = 'ws-1',
  String? conversationId,
  String? ticketId,
  String? spaceId,
  DateTime? startedAt,
  DateTime? completedAt,
  String status = 'completed',
  String? summary,
  String? adapter,
  int? pid,
  String? logPath,
  int inputTokens = 100,
  int outputTokens = 50,
  int thoughtTokens = 0,
  int cachedReadTokens = 0,
  int cachedWriteTokens = 0,
  int estimatedCostCents = 15,
  int childCostCents = 0,
  String? agentRole,
  int? durationMs,
  int? timeToFirstTokenMs,
  String? livenessClass,
  String? errorFamily,
  DateTime? lastOutputAt,
  String? continuationSummary,
  String? contextSnapshotJson,
  String? retryOfRunId,
  int retryAttempt = 0,
  String? expectedOutputSchema,
  String? outputContractMode,
  String? outputJson,
  int outputRejections = 0,
}) => AgentRunLogsTableData(
  id: id,
  agentId: agentId,
  workspaceId: workspaceId,
  conversationId: conversationId,
  ticketId: ticketId,
  spaceId: spaceId,
  startedAt: startedAt ?? DateTime(2025, 6, 1),
  completedAt: completedAt,
  status: status,
  summary: summary,
  adapter: adapter,
  pid: pid,
  logPath: logPath,
  inputTokens: inputTokens,
  outputTokens: outputTokens,
  thoughtTokens: thoughtTokens,
  cachedReadTokens: cachedReadTokens,
  cachedWriteTokens: cachedWriteTokens,
  estimatedCostCents: estimatedCostCents,
  childCostCents: childCostCents,
  agentRole: agentRole,
  durationMs: durationMs,
  timeToFirstTokenMs: timeToFirstTokenMs,
  livenessClass: livenessClass,
  errorFamily: errorFamily,
  lastOutputAt: lastOutputAt,
  continuationSummary: continuationSummary,
  contextSnapshotJson: contextSnapshotJson,
  retryOfRunId: retryOfRunId,
  retryAttempt: retryAttempt,
  memoryReads: 0,
  memoryWrites: 0,
  codeGraphCalls: 0,
  expectedOutputSchema: expectedOutputSchema,
  outputContractMode: outputContractMode,
  outputJson: outputJson,
  outputRejections: outputRejections,
);

void main() {
  group('AgentRunLogMapper', () {
    const mapper = AgentRunLogMapper();

    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final row = _makeRow(
        id: 'r1',
        agentId: 'a1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        ticketId: 't-1',
        spaceId: 'ch-1',
        completedAt: DateTime(2025, 6, 2),
        summary: 'did stuff',
        adapter: 'claude',
        pid: 12345,
        logPath: '/logs/r1.ndjson',
        inputTokens: 200,
        outputTokens: 100,
        thoughtTokens: 25,
        cachedReadTokens: 40,
        cachedWriteTokens: 10,
        estimatedCostCents: 30,
        childCostCents: 7,
        agentRole: 'sub',
        durationMs: 4200,
        timeToFirstTokenMs: 850,
        lastOutputAt: DateTime(2025, 6, 1, 23),
        continuationSummary: 'continued',
        contextSnapshotJson: '{}',
        retryOfRunId: 'parent-1',
        retryAttempt: 2,
        expectedOutputSchema: '{"type":"object"}',
        outputContractMode: 'permissive',
        outputJson: '{"result":"ok"}',
        outputRejections: 2,
      );

      final log = mapper.toDomain(row);

      expect(log.id, 'r1');
      expect(log.agentId, 'a1');
      expect(log.workspaceId, 'ws-1');
      expect(log.conversationId, 'conv-1');
      expect(log.ticketId, 't-1');
      expect(log.spaceId, 'ch-1');
      expect(log.completedAt, DateTime(2025, 6, 2));
      expect(log.summary, 'did stuff');
      expect(log.adapter, 'claude');
      expect(log.pid, 12345);
      expect(log.logPath, '/logs/r1.ndjson');
      expect(log.cost.inputTokens, 200);
      expect(log.cost.outputTokens, 100);
      expect(log.cost.thoughtTokens, 25);
      expect(log.cost.cachedReadTokens, 40);
      expect(log.cost.cachedWriteTokens, 10);
      expect(log.cost.estimatedCostCents, 30);
      expect(log.cost.durationMs, 4200);
      expect(log.cost.timeToFirstTokenMs, 850);
      expect(log.childCostCents, 7);
      expect(log.role, AgentRunRole.sub);
      expect(log.lastOutputAt, DateTime(2025, 6, 1, 23));
      expect(log.continuationSummary, 'continued');
      expect(log.contextSnapshotJson, '{}');
      expect(log.retry.parentRunId, 'parent-1');
      expect(log.retry.attempt, 2);
      expect(log.expectedOutputSchema, {'type': 'object'});
      expect(log.outputContractMode, OutputContractMode.permissive);
      expect(log.outputJson, {'result': 'ok'});
      expect(log.outputRejections, 2);
    });

    test(
      'defaults output contract fields when columns absent',
      timeout: const Timeout.factor(2),
      () {
        final log = mapper.toDomain(_makeRow());
        expect(log.expectedOutputSchema, isNull);
        expect(log.outputContractMode, OutputContractMode.strict);
        expect(log.outputJson, isNull);
        expect(log.outputRejections, 0);
        // A null/absent agentRole attributes to the main agent; no rolled-up
        // child cost by default.
        expect(log.role, AgentRunRole.main);
        expect(log.childCostCents, 0);
      },
    );

    group('_parseRunStatus', () {
      test('parses pending', timeout: const Timeout.factor(2), () {
        final log = mapper.toDomain(_makeRow(status: 'pending'));
        expect(log.status, RunStatus.pending);
      });

      test('parses running', timeout: const Timeout.factor(2), () {
        final log = mapper.toDomain(_makeRow(status: 'running'));
        expect(log.status, RunStatus.running);
      });

      test('parses completed', timeout: const Timeout.factor(2), () {
        final log = mapper.toDomain(_makeRow(status: 'completed'));
        expect(log.status, RunStatus.completed);
      });

      test('parses error', timeout: const Timeout.factor(2), () {
        final log = mapper.toDomain(_makeRow(status: 'error'));
        expect(log.status, RunStatus.error);
      });

      test(
        'defaults to error for unknown status',
        timeout: const Timeout.factor(2),
        () {
          final log = mapper.toDomain(_makeRow(status: 'unknown'));
          expect(log.status, RunStatus.error);
        },
      );
    });

    test('parses liveness class', timeout: const Timeout.factor(2), () {
      final log = mapper.toDomain(_makeRow(livenessClass: 'alive'));
      expect(log.liveness, RunLiveness.alive);
    });

    test(
      'an unclassified run maps to null liveness, not empty',
      timeout: const Timeout.factor(2),
      () {
        // Deliberately NOT `RunLiveness.empty`: `empty` is a verdict ("this
        // run produced nothing"), and answering it for a column nobody has
        // written yet gets that fabricated verdict persisted by the next
        // upsert. Unclassified stays unclassified.
        final log = mapper.toDomain(_makeRow(livenessClass: null));
        expect(log.liveness, isNull);
      },
    );

    test(
      'parses error family using camelCase name',
      timeout: const Timeout.factor(2),
      () {
        final log = mapper.toDomain(_makeRow(errorFamily: 'transientUpstream'));
        expect(log.errorFamily, RunErrorFamily.transientUpstream);
      },
    );

    test(
      'tryParse returns unknown for null errorFamily',
      timeout: const Timeout.factor(2),
      () {
        final log = mapper.toDomain(_makeRow(errorFamily: null));
        expect(log.errorFamily, RunErrorFamily.unknown);
      },
    );

    test('parses liveness stalled', timeout: const Timeout.factor(2), () {
      final log = mapper.toDomain(_makeRow(livenessClass: 'stalled'));
      expect(log.liveness, RunLiveness.stalled);
    });

    test('parses liveness dead', timeout: const Timeout.factor(2), () {
      final log = mapper.toDomain(_makeRow(livenessClass: 'dead'));
      expect(log.liveness, RunLiveness.dead);
    });

    test(
      'toDomainList maps multiple rows',
      timeout: const Timeout.factor(2),
      () {
        final rows = [
          _makeRow(id: 'r1', agentId: 'a1'),
          _makeRow(id: 'r2', agentId: 'a2'),
        ];
        final logs = mapper.toDomainList(rows);
        expect(logs, hasLength(2));
        expect(logs[0].id, 'r1');
        expect(logs[1].id, 'r2');
      },
    );

    test(
      'retry defaults to empty when not set',
      timeout: const Timeout.factor(2),
      () {
        final log = mapper.toDomain(
          _makeRow(retryOfRunId: null, retryAttempt: 0),
        );
        expect(log.retry.parentRunId, isNull);
        expect(log.retry.attempt, 0);
      },
    );
  });
}
