import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Server-side resolution and storage of per-forge credentials.
///
/// One workspace may hold repos on several forges, so there is no single "the
/// token" any more: every forge-touching call resolves its credential through
/// here, keyed by the forge of the repo it is acting on.
///
/// Every method takes an optional `userId`, and that argument is the whole
/// model:
///
///  * **With a user** — the credential that BELONGS to them, minted by signing
///    in or pasted by them. This is what an identity read ("am I connected?"),
///    an agent run they started and a private asset they are looking at
///    resolve through, so work is attributed to the human who asked for it.
///  * **Without one** — the server acting as itself: its app installation
///    token, then the server owner's own credential, then the environment.
///    Webhooks, polling and sync have no caller, and having them silently ride
///    on whichever human onboarded first is how forge access disappears when
///    that person leaves.
///
/// The precedence inside each lane is fixed rather than configurable so that
/// "I pasted a token and nothing changed" is never a supported outcome.
///
/// **Tokens never cross the RPC boundary.** [connections] is what clients see;
/// [tokenFor] is server-internal. Implementations must not log a token or put
/// one in an error message.
abstract interface class ForgeCredentialPort {
  /// The resolved token for [forge], or null when none is configured.
  ///
  /// Server-internal: callers are the HTTP clients and the git plumbing.
  Future<String?> tokenFor(ForgeHost forge, {String? userId});

  /// Stores [token] as [userId]'s credential for [forge]. An empty token
  /// clears it, falling back to the next source in precedence.
  ///
  /// Takes effect immediately: the token is read per request, so a user who
  /// pastes one does not restart the server to use it.
  Future<void> setToken(ForgeHost forge, String token, {String? userId});

  /// Clears [userId]'s stored credential for [forge].
  Future<void> clearToken(ForgeHost forge, {String? userId});

  /// The current connection state of every supported forge, in
  /// [ForgeHost.supported] order. Never carries a token.
  Future<List<ForgeConnection>> connections({String? userId});

  /// Re-probes [forge] and returns its connection state, refreshing the cached
  /// viewer identity. Backs the "test connection" affordance in Settings.
  Future<ForgeConnection> testConnection(ForgeHost forge, {String? userId});

  /// The account name on [forge], or an empty string when unknown.
  ///
  /// The per-forge identity that "is this mine?" resolves through — the same
  /// human is a different account on each forge, so this is asked once per
  /// forge rather than compared against one global login.
  Future<String> viewerLogin(ForgeHost forge, {String? userId});
}
