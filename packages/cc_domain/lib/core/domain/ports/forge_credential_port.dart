import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Server-side resolution and storage of per-forge credentials.
///
/// Keyed by forge (one workspace may hold several). Optional `userId`: with a
/// user → their credential (sign-in/paste); without → app install token, then
/// server owner's, then environment (webhooks/pollers have no caller).
/// Precedence is fixed. Tokens never cross the RPC boundary — [connections]
/// for clients, [tokenFor] server-internal; never log a token.
abstract interface class ForgeCredentialPort {
  /// The resolved token for [forge], or null when none is configured.
  ///
  /// Server-internal: callers are the HTTP clients and the git plumbing.
  Future<String?> tokenFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  });

  /// Stores [token] as [userId]'s credential for [forge]. An empty token
  /// clears it, falling back to the next source in precedence.
  ///
  /// Takes effect immediately: the token is read per request, so a user who
  /// pastes one does not restart the server to use it.
  ///
  /// A GitHub [workspaceId] writes the overlay for that workspace and does
  /// not overwrite the global onboarding slot.
  Future<void> setToken(
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

  /// The current connection state of every supported forge, in
  /// [ForgeHost.supported] order. Never carries a token.
  Future<List<ForgeConnection>> connections({
    String? userId,
    String? workspaceId,
  });

  /// Re-probes [forge] and returns its connection state, refreshing the cached
  /// viewer identity. Backs the "test connection" affordance in Settings.
  Future<ForgeConnection> testConnection(
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
