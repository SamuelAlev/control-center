/// Prevents agent→agent infinite loops.
///
/// Guards:
/// 1. Self-trigger suppression: don't re-trigger same agent on its own reply
/// 2. Agent→agent reply guard: detect if trigger author is another agent
/// 3. Dedup: check for pending tasks for same (ticket, agent) pair
/// 4. Mention inheritance guard: skip if thread already has agent participation
class AgentLoopGuard {
  /// Returns true if the dispatch should be suppressed to prevent a loop.
  bool shouldSuppress({
    required String triggerAuthorId,
    required String targetAgentId,
    required bool isAgentAuthor,
    Set<String>? recentAgentParticipants,
  }) {
    if (triggerAuthorId == targetAgentId) {
      return true;
    }

    if (isAgentAuthor && recentAgentParticipants != null) {
      if (recentAgentParticipants.contains(targetAgentId)) {
        return true;
      }
    }

    return false;
  }
}
