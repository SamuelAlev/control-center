import 'dart:convert';

import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_persistence/database/tables/evals_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'evals_dao.g.dart';

/// Workspace-scoped evaluation storage: legacy suites and paired skill
/// campaigns, attempts and opt-in policies. Skill evaluation reads and writes
/// enforce ownership of the attached workspace database.
@DriftAccessor(
  tables: [
    SessionRecordingsTable,
    GoldenSessionsTable,
    EvalSuitesTable,
    EvalRunsTable,
    AgentConfigVersionsTable,
    SkillEvalCampaignsTable,
    SkillEvalAttemptsTable,
    SkillEvalPoliciesTable,
  ],
)
class EvalsDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$EvalsDaoMixin {
  /// Creates an [EvalsDao].
  EvalsDao(super.db);

  // ── Session recordings ──

  /// Inserts or replaces a recording (deterministic id → PK upsert).
  Future<void> upsertRecording(SessionRecordingsTableCompanion entry) =>
      into(sessionRecordingsTable).insertOnConflictUpdate(entry);

  /// One recording by id within [workspaceId], or null.
  Future<SessionRecordingsTableData?> recordingById(
    String workspaceId,
    String id,
  ) =>
      (select(sessionRecordingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// The recording for a given run log within [workspaceId], or null.
  Future<SessionRecordingsTableData?> recordingByRunLog(
    String workspaceId,
    String runLogId,
  ) =>
      (select(sessionRecordingsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.runLogId.equals(runLogId),
          ))
          .getSingleOrNull();

  /// Recordings in [workspaceId], newest first (optionally filtered by agent).
  Future<List<SessionRecordingsTableData>> recordings(
    String workspaceId, {
    String? agentId,
    int limit = 200,
  }) {
    final q = select(sessionRecordingsTable)
      ..where((t) {
        final base = t.workspaceId.equals(workspaceId);
        return agentId == null ? base : base & t.agentId.equals(agentId);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return q.get();
  }

  /// Live recordings in [workspaceId], newest first.
  Stream<List<SessionRecordingsTableData>> watchRecordings(
    String workspaceId, {
    int limit = 200,
  }) =>
      (select(sessionRecordingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Deletes recordings older than [cutoff] within [workspaceId] (retention).
  Future<int> pruneRecordings(String workspaceId, DateTime cutoff) =>
      (delete(sessionRecordingsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.createdAt.isSmallerThanValue(cutoff),
          ))
          .go();

  // ── Golden sessions ──

  /// Inserts or replaces a golden (deterministic id → PK upsert).
  Future<void> upsertGolden(GoldenSessionsTableCompanion entry) =>
      into(goldenSessionsTable).insertOnConflictUpdate(entry);

  /// One golden by id within [workspaceId], or null.
  Future<GoldenSessionsTableData?> goldenById(String workspaceId, String id) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Enabled goldens for [agentId] within [workspaceId].
  Future<List<GoldenSessionsTableData>> goldensForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(goldenSessionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.agentId.equals(agentId) &
                t.enabled.equals(true),
          ))
          .get();

  /// All goldens in [workspaceId], newest first.
  Future<List<GoldenSessionsTableData>> goldens(String workspaceId) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.blessedAt)]))
          .get();

  /// Live goldens in [workspaceId].
  Stream<List<GoldenSessionsTableData>> watchGoldens(String workspaceId) =>
      (select(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.blessedAt)]))
          .watch();

  /// Records the last golden run result within [workspaceId].
  Future<void> updateGoldenResult(
    String workspaceId,
    String id,
    String status,
    String? scorecardJson,
  ) =>
      (update(goldenSessionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            GoldenSessionsTableCompanion(
              lastStatus: Value(status),
              lastScorecardJson: Value(scorecardJson),
            ),
          );

  /// Deletes a golden within [workspaceId].
  Future<void> deleteGolden(String workspaceId, String id) => (delete(
    goldenSessionsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Eval suites ──

  /// Inserts or replaces a suite (deterministic id → PK upsert).
  Future<void> upsertSuite(EvalSuitesTableCompanion entry) =>
      into(evalSuitesTable).insertOnConflictUpdate(entry);

  /// One suite by id within [workspaceId], or null.
  Future<EvalSuitesTableData?> suiteById(String workspaceId, String id) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// One suite by name within [workspaceId], or null.
  Future<EvalSuitesTableData?> suiteByName(String workspaceId, String name) =>
      (select(evalSuitesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.name.equals(name),
          ))
          .getSingleOrNull();

  /// Suites in [workspaceId], by name.
  Future<List<EvalSuitesTableData>> suites(String workspaceId) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Live suites in [workspaceId].
  Stream<List<EvalSuitesTableData>> watchSuites(String workspaceId) =>
      (select(evalSuitesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Deletes a suite within [workspaceId].
  Future<void> deleteSuite(String workspaceId, String id) => (delete(
    evalSuitesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Eval runs ──

  /// Inserts or replaces an eval run (deterministic id → PK upsert).
  Future<void> upsertRun(EvalRunsTableCompanion entry) =>
      into(evalRunsTable).insertOnConflictUpdate(entry);

  /// One run by id within [workspaceId], or null.
  Future<EvalRunsTableData?> runById(String workspaceId, String id) =>
      (select(evalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Runs for [suiteId] within [workspaceId], newest first.
  Future<List<EvalRunsTableData>> runsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 100,
  }) =>
      (select(evalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.suiteId.equals(suiteId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Live runs for [suiteId] within [workspaceId], newest first.
  Stream<List<EvalRunsTableData>> watchRunsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 100,
  }) =>
      (select(evalRunsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.suiteId.equals(suiteId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Marks a run terminal within [workspaceId].
  Future<void> updateRunResult(
    String workspaceId,
    String id, {
    required String status,
    String? scorecardJson,
    double? passRate,
    int? costCents,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) =>
      (update(evalRunsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            EvalRunsTableCompanion(
              status: Value(status),
              scorecardJson: scorecardJson == null
                  ? const Value.absent()
                  : Value(scorecardJson),
              passRate: passRate == null
                  ? const Value.absent()
                  : Value(passRate),
              costCents: costCents == null
                  ? const Value.absent()
                  : Value(costCents),
              startedAt: startedAt == null
                  ? const Value.absent()
                  : Value(startedAt),
              finishedAt: finishedAt == null
                  ? const Value.absent()
                  : Value(finishedAt),
            ),
          );

  // ── Agent config versions ──

  /// Inserts or replaces a config version (deterministic id → PK upsert).
  Future<void> upsertConfigVersion(AgentConfigVersionsTableCompanion entry) =>
      into(agentConfigVersionsTable).insertOnConflictUpdate(entry);

  /// The live config version for [agentId] within [workspaceId], or null.
  Future<AgentConfigVersionsTableData?> liveConfigVersion(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentConfigVersionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.agentId.equals(agentId) &
                  t.status.equals('live'),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// A config version by (agent, hash) within [workspaceId], or null.
  Future<AgentConfigVersionsTableData?> configVersionByHash(
    String workspaceId,
    String agentId,
    String configHash,
  ) =>
      (select(agentConfigVersionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.agentId.equals(agentId) &
                t.configHash.equals(configHash),
          ))
          .getSingleOrNull();

  /// All config versions for [agentId] within [workspaceId], newest first.
  Future<List<AgentConfigVersionsTableData>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentConfigVersionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Sets a config version's status within [workspaceId] (promote/retire).
  Future<void> setConfigVersionStatus(
    String workspaceId,
    String id, {
    required String status,
    String? promotedBy,
    DateTime? promotedAt,
    String? scorecardJson,
  }) =>
      (update(agentConfigVersionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            AgentConfigVersionsTableCompanion(
              status: Value(status),
              promotedBy: promotedBy == null
                  ? const Value.absent()
                  : Value(promotedBy),
              promotedAt: promotedAt == null
                  ? const Value.absent()
                  : Value(promotedAt),
              scorecardJson: scorecardJson == null
                  ? const Value.absent()
                  : Value(scorecardJson),
            ),
          );

  // ── Paired skill evaluation campaigns ──

  void _requireWorkspace(String workspaceId) {
    if (workspaceId != attachedDatabase.workspaceId) {
      throw StateError('Skill evaluation workspace does not own this database');
    }
  }

  bool _sameJson(dynamic first, dynamic second) {
    if (first is Map<String, dynamic> && second is Map<String, dynamic>) {
      return first.length == second.length &&
          first.keys.every(
            (key) =>
                second.containsKey(key) && _sameJson(first[key], second[key]),
          );
    }
    if (first is List && second is List) {
      if (first.length != second.length) {
        return false;
      }
      for (var i = 0; i < first.length; i++) {
        if (!_sameJson(first[i], second[i])) {
          return false;
        }
      }
      return true;
    }
    return first == second;
  }

  bool _canMoveCampaign(
    SkillEvaluationCampaignStatus from,
    SkillEvaluationCampaignStatus to,
  ) {
    if (from == to) {
      return true;
    }
    return switch (from) {
      SkillEvaluationCampaignStatus.queued =>
        to == SkillEvaluationCampaignStatus.running ||
            to == SkillEvaluationCampaignStatus.cancelling ||
            to == SkillEvaluationCampaignStatus.cancelled ||
            to == SkillEvaluationCampaignStatus.failed ||
            to == SkillEvaluationCampaignStatus.interrupted,
      SkillEvaluationCampaignStatus.running =>
        to == SkillEvaluationCampaignStatus.cancelling ||
            to == SkillEvaluationCampaignStatus.cancelled ||
            to == SkillEvaluationCampaignStatus.completed ||
            to == SkillEvaluationCampaignStatus.failed ||
            to == SkillEvaluationCampaignStatus.interrupted,
      SkillEvaluationCampaignStatus.cancelling =>
        to == SkillEvaluationCampaignStatus.cancelled ||
            to == SkillEvaluationCampaignStatus.failed ||
            to == SkillEvaluationCampaignStatus.interrupted,
      SkillEvaluationCampaignStatus.cancelled ||
      SkillEvaluationCampaignStatus.completed ||
      SkillEvaluationCampaignStatus.failed ||
      SkillEvaluationCampaignStatus.interrupted => false,
    };
  }

  /// An existing id cannot change workspace or skill, even through an upsert.
  Future<void> upsertSkillCampaign(
    SkillEvalCampaignsTableCompanion entry,
  ) async {
    final workspaceId = entry.workspaceId.value;
    _requireWorkspace(workspaceId);
    await transaction(() async {
      final existing = await (select(
        skillEvalCampaignsTable,
      )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();
      if (existing == null) {
        await into(skillEvalCampaignsTable).insert(entry);
      } else {
        if (existing.workspaceId != workspaceId ||
            existing.skillKey != entry.skillKey.value) {
          throw StateError('Cannot reassign an existing skill campaign');
        }
        final previous =
            jsonDecode(existing.payloadJson) as Map<String, dynamic>;
        final replacement =
            jsonDecode(entry.payloadJson.value) as Map<String, dynamic>;
        for (final key in [
          'skillSlug',
          'skillHash',
          'corpusId',
          'providerId',
          'modelId',
          'configurationHash',
          'baselineHash',
          'repoId',
          'comparison',
          'repetitions',
          'budgetMicros',
          'plannedAttempts',
          'createdAt',
          'actor',
          'triggeredBy',
        ]) {
          if (previous[key] != replacement[key]) {
            throw StateError('Cannot change the identity of a skill campaign');
          }
        }
        final oldStatus = SkillEvaluationCampaignStatus.fromWire(
          existing.status,
        );
        final newStatus = SkillEvaluationCampaignStatus.fromWire(
          entry.status.value,
        );
        if (!_sameJson(
              previous['configuration'],
              replacement['configuration'],
            ) ||
            !_canMoveCampaign(oldStatus, newStatus) ||
            (previous['completedAttempts'] as int) >
                (replacement['completedAttempts'] as int)) {
          throw StateError('Invalid skill campaign lifecycle transition');
        }
        await (update(skillEvalCampaignsTable)..where(
              (t) =>
                  t.id.equals(entry.id.value) &
                  t.workspaceId.equals(workspaceId) &
                  t.skillKey.equals(entry.skillKey.value),
            ))
            .write(
              SkillEvalCampaignsTableCompanion(
                status: entry.status,
                payloadJson: entry.payloadJson,
              ),
            );
      }
    });
  }

  /// Reads one campaign by id within its owning workspace, if present.
  Future<SkillEvalCampaignsTableData?> skillCampaignById(
    String workspaceId,
    String id,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalCampaignsTable)
          ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Lists newest campaigns in this workspace, optionally for one skill key.
  Future<List<SkillEvalCampaignsTableData>> skillCampaigns(
    String workspaceId, {
    String? skillKey,
    int limit = 100,
  }) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalCampaignsTable)
          ..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                (skillKey == null
                    ? const Constant(true)
                    : t.skillKey.equals(skillKey)),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  /// Watches workspace campaigns in reverse creation order, optionally by skill.
  Stream<List<SkillEvalCampaignsTableData>> watchSkillCampaigns(
    String workspaceId, {
    String? skillKey,
  }) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalCampaignsTable)
          ..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                (skillKey == null
                    ? const Constant(true)
                    : t.skillKey.equals(skillKey)),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Watches one campaign within its owning workspace, including its absence.
  Stream<SkillEvalCampaignsTableData?> watchSkillCampaign(
    String workspaceId,
    String id,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalCampaignsTable)
          ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// An attempt must belong to an existing campaign in this same workspace.
  Future<void> upsertSkillAttempt(SkillEvalAttemptsTableCompanion entry) async {
    final workspaceId = entry.workspaceId.value;
    _requireWorkspace(workspaceId);
    await transaction(() async {
      final campaign =
          await (select(skillEvalCampaignsTable)..where(
                (t) =>
                    t.id.equals(entry.campaignId.value) &
                    t.workspaceId.equals(workspaceId),
              ))
              .getSingleOrNull();
      if (campaign == null) {
        throw StateError(
          'Skill evaluation campaign does not belong to workspace',
        );
      }
      final existing = await (select(
        skillEvalAttemptsTable,
      )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();
      if (existing == null) {
        await into(skillEvalAttemptsTable).insert(entry);
      } else {
        if (existing.workspaceId != workspaceId ||
            existing.campaignId != entry.campaignId.value ||
            existing.ordinal != entry.ordinal.value) {
          throw StateError('Cannot reassign an existing skill attempt');
        }
        final previous =
            jsonDecode(existing.payloadJson) as Map<String, dynamic>;
        final replacement =
            jsonDecode(entry.payloadJson.value) as Map<String, dynamic>;
        for (final key in ['taskId', 'armId', 'repetition', 'createdAt']) {
          if (previous[key] != replacement[key]) {
            throw StateError('Cannot change the identity of a skill attempt');
          }
        }
        await (update(skillEvalAttemptsTable)..where(
              (t) =>
                  t.id.equals(entry.id.value) &
                  t.workspaceId.equals(workspaceId) &
                  t.campaignId.equals(entry.campaignId.value),
            ))
            .write(
              SkillEvalAttemptsTableCompanion(payloadJson: entry.payloadJson),
            );
      }
    });
  }

  /// Lists campaign attempts in stable ordinal and id order.
  Future<List<SkillEvalAttemptsTableData>> skillAttempts(
    String workspaceId,
    String campaignId,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalAttemptsTable)
          ..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.campaignId.equals(campaignId),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.ordinal),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// Reads an attempt only when its campaign belongs to this workspace.
  Future<SkillEvalAttemptsTableData?> skillAttemptById(
    String workspaceId,
    String campaignId,
    String id,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalAttemptsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.campaignId.equals(campaignId) &
              t.id.equals(id),
        ))
        .getSingleOrNull();
  }

  /// Upserts a workspace-owned skill opt-in policy.
  Future<void> upsertSkillPolicy(SkillEvalPoliciesTableCompanion entry) {
    _requireWorkspace(entry.workspaceId.value);
    return into(skillEvalPoliciesTable).insertOnConflictUpdate(entry);
  }

  /// Reads the policy for a skill in its owning workspace, if present.
  Future<SkillEvalPoliciesTableData?> skillPolicy(
    String workspaceId,
    String skillKey,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalPoliciesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) & t.skillKey.equals(skillKey),
        ))
        .getSingleOrNull();
  }

  /// Lists opted-in skill policies in ascending skill-key order.
  Future<List<SkillEvalPoliciesTableData>> enabledSkillPolicies(
    String workspaceId,
  ) {
    _requireWorkspace(workspaceId);
    return (select(skillEvalPoliciesTable)
          ..where(
            (t) => t.workspaceId.equals(workspaceId) & t.enabled.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.skillKey)]))
        .get();
  }
}
