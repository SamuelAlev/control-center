/// Immutable configuration for one `cc_worker` process, parsed from CLI flags.
class WorkerConfig {
  /// Creates a [WorkerConfig].
  const WorkerConfig({
    required this.serverUrl,
    required this.name,
    required this.deviceId,
    this.psk,
  });

  /// The cc_server URL to dial. Accepts `ws://`/`wss://`; `http`/`https` are
  /// coerced to `ws`/`wss`, and a missing path defaults to `/rpc`.
  final String serverUrl;

  /// Operator-facing worker name (defaults to the host name).
  final String name;

  /// Stable paired-device id — used both as the auth identity and, unless the
  /// server overrides it, as the worker id.
  final String deviceId;

  /// The paired-device pre-shared key. When null/empty the worker connects
  /// without the PSK auth handshake, which only a loopback dev server accepts.
  final String? psk;
}
