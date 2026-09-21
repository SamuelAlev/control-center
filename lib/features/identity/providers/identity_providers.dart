import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
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

/// The authenticated user's id, or null while identity is still loading.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentIdentityProvider).value?.user.id,
);

/// Whether the signed-in user is this INSTALL's operator (the recorded server
/// owner), as reported by `identity.me`.
///
/// Gates the install-wide settings surfaces — SSO, MCP, provider apps, model
/// management, backups — which the server refuses for anyone else
/// (`ServerAuthority.serverOwner` / `requireServerAdmin`). False while
/// identity is still loading, so a surface never flashes open and then
/// closes: the fail-safe direction is hiding an operator's own control for a
/// moment, not offering a control the server will refuse.
final isServerOwnerProvider = Provider<bool>(
  (ref) => ref.watch(currentIdentityProvider).value?.isServerOwner ?? false,
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

/// Live invites of one workspace (admin surface).
final workspaceInvitesProvider =
    StreamProvider.family<List<WorkspaceInviteDto>, String>(
      (ref, workspaceId) =>
          ref.watch(identityRepositoryProvider).watchInvites(workspaceId),
    );

/// Live cursor page of one workspace's audit trail.
final workspaceActivityPageProvider =
    StreamProvider.family<UserActivityPageDto, WorkspaceActivityPageQuery>(
      (ref, query) => ref
          .watch(identityRepositoryProvider)
          .watchActivityPage(
            query.workspaceId,
            cursor: query.cursor,
            query: query.search,
            ip: query.ip,
            countryCode: query.countryCode,
            localNetwork: query.localNetwork,
            userIds: query.userIds,
          ),
    );

/// Arguments for [workspaceActivityPageProvider] — workspace, cursor and
/// the filters the table sends with each page.
class WorkspaceActivityPageQuery {
  /// Creates a [WorkspaceActivityPageQuery].
  const WorkspaceActivityPageQuery({
    required this.workspaceId,
    this.cursor,
    this.search = '',
    this.ip,
    this.countryCode,
    this.localNetwork = false,
    this.userIds = const [],
  });

  /// Workspace whose trail is shown.
  final String workspaceId;

  /// Opaque page cursor (`?cursor=`), or null for the newest page.
  final String? cursor;

  /// Case-insensitive substring over action / target / IP / details.
  final String search;

  /// Exact client IP filter.
  final String? ip;

  /// Exact ISO country-code filter.
  final String? countryCode;

  /// Private/loopback rows with no GeoIP country.
  final bool localNetwork;

  /// Actor ids whose display name matched [search].
  final List<String> userIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceActivityPageQuery &&
          workspaceId == other.workspaceId &&
          cursor == other.cursor &&
          search == other.search &&
          ip == other.ip &&
          countryCode == other.countryCode &&
          localNetwork == other.localNetwork &&
          _idsEqual(userIds, other.userIds);

  @override
  int get hashCode => Object.hash(
    workspaceId,
    cursor,
    search,
    ip,
    countryCode,
    localNetwork,
    Object.hashAll(userIds),
  );
}

bool _idsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

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

