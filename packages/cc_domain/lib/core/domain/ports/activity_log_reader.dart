import 'package:cc_domain/core/domain/entities/activity_entry.dart';

/// A read-only port over the workspace-scoped audit trail (the `activity_log`
/// table), so the RPC catalog can stream an entity's history without importing
/// the persistence layer's DAO.
///
/// The write path (persisting `ActivityLogged` events) is host-side and is NOT
/// part of this port — the thin client only reads.
abstract class ActivityLogReader {
  /// Watches audit rows for a specific entity within [workspaceId] (newest
  /// first). The query MUST filter by `workspaceId` so a foreign-workspace row
  /// never streams through (the isolation boundary).
  Stream<List<ActivityEntry>> watchForEntity(
    String workspaceId,
    String entityType,
    String entityId,
  );
}
