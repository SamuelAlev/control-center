import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show ForgeRemote;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';

/// The agent run gateway's repository check: whether a run for
/// `actingUserId` (null: nobody asked for it) may push to the GitHub
/// repository `owner/name` in `workspaceId`.
///
/// The repository must be linked to the workspace, and the person who asked
/// for the run must hold Control Center's own grant to write to it there
/// ([RepoGrantLevel.write], "driving agent runs that write to the repo";
/// admins and the owner hold it on every linked repository). Their reach on
/// GitHub is not enough: a member granted one repository cannot have an
/// agent push to another linked one they happen to be able to push to on
/// GitHub. A run nobody asked for pushes as the workspace's automation,
/// whose token is bounded by the accountable human when it is minted.
Future<bool> Function(
  String workspaceId,
  String owner,
  String name,
  String? actingUserId,
)
agentPushRepoCheck({
  required Future<List<Repo>> Function(String workspaceId) linkedRepos,
  required WorkspaceMembershipRepository members,
}) => (workspaceId, owner, name, actingUserId) async {
  final wanted = '$owner/$name'.toLowerCase();
  Repo? linked;
  for (final repo in await linkedRepos(workspaceId)) {
    if (repo.forge == ForgeHost.github &&
        repo.hasForgeRemote &&
        repo.fullName.toLowerCase() == wanted) {
      linked = repo;
      break;
    }
  }
  if (linked == null) {
    return false;
  }
  if (actingUserId == null || actingUserId.isEmpty) {
    return true;
  }
  return holdsRepoWriteGrant(members, workspaceId, actingUserId, linked.id);
};

/// The agent run gateway's fetch credential (`AgentFetchCredential`): the
/// token a run's fetch of its GitLab or Bitbucket repository `repo` in
/// `workspaceId` is forwarded on, which never enters the run's sandbox.
///
/// The repository must be linked to the workspace. A run a person asked for
/// fetches on that person's own token ([personToken]); a run nobody asked for
/// fetches on the repository's automation token ([automationToken]). Neither
/// stands in for the other: without the one the run needs, the answer is a
/// refusal that says what to connect.
Future<({String? token, String? refusal})> Function(
  String workspaceId,
  ForgeRemote repo,
  String? actingUserId,
)
agentFetchCredential({
  required Future<List<Repo>> Function(String workspaceId) linkedRepos,
  required Future<String?> Function(
    ForgeHost forge,
    String userId,
    String workspaceId,
  )
  personToken,
  required Future<String?> Function(String workspaceId, Repo repo)
  automationToken,
}) => (workspaceId, wanted, actingUserId) async {
  ({String? token, String? refusal}) refuse(String why) =>
      (token: null, refusal: why);
  if (!ForgeAutomationTokens.supports(wanted.forge)) {
    return refuse(
      'the agent run gateway keeps no ${wanted.forge.displayName} token.',
    );
  }
  Repo? linked;
  for (final repo in await linkedRepos(workspaceId)) {
    if (repo.forge == wanted.forge &&
        repo.hasForgeRemote &&
        repo.remoteOwner.toLowerCase() == wanted.owner.toLowerCase() &&
        repo.remoteName.toLowerCase() == wanted.name.toLowerCase()) {
      linked = repo;
      break;
    }
  }
  if (linked == null) {
    return refuse(
      '${wanted.owner}/${wanted.name} is not linked to this workspace.',
    );
  }
  if (actingUserId != null && actingUserId.isNotEmpty) {
    final token = await personToken(wanted.forge, actingUserId, workspaceId);
    return token == null || token.isEmpty
        ? refuse(ForgeCredentials.signInRequiredMessage(wanted.forge))
        : (token: token, refusal: null);
  }
  final token = await automationToken(workspaceId, linked);
  return token == null || token.isEmpty
      ? refuse(ForgeAutomationTokens.missingMessage(linked))
      : (token: token, refusal: null);
};

/// Whether [userId] holds Control Center's write grant on repository
/// [repoId] of [workspaceId] ([RepoGrantLevel.write]; a workspace admin
/// holds it on every linked repository). Asked at the moment of every push
/// made for a person: the push gateway's and a stack publish's, on every
/// forge.
Future<bool> holdsRepoWriteGrant(
  WorkspaceMembershipRepository members,
  String workspaceId,
  String userId,
  String repoId,
) async {
  final member = await members.getMember(workspaceId, userId);
  if (member == null) {
    return false;
  }
  if (member.role.isAdmin) {
    return true;
  }
  final grants = await members.getRepoGrants(workspaceId, userId);
  return (grants[repoId] ?? RepoGrantLevel.none).atLeast(RepoGrantLevel.write);
}

/// The dispatch session's repository grant lookup: the worktrees of space
/// `spaceId` in `workspaceId` that a run for `actingUserId` may change. Every
/// other worktree in the space is read-only for the run (the session's
/// `ReadOnlyWorktrees`).
///
/// Changing a repository's checkout takes the same grant as pushing it
/// ([holdsRepoWriteGrant]), asked of the run's accountable human: the person
/// who asked for it, or for a run nobody asked for the human the push
/// gateway's automation token is bounded by ([accountableHuman] without an
/// acting person). With no accountable human, nothing is writable.
Future<List<String>> Function(
  String workspaceId,
  String spaceId,
  String? actingUserId,
)
agentWritableWorktrees({
  required IsolatedRepoRepository worktrees,
  required WorkspaceMembershipRepository members,
  required Future<String?> Function(String workspaceId, {String? actingUserId})
  accountableHuman,
}) => (workspaceId, spaceId, actingUserId) async {
  final human = await accountableHuman(workspaceId, actingUserId: actingUserId);
  if (human == null) {
    return const [];
  }
  return [
    for (final worktree in await worktrees.forSpace(workspaceId, spaceId))
      if (await holdsRepoWriteGrant(
        members,
        workspaceId,
        human,
        worktree.repoId,
      ))
        worktree.path,
  ];
};

/// The dispatch session's record of what a run in space `spaceId` of
/// `workspaceId` works on: the forge repositories of the space's checkouts.
///
/// Read from the server's own rows (the space's worktrees and the
/// workspace's linked repositories), never from a checkout's `origin`, which
/// the agent can rewrite. A run's commits are attributed for the forge these
/// are on, and on GitHub the agent run gateway hands the run a read token for
/// these and no other; the token itself is still bounded, when it is minted,
/// by what the run's accountable person may read.
Future<List<ForgeRemote>> Function(String workspaceId, String spaceId)
agentRunSpaceRepos({
  required IsolatedRepoRepository worktrees,
  required Future<List<Repo>> Function(String workspaceId) linkedRepos,
}) => (workspaceId, spaceId) async {
  final linked = {
    for (final repo in await linkedRepos(workspaceId)) repo.id: repo,
  };
  return [
    for (final worktree in await worktrees.forSpace(workspaceId, spaceId))
      if (linked[worktree.repoId] case final repo? when repo.hasForgeRemote)
        (forge: repo.forge, owner: repo.remoteOwner, name: repo.remoteName),
  ];
};
