import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';

/// The outcome of a canary-gate decision (PRD 21 §6).
class CanaryDecision {
  /// Creates a [CanaryDecision].
  const CanaryDecision({
    required this.promoted,
    required this.reason,
    this.overrideUsed = false,
  });

  /// Whether the canary was promoted to live.
  final bool promoted;

  /// Human-readable reason (green scorecard / blocked / override recorded).
  final String reason;

  /// Whether promotion happened via an explicit override (recorded).
  final bool overrideUsed;
}

/// Gates config changes behind a green scorecard (PRD 21 §6).
///
/// A config change is *canaried*: the old config stays live while the new one
/// runs its goldens + suite. It promotes only on a green scorecard — or via an
/// explicit, recorded override. Pure orchestration over the config-version
/// rows; the governance-approval attachment is the runtime's job.
class CanaryGateService {
  /// Creates a [CanaryGateService].
  CanaryGateService({
    required EvalsRepository repository,
    DateTime Function()? now,
    String Function()? newId,
    double greenThreshold = 0.9,
  }) : _repo = repository,
       _now = now ?? DateTime.now,
       _newId = newId ?? _defaultId,
       _greenThreshold = greenThreshold;

  final EvalsRepository _repo;
  final DateTime Function() _now;
  final String Function() _newId;
  final double _greenThreshold;

  static int _counter = 0;
  static String _defaultId() =>
      'cfg-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  /// Records the current effective config as the live version (idempotent by
  /// hash) — called on every run so "what changed?" always has an answer.
  Future<AgentConfigVersion> recordLiveConfig({
    required String workspaceId,
    required String agentId,
    required AgentConfigSnapshot snapshot,
  }) async {
    final existing = await _repo.configVersionByHash(
      workspaceId,
      agentId,
      snapshot.configHash,
    );
    if (existing != null) {
      return existing;
    }
    final version = AgentConfigVersion(
      id: _newId(),
      workspaceId: workspaceId,
      agentId: agentId,
      configHash: snapshot.configHash,
      hashVersion: snapshot.hashVersion,
      configJson: snapshot.toJsonString(),
      status: 'live',
      createdAt: _now(),
    );
    await _repo.upsertConfigVersion(version);
    return version;
  }

  /// Opens a canary for a proposed config change: the new version is recorded
  /// as `canary` while the live one stays live.
  Future<AgentConfigVersion> openCanary({
    required String workspaceId,
    required String agentId,
    required AgentConfigSnapshot snapshot,
  }) async {
    final existing = await _repo.configVersionByHash(
      workspaceId,
      agentId,
      snapshot.configHash,
    );
    // A config that is already live (or retired) must NOT be demoted to canary
    // by re-proposing the same hash — that would leave the agent with no live
    // version. Canarying only applies to a genuinely new (or already-canary)
    // config; an already-live hash is returned unchanged.
    if (existing != null && existing.status != 'canary') {
      return existing;
    }
    final version = AgentConfigVersion(
      id: existing?.id ?? _newId(),
      workspaceId: workspaceId,
      agentId: agentId,
      configHash: snapshot.configHash,
      hashVersion: snapshot.hashVersion,
      configJson: snapshot.toJsonString(),
      status: 'canary',
      createdAt: existing?.createdAt ?? _now(),
    );
    await _repo.upsertConfigVersion(version);
    return version;
  }

  /// Evaluates a canary against [scorecard] and promotes it only when green
  /// (or [override] is set — recorded). Retires the previously-live version.
  Future<CanaryDecision> evaluateAndPromote({
    required String workspaceId,
    required String agentId,
    required String configHash,
    required EvalScorecard scorecard,
    String? promotedBy,
    bool override = false,
  }) async {
    final green = scorecard.isGreen(threshold: _greenThreshold);
    if (!green && !override) {
      return CanaryDecision(
        promoted: false,
        reason:
            'Blocked: pass-rate ${(scorecard.passRate * 100).round()}% '
            '< ${(_greenThreshold * 100).round()}% over ${scorecard.batchSize} '
            'run(s).',
      );
    }
    final canary = await _repo.configVersionByHash(
      workspaceId,
      agentId,
      configHash,
    );
    if (canary == null) {
      return const CanaryDecision(
        promoted: false,
        reason: 'No canary version found for that config hash.',
      );
    }
    // Retire the currently-live version, then promote the canary.
    final live = await _repo.liveConfigVersion(workspaceId, agentId);
    if (live != null && live.configHash != configHash) {
      await _repo.setConfigVersionStatus(
        workspaceId,
        live.id,
        status: 'retired',
      );
    }
    await _repo.setConfigVersionStatus(
      workspaceId,
      canary.id,
      status: 'live',
      promotedBy: promotedBy,
      promotedAt: _now(),
      scorecardJson: scorecard.toJsonString(),
    );
    return CanaryDecision(
      promoted: true,
      overrideUsed: override && !green,
      reason: green
          ? 'Promoted on a green scorecard '
                '(${(scorecard.passRate * 100).round()}% over '
                '${scorecard.batchSize} run(s)).'
          : 'Promoted via recorded override despite a non-green scorecard.',
    );
  }
}
