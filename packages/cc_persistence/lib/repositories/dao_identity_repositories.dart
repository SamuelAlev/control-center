import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/user_activity_dao.dart';
import 'package:cc_persistence/database/daos/user_dao.dart';
import 'package:cc_persistence/database/daos/user_preference_dao.dart';
import 'package:cc_persistence/database/daos/workspace_invite_dao.dart';
import 'package:cc_persistence/database/daos/workspace_member_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/identity_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-backed [UserRepository].
///
/// Users are server-global — one human is one user across every workspace —
/// so this reads the `users` table in `global.db` directly rather than through
/// the per-workspace databases.
class DaoUserRepository implements UserRepository {
  /// Creates a [DaoUserRepository] over the global [UserDao].
  DaoUserRepository(this._dao);

  final UserDao _dao;
  static const _mapper = IdentityMapper();

  @override
  Future<List<User>> getAll() async =>
      (await _dao.getAll()).map(_mapper.userToDomain).toList();

  @override
  Stream<List<User>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.userToDomain).toList());

  @override
  Future<User?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapper.userToDomain(row);
  }

  @override
  Future<User?> getByHandle(String handle) async {
    final row = await _dao.getByHandle(handle);
    return row == null ? null : _mapper.userToDomain(row);
  }

  @override
  Future<User?> getByEmail(String email) async {
    final row = await _dao.getByEmail(email);
    return row == null ? null : _mapper.userToDomain(row);
  }

  @override
  Future<User?> getBySsoSubject(String issuer, String subject) async {
    final row = await _dao.getBySsoSubject(issuer, subject);
    return row == null ? null : _mapper.userToDomain(row);
  }

  @override
  Future<void> upsert(User user) => _dao.upsert(
    UsersTableCompanion(
      id: Value(user.id),
      handle: Value(user.handle),
      displayName: Value(user.displayName),
      email: Value(user.email),
      avatarRef: Value(user.avatarRef),
      gitAuthorName: Value(user.gitAuthorName),
      gitAuthorEmail: Value(user.gitAuthorEmail),
      ssoSubject: Value(user.ssoSubject),
      ssoIssuer: Value(user.ssoIssuer),
      deactivatedAt: Value(user.deactivatedAt),
      createdAt: Value(user.createdAt),
    ),
  );

  @override
  Future<int> count() => _dao.count();
}

/// DAO-backed [WorkspaceMembershipRepository].
///
/// Membership is the workspace access boundary and it is workspace-scoped:
/// rows live in the workspace's own database file, so this holds the
/// [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).workspaceMemberDao` per call. [getForUser] is the one
/// read that spans files, because "which workspaces do I belong to" is the
/// question the picker asks before any workspace is chosen.
class DaoWorkspaceMembershipRepository
    implements WorkspaceMembershipRepository {
  /// Creates a [DaoWorkspaceMembershipRepository] over the per-workspace
  /// databases.
  DaoWorkspaceMembershipRepository(this._dbs)
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  static const _mapper = IdentityMapper();

  WorkspaceMemberDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).workspaceMemberDao;

  @override
  Future<List<WorkspaceMember>> getForWorkspace(String workspaceId) async =>
      (await _dao(
        workspaceId,
      ).getForWorkspace(workspaceId)).map(_mapper.memberToDomain).toList();

  @override
  Stream<List<WorkspaceMember>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchForWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.memberToDomain).toList());

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    final row = await _dao(workspaceId).getMember(workspaceId, userId);
    return row == null ? null : _mapper.memberToDomain(row);
  }

  /// CROSS-WORKSPACE BY DESIGN: a user's memberships are, by definition, spread
  /// across workspaces — this is what the workspace picker lists and it runs
  /// before any workspace is selected. Every other read here is scoped to the
  /// one workspace whose file it opens.
  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.workspaceMemberDao.getForUser(userId),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _mapper.memberToDomain(row),
    ];
  }

  @override
  Future<void> upsert(WorkspaceMember member) =>
      // The membership names its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(member.workspaceId).upsert(
        WorkspaceMembersTableCompanion(
          id: Value(member.id),
          workspaceId: Value(member.workspaceId),
          userId: Value(member.userId),
          role: Value(member.role.wireName),
          invitedBy: Value(member.invitedBy),
          joinedAt: Value(member.joinedAt),
        ),
      );

  @override
  Future<void> setRole(String workspaceId, String userId, WorkspaceRole role) =>
      _dao(workspaceId).setRole(workspaceId, userId, role.wireName);

  @override
  Future<void> remove(String workspaceId, String userId) =>
      _dao(workspaceId).remove(workspaceId, userId);

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async {
    final rows = await _dao(workspaceId).getRepoGrants(workspaceId, userId);
    return {
      for (final row in rows)
        row.repoId: RepoGrantLevel.fromWire(row.level) ?? RepoGrantLevel.none,
    };
  }

  @override
  Future<void> setRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
    RepoGrantLevel level,
  ) async {
    if (level == RepoGrantLevel.none) {
      await _dao(workspaceId).removeRepoGrant(workspaceId, userId, repoId);
      return;
    }
    await _dao(workspaceId).upsertRepoGrant(
      WorkspaceMemberRepoGrantsTableCompanion(
        id: Value('$workspaceId:$userId:$repoId'),
        workspaceId: Value(workspaceId),
        userId: Value(userId),
        repoId: Value(repoId),
        level: Value(level.wireName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

/// DAO-backed [WorkspaceInviteRepository].
///
/// Invite rows live in their workspace's own database file, but redemption
/// arrives unauthenticated with nothing but a code — no workspace id — so
/// the hash has to name its workspace before any file can be opened. That is
/// what the global [WorkspaceRoutesTable] is for: [upsert] writes the row and
/// then its [WorkspaceRouteKind.inviteCode] route, [getByCodeHash] resolves
/// the route and reads the row from the workspace it names and a spent or
/// deleted invite drops the route so a dead hash stops resolving.
class DaoWorkspaceInviteRepository implements WorkspaceInviteRepository {
  /// Creates a [DaoWorkspaceInviteRepository] over the per-workspace databases
  /// [_dbs] and the global routing table [_routes].
  DaoWorkspaceInviteRepository(this._dbs, this._routes);

  final WorkspaceDatabaseManager _dbs;
  final WorkspaceRouteDao _routes;
  static const _mapper = IdentityMapper();

  WorkspaceInviteDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).workspaceInviteDao;

  @override
  Future<List<WorkspaceInvite>> getForWorkspace(String workspaceId) async =>
      (await _dao(
        workspaceId,
      ).getForWorkspace(workspaceId)).map(_mapper.inviteToDomain).toList();

  @override
  Stream<List<WorkspaceInvite>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchForWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.inviteToDomain).toList());

  /// Resolves [codeHash] to its workspace through the global routing table,
  /// then reads the invite from that workspace's file.
  ///
  /// A missing route is a miss, not a reason to scan every workspace: a scan
  /// would turn "the route was never written" into a slow success and hide it,
  /// and it would hand an unauthenticated caller a probe across every file.
  @override
  Future<WorkspaceInvite?> getByCodeHash(String codeHash) async {
    final workspaceId = await _routes.resolve(
      WorkspaceRouteKind.inviteCode,
      codeHash,
    );
    if (workspaceId == null) {
      return null;
    }
    final row = await _dao(workspaceId).getByCodeHash(codeHash);
    return row == null ? null : _mapper.inviteToDomain(row);
  }

  /// Writes [invite] into its workspace's file, then updates its route.
  ///
  /// Row first, route second: a route pointing at a row that does not exist yet
  /// would resolve to a not-found, whereas the reverse order fails loudly on
  /// the very next read. A spent invite (revoked, or already used) drops its
  /// route instead — it can never be redeemed again, so nothing resolves it.
  @override
  Future<void> upsert(WorkspaceInvite invite) async {
    await _dao(invite.workspaceId).upsert(
      WorkspaceInvitesTableCompanion(
        id: Value(invite.id),
        workspaceId: Value(invite.workspaceId),
        codeHash: Value(invite.codeHash),
        role: Value(invite.role.wireName),
        repoGrantsJson: Value(
          IdentityMapper.encodeRepoGrants(invite.repoGrants),
        ),
        createdBy: Value(invite.createdBy),
        createdAt: Value(invite.createdAt),
        expiresAt: Value(invite.expiresAt),
        usedAt: Value(invite.usedAt),
        usedBy: Value(invite.usedBy),
        revokedAt: Value(invite.revokedAt),
      ),
    );
    final spent = invite.revokedAt != null || invite.usedAt != null;
    if (spent) {
      await _routes.remove(WorkspaceRouteKind.inviteCode, invite.codeHash);
      return;
    }
    await _routes.put(
      WorkspaceRouteKind.inviteCode,
      invite.codeHash,
      invite.workspaceId,
    );
  }

  /// Deletes the invite and its route.
  ///
  /// The row is read first because the route is keyed by the code hash, not by
  /// the invite id; dropping the row without the route would leave a hash
  /// resolving to a workspace where nothing matches it.
  @override
  Future<void> delete(String workspaceId, String id) async {
    final rows = await _dao(workspaceId).getForWorkspace(workspaceId);
    String? codeHash;
    for (final row in rows) {
      if (row.id == id) {
        codeHash = row.codeHash;
        break;
      }
    }
    await _dao(workspaceId).deleteInvite(workspaceId, id);
    if (codeHash != null) {
      await _routes.remove(WorkspaceRouteKind.inviteCode, codeHash);
    }
  }
}

/// DAO-backed [UserActivityRepository].
///
/// Activity is workspace-scoped audit history, so it lives in the workspace's
/// own database file and this holds the [WorkspaceDatabaseManager].
class DaoUserActivityRepository implements UserActivityRepository {
  /// Creates a [DaoUserActivityRepository] over the per-workspace databases.
  DaoUserActivityRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  static const _mapper = IdentityMapper();

  UserActivityDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).userActivityDao;

  @override
  Future<void> append(UserActivityEntry entry) =>
      // The entry names its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(entry.workspaceId).append(
        UserActivityTableCompanion(
          id: Value(entry.id),
          workspaceId: Value(entry.workspaceId),
          userId: Value(entry.userId),
          action: Value(entry.action),
          targetType: Value(entry.targetType),
          targetId: Value(entry.targetId),
          deviceId: Value(entry.deviceId),
          ip: Value(entry.ip),
          countryCode: Value(entry.countryCode),
          createdAt: Value(entry.createdAt),
        ),
      );

  @override
  Future<List<UserActivityEntry>> getForWorkspace(
    String workspaceId, {
    int limit = 200,
  }) async => (await _dao(workspaceId).getForWorkspace(
    workspaceId,
    limit: limit,
  )).map(_mapper.activityToDomain).toList();

  @override
  Stream<List<UserActivityEntry>> watchForWorkspace(
    String workspaceId, {
    int limit = 200,
  }) => _dao(workspaceId)
      .watchForWorkspace(workspaceId, limit: limit)
      .map((rows) => rows.map(_mapper.activityToDomain).toList());
}

/// DAO-backed [UserPreferencesRepository].
///
/// Preferences follow the user, not a workspace, so they live in `global.db`
/// alongside the `users` table and this reads the global DAO directly.
///
/// Writes are quota-bounded ([maxValueBytes], [maxKeysPerUser]). The store is
/// an opaque client-defined key space reached over `prefs.set`, every row is
/// streamed back in full to every signed-in device by `prefs.watchOwn` and
/// `global.db` is the one database the server always has open — so an
/// unbounded value or an unbounded key count is a denial-of-service on every
/// workspace at once, not just on the offending user. The caps are generous
/// enough for the real payloads (a VS Code colour theme is the largest at
/// ~50-200 KB) and small enough that a runaway client fails loudly.
class DaoUserPreferencesRepository implements UserPreferencesRepository {
  /// Creates a [DaoUserPreferencesRepository] over the global
  /// [UserPreferenceDao].
  DaoUserPreferencesRepository(this._dao);

  /// Largest accepted value, in UTF-8 bytes.
  ///
  /// Sized for the biggest legitimate payload — an imported VS Code colour
  /// theme (`vscode_editor_theme_json`) runs 50-200 KB — with headroom.
  static const int maxValueBytes = 512 * 1024;

  /// Largest number of distinct keys one user may hold.
  ///
  /// The synced set is a fixed, code-defined registry of a few dozen keys;
  /// this only bites when a client invents keys in a loop.
  static const int maxKeysPerUser = 256;

  final UserPreferenceDao _dao;

  @override
  Future<String?> get(String userId, String key) => _dao.getValue(userId, key);

  @override
  Future<Map<String, String>> getAll(String userId) async {
    final rows = await _dao.getForUser(userId);
    return {for (final row in rows) row.key: row.value};
  }

  @override
  Stream<Map<String, String>> watchAll(String userId) => _dao
      .watchForUser(userId)
      .map((rows) => {for (final row in rows) row.key: row.value});

  @override
  Future<void> set(String userId, String key, String? value) async {
    if (value == null) {
      await _dao.deleteValue(userId, key);
      return;
    }
    if (key.isEmpty) {
      throw const ValidationException('Preference key must not be empty.');
    }
    final bytes = utf8.encode(value).length;
    if (bytes > maxValueBytes) {
      throw ValidationException(
        'Preference "$key" is $bytes bytes, over the '
        '$maxValueBytes-byte limit.',
      );
    }
    // Only a NEW key can grow the row count, so an over-quota user can still
    // edit the keys they already have (and delete their way back under).
    if (await _dao.getValue(userId, key) == null) {
      final count = await _dao.countForUser(userId);
      if (count >= maxKeysPerUser) {
        throw ValidationException(
          'Preference limit reached ($maxKeysPerUser keys); '
          'cannot add "$key".',
        );
      }
    }
    await _dao.setValue(userId, key, value);
  }
}
