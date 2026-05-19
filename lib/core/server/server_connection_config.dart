import 'package:control_center/core/providers/storage_providers.dart';

/// How the desktop reaches the `cc_server` that owns its data.
///
/// The desktop is a thin client: it never opens the database itself. It either
/// spawns a `cc_server` subprocess on this machine ([local]) or connects to one
/// running elsewhere ([remote]). Both paths end in a `RemoteRpcClient` the whole
/// UI talks to over RPC.
enum ServerConnectionMode {
  /// Spawn and supervise a local `cc_server`, which owns the database on this
  /// machine. The default, self-contained, single-user setup.
  local,

  /// Connect to a `cc_server` running on another machine over WebSocket. The
  /// data lives on that server; this desktop is purely a renderer.
  remote;

  /// Parses a persisted [value], defaulting to [local] for null/unknown input.
  static ServerConnectionMode fromName(String? value) => switch (value) {
    'remote' => ServerConnectionMode.remote,
    _ => ServerConnectionMode.local,
  };
}

/// The desktop's persisted server-connection choice (non-secret fields only).
///
/// The remote pairing key is intentionally NOT held here — it is a secret and
/// lives in the OS keychain, read separately via [ServerConnectionStore.readPsk]
/// so it never travels through this value object or any log line.
class ServerConnectionConfig {
  /// Creates a config. [remoteUrl] / [remoteDeviceId] are only meaningful when
  /// [mode] is [ServerConnectionMode.remote].
  const ServerConnectionConfig({
    required this.mode,
    this.remoteUrl = '',
    this.remoteDeviceId = defaultRemoteDeviceId,
  });

  /// The default for a fresh install: run a local in-app server.
  static const ServerConnectionConfig localDefault = ServerConnectionConfig(
    mode: ServerConnectionMode.local,
  );

  /// Device id the desktop presents when connecting to a remote server.
  static const String defaultRemoteDeviceId = 'desktop-remote';

  /// Whether to spawn a local server or dial a remote one.
  final ServerConnectionMode mode;

  /// The remote server's RPC WebSocket URL (e.g. `wss://host:9030/rpc`). Empty
  /// in [ServerConnectionMode.local].
  final String remoteUrl;

  /// Device id presented to the remote server (paired against its PSK).
  final String remoteDeviceId;

  /// Whether a remote connection has the URL it needs (the PSK is validated
  /// separately at connect time).
  bool get isRemoteComplete =>
      mode == ServerConnectionMode.remote && remoteUrl.trim().isNotEmpty;

  /// Canonicalizes a user-entered remote URL into the exact endpoint the
  /// `cc_server` will upgrade, or returns null when it cannot be a valid
  /// WebSocket URL.
  ///
  /// Forgives the shapes people actually type:
  ///   * a bare `host:port` (assumes `ws://`),
  ///   * an `http`/`https` scheme (mapped to `ws`/`wss`),
  ///   * a missing path — defaulted to `/rpc`, the ONLY path the `cc_server`
  ///     (`LocalRpcServer`) upgrades (any other path is served as static
  ///     content, so the handshake reports the opaque "was not upgraded to
  ///     websocket").
  ///
  /// Query and fragment are dropped (the server keys purely on the path), which
  /// also strips the stray `#`/`?` that crept into older saved values.
  static String? normalizeRemoteUrl(String raw) {
    var text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    // A bare `host:port` has no scheme delimiter; assume an insecure WS dial.
    if (!text.contains('://')) {
      text = 'ws://$text';
    }
    final parsed = Uri.tryParse(text);
    if (parsed == null || parsed.host.isEmpty) {
      return null;
    }
    final scheme = switch (parsed.scheme) {
      'ws' || 'wss' => parsed.scheme,
      'http' => 'ws',
      'https' => 'wss',
      _ => null,
    };
    if (scheme == null) {
      return null;
    }
    final path = (parsed.path.isEmpty || parsed.path == '/')
        ? '/rpc'
        : parsed.path;
    return Uri(
      scheme: scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: path,
    ).toString();
  }

  /// Returns a copy with the given fields replaced.
  ServerConnectionConfig copyWith({
    ServerConnectionMode? mode,
    String? remoteUrl,
    String? remoteDeviceId,
  }) => ServerConnectionConfig(
    mode: mode ?? this.mode,
    remoteUrl: remoteUrl ?? this.remoteUrl,
    remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
  );

  @override
  bool operator ==(Object other) =>
      other is ServerConnectionConfig &&
      other.mode == mode &&
      other.remoteUrl == remoteUrl &&
      other.remoteDeviceId == remoteDeviceId;

  @override
  int get hashCode => Object.hash(mode, remoteUrl, remoteDeviceId);
}

/// Reads/writes the [ServerConnectionConfig] across [AppPreferences] (non-secret
/// fields) and [SecureStore] (the remote pairing key).
///
/// Shared deliberately by two callers: the boot-time resolver (which runs before
/// Riverpod is up, so it takes the backends directly) and the settings notifier.
/// Both use the same keys, so a change in Settings is what the next boot reads.
class ServerConnectionStore {
  /// Creates a store over the given storage backends.
  const ServerConnectionStore(this._prefs, this._secure);

  final AppPreferences _prefs;
  final SecureStore _secure;

  /// Prefs key holding the [ServerConnectionMode] name. Its presence is how we
  /// detect first run (the user has not chosen yet).
  static const String modeKey = 'server_connection_mode';

  /// Prefs key for the remote server URL.
  static const String remoteUrlKey = 'server_remote_url';

  /// Prefs key for the remote device id.
  static const String remoteDeviceIdKey = 'server_remote_device_id';

  /// Keychain key for the remote pairing key (PSK).
  static const String remotePskKey = 'server_remote_psk';

  /// Whether the user has made a server-connection choice yet.
  bool get isConfigured => _prefs.containsKey(modeKey);

  /// Reads the persisted config (non-secret fields), defaulting to a local
  /// server when nothing is stored.
  ServerConnectionConfig read() => ServerConnectionConfig(
    mode: ServerConnectionMode.fromName(_prefs.getString(modeKey)),
    remoteUrl: _prefs.getString(remoteUrlKey) ?? '',
    remoteDeviceId:
        _prefs.getString(remoteDeviceIdKey) ??
        ServerConnectionConfig.defaultRemoteDeviceId,
  );

  /// Reads the stored remote pairing key, or null if none.
  Future<String?> readPsk() => _secure.read(key: remotePskKey);

  /// Persists [config]. When [psk] is non-null it is written to the keychain
  /// (an empty string clears it); a null [psk] leaves any stored key untouched.
  Future<void> save(ServerConnectionConfig config, {String? psk}) async {
    await _prefs.setString(modeKey, config.mode.name);
    await _prefs.setString(remoteUrlKey, config.remoteUrl.trim());
    await _prefs.setString(remoteDeviceIdKey, config.remoteDeviceId.trim());
    if (psk != null) {
      if (psk.isEmpty) {
        await _secure.delete(key: remotePskKey);
      } else {
        await _secure.write(key: remotePskKey, value: psk);
      }
    }
  }

  /// Forgets the persisted connection entirely, so [isConfigured] reads false
  /// again and the next boot returns to the connect/setup screen. Used by the
  /// web client on an explicit disconnect or a non-remembered session (where
  /// the pairing key must not linger in the browser).
  Future<void> clear() async {
    await _prefs.remove(modeKey);
    await _prefs.remove(remoteUrlKey);
    await _prefs.remove(remoteDeviceIdKey);
    await _secure.delete(key: remotePskKey);
  }
}
