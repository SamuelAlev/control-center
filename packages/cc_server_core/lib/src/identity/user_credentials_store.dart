import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// Per-user forge/ticketing credentials on the server (never on clients).
///
/// Lives in [FileSecretsStore] under `user_forge_*` / workspace overlay keys. Write-only to clients.
class UserCredentialsStore {
  /// Creates a store over the server's shared secrets file.
  UserCredentialsStore(this._secrets);

  final FileSecretsStore _secrets;

  /// Secrets-file key for [userId]'s [forge] credential.
  ///
  /// When [workspaceId] is set this is the overlay for that workspace; when
  /// omitted it is the global onboarding slot.
  static String forgeKey(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) {
    final base = 'user_forge_${forge.wire}_$userId';
    if (workspaceId == null || workspaceId.isEmpty) {
      return base;
    }
    return '${base}_$workspaceId';
  }

  static String _ticketKey(TicketProvider provider, String userId) =>
      'user_ticket_${provider.name}_$userId';

  /// [userId]'s credential for [forge], or null when they have none.
  ///
  /// A non-empty [workspaceId] reads the overlay for that workspace only —
  /// it does not fall back to the global slot. Callers that want the inherit
  /// chain (overlay then onboarding) do that themselves.
  Future<ProviderToken?> forgeToken(
    String userId,
    ForgeHost forge, {
    String? workspaceId,
  }) => _secrets
      .readPsk(forgeKey(forge, userId, workspaceId: workspaceId))
      .then(ProviderToken.tryParse);

  /// Stores [token] as [userId]'s credential for [forge].
  Future<void> setForgeToken(
    String userId,
    ForgeHost forge,
    ProviderToken token, {
    String? workspaceId,
  }) async {
    if (token.accessToken.isEmpty) {
      await clearForgeToken(userId, forge, workspaceId: workspaceId);
      return;
    }
    await _secrets.writePsk(
      forgeKey(forge, userId, workspaceId: workspaceId),
      token.encode(),
    );
  }

  /// Removes [userId]'s credential for [forge].
  Future<void> clearForgeToken(
    String userId,
    ForgeHost forge, {
    String? workspaceId,
  }) => _secrets.deletePsk(forgeKey(forge, userId, workspaceId: workspaceId));

  /// Whether [userId] has a credential for [forge] (presence only — the value
  /// itself is never exposed).
  Future<bool> hasForgeToken(
    String userId,
    ForgeHost forge, {
    String? workspaceId,
  }) async =>
      (await forgeToken(userId, forge, workspaceId: workspaceId)) != null;

  /// [userId]'s credential for the ticketing [provider], or null.
  Future<ProviderToken?> ticketToken(
    String userId,
    TicketProvider provider,
  ) async => ProviderToken.tryParse(
    await _secrets.readPsk(_ticketKey(provider, userId)),
  );

  /// Stores [token] as [userId]'s credential for the ticketing [provider].
  Future<void> setTicketToken(
    String userId,
    TicketProvider provider,
    ProviderToken token,
  ) async {
    if (token.accessToken.isEmpty) {
      await clearTicketToken(userId, provider);
      return;
    }
    await _secrets.writePsk(_ticketKey(provider, userId), token.encode());
  }

  /// Removes [userId]'s credential for the ticketing [provider].
  Future<void> clearTicketToken(String userId, TicketProvider provider) =>
      _secrets.deletePsk(_ticketKey(provider, userId));

  /// Whether [userId] has a credential for the ticketing [provider].
  Future<bool> hasTicketToken(String userId, TicketProvider provider) async =>
      (await ticketToken(userId, provider)) != null;

  /// Stores a pasted GitHub token for [userId]. An empty token deletes the
  /// entry (the member reverts to the server's app credential).
  Future<void> setGitHubToken(
    String userId,
    String token, {
    String? workspaceId,
  }) => setForgeToken(
    userId,
    ForgeHost.github,
    ProviderToken(accessToken: token),
    workspaceId: workspaceId,
  );

  /// Whether [userId] has a GitHub token configured.
  Future<bool> hasGitHubToken(String userId, {String? workspaceId}) =>
      hasForgeToken(userId, ForgeHost.github, workspaceId: workspaceId);
}
