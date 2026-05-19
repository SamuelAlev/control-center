/// Abstraction over per-device PSK storage, so `LocalRpcServer` never binds to a
/// specific secrets backend.
///
/// The desktop implements it with the OS keychain (`flutter_secure_storage`);
/// the headless `cc_server` with an encrypted file under its data dir. Keeping
/// the port here lets the server stay pure-Dart (`dart build cli`) while the
/// desktop keeps its keychain store.
abstract interface class PairedDeviceSecretsPort {
  /// Reads the PSK for [deviceId], or null if absent.
  Future<String?> readPsk(String deviceId);

  /// Stores [psk] for [deviceId]; returns whether it was written.
  Future<bool> writePsk(String deviceId, String psk);

  /// Removes the PSK for [deviceId] (fails closed — a revoked device can't auth).
  Future<void> deletePsk(String deviceId);
}
