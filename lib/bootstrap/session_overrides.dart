import 'package:cc_data/cc_data.dart' show RemoteIdentityRepository;
import 'package:cc_rpc/cc_rpc.dart'
    show RemoteRpcClient, ServerConnectionSupervisor;
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// The provider overrides every connected session installs, on desktop and
/// web alike: the connected client and the services beside it, the
/// platform's preference and secret stores, the server switch / sign-in
/// actions and the session's [SessionScope].
///
/// One list, so the two composition roots cannot drift apart; [platform]
/// carries what only one of them has (desktop media playback, the tray shell).
List<Override> sessionOverrides({
  required RemoteRpcClient client,
  required ServerConnectionSupervisor supervisor,
  required MediaProxyConfig? mediaProxy,
  required ObservableKeyValueBackend prefsBackend,
  required SecureStore secureStore,
  required SessionScope? scope,
  required Future<void> Function(String serverId) switchServer,
  required Future<void> Function() returnToSignIn,
  List<Override> platform = const [],
}) => [
  rpcClientProvider.overrideWithValue(client),
  // The bulk-content lane, beside the RPC client it belongs with. The composer
  // uploads an attached picture over HTTP because the RPC socket refuses a
  // frame that size; the notifier doing it has no BuildContext, so
  // MediaProxyScope alone is not enough.
  mediaProxyConfigProvider.overrideWithValue(mediaProxy),
  serverConnectionSupervisorProvider.overrideWithValue(supervisor),
  // Leaving this session (another server, or back to sign-in) drops the
  // offline queue first: nothing queued here may replay as the next one.
  serverSwitchHandlerProvider.overrideWith(
    (ref) => (serverId) async {
      await ref
          .read(offlineQueueControllerProvider.notifier)
          .discardForSessionEnd();
      await switchServer(serverId);
    },
  ),
  returnToServerSignInProvider.overrideWith(
    (ref) => () async {
      await ref
          .read(offlineQueueControllerProvider.notifier)
          .discardForSessionEnd();
      await returnToSignIn();
    },
  ),
  // One store per process, shared with the pre-app surfaces: a server choice
  // or appearance change made there is what the connected app reads.
  appPreferencesProvider.overrideWithValue(AppPreferences(prefsBackend)),
  keyValueBackendProvider.overrideWithValue(prefsBackend),
  secureStoreProvider.overrideWithValue(secureStore),
  sessionScopeProvider.overrideWithValue(scope),
  ...platform,
];

/// Resolves the [SessionScope] for a fresh connection: the server's identity
/// from [supervisor] and the signed-in user from `identity.me`.
///
/// Throws when `identity.me` fails or names no user, so a root that treats it
/// as admission can fall back to its sign-in surface.
Future<SessionScope> resolveSessionScope(
  RemoteRpcClient client,
  ServerConnectionSupervisor supervisor,
) async {
  final me = await RemoteIdentityRepository(client).me();
  return SessionScope(
    serverId: supervisor.descriptor.serverId,
    userId: me.user.id,
  );
}

/// Admission for a root that refuses a connection whose user it cannot name
/// (the web gate): the connection's [SessionScope], or — when `identity.me`
/// fails — [dispose] is awaited and the failure rethrown, so the root shows
/// its connect surface with the error and no half-admitted connection leaks.
Future<SessionScope> admitSessionScope(
  RemoteRpcClient client,
  ServerConnectionSupervisor supervisor, {
  required Future<void> Function() dispose,
}) async {
  try {
    return await resolveSessionScope(client, supervisor);
  } on Object {
    await dispose();
    rethrow;
  }
}

/// The [SessionScope] for a root that keeps the connection either way (the
/// desktop, whose backend is already up): null when `identity.me` fails.
///
/// A null scope is never filled in later in the session. Every scoped cache
/// then neither reads nor writes — the onboarding gate holds the splash until
/// its live checks settle and no remembered workspace id is offered — so the
/// session waits for live answers instead of guessing from another server's
/// or user's data. Adopting a scope mid-session would rebuild the active
/// workspace from the cache and overrule the route.
Future<SessionScope?> tryResolveSessionScope(
  RemoteRpcClient client,
  ServerConnectionSupervisor supervisor, {
  void Function(Object error)? onError,
}) async {
  try {
    return await resolveSessionScope(client, supervisor);
  } on Object catch (e) {
    onError?.call(e);
    return null;
  }
}
