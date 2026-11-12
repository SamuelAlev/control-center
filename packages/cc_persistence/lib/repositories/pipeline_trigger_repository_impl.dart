import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/pipeline_trigger_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    show PipelineTriggersTableData;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/pipeline_trigger_mappers.dart';

/// Drift-backed implementation of [PipelineTriggerRepository].
///
/// Triggers are workspace-scoped rows in the workspace's own database file. Two
/// surfaces cross that boundary by nature and are the only ones that do — both
/// server-side, never reachable over RPC: the event dispatcher (and the cron
/// scheduler), which must consider every workspace's triggers for an
/// incoming event and the inbound webhook URL, which carries a token and no
/// workspace — the latter resolves through the global routing table, kept in
/// step on every write and dropped in [deleteById].
///
/// A webhook token never reaches either database. It is kept in the server's
/// secrets store through [WebhookSecretVault]; the trigger row stores only its
/// reference and the routing table only [WebhookSecretVault.webhookRouteKey]
/// of it. Every read resolves the token back through the reference, so a
/// trigger whose secret is gone reads as having no token (and is given a new
/// one by its next save).
class PipelineTriggerRepositoryImpl implements PipelineTriggerRepository {
  /// Creates a [PipelineTriggerRepositoryImpl] over the per-workspace databases
  /// [_dbs], using [_routes] to resolve inbound webhook tokens to a workspace
  /// and [_secrets] to keep the tokens themselves.
  PipelineTriggerRepositoryImpl(this._dbs, this._routes, this._secrets)
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final WorkspaceRouteDao _routes;
  final WebhookSecretVault _secrets;
  final CrossWorkspaceQueries _cross;

  PipelineTriggerDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).pipelineTriggerDao;

  /// The route key and secrets reference of [trigger]'s token, or null when it
  /// carries none.
  Future<({String routeKey, String ref, String token})?> _tokenSlot(
    PipelineTrigger trigger,
  ) async {
    final token = trigger.webhookToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    final routeKey = await _secrets.webhookRouteKey(token);
    return (
      routeKey: routeKey,
      ref: WebhookSecretVault.pipelineTriggerRef(trigger.workspaceId, routeKey),
      token: token,
    );
  }

  /// Refuses a token that already belongs to another trigger.
  ///
  /// A token routed to ANOTHER workspace is refused, never re-pointed: the
  /// token is also that workspace's HMAC secret, so overwriting the route
  /// would hijack its inbound webhooks. One bound to another trigger of this
  /// workspace is refused too: the two would share one stored secret, and
  /// deleting either would take it from both. Tokens are minted server-side,
  /// so this only fires on a collision or a forged write — defence in depth.
  Future<void> _assertTokenFree(
    PipelineTrigger trigger,
    ({String routeKey, String ref, String token})? slot,
  ) async {
    if (slot == null) {
      return;
    }
    final owner = await _routes.resolve(
      WorkspaceRouteKind.webhookToken,
      slot.routeKey,
    );
    if (owner != null && owner != trigger.workspaceId) {
      throw const WorkspaceMismatchException(
        'Webhook token is already routed to a different workspace',
      );
    }
    final holder = await _dao(
      trigger.workspaceId,
    ).anyByWebhookTokenRef(slot.ref);
    if (holder != null && holder.id != trigger.id) {
      throw StateError('Webhook token is already bound to another trigger');
    }
  }

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    final slot = await _tokenSlot(trigger);
    // Checked before anything lands so a refused token leaves nothing behind.
    await _assertTokenFree(trigger, slot);
    await _write(
      trigger,
      slot,
      () => _dao(
        trigger.workspaceId,
      ).insert(triggerToCompanion(trigger, webhookTokenRef: slot?.ref)),
    );
  }

  @override
  Future<void> update(PipelineTrigger trigger) async {
    final slot = await _tokenSlot(trigger);
    await _assertTokenFree(trigger, slot);
    final dao = _dao(trigger.workspaceId);
    final previousRef = (await dao.getById(trigger.id))?.webhookTokenRef;
    await _write(
      trigger,
      slot,
      () => dao.updateTrigger(
        triggerToCompanion(trigger, webhookTokenRef: slot?.ref),
      ),
    );
    // A token can be minted, rotated or dropped on an existing trigger: the
    // old one's secret and route go with it.
    if (previousRef != null && previousRef != slot?.ref) {
      await _forget(previousRef);
    }
  }

  /// Stores [slot]'s secret, then the row ([writeRow]), then the route.
  ///
  /// The secret goes first so a row never names a reference with nothing
  /// behind it, and the route last so it never resolves to a row that does not
  /// exist yet. A failed row write takes the freshly stored secret back out.
  Future<void> _write(
    PipelineTrigger trigger,
    ({String routeKey, String ref, String token})? slot,
    Future<void> Function() writeRow,
  ) async {
    if (slot == null) {
      await writeRow();
      return;
    }
    final hadSecret = await _secrets.read(slot.ref) != null;
    await _secrets.write(slot.ref, slot.token);
    try {
      await writeRow();
    } on Object {
      if (!hadSecret) {
        await _secrets.delete(slot.ref);
      }
      rethrow;
    }
    await _routes.put(
      WorkspaceRouteKind.webhookToken,
      slot.routeKey,
      trigger.workspaceId,
    );
  }

  /// Drops the secret stored under [ref] and the route its key names.
  Future<void> _forget(String ref) async {
    await _routes.remove(
      WorkspaceRouteKind.webhookToken,
      WebhookSecretVault.routeKeyOfTriggerRef(ref),
    );
    await _secrets.delete(ref);
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    final dao = _dao(workspaceId);
    // Read the row first: its reference is the only way to name the secret and
    // the route that must die with it. A route outliving its trigger would
    // send the next inbound webhook to a workspace that no longer has it.
    final row = await dao.getById(id);
    await dao.deleteById(id);
    final ref = row?.webhookTokenRef;
    if (ref != null) {
      await _forget(ref);
    }
  }

  /// [row] as a trigger, its token resolved through the secrets store.
  Future<PipelineTrigger> _fromRow(PipelineTriggersTableData row) async {
    final ref = row.webhookTokenRef;
    return triggerFromRow(
      row,
      webhookToken: ref == null ? null : await _secrets.read(ref),
    );
  }

  Future<List<PipelineTrigger>> _fromRows(
    List<PipelineTriggersTableData> rows,
  ) => Future.wait(rows.map(_fromRow));

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async {
    return _fromRows(await _dao(workspaceId).forWorkspace(workspaceId));
  }

  /// CROSS-WORKSPACE BY DESIGN: the trigger dispatcher. A domain event is
  /// published once and every workspace's triggers have to be offered it, so
  /// the dispatcher fans out and then re-filters per event and per workspace.
  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) =>
      _enabledForEventAcrossWorkspaces(eventType);

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId).watchForWorkspace(workspaceId).asyncMap(_fromRows);
  }

  @override
  Future<PipelineTrigger?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row != null ? _fromRow(row) : null;
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
      backgroundWriter: 'pipeline trigger dispatch',
    );
    return _fromRows([for (final rows in perWorkspace) ...rows]);
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
    final routeKey = await _secrets.webhookRouteKey(token);
    final workspaceId = await _routes.resolve(
      WorkspaceRouteKind.webhookToken,
      routeKey,
    );
    if (workspaceId == null) {
      return null;
    }
    final row = await _dao(workspaceId).byWebhookTokenRef(
      WebhookSecretVault.pipelineTriggerRef(workspaceId, routeKey),
    );
    if (row == null) {
      return null;
    }
    final trigger = await _fromRow(row);
    // A row whose secret is gone has nothing to verify a signature with.
    return trigger.webhookToken == null ? null : trigger;
  }
}
