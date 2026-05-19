/// Abstraction over per-device PSK storage, so `LocalRpcServer` never binds to a
/// specific secrets backend.
///
/// The desktop implements it with the OS keychain (`flutter_secure_storage`);
/// the headless `cc_server` with a `0600` JSON file under its data dir
/// (`FileSecretsStore`, whose `secrets.json` also holds every other
/// server-side secret behind a namespaced key). Keeping the port here lets the
/// server stay pure-Dart (`dart build cli`) while the desktop keeps its
/// keychain store.
///
/// The server-side file is PLAINTEXT: its protection is filesystem permissions
/// on a single-tenant host, not encryption. Anything that would need more than
/// that needs a different backend, not a different doc comment.
abstract interface class PairedDeviceSecretsPort {
  /// Reads the PSK for [deviceId], or null if absent.
  Future<String?> readPsk(String deviceId);

  /// Stores [psk] for [deviceId]; returns whether it was written.
  Future<bool> writePsk(String deviceId, String psk);

  /// Removes the PSK for [deviceId] (fails closed — a revoked device can't auth).
  Future<void> deletePsk(String deviceId);
}
