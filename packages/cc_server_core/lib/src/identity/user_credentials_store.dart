import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// Per-user forge/ticketing credentials on the server (never on clients).
///
/// Lives in [FileSecretsStore] under `user_forge_*` / workspace overlay keys.
/// Write-only to clients. A Connect-sealed credential stores only its seal;
/// see [ProviderToken].
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

  /// Secrets-file key for [userId]'s ticketing [provider] credential: the
  /// person's global slot, or with [workspaceId] the slot of a workspace that
  /// signs people in to its own app.
  static String ticketKey(
    TicketProvider provider,
    String userId, {
    String? workspaceId,
  }) => workspaceId == null || workspaceId.isEmpty
      ? 'user_ticket_${provider.name}_$userId'
      : '${_workspaceTicketPrefix(provider)}$workspaceId:$userId';

  static String _workspaceTicketPrefix(TicketProvider provider) =>
      'workspace_ticket_${provider.name}:';

  /// True when [key] is a member's ticketing credential in [workspaceId]'s
  /// own slot.
  static bool isWorkspaceTicketKey(String key, String workspaceId) {
    for (final provider in TicketProvider.values) {
      if (key.startsWith('${_workspaceTicketPrefix(provider)}$workspaceId:')) {
        return true;
      }
    }
    return false;
  }

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
    if (!token.isSealed && token.accessToken.isEmpty) {
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
  ///
  /// A non-empty [workspaceId] reads that workspace's own slot only; it never
  /// falls back to the global one.
  Future<ProviderToken?> ticketToken(
    String userId,
    TicketProvider provider, {
    String? workspaceId,
  }) async => ProviderToken.tryParse(
    await _secrets.readPsk(
      ticketKey(provider, userId, workspaceId: workspaceId),
    ),
  );

  /// Stores [token] as [userId]'s credential for the ticketing [provider].
  Future<void> setTicketToken(
    String userId,
    TicketProvider provider,
    ProviderToken token, {
    String? workspaceId,
  }) async {
    if (!token.isSealed && token.accessToken.isEmpty) {
      await clearTicketToken(userId, provider, workspaceId: workspaceId);
      return;
    }
    await _secrets.writePsk(
      ticketKey(provider, userId, workspaceId: workspaceId),
      token.encode(),
    );
  }

  /// Removes [userId]'s credential for the ticketing [provider].
  Future<void> clearTicketToken(
    String userId,
    TicketProvider provider, {
    String? workspaceId,
  }) => _secrets.deletePsk(
    ticketKey(provider, userId, workspaceId: workspaceId),
  );

  /// Whether [userId] has a credential for the ticketing [provider].
  Future<bool> hasTicketToken(
    String userId,
    TicketProvider provider, {
    String? workspaceId,
  }) async =>
      (await ticketToken(userId, provider, workspaceId: workspaceId)) != null;

  /// Every user holding a global credential for the ticketing [provider].
  Future<List<String>> ticketUsers(TicketProvider provider) async {
    final prefix = 'user_ticket_${provider.name}_';
    return [
      for (final key in await _secrets.keysMatching(
        (key) => key.startsWith(prefix),
      ))
        key.substring(prefix.length),
    ];
  }

  /// Every `(workspace, user)` holding a credential for the ticketing
  /// [provider] in a workspace's own slot.
  Future<List<({String workspaceId, String userId})>> workspaceTicketSlots(
    TicketProvider provider,
  ) async {
    final prefix = _workspaceTicketPrefix(provider);
    return [
      for (final key in await _secrets.keysMatching(
        (key) => key.startsWith(prefix),
      ))
        if (key.indexOf(':', prefix.length) case final colon when colon > 0)
          (
            workspaceId: key.substring(prefix.length, colon),
            userId: key.substring(colon + 1),
          ),
    ];
  }

  /// Deletes every member's [provider] credential in [workspaceId]'s own slot
  /// and returns the tokens removed, so the caller can revoke them.
  Future<List<ProviderToken>> clearWorkspaceTicketTokens(
    String workspaceId,
    TicketProvider provider,
  ) async {
    final prefix = '${_workspaceTicketPrefix(provider)}$workspaceId:';
    final removed = <ProviderToken>[];
    for (final key in await _secrets.keysMatching(
      (key) => key.startsWith(prefix),
    )) {
      final token = ProviderToken.tryParse(await _secrets.readPsk(key));
      if (token != null) {
        removed.add(token);
      }
      await _secrets.deletePsk(key);
    }
    return removed;
  }
}
