part of 'agent_run_gateway.dart';

/// A branch an agent run pushed through the gateway, and the commit it set
/// it to (one record per push).
final class AgentRunPushedBranch {
  /// Creates an [AgentRunPushedBranch]. [owner] and [name] compare without
  /// case, as GitHub does; [branch] exactly.
  AgentRunPushedBranch({
    required String owner,
    required String name,
    required this.branch,
    String sha = '',
  }) : owner = owner.toLowerCase(),
       name = name.toLowerCase(),
       sha = sha.toLowerCase();

  /// The branches of a push's ref [updates] (full ref name → new object id)
  /// to [owner]/[name]; tags and deletions are not branches pushed.
  static Iterable<AgentRunPushedBranch> ofUpdates(
    String owner,
    String name,
    Map<String, String> updates,
  ) sync* {
    for (final MapEntry(key: ref, value: sha) in updates.entries) {
      if (ref.startsWith('refs/heads/') && sha.replaceAll('0', '').isNotEmpty) {
        yield AgentRunPushedBranch(
          owner: owner,
          name: name,
          branch: ref.substring('refs/heads/'.length),
          sha: sha,
        );
      }
    }
  }

  /// Repository owner, lower-cased.
  final String owner;

  /// Repository name, lower-cased.
  final String name;

  /// Branch name (no `refs/heads/`).
  final String branch;

  /// The full commit id the push set [branch] to, lower-cased ('' unknown).
  final String sha;

  /// Whether this is [branch] on [owner]/[name].
  bool matches(String owner, String name, String branch) =>
      this.owner == owner.toLowerCase() &&
      this.name == name.toLowerCase() &&
      this.branch == branch;

  @override
  bool operator ==(Object other) =>
      other is AgentRunPushedBranch &&
      other.owner == owner &&
      other.name == name &&
      other.branch == branch &&
      other.sha == sha;

  @override
  int get hashCode => Object.hash(owner, name, branch, sha);
}

/// An open agent run as server-side tools see it: who it acts for and what
/// it pushed.
final class AgentRunView {
  /// Creates an [AgentRunView].
  const AgentRunView({required this.grant, required this.pushedBranches});

  /// The run's registered identity.
  final AgentRunGrant grant;

  /// Branches it pushed through the gateway so far.
  final Set<AgentRunPushedBranch> pushedBranches;

  /// Whether the run pushed [branch] to [owner]/[name].
  bool pushed(String owner, String name, String branch) =>
      pushedBranches.any((b) => b.matches(owner, name, branch));

  /// Whether the run pushed [branch] to [owner]/[name] at commit [sha]. A
  /// forge that reports an abbreviated id (Bitbucket's 12 characters) matches
  /// the full one it abbreviates; fewer than 7 characters match nothing.
  bool pushedAt(String owner, String name, String branch, String sha) {
    final wanted = sha.trim().toLowerCase();
    return wanted.length >= 7 &&
        pushedBranches.any(
          (b) =>
              b.matches(owner, name, branch) &&
              b.sha.isNotEmpty &&
              b.sha.startsWith(wanted),
        );
  }
}
