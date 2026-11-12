import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_persistence/database/daos/action_policy_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/action_policy_mapper.dart';

/// Drift-backed [ActionPolicyRepository] (PRD 24).
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).actionPolicyDao` per call: policy rules live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs. Rows↔entities are mapped with [ActionPolicyMapper].
class DaoActionPolicyRepository implements ActionPolicyRepository {
  /// Creates a [DaoActionPolicyRepository] over the per-workspace databases.
  DaoActionPolicyRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final ActionPolicyMapper _mapper = const ActionPolicyMapper();

  ActionPolicyDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).actionPolicyDao;

  @override
  Future<void> upsertRule(ActionPolicyRule rule) =>
      // The rule carries its own workspace, so the file is picked from the
      // entity rather than from a second parameter that could disagree with
      // it. Rule identity is the table's unique key, so the DAO writes one
      // upsert on it (see [ActionPolicyDao.upsertRule]).
      _dao(rule.workspaceId).upsertRule(_mapper.ruleToCompanion(rule));

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => (await _dao(
    workspaceId,
  ).rules(workspaceId)).map(_mapper.ruleFromRow).toList();

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      _dao(workspaceId)
          .watchRules(workspaceId)
          .map((rows) => rows.map(_mapper.ruleFromRow).toList());

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => (await _dao(workspaceId).rulesForScope(
    workspaceId,
    scopeType.wire,
    scopeId,
  )).map(_mapper.ruleFromRow).toList();

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).ruleById(workspaceId, id);
    return row == null ? null : _mapper.ruleFromRow(row);
  }

  @override
  Future<void> deleteRule(String workspaceId, String id) =>
      _dao(workspaceId).deleteRule(workspaceId, id);
}
