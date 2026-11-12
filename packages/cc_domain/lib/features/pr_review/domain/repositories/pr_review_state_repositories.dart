/// Reviewer identities a forge once flagged as code owners of a pull request.
///
/// A forge drops the flag once the review request is satisfied, so this set is
/// the only memory that the reviewer was a code owner: state, never a cache
/// row. It only grows.
abstract interface class PrCodeOwnerRepository {
  /// Adds [identities] to the set of pull request [prNumber] of [repoKey] and
  /// returns the whole set.
  Future<Set<String>> addAndList(
    String workspaceId, {
    required String repoKey,
    required int prNumber,
    required Set<String> identities,
  });
}

/// The reply an agent run owes a pull-request conversation, written when the
/// run is dispatched and consumed when it completes.
///
/// Losing it means the question on the forge is never answered: state, never
/// a cache row. It goes when its run is deleted.
abstract interface class PendingPrReplyRepository {
  /// Records [reply] (its JSON object form) for the run [runLogId].
  Future<void> save(
    String workspaceId,
    String runLogId,
    Map<String, dynamic> reply,
  );

  /// Removes and returns the reply owed by [runLogId], or null. Of two
  /// concurrent calls only one receives it.
  Future<Map<String, dynamic>?> take(String workspaceId, String runLogId);
}
