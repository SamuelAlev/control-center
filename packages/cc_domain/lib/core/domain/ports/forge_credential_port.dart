import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// The server-secret half of per-forge credentials: the tokens themselves.
///
/// Keyed by forge (one workspace may hold several). With a `userId` → that
/// person's own credential (sign-in or pasted token), nobody else's. Without
/// one, GitHub answers nothing: automation reaches GitHub only through a
/// one-repository App token bounded by an accountable human
/// (`GitHubClients.mintScoped`/`forOwner`), never a person's, the server
/// owner's or the environment's. A token-only forge (GitLab, Bitbucket) answers
/// the server owner's pasted token, then the environment, for work no person is
/// doing.
///
/// Server-internal: implementations and callers never let a token cross the
/// RPC boundary or reach a log. What clients see is [ForgeConnectionView].
abstract interface class ForgeTokenStore {
  /// The resolved token for [forge], or null when none is configured.
  ///
  /// Callers are the HTTP clients and the git plumbing.
  Future<String?> tokenFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  });

  /// Stores [token] as [userId]'s credential for [forge] and answers the
  /// connection as the forge now sees it, probed with the new token so a
  /// rejected paste reads as unauthenticated with a reason.
  ///
  /// Takes effect immediately: the token is read per request, so a user who
  /// pastes one does not restart the server to use it. GitHub is sign-in only
  /// and refuses a pasted token.
  Future<ForgeConnection> setToken(
    ForgeHost forge,
    String token, {
    String? userId,
    String? workspaceId,
  });

  /// Clears [userId]'s stored credential for [forge].
  Future<void> clearToken(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  });
}

/// The client-view half of per-forge credentials: connection state and
/// identity, never a token. Backs `forge.listConnections` and every
/// "is this mine?" lookup on the server.
abstract interface class ForgeConnectionView {
  /// The current connection state of every supported forge, in
  /// [ForgeHost.supported] order.
  Future<List<ForgeConnection>> connections({
    String? userId,
    String? workspaceId,
  });

  /// The account name on [forge], or an empty string when unknown.
  ///
  /// The per-forge identity that "is this mine?" resolves through — the same
  /// human is a different account on each forge, so this is asked once per
  /// forge rather than compared against one global login.
  Future<String> viewerLogin(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  });
}
