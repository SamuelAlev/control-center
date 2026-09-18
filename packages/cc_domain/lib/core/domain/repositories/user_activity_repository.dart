import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/value_objects/user_activity_page.dart';

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

  /// One newest-first page of [workspaceId]'s trail, with the real total
  /// and cursors for the adjacent pages.
  Future<UserActivityPage> getPage(
    String workspaceId, {
    int limit = defaultUserActivityPageSize,
    String? cursor,
    UserActivityFilter filter = const UserActivityFilter(),
  });

  /// Live counterpart of [getPage]. Re-emits when a new row is appended.
  Stream<UserActivityPage> watchPage(
    String workspaceId, {
    int limit = defaultUserActivityPageSize,
    String? cursor,
    UserActivityFilter filter = const UserActivityFilter(),
  });
}
