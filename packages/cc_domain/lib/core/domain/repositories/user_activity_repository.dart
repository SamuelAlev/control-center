import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';

/// Persistence port for the append-only per-user audit trail.
///
/// The read side is keyset paging over `(createdAt, id)`, the same order as
/// the server trail, so the audit log can merge both into one table. Every
/// record here returned successfully: an outcome filter that leaves out
/// `ok` matches nothing.
abstract class UserActivityRepository {
  /// Appends one audit record.
  Future<void> append(UserActivityEntry entry);

  /// Latest activity in [workspaceId], newest first, capped at [limit].
  Future<List<UserActivityEntry>> getForWorkspace(
    String workspaceId, {
    int limit = 200,
  });

  /// Live stream of [workspaceId]'s latest activity, newest first.
  Stream<List<UserActivityEntry>> watchForWorkspace(
    String workspaceId, {
    int limit = 200,
  });

  /// Matching records of [workspaceId] strictly older than [olderThan] (from
  /// the newest when null), newest first, at most [limit].
  Future<List<UserActivityEntry>> pageRows(
    String workspaceId, {
    ActivityCursor? olderThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// Matching records of [workspaceId] strictly newer than [newerThan],
  /// oldest first, at most [limit].
  Future<List<UserActivityEntry>> newerRows(
    String workspaceId, {
    required ActivityCursor newerThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// How many of [workspaceId]'s records match, or only those strictly newer
  /// than [newerThan].
  Future<int> count(
    String workspaceId, {
    AuditLogFilter filter = const AuditLogFilter(),
    ActivityCursor? newerThan,
  });

  /// [workspaceId]'s matching records per actor id.
  Future<Map<String, int>> countByActor(
    String workspaceId, {
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// Emits whenever [workspaceId]'s trail gains or loses a record.
  Stream<void> watchChanges(String workspaceId);
}
