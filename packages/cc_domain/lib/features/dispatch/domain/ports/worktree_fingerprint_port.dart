/// A cheap fingerprint of a conversation's worktree: equal while nothing in
/// it changed (no edit, no commit, no new file), different after any of
/// them. A goal's verification compares it with the one recorded at the last
/// failed check, so an unchanged workspace is not checked again, and its
/// no-progress count reads it after each segment.
abstract interface class WorktreeFingerprintPort {
  /// The fingerprint of [conversationId]'s worktree in [workspaceId]; null
  /// when the conversation has no worktree or it cannot be fingerprinted.
  Future<String?> fingerprint({
    required String workspaceId,
    required String conversationId,
  });
}
