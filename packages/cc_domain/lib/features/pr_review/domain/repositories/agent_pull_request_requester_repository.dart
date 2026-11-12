/// Whether a requester record names a pull request by number or, before the
/// forge answered, by its head branch.
enum AgentPullRequestRecordState {
  /// A pull request an agent opened; key `<forge>|<host>|id:<repo id>#<n>`.
  opened('opened'),

  /// A pull request an agent is opening; key
  /// `<forge>|<host>|<owner>/<name>@<head branch>`.
  pending('pending');

  const AgentPullRequestRecordState(this.wire);

  /// The value stored in `agent_pull_request_requesters.state`.
  final String wire;
}

/// Who asked an agent for each pull request it opened, so they cannot approve
/// it.
///
/// Durable state, kept for as long as the pull request can be approved; never
/// a cache row. Server-wide rather than per workspace: a pull request belongs
/// to the forge, so the same forge repository linked in two workspaces is one
/// pull request with one record, which outlives the workspace it was written
/// through.
abstract interface class AgentPullRequestRequesterRepository {
  /// Adds [userIds] to the record [key] in [state], keeping whoever it
  /// already names.
  Future<void> add(
    AgentPullRequestRecordState state,
    String key,
    Set<String> userIds,
  );

  /// Everyone the opened record [openedKey] or the pending record
  /// [pendingKey] names (either may be null or empty: not asked).
  Future<Set<String>> requesters({String? openedKey, String? pendingKey});

  /// The pending records whose key starts with [keyPrefix], with who each
  /// names and when it was last added to.
  Future<List<({String key, Set<String> userIds, DateTime recordedAt})>>
  pendingWithPrefix(String keyPrefix);

  /// Removes the record [key] in [state]. A no-op when absent.
  Future<void> remove(AgentPullRequestRecordState state, String key);

  /// Moves who the pending record [pendingKey] names to the opened record
  /// [openedKey], in one transaction. A no-op when it names nobody.
  Future<void> promote(String pendingKey, String openedKey);
}
