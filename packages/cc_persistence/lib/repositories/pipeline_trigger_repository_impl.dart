import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/pipeline_trigger_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/pipeline_trigger_mappers.dart';

/// Drift-backed implementation of [PipelineTriggerRepository].
///
/// Triggers are workspace-scoped rows in the workspace's own database file. Two
/// surfaces cross that boundary by nature and are the only ones that do: the
/// event dispatcher, which must consider every workspace's triggers for an
/// incoming event, and the inbound webhook URL, which carries a token and no
/// workspace — the latter resolves through the global routing table, kept in
/// step by [_syncWebhookRoute] on write and dropped in [deleteById].
class PipelineTriggerRepositoryImpl implements PipelineTriggerRepository {
  /// Creates a [PipelineTriggerRepositoryImpl] over the per-workspace databases
  /// [_dbs], using [_routes] to resolve inbound webhook tokens to a workspace.
  PipelineTriggerRepositoryImpl(this._dbs, this._routes)
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final WorkspaceRouteDao _routes;
  final CrossWorkspaceQueries _cross;

  PipelineTriggerDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).pipelineTriggerDao;

  /// Points the global routing table at [trigger]'s workspace when it carries a
  /// webhook token, so an inbound `/webhooks/<token>` POST can find it.
  ///
  /// Written after the row so the route never resolves to a trigger that does
  /// not exist yet. A trigger with no token has nothing to route.
  Future<void> _syncWebhookRoute(PipelineTrigger trigger) async {
    final token = trigger.webhookToken;
    if (token == null || token.isEmpty) {
      return;
    }
    await _routes.put(
      WorkspaceRouteKind.webhookToken,
      token,
      trigger.workspaceId,
    );
  }

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    await _dao(trigger.workspaceId).insert(triggerToCompanion(trigger));
    await _syncWebhookRoute(trigger);
  }

  @override
  Future<void> update(PipelineTrigger trigger) async {
    await _dao(trigger.workspaceId).updateTrigger(triggerToCompanion(trigger));
    // A token can be minted (or rotated) on an existing trigger, so the route
    // is refreshed on every update.
    await _syncWebhookRoute(trigger);
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    final dao = _dao(workspaceId);
    // Read the row first: its token is the only way to name the route that must
    // die with it. A route outliving its trigger would send the next inbound
    // webhook to a workspace that no longer has it.
    final row = await dao.getById(id);
    await dao.deleteById(id);
    final token = row?.webhookToken;
    if (token != null && token.isNotEmpty) {
      await _routes.remove(WorkspaceRouteKind.webhookToken, token);
    }
  }

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).forWorkspace(workspaceId);
    return rows.map(triggerFromRow).toList();
  }

  /// CROSS-WORKSPACE BY DESIGN: the trigger dispatcher. A domain event is
  /// published once and every workspace's triggers have to be offered it, so
  /// the dispatcher fans out and then re-filters per event and per workspace.
  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) =>
      _enabledForEventAcrossWorkspaces(eventType);

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId)
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(triggerFromRow).toList());
  }

  @override
  Future<PipelineTrigger?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row != null ? triggerFromRow(row) : null;
  }

  /// CROSS-WORKSPACE BY DESIGN: the cron scheduler is a single install-wide
  /// ticker, so it needs every workspace's due schedules on each tick.
  @override
  Future<List<PipelineTrigger>> scheduled() =>
      _enabledForEventAcrossWorkspaces(PipelineTrigger.scheduleEventType);

  Future<List<PipelineTrigger>> _enabledForEventAcrossWorkspaces(
    String eventType,
  ) async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.pipelineTriggerDao.enabledForEvent(eventType),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) triggerFromRow(row),
    ];
  }

  @override
  Future<void> markFired(String workspaceId, String id, DateTime when) =>
      _dao(workspaceId).markFired(id, when);

  @override
  Future<void> setSchedule(
    String workspaceId,
    String id, {
    DateTime? nextRunAt,
    DateTime? lastFiredAt,
  }) => _dao(
    workspaceId,
  ).setSchedule(id, nextRunAt: nextRunAt, lastFiredAt: lastFiredAt);

  @override
  Future<PipelineTrigger?> byWebhookToken(String token) async {
    final workspaceId = await _routes.resolve(
      WorkspaceRouteKind.webhookToken,
      token,
    );
    if (workspaceId == null) {
      return null;
    }
    final row = await _dao(workspaceId).byWebhookToken(token);
    return row != null ? triggerFromRow(row) : null;
  }
}
