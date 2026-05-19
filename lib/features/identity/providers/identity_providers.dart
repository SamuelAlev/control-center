import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/settings/user_preference_sync.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The identity & membership data surface (who am I, users, members, invites,
/// per-user prefs, audit trail) over the RPC client.
final identityRepositoryProvider = Provider<RemoteIdentityRepository>(
  (ref) => RemoteIdentityRepository(ref.watch(rpcClientProvider)),
);

/// The session's resolved identity: the authenticated user + memberships.
/// Loaded once per connection; `refresh` after profile edits.
final currentIdentityProvider = FutureProvider<IdentityMe>(
  (ref) => ref.watch(identityRepositoryProvider).me(),
);

/// The authenticated user's id, or null while identity is still loading.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentIdentityProvider).value?.user.id,
);

/// Live users visible to this session, keyed by id — the lookup behind
/// message authorship, member rosters, and audit rows.
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

/// Live invites of one workspace (admin surface).
final workspaceInvitesProvider =
    StreamProvider.family<List<WorkspaceInviteDto>, String>(
      (ref, workspaceId) =>
          ref.watch(identityRepositoryProvider).watchInvites(workspaceId),
    );

/// Live audit trail of one workspace, newest first.
final workspaceActivityProvider =
    StreamProvider.family<List<UserActivityDto>, String>(
      (ref, workspaceId) =>
          ref.watch(identityRepositoryProvider).watchActivity(workspaceId),
    );

/// Live stream of the current user's own server-side preferences.
final ownServerPrefsProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(identityRepositoryProvider).watchOwnPrefs(),
);

/// Two-way per-user preference sync: a user's setup follows them across
/// desktop, web, and phone.
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

/// Resolves a display name for a principal id of the given type. Falls back
/// to a shortened id while the directory is still loading.
String principalDisplayName(
  Ref ref, {
  required String principalId,
  required PrincipalType type,
  String? agentName,
}) {
  if (type == PrincipalType.agent) {
    return agentName ?? principalId;
  }
  final users = ref.read(usersByIdProvider).value;
  return users?[principalId]?.displayName ??
      (principalId.length > 8 ? principalId.substring(0, 8) : principalId);
}
