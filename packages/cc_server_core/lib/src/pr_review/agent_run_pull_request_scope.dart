import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/cc_infra.dart' show AgentRunView;
import 'package:cc_natives/cc_natives.dart' show IsolatedGit, RigWorktreeGuard;

/// The open runs of a conversation in a workspace (the agent run gateway's
/// `openRuns`).
typedef AgentRunsLookup =
    List<AgentRunView> Function({
      required String workspaceId,
      required String conversationId,
    });

/// Whether [userId] is a member of [workspaceId] who may read [repo] there
/// (an admin, or a read grant on it).
typedef MemberMayReadRepo =
    Future<bool> Function(String workspaceId, String userId, Repo repo);

/// The commit [branch] points at in [spaceId]'s own checkout of [repo], or
/// null when the space has no checkout of it or no such branch.
typedef SpaceBranchHead =
    Future<String?> Function(
      String workspaceId,
      String spaceId,
      Repo repo,
      String branch,
    );

/// [SpaceBranchHead] read from the space checkouts [isolated] records.
SpaceBranchHead spaceBranchHeadIn(IsolatedRepoRepository isolated) =>
    (workspaceId, spaceId, repo, branch) async {
      final checkout = await isolated.forUnitRepo(
        workspaceId,
        spaceId,
        repo.id,
      );
      if (checkout == null || branch.isEmpty || branch.startsWith('-')) {
        return null;
      }
      final result = await IsolatedGit.run(
        RigWorktreeGuard.gitArgs([
          'rev-parse',
          '--verify',
          '--quiet',
          'refs/heads/$branch^{commit}',
        ], workingDirectory: checkout.path),
        workingDirectory: checkout.path,
      );
      final sha = '${result.stdout}'.trim();
      return result.exitCode == 0 && sha.isNotEmpty ? sha : null;
    };

/// The agent runs open in one conversation and the one member they act for
/// (null: nobody requested them).
typedef AgentRunsFor = ({List<AgentRunView> runs, String? requester});

/// Which runs, repositories, branches and pull requests an agent run may act
/// on through the server's pull request tools, and for whom.
///
/// The runs are read from the agent run gateway for the run's own
/// conversation (its attested scope, never the model). They must all act
/// for one member (or for nobody), who must still be a member of the
/// workspace and may read the repository there. The repository must be
/// linked to the run's workspace. A branch is the run's own when it pushed
/// it through the gateway, or it is the run's space branch for that
/// repository. A pull request is the run's own when its head lives in that
/// repository (never a fork) and sits at a commit the run pushed there
/// through the gateway, or at its space's checkout of its space branch.
///
/// Every refusal names what was refused through a `doing` phrase ("open a
/// pull request", "comment on its pull request"), so an agent reads what to
/// change.
class AgentRunPullRequestScope {
  /// Creates the scope.
  AgentRunPullRequestScope({
    required this._openRuns,
    required this._linkedRepos,
    required this._spaceBranches,
    required this._spaceBranchHead,
    required this._isMember,
    required this._mayRead,
  });

  final AgentRunsLookup _openRuns;
  final Future<List<Repo>> Function(String workspaceId) _linkedRepos;
  final Future<Map<String, String>> Function(String workspaceId, String spaceId)
  _spaceBranches;
  final SpaceBranchHead _spaceBranchHead;
  final Future<bool> Function(String workspaceId, String userId) _isMember;
  final MemberMayReadRepo _mayRead;

  /// The open runs of [conversationId] and the one member they act for, who
  /// must still be a member of [workspaceId].
  Future<AgentRunsFor> runsOf(
    String workspaceId,
    String conversationId, {
    required String doing,
  }) async {
    final runs = _openRuns(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (runs.isEmpty) {
      throw ValidationException(
        'Only a running Control Center agent run can $doing.',
      );
    }
    final requesterIds = {for (final r in runs) r.grant.actingUserId ?? ''};
    if (requesterIds.length != 1) {
      throw const ValidationException(
        'Runs for different people are active in this conversation, so it '
        'is not clear whose pull request this is.',
      );
    }
    final requester = requesterIds.single.isEmpty ? null : requesterIds.single;
    if (requester != null && !await _isMember(workspaceId, requester)) {
      throw const AuthException(
        'The person who asked for this run is no longer a member of this '
        'workspace.',
      );
    }
    return (runs: runs, requester: requester);
  }

  /// The repository [repo] (`owner/name`, or null for the runs' own worktree
  /// repository) names among those linked to [workspaceId], which the runs'
  /// requester may read there.
  Future<Repo> repoFor(
    String workspaceId,
    String? repo,
    AgentRunsFor runs, {
    required String doing,
  }) async {
    final (owner, name) = _target(repo, runs.runs);
    final matches = [
      for (final r in await _linkedRepos(workspaceId))
        if (r.hasForgeRemote &&
            r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
            r.remoteName.toLowerCase() == name.toLowerCase())
          r,
    ];
    if (matches.isEmpty) {
      throw ValidationException(
        '$owner/$name is not linked to this workspace, so agents here cannot '
        '$doing there.',
      );
    }
    if (matches.map((r) => r.forge).toSet().length > 1) {
      throw ValidationException(
        '$owner/$name names repositories on more than one forge in this '
        'workspace.',
      );
    }
    final linked = matches.first;
    final requester = runs.requester;
    if (requester != null && !await _mayRead(workspaceId, requester, linked)) {
      throw AuthException(
        'The person who asked for this run has no access to '
        '${linked.fullName} in this workspace, so an agent cannot $doing '
        'there for them.',
      );
    }
    return linked;
  }

  /// Whether [branch] of [repo] is the runs' own: one of them pushed it
  /// through the gateway, or it is their space's branch for [repo].
  Future<bool> isRunBranch(
    String workspaceId,
    List<AgentRunView> runs,
    Repo repo,
    String branch,
  ) async {
    if (runs.any((r) => r.pushed(repo.remoteOwner, repo.remoteName, branch))) {
      return true;
    }
    for (final spaceId in _spaces(runs)) {
      final branches = await _spaceBranches(workspaceId, spaceId);
      if (branches[repo.id] == branch) {
        return true;
      }
    }
    return false;
  }

  /// Pull request [number] of [repo], read through [client], when it is the
  /// runs' own. Throws [NotFoundException] when it does not exist and
  /// [ValidationException] when it is not theirs.
  Future<PullRequest> ownPullRequest(
    ForgePrClient client, {
    required String workspaceId,
    required List<AgentRunView> runs,
    required Repo repo,
    required int number,
  }) async {
    final pr = await client.getPullRequest(number);
    if (pr == null) {
      throw NotFoundException('${repo.fullName}#$number does not exist.');
    }
    if (!pr.isFromBaseRepository) {
      throw ValidationException(
        '${repo.fullName}#$number is not this run\'s pull request: its head '
        'branch is not in ${repo.fullName} (a fork, or the forge did not '
        'say).',
      );
    }
    if (!await _isRunHead(workspaceId, runs, repo, pr)) {
      throw ValidationException(
        '${repo.fullName}#$number is not this run\'s pull request: its head '
        '${pr.headRef} is at a commit this run neither pushed nor has on its '
        'space branch.',
      );
    }
    return pr;
  }

  /// `owner/name` from [repo], or the runs' own GitHub repository.
  static (String, String) _target(String? repo, List<AgentRunView> runs) {
    if (repo != null) {
      final parts = repo.trim().split('/');
      if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
        throw const ValidationException('Name the repository as owner/name.');
      }
      return (parts[0], parts[1]);
    }
    final own = <String, (String, String)>{
      for (final r in runs)
        if (r.grant.soleGitHubRepo case final repo?)
          '${repo.owner}/${repo.name}'.toLowerCase(): (repo.owner, repo.name),
    };
    if (own.length != 1) {
      throw const ValidationException(
        'This run has no single repository of its own: name the repository '
        'as owner/name.',
      );
    }
    return own.values.single;
  }

  /// Whether [pr]'s head is the run's own: its branch at a commit the run
  /// pushed, or its space branch at the commit the space's checkout has.
  Future<bool> _isRunHead(
    String workspaceId,
    List<AgentRunView> runs,
    Repo repo,
    PullRequest pr,
  ) async {
    final branch = pr.headRef;
    final sha = pr.headSha.trim().toLowerCase();
    if (branch.isEmpty || sha.length < 7) {
      return false;
    }
    if (runs.any(
      (r) => r.pushedAt(repo.remoteOwner, repo.remoteName, branch, sha),
    )) {
      return true;
    }
    for (final spaceId in _spaces(runs)) {
      final branches = await _spaceBranches(workspaceId, spaceId);
      if (branches[repo.id] != branch) {
        continue;
      }
      final head = await _spaceBranchHead(workspaceId, spaceId, repo, branch);
      if (head != null && head.toLowerCase().startsWith(sha)) {
        return true;
      }
    }
    return false;
  }

  static Set<String> _spaces(List<AgentRunView> runs) => {
    for (final r in runs)
      if ((r.grant.spaceId ?? '').isNotEmpty) r.grant.spaceId!,
  };
}
