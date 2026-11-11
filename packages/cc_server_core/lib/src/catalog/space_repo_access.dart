/// Who may read a space: its content (messages, tool output, diffs, file
/// contents its agents read, run logs) carries the code of the repositories
/// the space exposes, so it is readable only by a caller who may read every
/// one of them, exactly as the code ops decide per repository: a read grant
/// (workspace admins hold every grant) and their own forge sign-in reading
/// it ([RepoForgeReadCheck]; the server owner is exempt from that half).
///
/// The repositories a space exposes are its explicit selection; no
/// selection and `no_repos` false is every linked repository; `no_repos`
/// true is none, so a space without repositories stays open to every
/// member.
library;

import 'package:cc_domain/cc_domain.dart'
    show AuthException, RepoGrantRequiredException;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show WorkspaceDatabaseManager;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart'
    show SpaceReadGate;
import 'package:cc_server_core/src/catalog/repo_forge_read.dart';

/// The repositories a space exposes in [workspaceId], from its [selection]
/// as `MessagingRepository.spaceRepoSelection` answers it: null (no
/// selection, or no such space) is every linked repository, empty is none.
/// The one rule every space surface applies, here and for ops built outside
/// the catalog (`context.inspect`).
Future<List<String>> spaceExposedRepos(
  WorkspaceRepository workspaces,
  String workspaceId,
  List<String>? selection,
) async =>
    selection ??
    [
      for (final r
          in await workspaces.watchReposForWorkspace(workspaceId).first)
        r.id,
    ];

/// The space read gate over a workspace's spaces, repositories, members and
/// forge reads.
final class SpaceRepoAccess implements SpaceReadGate {
  /// Creates the gate. Without `dbs` there are no space selections to read,
  /// so a space exposes nothing; without `members` a space exposing a
  /// repository is refused (fail closed).
  SpaceRepoAccess({
    required this._dbs,
    required this._messaging,
    required this._workspaces,
    required this._members,
    required this._forgeRead,
  });

  final WorkspaceDatabaseManager? _dbs;
  final MessagingRepository _messaging;
  final WorkspaceRepository _workspaces;
  final WorkspaceMembershipRepository? _members;
  final RepoForgeReadCheck _forgeRead;

  Future<List<String>> _linked(String workspaceId) =>
      spaceExposedRepos(_workspaces, workspaceId, null);

  /// The repositories [spaceId] exposes in [workspaceId]; every linked one
  /// when [spaceId] is null (a host shell can reach each of them).
  Future<List<String>> exposedBy(String workspaceId, String? spaceId) async {
    final dbs = _dbs;
    if (dbs == null) {
      return const [];
    }
    return spaceExposedRepos(
      _workspaces,
      workspaceId,
      spaceId == null || spaceId.isEmpty
          ? null
          : await _messaging.spaceRepoSelection(workspaceId, spaceId),
    );
  }

  /// A check of [userId]'s reads in [workspaceId], one repository at a time,
  /// sharing one membership lookup. Throws the refusal the code ops give.
  Future<Future<void> Function(String repoId)> _reader(
    String workspaceId,
    String userId,
  ) async {
    final members = _members;
    if (members == null) {
      throw const AuthException(
        'This server has no membership wiring, so repo access cannot be '
        'authorized.',
      );
    }
    final member = await members.getMember(workspaceId, userId);
    if (member == null) {
      throw const AuthException('Not a member of this workspace');
    }
    final grants = member.role.isAdmin
        ? null
        : await members.getRepoGrants(workspaceId, userId);
    return (repoId) async {
      if (grants != null &&
          !(grants[repoId] ?? RepoGrantLevel.none).allowsRead) {
        throw const RepoGrantRequiredException(
          RepoGrantLevel.read,
          'No read access to this repo',
        );
      }
      await _forgeRead(
        workspaceId: workspaceId,
        userId: userId,
        repoId: repoId,
      );
    };
  }

  @override
  Future<void> require(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {
    final exposed = await exposedBy(workspaceId, spaceId);
    if (exposed.isEmpty) {
      return;
    }
    final read = await _reader(workspaceId, userId);
    for (final repoId in exposed) {
      await read(repoId);
    }
  }

  @override
  Future<Set<String>> unreadable(String workspaceId, String userId) async {
    final dbs = _dbs;
    if (dbs == null) {
      return const {};
    }
    final db = dbs.of(workspaceId);
    final spaces = [
      for (final space
          in await db.messagingDao.watchSpacesByWorkspace(workspaceId).first)
        if (!space.noRepos) space.id,
    ];
    if (spaces.isEmpty) {
      // Only `no_repos` spaces (or none): nothing depends on a repository,
      // so no grant or forge question is asked.
      return const {};
    }
    final selections = await db.spaceRepoDao.repoIdsBySpace(workspaceId);
    final linked = spaces.any((id) => selections[id] == null)
        ? await _linked(workspaceId)
        : const <String>[];
    final exposedBy = {for (final id in spaces) id: selections[id] ?? linked};
    // Only the repositories some space exposes are asked about.
    final candidates = {for (final ids in exposedBy.values) ...ids};
    if (candidates.isEmpty) {
      return const {};
    }
    final denied = <String>{};
    try {
      final read = await _reader(workspaceId, userId);
      for (final repoId in candidates) {
        try {
          await read(repoId);
        } on Object {
          denied.add(repoId);
        }
      }
    } on Object {
      denied.addAll(candidates);
    }
    return {
      for (final MapEntry(key: id, value: ids) in exposedBy.entries)
        if (ids.any(denied.contains)) id,
    };
  }
}
