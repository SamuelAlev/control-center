import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';

/// Persistence port for the server-scope audit trail.
///
/// The read side is keyset paging over `(createdAt, id)`, the same order as
/// the workspace trail, so the audit log can merge both into one table.
abstract interface class ServerAuditRepository {
  /// Appends one record. The store keeps a bounded number of the newest rows.
  Future<void> append(ServerAuditEntry entry);

  /// Matching records strictly older than [olderThan] (from the newest when
  /// null), newest first, at most [limit].
  Future<List<ServerAuditEntry>> pageRows({
    ActivityCursor? olderThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// Matching records strictly newer than [newerThan], oldest first, at most
  /// [limit].
  Future<List<ServerAuditEntry>> newerRows({
    required ActivityCursor newerThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// How many records match, or only those strictly newer than [newerThan].
  Future<int> count({
    AuditLogFilter filter = const AuditLogFilter(),
    ActivityCursor? newerThan,
  });

  /// Matching records per actor id.
  Future<Map<String, int>> countByActor({
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// Matching records per outcome.
  Future<Map<AuditOutcome, int>> countByOutcome({
    AuditLogFilter filter = const AuditLogFilter(),
  });

  /// Emits whenever a record is appended or pruned.
  Stream<void> watchChanges();
}
