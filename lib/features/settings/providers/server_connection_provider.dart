import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings-side view of the desktop's server-connection choice.
///
/// Reads/writes the same [ServerConnectionStore] the boot resolver uses, so a
/// change here is exactly what the next boot reads. A connection change applies
/// on restart (the RPC client is established once at boot, before the provider
/// tree exists), which the settings UI surfaces as a hint.
final serverConnectionConfigProvider =
    NotifierProvider<ServerConnectionNotifier, ServerConnectionConfig>(
      ServerConnectionNotifier.new,
    );

/// Notifier backing [serverConnectionConfigProvider]. Persists every change
/// through [ServerConnectionStore] (prefs for the non-secret fields, keychain
/// for the pairing key).
class ServerConnectionNotifier extends Notifier<ServerConnectionConfig> {
  late ServerConnectionStore _store;

  @override
  ServerConnectionConfig build() {
    _store = ServerConnectionStore(
      ref.read(appPreferencesProvider),
      ref.read(secureStoreProvider),
    );
    final config = _store.read();
    // The web client can never run a local server (a browser cannot spawn a
    // subprocess), so it is always in remote mode — coerce a fresh/legacy
    // `local` choice so the settings UI and every save stay consistent.
    return kIsWeb
        ? config.copyWith(mode: ServerConnectionMode.remote)
        : config;
  }

  /// Switches between a local and a remote server.
  Future<void> setMode(ServerConnectionMode mode) async {
    final next = state.copyWith(mode: mode);
    await _store.save(next);
    state = next;
  }

  /// Sets the remote server's RPC WebSocket URL, canonicalized to the endpoint
  /// the server upgrades (adds the required `/rpc` path, maps `http(s)`→`ws(s)`,
  /// strips query/fragment). Falls back to the trimmed input when it cannot be
  /// parsed, so a partial value is never silently dropped — the boot resolver
  /// normalizes again before dialing.
  Future<void> setRemoteUrl(String url) async {
    final normalized =
        ServerConnectionConfig.normalizeRemoteUrl(url) ?? url.trim();
    final next = state.copyWith(remoteUrl: normalized);
    await _store.save(next);
    state = next;
  }

  /// Sets the device id presented to the remote server (falls back to the
  /// default when cleared).
  Future<void> setRemoteDeviceId(String deviceId) async {
    final trimmed = deviceId.trim();
    final next = state.copyWith(
      remoteDeviceId: trimmed.isEmpty
          ? ServerConnectionConfig.defaultRemoteDeviceId
          : trimmed,
    );
    await _store.save(next);
    state = next;
  }

  /// Reads the stored pairing key (used to prefill the edit dialog).
  Future<String?> readPairingKey() => _store.readPsk();

  /// Persists a new pairing key (empty clears it); leaves the other fields as-is.
  Future<void> setPairingKey(String psk) => _store.save(state, psk: psk.trim());
}
