import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// The server-secret half of per-forge credentials: the tokens themselves.
///
/// Keyed by forge (one workspace may hold several). With a `userId` → that
/// person's own credential (sign-in or pasted token), nobody else's. Without
/// one, every forge answers nothing: automation reaches GitHub only through a
/// one-repository App token bounded by an accountable human
/// (`GitHubClients.mintScoped`/`forOwner`), and GitLab or Bitbucket only
/// through the repository's or workspace's automation token (a project/group
/// or repository/workspace access token an admin stored), never a person's,
/// the server owner's or the environment's.
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

  /// Stores [token] as [userId]'s one credential for [forge] on this server,
  /// used in every workspace, and answers the connection as the forge now
  /// sees it, probed with the new token so a rejected paste reads as needing
  /// a new one.
  ///
  /// Takes effect immediately: the token is read per request. GitHub is
  /// sign-in only and refuses a pasted token.
  Future<ForgeConnection> setToken(
    ForgeHost forge,
    String token, {
    String? userId,
  });

  /// Clears [userId]'s credential in effect for [forge] in [workspaceId]
  /// (a GitHub sign-in kept for that workspace when one is in effect there,
  /// else the person's server-wide credential) and answers the scope it
  /// cleared, or null when nothing was stored.
  Future<ForgeCredentialScope?> clearToken(
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

  /// The connection state of one [forge].
  Future<ForgeConnection> connection(
    ForgeHost forge, {
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
