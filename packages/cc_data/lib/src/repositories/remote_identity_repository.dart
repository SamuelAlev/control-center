import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The session's resolved identity: the authenticated user, the device the
/// session rides on, and every workspace membership.
class IdentityMe {
  /// Creates an [IdentityMe].
  const IdentityMe({
    required this.user,
    required this.deviceId,
    required this.isServerOwner,
    required this.memberships,
  });

  /// Decodes the `identity.me` payload.
  factory IdentityMe.fromJson(Map<String, dynamic> json) => IdentityMe(
    user: UserDto.fromJson((json['user'] as Map).cast<String, dynamic>()),
    deviceId: json['device_id'] as String? ?? '',
    isServerOwner: json['is_server_owner'] as bool? ?? false,
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
/// invites, per-user preferences, and the audit trail. The server resolves
/// the acting user from the session — none of these calls carry a user id
/// for "self" operations.
class RemoteIdentityRepository {
  /// Creates a [RemoteIdentityRepository] over [_client].
  RemoteIdentityRepository(this._client);

  final RemoteRpcClient _client;

  /// The session's resolved identity.
  Future<IdentityMe> me() async =>
      IdentityMe.fromJson(await _client.call('identity.me', const {}));

  /// Users visible to the caller (self + co-members; the owner sees all).
  Future<List<UserDto>> listUsers() async {
    final data = await _client.call('users.list', const {});
    return _users(data);
  }

  /// Live stream of all users (authorship display).
  Stream<List<UserDto>> watchUsers() =>
      _client.subscribe('users.watchAll', const {}).map(_users);

  /// Updates the caller's own profile fields (null leaves a field unchanged).
  Future<UserDto> updateProfile({
    String? displayName,
    String? email,
    String? avatarRef,
    String? gitAuthorName,
    String? gitAuthorEmail,
  }) async {
    final data = await _client.call('users.updateProfile', {
      'display_name': ?displayName,
      'email': ?email,
      'avatar_ref': ?avatarRef,
      'git_author_name': ?gitAuthorName,
      'git_author_email': ?gitAuthorEmail,
    });
    return UserDto.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

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
  Future<void> setRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
    String level,
  ) => _client.call('members.setRepoGrant', {
    'workspace_id': workspaceId,
    'user_id': userId,
    'repo_id': repoId,
    'level': level,
  });

  /// Mints an invite; returns the metadata, the ONE-TIME code, the server's
  /// redemption URL (derived from the live descriptor — empty when the host
  /// advertises no off-loopback path), and the live [ConnectionDescriptor]
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

  /// Live audit trail of [workspaceId], newest first.
  Stream<List<UserActivityDto>> watchActivity(String workspaceId) => _client
      .subscribe('activity.watchForWorkspace', {'workspace_id': workspaceId})
      .map(_activity);

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

  static List<UserActivityDto> _activity(Map<String, dynamic> data) =>
      ((data['entries'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => UserActivityDto.fromJson(e.cast<String, dynamic>()))
          .toList();
}
