/// `caches` kinds that record who asked an agent for each pull request it
/// opened, so that person cannot approve it.
///
/// Durable state, not a staleness buffer: retention never prunes these rows
/// (a pull request can stay open longer than any cache window), and the
/// `cache.*` RPC ops cannot reach them. Keys are forge identities, never a
/// workspace's repo id, because the same forge repository linked in another
/// workspace is the same pull request. The payload is the comma-separated
/// user ids who may not approve it.
abstract final class AgentPullRequestCacheKinds {
  /// A pull request an agent opened; key `<forge>|<host>|id:<repo id>#<n>`,
  /// by the forge's durable repository id (GitHub repository id, GitLab
  /// project id, Bitbucket repository uuid), so a rename or a transfer of
  /// the repository does not lose it.
  static const String opened = 'agent_pr_requester_v1';

  /// A pull request an agent is opening, written before the forge is asked;
  /// key `<forge>|<host>|<owner>/<name>@<head branch>` (no pull request, so
  /// no repository id, exists yet). It stays when the opened row could not
  /// be written, so the guard still matches the pull request by its head
  /// branch until the poller or an approval check promotes it.
  static const String pending = 'agent_pr_requester_pending_v1';

  /// Every kind, for retention to spare.
  static const Set<String> all = {opened, pending};
}
