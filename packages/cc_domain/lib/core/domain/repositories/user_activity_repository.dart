import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';

/// Persistence port for the append-only per-user audit trail.
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
}
