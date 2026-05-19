import 'package:cc_server_core/src/file_secrets_store.dart';

/// Per-user credential store for the headless server.
///
/// Each member may store their OWN GitHub token so runs they request act under
/// their GitHub identity instead of the server owner's PAT. Secrets live in the
/// server's single [FileSecretsStore] (composition, not a second file): one
/// on-disk map, one in-memory cache, the same 0600 host-filesystem trust
/// boundary as the device PSKs. Entries are namespaced with a
/// `user_github_token_<userId>` key so they can never collide with device ids.
///
/// Tokens are write-only from the API's point of view: callers can store,
/// delete and probe for presence and the dispatch path reads the raw value —
/// but nothing here (or in the RPC surface above it) ever returns a stored
/// token to a client or writes one to a log.
class UserCredentialsStore {
  /// Creates a store over the server's shared secrets file.
  UserCredentialsStore(this._secrets);

  final FileSecretsStore _secrets;

  static String _gitHubKey(String userId) => 'user_github_token_$userId';

  /// Stores [token] as [userId]'s own GitHub token. An empty token deletes the
  /// entry (the member reverts to the server's broker-provided credential).
  Future<void> setGitHubToken(String userId, String token) async {
    if (token.isEmpty) {
      await _secrets.deletePsk(_gitHubKey(userId));
      return;
    }
    await _secrets.writePsk(_gitHubKey(userId), token);
  }

  /// Removes [userId]'s stored GitHub token, if any.
  Future<void> deleteGitHubToken(String userId) =>
      _secrets.deletePsk(_gitHubKey(userId));

  /// The stored GitHub token for [userId], or null when none is configured.
  /// Read only by the dispatch env assembly — never surfaced to clients.
  Future<String?> gitHubToken(String userId) =>
      _secrets.readPsk(_gitHubKey(userId));

  /// Whether [userId] has a GitHub token configured (presence only — the
  /// value itself is never exposed).
  Future<bool> hasGitHubToken(String userId) async {
    final token = await _secrets.readPsk(_gitHubKey(userId));
    return token != null && token.isNotEmpty;
  }
}
