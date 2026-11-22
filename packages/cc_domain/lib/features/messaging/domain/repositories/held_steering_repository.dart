/// A person's control over the steering cards the server held when they
/// stopped a run (`steering.release`). The cards themselves are conversation
/// rows the feed already carries (`Message.isSteeringHeld`); this is only the
/// release. Deleting a held card is the ordinary steering delete.
abstract interface class HeldSteeringRepository {
  /// Puts the cards the person's Stop held back in the queue: with no live
  /// run the server sends them at once, with a live run they go into its
  /// lane. Cards held by a usage-limit pause are not touched: they go out
  /// when that pause resumes. Returns how many were released. Refused when
  /// the caller may not act in the space.
  Future<int> release({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
  });
}
