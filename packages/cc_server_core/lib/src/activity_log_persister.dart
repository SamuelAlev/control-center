import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Persists [ActivityLogged] into `activity_log` — the audit trail for Settings → Activity.
///
/// Listens on the domain bus; writes only rows with a workspace id (unscoped events stay toast-only).
/// Failures are logged, never rethrown (audit must not take down the publisher).
class ActivityLogPersister {
  /// Creates an [ActivityLogPersister] over the per-workspace databases [_dbs].
  ActivityLogPersister({
    required this._eventBus,
    required this._dbs,
    this._workspaceExists,
  });

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
