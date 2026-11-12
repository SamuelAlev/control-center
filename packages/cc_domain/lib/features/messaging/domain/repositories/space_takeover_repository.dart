import 'package:cc_domain/features/messaging/domain/entities/space_takeover.dart';

/// Durable take-over markers, one per space, in the space's workspace.
///
/// The marker is the dispatch gate of a space, so it lives until it is handed
/// back, however long that takes: it is state, never a cache row.
abstract interface class SpaceTakeoverRepository {
  /// The take-over standing on [spaceId], or null.
  Future<SpaceTakeover?> get(String workspaceId, String spaceId);

  /// The take-over on [spaceId] as it changes (null when none stands).
  Stream<SpaceTakeover?> watch(String workspaceId, String spaceId);

  /// Records [takeover] unless one already stands on its space, in one
  /// conditional write. Returns whether this call recorded it: of two
  /// concurrent claims exactly one wins.
  Future<bool> claim(String workspaceId, SpaceTakeover takeover);

  /// Records which runs the take-over on [spaceId] paused and stopped. A
  /// no-op when none stands.
  Future<void> recordHeldRuns(
    String workspaceId,
    String spaceId, {
    required List<String> paused,
    required List<String> stopped,
  });

  /// Removes the take-over on [spaceId]. A no-op when none stands.
  Future<void> release(String workspaceId, String spaceId);
}
