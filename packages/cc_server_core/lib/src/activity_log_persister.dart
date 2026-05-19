import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Persists [ActivityLogged] events into the `activity_log` table — the single
/// write path for the audit trail.
///
/// Two things about the shape here are deliberate.
///
/// **It holds the manager, not a DAO.** The first version took an
/// `ActivityLogDao` in its constructor. A workspace-scoped DAO can only have
/// been resolved from SOME workspace, so every audit row for every workspace
/// would have landed in that one file — with a `workspace_id` column claiming
/// otherwise, which is worse than losing the row, because
/// `DaoActivityLogReader` reads the workspace's own file and would never show
/// it. The event names its workspace; that name picks the database.
///
/// **An event with no workspace is DROPPED, loudly.** `ActivityLogged`
/// carries a nullable `workspaceId` (server-wide actions have no workspace),
/// and there is no such thing as a default database to fall back on. Writing
/// it somewhere would be a silent cross-workspace write; dropping it with a
/// warning is honest and leaves the audit trail's gaps visible.
class ActivityLogPersister {
  /// Creates an [ActivityLogPersister] over the per-workspace databases [dbs].
  ActivityLogPersister({
    required DomainEventBus eventBus,
    required WorkspaceDatabaseManager dbs,
    WorkspaceExistsChecker? workspaceExists,
  }) : _eventBus = eventBus,
       _dbs = dbs,
       _workspaceExists = workspaceExists;

  final DomainEventBus _eventBus;
  final WorkspaceDatabaseManager _dbs;

  /// Guards against materialising a database file for a workspace that no
  /// longer exists: `of()` opens (and therefore CREATES) the named file, and a
  /// late event from a just-deleted workspace would resurrect it as a ghost.
  final WorkspaceExistsChecker? _workspaceExists;

  StreamSubscription<ActivityLogged>? _sub;

  /// Starts persisting audit events.
  void start() {
    _sub ??= _eventBus.on<ActivityLogged>().listen(_persist);
  }

  /// Stops listening.
  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  Future<void> _persist(ActivityLogged e) async {
    final workspaceId = e.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      CcInfraLog.warning(
        'audit row dropped: ${e.actorType} "${e.action}" on '
        '${e.entityType} names no workspace, and there is no default '
        'database to write it to',
      );
      return;
    }
    final exists = _workspaceExists;
    if (exists != null && !await exists(workspaceId)) {
      CcInfraLog.warning(
        'audit row dropped: workspace $workspaceId is not registered',
      );
      return;
    }
    try {
      await _dbs
          .of(workspaceId)
          .activityLogDao
          .insertEntry(
            ActivityLogTableCompanion(
              id: Value(e.id),
              workspaceId: Value(workspaceId),
              actorType: Value(e.actorType),
              actorId: Value(e.actorId),
              action: Value(e.action),
              entityType: Value(e.entityType),
              entityId: Value(e.entityId),
              details: Value(e.details),
              runId: Value(e.runId),
              createdAt: Value(e.occurredAt),
            ),
          );
    } on Object catch (err, st) {
      // Audit is best-effort observability; never let it break a flow.
      CcInfraLog.warning('failed to persist audit row: $err\n$st');
    }
  }
}
