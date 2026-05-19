import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// Per-user provider credentials for the headless server.
///
/// Every credential a HUMAN owns lives here, keyed by their user id: the token
/// they minted by signing in to a forge, the one they pasted, the ticketing
/// key. Nothing is held on the client — a thin client that stored a token
/// would put the same secret on every machine the operator signs in from, and
/// a phone has no keychain we control.
///
/// Secrets live in the server's single [FileSecretsStore] (composition, not a
/// second file): one on-disk map, one in-memory cache, the same 0600
/// host-filesystem trust boundary as the device PSKs. Keys are namespaced
/// (`user_forge_<forge>_<userId>`) so they can never collide with device ids.
///
/// Tokens are write-only from the API's point of view: callers can store,
/// delete and probe for presence, and the resolution paths read the raw value —
/// but nothing here (or in the RPC surface above it) ever returns a stored
/// token to a client or writes one to a log.
class UserCredentialsStore {
  /// Creates a store over the server's shared secrets file.
  UserCredentialsStore(this._secrets);

  final FileSecretsStore _secrets;

  static String _forgeKey(ForgeHost forge, String userId) =>
      'user_forge_${forge.wire}_$userId';

  static String _ticketKey(TicketProvider provider, String userId) =>
      'user_ticket_${provider.name}_$userId';

  /// [userId]'s credential for [forge], or null when they have none.
  Future<ProviderToken?> forgeToken(String userId, ForgeHost forge) =>
      _secrets.readPsk(_forgeKey(forge, userId)).then(ProviderToken.tryParse);

  /// Stores [token] as [userId]'s credential for [forge].
  Future<void> setForgeToken(
    String userId,
    ForgeHost forge,
    ProviderToken token,
  ) async {
    if (token.accessToken.isEmpty) {
      await clearForgeToken(userId, forge);
      return;
    }
    await _secrets.writePsk(_forgeKey(forge, userId), token.encode());
  }

  /// Removes [userId]'s credential for [forge].
  Future<void> clearForgeToken(String userId, ForgeHost forge) =>
      _secrets.deletePsk(_forgeKey(forge, userId));

  /// Whether [userId] has a credential for [forge] (presence only — the value
  /// itself is never exposed).
  Future<bool> hasForgeToken(String userId, ForgeHost forge) async =>
      (await forgeToken(userId, forge)) != null;

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
  Future<void> setGitHubToken(String userId, String token) => setForgeToken(
    userId,
    ForgeHost.github,
    ProviderToken(accessToken: token),
  );

  /// Removes [userId]'s stored GitHub token, if any.
  Future<void> deleteGitHubToken(String userId) =>
      clearForgeToken(userId, ForgeHost.github);

  /// Whether [userId] has a GitHub token configured.
  Future<bool> hasGitHubToken(String userId) =>
      hasForgeToken(userId, ForgeHost.github);
}
