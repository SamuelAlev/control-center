import 'package:cc_server_core/cc_server_core.dart' show PairedDeviceSecretsPort;
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/data/repositories/secure_credentials_repository.dart'
    show SecureCredentialsRepository;

/// Stores the PSK for each paired device in the platform secure store
/// (macOS keychain / Windows credential store / Linux libsecret).
///
/// Mirrors [SecureCredentialsRepository]: secrets live here, while the
/// non-secret device metadata (label, platform, status, fingerprint) lives in
/// the `paired_devices` Drift table. The store key is `paired_device_psk_<id>`,
/// referenced from the table row's `pskRef` column.
///
/// Revoking a device deletes its PSK here (so it fails closed) and then the
/// metadata row.
class PairedDeviceSecretsRepository implements PairedDeviceSecretsPort {
  /// Creates a [PairedDeviceSecretsRepository].
  PairedDeviceSecretsRepository(this._storage);

  final SecureStore _storage;

  /// Builds the secure-store key for [deviceId]'s PSK.
  static String keyFor(String deviceId) => 'paired_device_psk_$deviceId';

  /// Reads the stored PSK for [deviceId], or null when none/revoked.
  @override
  Future<String?> readPsk(String deviceId) =>
      _storage.read(key: keyFor(deviceId));

  /// Persists the [psk] for [deviceId]. Returns whether the secure store
  /// reported success, so the pairing flow can detect a keychain write that
  /// silently failed before handing out a QR the phone could never authenticate.
  @override
  Future<bool> writePsk(String deviceId, String psk) =>
      _storage.write(key: keyFor(deviceId), value: psk);

  /// Deletes the PSK for [deviceId] (fails closed on next reconnect).
  @override
  Future<void> deletePsk(String deviceId) =>
      _storage.delete(key: keyFor(deviceId));
}
