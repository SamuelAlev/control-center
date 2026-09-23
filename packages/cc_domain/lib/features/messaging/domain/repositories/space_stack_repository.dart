import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';

/// Persistence for [SpaceStackEntry] rows. Every method takes a required
/// [workspaceId]: that is what selects the workspace database.
abstract class SpaceStackRepository {
  /// Every layer in [spaceId], ordered by repo then position.
  Future<List<SpaceStackEntry>> forSpace(String workspaceId, String spaceId);

  /// The layers of one repo, bottom to top.
  Future<List<SpaceStackEntry>> forRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  );

  /// Inserts or replaces [entry] (primary key).
  Future<void> upsert(SpaceStackEntry entry);

  /// Deletes every layer of one repo's stack.
  Future<void> deleteForRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  );

  /// Deletes the row [id] inside [workspaceId].
  Future<void> deleteById(String workspaceId, String id);
}
