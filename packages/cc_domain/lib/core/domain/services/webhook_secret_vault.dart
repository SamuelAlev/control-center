import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:crypto/crypto.dart';

/// Keeps inbound-webhook secrets out of the databases and derives the keys
/// that route an inbound webhook to its workspace.
///
/// A pipeline trigger's webhook token and a ticket-sync config's webhook secret
/// live in the server's secrets store under a reference ([pipelineTriggerRef],
/// [ticketSyncRef]); the row stores only that reference, so a snapshot or an
/// admin export of a workspace carries no secret. The pre-auth route index
/// stores [webhookRouteKey] of a token rather than the token itself.
class WebhookSecretVault {
  /// Creates a vault over the server's secrets store. [random] mints the server route key on
  /// first use (a secure generator unless a test pins one).
  WebhookSecretVault(this._store, {Random? random})
    : _random = random ?? Random.secure();

  final SecretStorePort _store;
  final Random _random;
  Future<List<int>>? _serverKey;

  /// The secrets-store key of the server's route key: 32 random bytes,
  /// base64url, minted the first time any webhook route is computed.
  static const String serverRouteKeySlot = 'server_webhook_route_key';

  static const String _prefix = 'webhook_secret:';
  static const String _triggerKind = 'pipeline_trigger';
  static const String _ticketSyncKind = 'ticket_sync';

  /// The key under which [token] is routed: hex `HMAC-SHA256(server route
  /// key, token)`.
  ///
  /// The one function that turns a pipeline trigger's webhook token into its
  /// `workspace_routes` key. Saving a trigger, resolving an inbound
  /// `/webhooks/<token>` and rebuilding routes from an imported workspace all
  /// call it, so the three agree. Without the server route key the stored
  /// route keys reveal nothing about the tokens they route.
  Future<String> webhookRouteKey(String token) async {
    final pending = _serverKey ??= _loadServerKey();
    final List<int> key;
    try {
      key = await pending;
    } on Object {
      // A failed read or mint is retried by the next call, not cached.
      if (identical(_serverKey, pending)) {
        _serverKey = null;
      }
      rethrow;
    }
    return Hmac(sha256, key).convert(utf8.encode(token)).toString();
  }

  /// The reference under which a trigger's webhook token is stored, for the
  /// trigger in [workspaceId] whose token routes as [routeKey].
  ///
  /// Derived from the route key so an inbound webhook finds its trigger row by
  /// an indexed equality, without the token ever being stored in the row.
  static String pipelineTriggerRef(String workspaceId, String routeKey) =>
      '$_prefix$_triggerKind:$workspaceId:$routeKey';

  /// The route key a [pipelineTriggerRef] was derived from.
  static String routeKeyOfTriggerRef(String ref) =>
      ref.substring(ref.lastIndexOf(':') + 1);

  /// The reference under which ticket-sync config [configId]'s webhook secret
  /// is stored.
  static String ticketSyncRef(String workspaceId, String configId) =>
      '$_prefix$_ticketSyncKind:$workspaceId:$configId';

  /// Whether [key] is a webhook secret belonging to [workspaceId]. Every
  /// reference ends its workspace id with `:`, which workspace ids cannot
  /// contain, so one workspace never matches another's secrets.
  static bool isWorkspaceSecret(String key, String workspaceId) =>
      key.startsWith('$_prefix$_triggerKind:$workspaceId:') ||
      key.startsWith('$_prefix$_ticketSyncKind:$workspaceId:');

  /// The secret stored under [ref], or null when it is gone.
  Future<String?> read(String ref) => _store.read(ref);

  /// Stores [secret] under [ref].
  Future<void> write(String ref, String secret) => _store.write(ref, secret);

  /// Removes the secret under [ref].
  Future<void> delete(String ref) => _store.delete(ref);

  /// Removes every webhook secret of [workspaceId], for a workspace that is
  /// being deleted with all its triggers and sync configs.
  Future<int> deleteForWorkspace(String workspaceId) =>
      _store.deleteMatching((key) => isWorkspaceSecret(key, workspaceId));

  Future<List<int>> _loadServerKey() async {
    final stored = await _store.read(serverRouteKeySlot);
    if (stored != null && stored.isNotEmpty) {
      return base64Url.decode(stored);
    }
    final minted = List<int>.generate(32, (_) => _random.nextInt(256));
    await _store.write(serverRouteKeySlot, base64Url.encode(minted));
    return minted;
  }
}
