import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';
import 'package:drift/drift.dart';

/// Persists [ActivityLogged] events into the `activity_log` table — the single
/// write path for the audit trail. The table + logger existed but nothing ever
/// wrote rows; this closes that gap.
class ActivityLogPersister {
  /// Creates an [ActivityLogPersister].
  ActivityLogPersister({
    required DomainEventBus eventBus,
    required ActivityLogDao dao,
  })  : _eventBus = eventBus,
        _dao = dao;

  final DomainEventBus _eventBus;
  final ActivityLogDao _dao;

  StreamSubscription<ActivityLogged>? _sub;

  /// Starts persisting audit events.
  void start() {
    _sub = _eventBus.on<ActivityLogged>().listen(_persist);
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _persist(ActivityLogged e) async {
    try {
      await _dao.insertEntry(ActivityLogTableCompanion(
        id: Value(e.id),
        workspaceId: Value(e.workspaceId),
        actorType: Value(e.actorType),
        actorId: Value(e.actorId),
        action: Value(e.action),
        entityType: Value(e.entityType),
        entityId: Value(e.entityId),
        details: Value(e.details),
        runId: Value(e.runId),
        createdAt: Value(e.occurredAt),
      ));
    } on Object catch (err, st) {
      // Audit is best-effort observability; never let it break a flow.
      CcInfraLog.warning('failed to persist audit row: $err\n$st');
    }
  }
}
