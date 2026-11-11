import 'package:cc_data/src/server_owner_failure.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart'
    show RepoGrantAccessWarning;
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The session's resolved identity: the authenticated user, the device the
/// session rides on and every workspace membership.
class IdentityMe {
  /// Creates an [IdentityMe].
  const IdentityMe({
    required this.user,
    required this.deviceId,
    required this.isServerOwner,
    required this.memberships,
    this.canCreateWorkspaces = false,
    this.canUseHost = false,
    this.ssoIssuer = '',
  });

  /// Decodes the `identity.me` payload.
  factory IdentityMe.fromJson(Map<String, dynamic> json) => IdentityMe(
    user: UserDto.fromJson((json['user'] as Map).cast<String, dynamic>()),
    deviceId: json['device_id'] as String? ?? '',
    isServerOwner: json['is_server_owner'] as bool? ?? false,
    canCreateWorkspaces: json['can_create_workspaces'] as bool? ?? false,
    canUseHost: json['can_use_host'] as bool? ?? false,
    ssoIssuer: json['sso_issuer'] as String? ?? '',
    memberships: [
      for (final m in (json['memberships'] as List? ?? const []))
        if (m is Map) WorkspaceMemberDto.fromJson(m.cast<String, dynamic>()),
    ],
  );

  /// The authenticated user.
  final UserDto user;

  /// The device credential this session authenticated with.
  final String deviceId;

  /// Whether this user is the bootstrap owner (admin of server-global
  /// surfaces like the device registry).
  final bool isServerOwner;

  /// Whether this user may create workspaces (`workspace.create`). Today
  /// only the server owner may; the client follows this flag, never
  /// [isServerOwner], so a wider rule needs no client change.
  final bool canCreateWorkspaces;

  /// Whether this user may run unsandboxed on the server host: the host
  /// shell, the embedded code-server editor, host-placed environments.
  /// Today only the server owner may; everyone else gets sandboxed tools.
  /// Absent reads as false.
  final bool canUseHost;

  /// The identity provider (issuer) this account is pinned to by single
  /// sign-on; empty when the account has none.
  final String ssoIssuer;

  /// Every workspace membership of the user.
  final List<WorkspaceMemberDto> memberships;

  /// The user's role in [workspaceId], or null when not a member.
  String? roleIn(String workspaceId) => memberships
      .where((m) => m.workspaceId == workspaceId)
      .map((m) => m.role)
      .firstOrNull;
}

/// Reads/mutates the identity & membership surface over the RPC client:
/// who am I, visible users, workspace members + roles + per-repo grants,
/// invites, per-user preferences and the audit trail. The server resolves
/// the acting user from the session — none of these calls carry a user id
/// for "self" operations.
class RemoteIdentityRepository {
  /// Creates a [RemoteIdentityRepository] over [_client].
  RemoteIdentityRepository(this._client);

  final RemoteRpcClient _client;

  /// The session's resolved identity.
  ///
  /// When [workspaceId] is set the server overlays that workspace's member
  /// profile (name, email, git author) onto the global user. Omitting it
  /// returns the account row as-is — onboarding and signed-out have no
  /// workspace to overlay.
  Future<IdentityMe> me({String? workspaceId}) async {
    final args = workspaceId == null || workspaceId.isEmpty
        ? const <String, dynamic>{}
        : <String, dynamic>{'workspace_id': workspaceId};
    return IdentityMe.fromJson(await _client.call('identity.me', args));
  }

  /// Users visible to the caller (self + co-members; the owner sees all).
  Future<List<UserDto>> listUsers() async {
    final data = await _client.call('users.list', const {});
    return _users(data);
  }

  /// Live stream of all users (authorship display).
  Stream<List<UserDto>> watchUsers() =>
      _client.subscribe('users.watchAll', const {}).map(_users);

  /// Updates the caller's own account row (null or blank leaves a field
  /// unchanged) and returns it.
  ///
  /// A refused [handle] throws [UsernameRefusedException], read from the
  /// error's `data.kind`, so the caller can say why in its own language.
  Future<UserDto> updateProfile({
    String? handle,
    String? displayName,
    String? email,
    String? avatarRef,
    String? gitAuthorName,
    String? gitAuthorEmail,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = await _client.call('users.updateProfile', {
        'handle': ?handle,
        'display_name': ?displayName,
        'email': ?email,
        'avatar_ref': ?avatarRef,
        'git_author_name': ?gitAuthorName,
        'git_author_email': ?gitAuthorEmail,
      });
    } on RemoteRpcException catch (error) {
      if (usernameRefusalOf(error) case final reason?) {
        throw UsernameRefusedException(reason);
      }
      rethrow;
    }
    return UserDto.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  /// Whether [handle] could be the caller's username right now.
  ///
  /// Live validation only: a later [updateProfile] can still be refused
  /// when someone takes the name in between.
  Future<UsernameCheck> checkHandle(String handle) async {
    final data = await _client.call('users.checkHandle', {'handle': handle});
    return UsernameCheck.fromJson(data);
  }

  /// Confirms, as the server owner, that [userId]'s email address is theirs,
  /// so single sign-on matches it to their account; returns the updated row.
  ///
  /// Server owner only: anyone else gets [ServerOwnerRequiredException].
  Future<UserDto> vouchEmail(String userId) async {
    final data = await _client.callAsOwner('users.vouchEmail', {
      'user_id': userId,
    });
    return UserDto.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  /// Updates the caller's profile overlay in the bound workspace.
  ///
  /// Empty strings inherit the global account row. Handle, SSO and devices
  /// stay on the account.
  Future<UserDto> updateWorkspaceProfile({
    required String workspaceId,
    required String displayName,
    required String email,
    required String gitAuthorName,
    required String gitAuthorEmail,
  }) async {
    final data = await _client.call('identity.updateWorkspaceProfile', {
      'workspace_id': workspaceId,
      'display_name': displayName,
      'email': email,
      'git_author_name': gitAuthorName,
      'git_author_email': gitAuthorEmail,
    });
    return UserDto.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  /// Records that the caller has finished first-run setup.
  ///
  /// Monotonic and idempotent server-side: calling it again keeps the original
  /// timestamp, so the onboarding gate can re-stamp freely whenever it observes
  /// an already-complete setup. Refresh [me] afterwards to see the new value.
  Future<void> markOnboardingFinished() =>
      _client.call('users.markOnboardingFinished', const {});

  /// Live members of [workspaceId].
  Stream<List<WorkspaceMemberDto>> watchMembers(String workspaceId) => _client
      .subscribe('members.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_members);

  /// Changes [userId]'s role in [workspaceId] (admin-gated server-side).
  Future<void> setMemberRole(String workspaceId, String userId, String role) =>
      _client.call('members.setRole', {
        'workspace_id': workspaceId,
        'user_id': userId,
        'role': role,
      });

  /// Removes [userId] from [workspaceId] (admin-gated server-side).
  Future<void> removeMember(String workspaceId, String userId) => _client.call(
    'members.remove',
    {'workspace_id': workspaceId, 'user_id': userId},
  );

  /// Hands ownership of [workspaceId] to [userId], who must already be an
  /// admin (owner-gated server-side; the caller is demoted to admin in the
  /// same operation). Without this an owner who leaves cannot be removed —
  /// SCIM deprovisioning refuses to delete the last owner.
  Future<void> transferOwnership(String workspaceId, String userId) =>
      _client.call('workspace.transferOwnership', {
        'workspace_id': workspaceId,
        'user_id': userId,
      });

  /// [userId]'s per-repo grants in [workspaceId] (repo id → level wire name).
  Future<Map<String, String>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async {
    final data = await _client.call('members.getRepoGrants', {
      'workspace_id': workspaceId,
      'user_id': userId,
    });
    final grants = data['grants'];
    return grants is Map
        ? grants.map((k, v) => MapEntry(k as String, v as String))
        : const {};
  }

  /// Sets [userId]'s grant on [repoId] (admin-gated server-side).
  ///
  /// The grant is saved either way; the result says when the member still
  /// cannot read the repository with their own forge sign-in (null when they
  /// can, or the grant was removed).
  Future<RepoGrantAccessWarning?> setRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
    String level,
  ) async {
    final data = await _client.call('members.setRepoGrant', {
      'workspace_id': workspaceId,
      'user_id': userId,
      'repo_id': repoId,
      'level': level,
    });
    return RepoGrantAccessWarning.fromResult(data['access_warning']);
  }

  /// Mints an invite; returns the metadata, the ONE-TIME code, the server's
  /// redemption URL (derived from the live descriptor — empty when the host
  /// advertises no off-loopback path) and the live [ConnectionDescriptor]
  /// (null when the server didn't publish one) so the client can embed every
  /// path in the invite QR/link.
  Future<
    ({
      WorkspaceInviteDto invite,
      String code,
      String redeemUrl,
      ConnectionDescriptor? descriptor,
    })
  >
  createInvite(
    String workspaceId, {
    required String role,
    Map<String, String> repoGrants = const {},
    int? ttlHours,
  }) async {
    final data = await _client.call('invites.create', {
      'workspace_id': workspaceId,
      'role': role,
      'repo_grants': repoGrants,
      'ttl_hours': ?ttlHours,
    });
    final descriptorJson = data['descriptor'];
    return (
      invite: WorkspaceInviteDto.fromJson(
        (data['invite'] as Map).cast<String, dynamic>(),
      ),
      code: data['code'] as String? ?? '',
      redeemUrl: data['redeem_url'] as String? ?? '',
      descriptor: descriptorJson is Map
          ? ConnectionDescriptor.fromJson(
              descriptorJson.cast<String, dynamic>(),
            )
          : null,
    );
  }

  /// Live invites of [workspaceId] (admin-gated server-side).
  Stream<List<WorkspaceInviteDto>> watchInvites(String workspaceId) => _client
      .subscribe('invites.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_invites);

  /// Revokes the open invite [inviteId].
  Future<void> revokeInvite(String workspaceId, String inviteId) =>
      _client.call('invites.revoke', {
        'workspace_id': workspaceId,
        'invite_id': inviteId,
      });

  /// The caller's own preferences.
  Future<Map<String, String>> prefsGetAll() async {
    final data = await _client.call('prefs.getAll', const {});
    final prefs = data['prefs'];
    return prefs is Map
        ? prefs.map((k, v) => MapEntry(k as String, v as String))
        : const {};
  }

  /// Sets one of the caller's own preferences (null deletes the key).
  Future<void> prefsSet(String key, String? value) =>
      _client.call('prefs.set', {'key': key, 'value': ?value});

  /// Live stream of the caller's own preferences.
  Stream<Map<String, String>> watchOwnPrefs() =>
      _client.subscribe('prefs.watchOwn', const {}).map((data) {
        final prefs = data['prefs'];
        return prefs is Map
            ? prefs.map((k, v) => MapEntry(k as String, v as String))
            : const <String, String>{};
      });

  static List<UserDto> _users(Map<String, dynamic> data) =>
      ((data['users'] as List?) ?? const [])
          .whereType<Map>()
          .map((u) => UserDto.fromJson(u.cast<String, dynamic>()))
          .toList();

  static List<WorkspaceMemberDto> _members(Map<String, dynamic> data) =>
      ((data['members'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => WorkspaceMemberDto.fromJson(m.cast<String, dynamic>()))
          .toList();

  static List<WorkspaceInviteDto> _invites(Map<String, dynamic> data) =>
      ((data['invites'] as List?) ?? const [])
          .whereType<Map>()
          .map((i) => WorkspaceInviteDto.fromJson(i.cast<String, dynamic>()))
          .toList();
}

/// The username refusal [error] carries, or null when it is another error.
UsernameRefusal? usernameRefusalOf(Object? error) {
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.validation ||
      error.data is! Map) {
    return null;
  }
  final kind = (error.data! as Map)['kind'];
  return UsernameRefusal.values.where((r) => r.errorKind == kind).firstOrNull;
}
