import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/ports/activity_log_reader.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';

/// An [ActivityLogReader] backed by the Drift `activity_log` DAO — the
/// server-side read path for the audit trail. Maps each `activity_log` row to
/// the [ActivityEntry] domain view; the DAO query already filters by
/// `workspaceId`, so a foreign-workspace row never streams through.
class DaoActivityLogReader implements ActivityLogReader {
  /// Creates a [DaoActivityLogReader] over [_dao].
  DaoActivityLogReader(this._dao);

  final ActivityLogDao _dao;

  @override
  Stream<List<ActivityEntry>> watchForEntity(
    String workspaceId,
    String entityType,
    String entityId,
  ) =>
      _dao.watchForEntity(workspaceId, entityType, entityId).map(
            (rows) => [
              for (final r in rows)
                ActivityEntry(
                  id: r.id,
                  actorType: r.actorType,
                  action: r.action,
                  entityType: r.entityType,
                  createdAt: r.createdAt,
                  actorId: r.actorId,
                  entityId: r.entityId,
                  details: r.details,
                  workspaceId: r.workspaceId,
                  runId: r.runId,
                ),
            ],
          );
}
