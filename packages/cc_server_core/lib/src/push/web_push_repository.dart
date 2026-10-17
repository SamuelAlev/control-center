import 'dart:convert';

import 'package:cc_server_core/src/file_secrets_store.dart';

/// A push endpoint is a bearer capability, never a synced user preference.
/// Both subscription and VAPID private key stay in the server's owner-only
/// secrets file. Device IDs are authenticated at the RPC boundary.
class WebPushRepository {
  /// Uses the server's owner-only secret store, never workspace preferences.
  WebPushRepository(this._secrets);

  final FileSecretsStore _secrets;
  static const _vapidKey = 'web_push_vapid_v1';
  static String _subscriptionKey(String deviceId) =>
      'web_push_device_$deviceId';

  /// Reads the server-wide signing identity without exposing it over RPC.
  Future<String?> readVapid() => _secrets.readFresh(_vapidKey);

  /// Persists the serialized signing identity for stable browser subscriptions.
  Future<void> writeVapid(String value) async {
    await _secrets.writePsk(_vapidKey, value);
  }

  /// Reads one device's subscription; malformed records disable delivery.
  Future<PushSubscriptionRecord?> read(String deviceId) async {
    final raw = await _secrets.readFresh(_subscriptionKey(deviceId));
    if (raw == null) {
      return null;
    }
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      return PushSubscriptionRecord(
        endpoint: value['endpoint'] as String,
        p256dh: value['p256dh'] as String,
        auth: value['auth'] as String,
        categories: (value['categories'] as List).cast<String>().toSet(),
        quiet: value['quiet'] == true,
      );
    } on Object {
      // Corrupt subscription records never fall back to an unfiltered push.
      return null;
    }
  }

  /// Replaces the authenticated device's endpoint, keys and delivery choices.
  Future<void> save(String deviceId, PushSubscriptionRecord record) async {
    await _secrets.writePsk(
      _subscriptionKey(deviceId),
      jsonEncode({
        'endpoint': record.endpoint,
        'p256dh': record.p256dh,
        'auth': record.auth,
        'categories': record.categories.toList()..sort(),
        'quiet': record.quiet,
      }),
    );
  }

  /// Deletes a device's subscription without changing the VAPID identity.
  Future<void> remove(String deviceId) =>
      _secrets.deletePsk(_subscriptionKey(deviceId));

  /// Invoked on unpair/revoke (including server-side device revocations).
  Future<void> revokeDevice(String deviceId) => remove(deviceId);
}

/// Server-only browser subscription and background-delivery preferences.
class PushSubscriptionRecord {
  /// Captures validated registration input for one paired device.
  const PushSubscriptionRecord({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
    required this.categories,
    required this.quiet,
  });

  /// Bearer-capability URL issued by an approved browser push service.
  final String endpoint;

  /// Base64url-encoded uncompressed P-256 recipient public key.
  final String p256dh;

  /// Base64url-encoded 16-byte recipient authentication secret.
  final String auth;

  /// Notification categories this device opted into receiving.
  final Set<String> categories;

  /// Pauses delivery without deleting the browser subscription.
  final bool quiet;
}
