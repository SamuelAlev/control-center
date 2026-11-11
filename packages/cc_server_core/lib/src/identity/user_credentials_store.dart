import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// Per-user forge/ticketing credentials on the server (never on clients).
///
/// Lives in [FileSecretsStore]: a person's global slot under `user_*` keys,
/// a workspace's own slot under `workspace_*:<workspaceId>:<userId>` keys.
/// Only a sign-in issued by an app has a workspace slot (GitHub, Linear, in a
/// workspace whose sign-in target differs from the server's); a pasted
/// GitLab or Bitbucket token is always in the global slot.
/// Write-only to clients. A Connect-sealed credential stores only its seal;
/// see [ProviderToken].
class UserCredentialsStore {
  /// Creates a store over the server's shared secrets file.
  UserCredentialsStore(this._secrets);

  final FileSecretsStore _secrets;

  /// Secrets-file key for [userId]'s [forge] credential: the global slot
  /// (`user_forge_<forge>_<userId>`), or with [workspaceId] that workspace's
  /// own slot (`workspace_forge_<forge>:<workspaceId>:<userId>`).
  ///
  /// The two shapes cannot collide: user and workspace ids never contain
  /// `:`, and user ids (UUIDs) never contain `_`, so a workspace-slot key is
  /// never read as a global one, nor one workspace's as another's.
  static String forgeKey(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) => workspaceId == null || workspaceId.isEmpty
      ? '${_globalForgePrefix(forge)}$userId'
      : '${_workspaceForgePrefix(forge, workspaceId)}$userId';

  static String _globalForgePrefix(ForgeHost forge) =>
      'user_forge_${forge.wire}_';

  static String _workspaceForgePrefix(ForgeHost forge, String workspaceId) =>
      'workspace_forge_${forge.wire}:$workspaceId:';

  static String _globalLapsePrefix(ForgeHost forge) =>
      'user_forge_lapsed_${forge.wire}_';

  static String _workspaceLapsePrefix(ForgeHost forge, String workspaceId) =>
      'workspace_forge_lapsed_${forge.wire}:$workspaceId:';

  /// The user id a global-slot key with [prefix] names, or null when [key]
  /// is not one.
  static String? _globalUserOf(String key, String prefix) {
    if (!key.startsWith(prefix)) {
      return null;
    }
    final userId = key.substring(prefix.length);
    return userId.isEmpty || userId.contains('_') || userId.contains(':')
        ? null
        : userId;
  }

  /// True when [key] is a member's forge credential or lapse marker in
  /// [workspaceId]'s own slot, for any forge.
  static bool isWorkspaceForgeKey(String key, String workspaceId) {
    if (workspaceId.isEmpty) {
      return false;
    }
    for (final forge in ForgeHost.values) {
      if (key.startsWith(_workspaceForgePrefix(forge, workspaceId)) ||
          key.startsWith(_workspaceLapsePrefix(forge, workspaceId))) {
        return true;
      }
    }
    return false;
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

  /// Every stored [forge] credential: each person's global one
  /// (`workspaceId` null) and each one in a workspace's own slot.
  Future<List<({String userId, String? workspaceId, ProviderToken token})>>
  forgeTokens(ForgeHost forge) async {
    final global = _globalForgePrefix(forge);
    final slots = 'workspace_forge_${forge.wire}:';
    final out = <({String userId, String? workspaceId, ProviderToken token})>[];
    for (final key in await _secrets.keysMatching(
      (key) => key.startsWith(global) || key.startsWith(slots),
    )) {
      final String userId;
      final String? workspaceId;
      final globalUser = _globalUserOf(key, global);
      if (globalUser != null) {
        userId = globalUser;
        workspaceId = null;
      } else if (key.startsWith(slots)) {
        final parts = key.substring(slots.length).split(':');
        if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
          continue;
        }
        workspaceId = parts[0];
        userId = parts[1];
      } else {
        continue;
      }
      final token = ProviderToken.tryParse(await _secrets.readPsk(key));
      if (token != null) {
        out.add((userId: userId, workspaceId: workspaceId, token: token));
      }
    }
    return out;
  }

  /// Deletes every member's [forge] credential in [workspaceId]'s own slot
  /// and returns what was removed, so the caller can revoke each grant
  /// upstream. With [where], only the credentials it accepts go.
  Future<List<({String userId, ProviderToken token})>>
  clearWorkspaceForgeTokens(
    ForgeHost forge,
    String workspaceId, {
    bool Function(ProviderToken token)? where,
  }) async {
    final removed = <({String userId, ProviderToken token})>[];
    if (workspaceId.isEmpty) {
      return removed;
    }
    final prefix = _workspaceForgePrefix(forge, workspaceId);
    for (final key in await _secrets.keysMatching(
      (key) => key.startsWith(prefix),
    )) {
      final userId = key.substring(prefix.length);
      final token = ProviderToken.tryParse(await _secrets.readPsk(key));
      if (token != null && where != null && !where(token)) {
        continue;
      }
      if (token != null) {
        removed.add((userId: userId, token: token));
      }
      await _secrets.deletePsk(key);
    }
    return removed;
  }

  /// Deletes [userId]'s credentials and lapse markers for every forge: in
  /// [workspaceId]'s own slot only, or with [workspaceId] null in every slot
  /// they hold (the global one and each workspace's). Returns what was
  /// removed, so the caller can revoke each grant upstream.
  Future<List<({ForgeHost forge, String? workspaceId, ProviderToken token})>>
  clearPersonForgeTokens(String userId, {String? workspaceId}) async {
    final removed =
        <({ForgeHost forge, String? workspaceId, ProviderToken token})>[];
    for (final forge in ForgeHost.values) {
      for (final held in await forgeTokens(forge)) {
        if (held.userId != userId ||
            (workspaceId != null && held.workspaceId != workspaceId)) {
          continue;
        }
        removed.add((
          forge: forge,
          workspaceId: held.workspaceId,
          token: held.token,
        ));
        await clearForgeToken(userId, forge, workspaceId: held.workspaceId);
      }
      if (workspaceId != null) {
        await clearForgeLapse(userId, forge, workspaceId: workspaceId);
      } else {
        await clearForgeLapse(userId, forge);
        final slots = 'workspace_forge_lapsed_${forge.wire}:';
        await _secrets.deleteMatching(
          (key) => key.startsWith(slots) && key.split(':').last == userId,
        );
      }
    }
    return removed;
  }

  /// Secrets-file key of the marker left when [userId]'s [forge] credential
  /// in the slot ([workspaceId], null for the global one) was cleared because
  /// its grant was refused or expired upstream. Its value is the account the
  /// credential belonged to.
  static String forgeLapseKey(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) => workspaceId == null || workspaceId.isEmpty
      ? '${_globalLapsePrefix(forge)}$userId'
      : '${_workspaceLapsePrefix(forge, workspaceId)}$userId';

  /// Records that [userId]'s [forge] credential in the slot was cleared
  /// because it can never work again, so the connection reads
  /// `needs_sign_in` (with [accountLogin]) across restarts until they sign
  /// in again or disconnect.
  Future<void> markForgeLapsed(
    String userId,
    ForgeHost forge,
    String accountLogin, {
    String? workspaceId,
  }) async {
    await _secrets.writePsk(
      forgeLapseKey(forge, userId, workspaceId: workspaceId),
      accountLogin,
    );
  }

  /// The account of [userId]'s lapsed [forge] credential in the slot, or
  /// null when it did not lapse (`''` when the account was unknown).
  Future<String?> forgeLapse(
    String userId,
    ForgeHost forge, {
    String? workspaceId,
  }) =>
      _secrets.readPsk(forgeLapseKey(forge, userId, workspaceId: workspaceId));

  /// Forgets the lapse marker of [userId]'s [forge] credential in the slot:
  /// they signed in again, pasted a new token or disconnected.
  Future<void> clearForgeLapse(
    String userId,
    ForgeHost forge, {
    String? workspaceId,
  }) => _secrets.deletePsk(
    forgeLapseKey(forge, userId, workspaceId: workspaceId),
  );

  /// Forgets every member's [forge] lapse marker in [workspaceId]'s own slot,
  /// when that slot is reset.
  Future<void> clearWorkspaceForgeLapses(
    ForgeHost forge,
    String workspaceId,
  ) async {
    if (workspaceId.isEmpty) {
      return;
    }
    final prefix = _workspaceLapsePrefix(forge, workspaceId);
    await _secrets.deleteMatching((key) => key.startsWith(prefix));
  }

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
  }) =>
      _secrets.deletePsk(ticketKey(provider, userId, workspaceId: workspaceId));

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

  /// Deletes [userId]'s ticketing credentials for every provider: in
  /// [workspaceId]'s own slot only, or with [workspaceId] null in every slot
  /// they hold. Returns the tokens removed, so the caller can revoke them.
  Future<List<({TicketProvider provider, ProviderToken token})>>
  clearPersonTicketTokens(String userId, {String? workspaceId}) async {
    final removed = <({TicketProvider provider, ProviderToken token})>[];
    for (final provider in TicketProvider.values) {
      final slots = <String?>[
        if (workspaceId != null)
          workspaceId
        else ...[
          null,
          for (final slot in await workspaceTicketSlots(provider))
            if (slot.userId == userId) slot.workspaceId,
        ],
      ];
      for (final slot in slots) {
        final token = await ticketToken(userId, provider, workspaceId: slot);
        if (token == null) {
          continue;
        }
        removed.add((provider: provider, token: token));
        await clearTicketToken(userId, provider, workspaceId: slot);
      }
    }
    return removed;
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
