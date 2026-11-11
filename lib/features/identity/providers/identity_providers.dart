import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/settings/user_preference_sync.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The identity & membership data surface (who am I, users, members, invites,
/// per-user prefs, audit trail) over the RPC client.
final identityRepositoryProvider = Provider<RemoteIdentityRepository>(
  (ref) => RemoteIdentityRepository(ref.watch(rpcClientProvider)),
);

/// The session's resolved identity: the authenticated user + memberships.
///
/// Watches the active workspace so Workspace → Profile shows that workspace's
/// overlay (name, email, git author) rather than a stale global snapshot.
final currentIdentityProvider = FutureProvider<IdentityMe>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return ref.watch(identityRepositoryProvider).me(workspaceId: workspaceId);
});

/// The authenticated user, retained through outages but never through denial.
final currentUserIdProvider = Provider<String?>((ref) {
  final identity = ref.watch(currentIdentityProvider);
  final error = identity.error;
  if (error is RemoteRpcException &&
      (error.code == RpcErrorCodes.unauthorized ||
          error.code == RpcErrorCodes.workspaceMismatch ||
          error.code == RpcErrorCodes.notFound)) {
    return null;
  }
  return identity.value?.user.id;
});

/// Whether the signed-in user is this INSTALL's operator (the recorded server
/// owner), as reported by `identity.me`.
///
/// Gates the install-wide settings surfaces — SSO, MCP, provider apps, model
/// management, backups — which the server refuses for anyone else
/// (the declared `ServerAuthority.serverOwner` authority). False while
/// identity is still loading, so a surface never flashes open and then
/// closes: the fail-safe direction is hiding an operator's own control for a
/// moment, not offering a control the server will refuse.
final isServerOwnerProvider = Provider<bool>(
  (ref) => ref.watch(currentIdentityProvider).value?.isServerOwner ?? false,
);

/// Whether this user administers at least one workspace, as `identity.me`
/// reports their memberships. False while identity is loading.
final isWorkspaceAdminAnywhereProvider = Provider<bool>((ref) {
  final memberships =
      ref.watch(currentIdentityProvider).value?.memberships ?? const [];
  return memberships.any(
    (m) => WorkspaceRole.fromWire(m.role)?.isAdmin ?? false,
  );
});

/// Whether this user may create workspaces, as `identity.me` reports it.
///
/// Every "new workspace" affordance follows this, never [isServerOwnerProvider]:
/// the server decides who may create, and today that is only its owner.
/// False while identity is loading, so a create action never flashes open.
final canCreateWorkspacesProvider = Provider<bool>(
  (ref) =>
      ref.watch(currentIdentityProvider).value?.canCreateWorkspaces ?? false,
);

/// Whether this user may run unsandboxed on the server host, as
/// `identity.me` reports it (`can_use_host`).
///
/// Gates the host shell, the embedded code-server editor and every "open in
/// editor" affordance. False while identity is loading, like the create right.
final canUseHostProvider = Provider<bool>(
  (ref) => ref.watch(currentIdentityProvider).value?.canUseHost ?? false,
);

/// Live users visible to this session, keyed by id — the lookup behind
/// message authorship, member rosters and audit rows.
final usersByIdProvider = StreamProvider<Map<String, UserDto>>(
  (ref) => ref
      .watch(identityRepositoryProvider)
      .watchUsers()
      .map((users) => {for (final u in users) u.id: u}),
);

/// Live members of one workspace.
final workspaceMembersProvider =
    StreamProvider.family<List<WorkspaceMemberDto>, String>(
      (ref, workspaceId) =>
          ref.watch(identityRepositoryProvider).watchMembers(workspaceId),
    );

/// The current user's role in one workspace (null while loading / not a
/// member). Drives role-dependent UI (hide admin affordances from members).
final myWorkspaceRoleProvider = Provider.family<WorkspaceRole?, String>((
  ref,
  workspaceId,
) {
  final me = ref.watch(currentIdentityProvider).value;
  return WorkspaceRole.fromWire(me?.roleIn(workspaceId));
});

/// The names of `workspaceId`'s admins, for "ask an admin" copy shown to a
/// member who cannot fix something themselves. Empty while loading.
final workspaceAdminNamesProvider = Provider.family<List<String>, String>((
  ref,
  workspaceId,
) {
  final members =
      ref.watch(workspaceMembersProvider(workspaceId)).value ?? const [];
  final users = ref.watch(usersByIdProvider).value ?? const {};
  return [
    for (final m in members)
      if (WorkspaceRole.fromWire(m.role)?.isAdmin ?? false)
        if ([m.displayName, users[m.userId]?.displayName, m.email].firstWhere(
              (n) => n != null && n.trim().isNotEmpty,
              orElse: () => null,
            )
            case final name?)
          name.trim(),
  ];
});

/// Live invites of one workspace (admin surface).
final workspaceInvitesProvider =
    StreamProvider.family<List<WorkspaceInviteDto>, String>(
      (ref, workspaceId) =>
          ref.watch(identityRepositoryProvider).watchInvites(workspaceId),
    );

/// Live stream of the current user's own server-side preferences.
final ownServerPrefsProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(identityRepositoryProvider).watchOwnPrefs(),
);

/// Two-way per-user preference sync: a user's setup follows them across
/// desktop, web and phone.
///
/// Drives the declarative registry in `di/synced_preferences.dart` — adding a
/// synced key is one entry there, not another listener here.
///
/// Pull applies the server's value to the local store and refreshes its
/// readers. Push observes the key-value STORE rather than N providers, so a
/// write from anywhere is caught. The first snapshot runs the one-time
/// promotion pass, which seeds the server from this device's local values
/// exactly once per key; pushes stay disarmed until it resolves, so a local
/// write racing the pass cannot push a value the pass is about to reconcile.
///
/// See [UserPreferenceSync] for the loop-safety and promotion-marker rules.
/// Activated once at the app root.
final userPreferencesSyncProvider = Provider<void>((ref) {
  final sync = UserPreferenceSync(
    ref: ref,
    registry: buildSyncedPreferences(),
    push: ref.read(identityRepositoryProvider).prefsSet,
  );
  ref.onDispose(sync.dispose);

  var bootstrapped = false;
  ref.listen(ownServerPrefsProvider, fireImmediately: true, (previous, next) {
    final server = next.value;
    if (server == null) {
      return;
    }
    if (!bootstrapped) {
      bootstrapped = true;
      unawaited(sync.bootstrap(server));
      return;
    }
    sync.applyServerSnapshot(server);
  });
});

/// The current user's own devices (list / rename / revoke).
final ownDevicesProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(rpcClientProvider)
      .subscribe('pairing.watchOwn', const {})
      .map(
        (data) => ((data['devices'] as List?) ?? const [])
            .whereType<Map>()
            .map((d) => d.cast<String, dynamic>())
            .toList(),
      ),
);
