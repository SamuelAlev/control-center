import 'package:cc_harness/cancellation.dart';

/// What `RepoWorkspaceProvisionerPort.ensureSpaceWorkspace` is asked to
/// prepare: a space's isolated worktrees plus one agent's overlay in it.
class SpaceWorkspaceRequest {
  /// Creates a [SpaceWorkspaceRequest].
  ///
  /// Throws [ArgumentError] when [workspaceId], [spaceId] or [agentSlug] is
  /// empty: a provision without a space has nowhere to go, and saying so
  /// beats quietly running somewhere else.
  SpaceWorkspaceRequest({
    required this.workspaceId,
    required this.spaceId,
    required this.agentSlug,
    this.conversationId,
    this.agentConfigDir,
    this.ticketId,
    this.ticketKey,
    this.ticketTitle,
    this.branchType = 'feature',
    this.prHeadRef,
    this.prHeadRepoFullName,
    this.prBranch,
    this.repoAllowlist,
    this.onRepoProvision,
    this.onRepoProvisionTasks,
    this.cancel,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'is empty');
    }
    if (spaceId.isEmpty) {
      throw ArgumentError.value(spaceId, 'spaceId', 'is empty');
    }
    if (agentSlug.isEmpty) {
      throw ArgumentError.value(agentSlug, 'agentSlug', 'is empty');
    }
  }

  /// The workspace.
  final String workspaceId;

  /// The space whose worktrees are shared by every conversation in it.
  final String spaceId;

  /// Keys the overlay, with [conversationId].
  final String agentSlug;

  /// Keys the overlay, so two conversations can run the same agent at once.
  final String? conversationId;

  /// The agent's global dir: AGENTS.md and `.agents` link there.
  final String? agentConfigDir;

  /// The ticket whose pre-provisioned worktrees may be reused.
  final String? ticketId;

  /// With [ticketTitle], names the branch; else the space's scratch branch.
  final String? ticketKey;

  /// See [ticketKey].
  final String? ticketTitle;

  /// The branch prefix (`feature`, `fix`, …).
  final String branchType;

  /// A PR head ref to check out, pristine, on [prBranch] for
  /// [prHeadRepoFullName].
  final String? prHeadRef;

  /// See [prHeadRef].
  final String? prHeadRepoFullName;

  /// See [prHeadRef].
  final String? prBranch;

  /// The repos to provision; null asks the space, then every linked repo.
  final Set<String>? repoAllowlist;

  /// Fires when a repo is freshly materialized; must not throw.
  final void Function(String repoName, {required bool prHead})? onRepoProvision;

  /// Fires when a fresh repo's provision tasks start; must not throw.
  final void Function(String repoName)? onRepoProvisionTasks;

  /// Kills the running git command and stops.
  final CancellationToken? cancel;
}

/// What came of a `ensureSpaceWorkspace` call.
sealed class SpaceWorkspace {
  const SpaceWorkspace();
}

/// The overlay is ready at [path]: the agent's working directory.
final class SpaceWorkspaceReady extends SpaceWorkspace {
  /// Creates a [SpaceWorkspaceReady].
  const SpaceWorkspaceReady(this.path);

  /// The overlay directory.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is SpaceWorkspaceReady && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'SpaceWorkspaceReady($path)';
}

/// Why no overlay was prepared.
enum SpaceWorkspaceUnavailableReason {
  /// The space checks out no repo. Not a fault: there is nothing to isolate,
  /// and the agent works in its own directory.
  noRepos,

  /// Someone stopped the space's preparation.
  cancelled,

  /// Preparation broke. [SpaceWorkspaceUnavailable.message] says how.
  failed,
}

/// No overlay was prepared, and [reason] says why. The caller decides what
/// that means for its run; nothing substitutes a directory behind its back.
final class SpaceWorkspaceUnavailable extends SpaceWorkspace {
  /// Creates a [SpaceWorkspaceUnavailable].
  const SpaceWorkspaceUnavailable(this.reason, [this.message]);

  /// Why.
  final SpaceWorkspaceUnavailableReason reason;

  /// The failure, for [SpaceWorkspaceUnavailableReason.failed].
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is SpaceWorkspaceUnavailable &&
      other.reason == reason &&
      other.message == message;

  @override
  int get hashCode => Object.hash(reason, message);

  @override
  String toString() =>
      'SpaceWorkspaceUnavailable(${reason.name}'
      '${message == null ? '' : ': $message'})';
}
