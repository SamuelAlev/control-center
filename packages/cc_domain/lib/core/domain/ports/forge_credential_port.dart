import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Server-side resolution and storage of per-forge credentials.
///
/// One workspace may hold repos on several forges, so there is no single
/// "the token" any more: every forge-touching call resolves its credential
/// through here, keyed by the forge of the repo it is acting on.
///
/// Resolution precedence is [ForgeCredentialSource]'s declaration order —
/// Settings, then environment, then a logged-in vendor CLI. The precedence is
/// fixed rather than configurable so that "I pasted a token and nothing
/// changed" is never a supported outcome.
///
/// **Tokens never cross the RPC boundary.** [connections] is what clients see;
/// [tokenFor] is server-internal. Implementations must not log a token or put
/// one in an error message.
abstract interface class ForgeCredentialPort {
  /// The resolved token for [forge], or null when none is configured.
  ///
  /// Server-internal: callers are the HTTP clients and the git plumbing.
  Future<String?> tokenFor(ForgeHost forge);

  /// Stores [token] as the Settings-sourced credential for [forge]. An empty
  /// token clears it, falling back to the next source in precedence.
  ///
  /// Takes effect immediately: any cached HTTP client for [forge] is rebuilt on
  /// the next call, so an operator who pastes a token does not restart the
  /// server to use it.
  Future<void> setToken(ForgeHost forge, String token);

  /// Clears the Settings-sourced credential for [forge].
  Future<void> clearToken(ForgeHost forge);

  /// The current connection state of every supported forge, in
  /// [ForgeHost.supported] order. Never carries a token.
  Future<List<ForgeConnection>> connections();

  /// Re-probes [forge] and returns its connection state, refreshing the cached
  /// viewer identity. Backs the "test connection" affordance in Settings.
  Future<ForgeConnection> testConnection(ForgeHost forge);

  /// The operator's account name on [forge], or an empty string when unknown.
  ///
  /// The per-forge identity that "is this mine?" resolves through — the same
  /// human is a different account on each forge, so this is asked once per
  /// forge rather than compared against one global login.
  Future<String> viewerLogin(ForgeHost forge);
}
