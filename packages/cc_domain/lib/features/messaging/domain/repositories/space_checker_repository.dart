/// Which agent reviews every other agent's finished main run in a space (the
/// space's checker).
///
/// A setting someone chose, so it stays until they change it: never a cache
/// row.
abstract interface class SpaceCheckerRepository {
  /// The checker agent of [spaceId], or null when the space names none.
  Future<String?> checkerOf(String workspaceId, String spaceId);

  /// Names [agentId] the checker of [spaceId], replacing any other.
  Future<void> setChecker(String workspaceId, String spaceId, String agentId);

  /// Removes the checker of [spaceId]. A no-op when it names none.
  Future<void> clearChecker(String workspaceId, String spaceId);
}
