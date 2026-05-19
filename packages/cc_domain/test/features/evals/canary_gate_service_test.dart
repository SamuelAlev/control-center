import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/services/canary_gate_service.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';
import 'package:test/test.dart';

/// Map-backed [EvalsRepository] fake. Only the config-version methods carry
/// real behaviour; the rest forward to [noSuchMethod] and throw.
class _FakeEvalsRepository implements EvalsRepository {
  final Map<String, AgentConfigVersion> _versions = {};

  @override
  Future<void> upsertConfigVersion(AgentConfigVersion version) async {
    _versions[version.id] = version;
  }

  @override
  Future<AgentConfigVersion?> liveConfigVersion(
    String workspaceId,
    String agentId,
  ) async {
    for (final v in _versions.values) {
      if (v.workspaceId == workspaceId &&
          v.agentId == agentId &&
          v.status == 'live') {
        return v;
      }
    }
    return null;
  }

  @override
  Future<AgentConfigVersion?> configVersionByHash(
    String workspaceId,
    String agentId,
    String configHash,
  ) async {
    for (final v in _versions.values) {
      if (v.workspaceId == workspaceId &&
          v.agentId == agentId &&
          v.configHash == configHash) {
        return v;
      }
    }
    return null;
  }

  @override
  Future<List<AgentConfigVersion>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  ) async => _versions.values
      .where((v) => v.workspaceId == workspaceId && v.agentId == agentId)
      .toList();

  @override
  Future<void> setConfigVersionStatus(
    String workspaceId,
    String id, {
    required String status,
    String? promotedBy,
    DateTime? promotedAt,
    String? scorecardJson,
  }) async {
    final v = _versions[id];
    if (v == null) {
      return;
    }
    _versions[id] = AgentConfigVersion(
      id: v.id,
      workspaceId: v.workspaceId,
      agentId: v.agentId,
      configHash: v.configHash,
      createdAt: v.createdAt,
      hashVersion: v.hashVersion,
      configJson: v.configJson,
      status: status,
      scorecardJson: scorecardJson ?? v.scorecardJson,
      promotedBy: promotedBy ?? v.promotedBy,
      promotedAt: promotedAt ?? v.promotedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AgentConfigSnapshot _snapshot(String systemPrompt) => AgentConfigSnapshot(
  systemPrompt: systemPrompt,
  modePrompts: const ['mode-a'],
  tools: const [ToolFingerprint(name: 'read', schemaHash: 'h1')],
  modelId: 'anthropic/claude-opus-4-8',
  memoryPolicies: const ['p1@1'],
  routingHash: 'route-abc',
);

EvalScorecard _scorecard({required double passRate, required int batchSize}) =>
    EvalScorecard(
      batchSize: batchSize,
      passRate: passRate,
      passRateStdDev: 0,
      avgCostCents: 0,
      costStdDev: 0,
      avgTurns: 0,
      avgDurationMs: 0,
      perGraderPassRate: const {},
      repsPassed: (passRate * batchSize).round(),
    );

CanaryGateService _service(EvalsRepository repo) {
  var counter = 0;
  return CanaryGateService(
    repository: repo,
    now: () => DateTime(2026),
    newId: () => 'cfg-${counter++}',
  );
}

void main() {
  final v1 = _snapshot('config v1');
  final v2 = _snapshot('config v2');

  group('CanaryGateService', () {
    test(
      'openCanary records a canary while the prior live stays live',
      () async {
        final repo = _FakeEvalsRepository();
        final svc = _service(repo);

        final live = await svc.recordLiveConfig(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v1,
        );
        expect(live.status, 'live');

        final canary = await svc.openCanary(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v2,
        );
        expect(canary.status, 'canary');
        expect(canary.configHash, v2.configHash);

        final stillLive = await repo.liveConfigVersion('w1', 'a1');
        expect(stillLive!.configHash, v1.configHash);
        expect(stillLive.status, 'live');
      },
    );

    test(
      'openCanary on the already-live hash does not demote it (regression)',
      () async {
        final repo = _FakeEvalsRepository();
        final svc = _service(repo);

        await svc.recordLiveConfig(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v1,
        );
        // Re-proposing the SAME (already-live) config as a canary must be a no-op
        // — never leave the agent with no live version.
        final result = await svc.openCanary(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v1,
        );
        expect(result.status, 'live');

        final stillLive = await repo.liveConfigVersion('w1', 'a1');
        expect(stillLive!.configHash, v1.configHash);
        expect(stillLive.status, 'live');
      },
    );

    test(
      'a green scorecard promotes the canary and retires the old live',
      () async {
        final repo = _FakeEvalsRepository();
        final svc = _service(repo);
        await svc.recordLiveConfig(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v1,
        );
        await svc.openCanary(workspaceId: 'w1', agentId: 'a1', snapshot: v2);

        final decision = await svc.evaluateAndPromote(
          workspaceId: 'w1',
          agentId: 'a1',
          configHash: v2.configHash,
          scorecard: _scorecard(passRate: 0.95, batchSize: 10),
        );
        expect(decision.promoted, isTrue);
        expect(decision.overrideUsed, isFalse);

        final nowLive = await repo.liveConfigVersion('w1', 'a1');
        expect(nowLive!.configHash, v2.configHash);

        final oldLive = await repo.configVersionByHash(
          'w1',
          'a1',
          v1.configHash,
        );
        expect(oldLive!.status, 'retired');
      },
    );

    test('a non-green scorecard without an override is blocked', () async {
      final repo = _FakeEvalsRepository();
      final svc = _service(repo);
      await svc.recordLiveConfig(
        workspaceId: 'w1',
        agentId: 'a1',
        snapshot: v1,
      );
      await svc.openCanary(workspaceId: 'w1', agentId: 'a1', snapshot: v2);

      final decision = await svc.evaluateAndPromote(
        workspaceId: 'w1',
        agentId: 'a1',
        configHash: v2.configHash,
        scorecard: _scorecard(passRate: 0.5, batchSize: 10),
      );
      expect(decision.promoted, isFalse);
      expect(decision.reason, contains('Blocked'));
    });

    test(
      'a non-green scorecard with an override promotes and is recorded',
      () async {
        final repo = _FakeEvalsRepository();
        final svc = _service(repo);
        await svc.recordLiveConfig(
          workspaceId: 'w1',
          agentId: 'a1',
          snapshot: v1,
        );
        await svc.openCanary(workspaceId: 'w1', agentId: 'a1', snapshot: v2);

        final decision = await svc.evaluateAndPromote(
          workspaceId: 'w1',
          agentId: 'a1',
          configHash: v2.configHash,
          scorecard: _scorecard(passRate: 0.5, batchSize: 10),
          override: true,
        );
        expect(decision.promoted, isTrue);
        expect(decision.overrideUsed, isTrue);

        final nowLive = await repo.liveConfigVersion('w1', 'a1');
        expect(nowLive!.configHash, v2.configHash);
      },
    );
  });
}
