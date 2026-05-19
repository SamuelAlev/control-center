/// Immutable configuration for one `cc_worker` process, parsed from CLI flags.
class WorkerConfig {
  /// Creates a [WorkerConfig].
  const WorkerConfig({
    required this.serverUrl,
    required this.name,
    required this.deviceId,
    this.psk,
    this.maxJobs = 4,
  });

  /// The cc_server URL to dial. Accepts `ws://`/`wss://`; `http`/`https` are
  /// coerced to `ws`/`wss` and a missing path defaults to `/rpc`.
  final String serverUrl;

  /// Operator-facing worker name (defaults to the host name).
  final String name;

  /// Stable paired-device id — used both as the auth identity and, unless the
  /// server overrides it, as the worker id.
  final String deviceId;

  /// The paired-device pre-shared key. When null/empty the worker connects
  /// without the PSK auth handshake, which only a loopback dev server accepts.
  final String? psk;

  /// Hard ceiling on jobs this worker executes CONCURRENTLY.
  ///
  /// Every lease offer used to start immediately, so a mis-pinned burst or a
  /// scheduler bug turned the worker into a fork bomb on the operator's
  /// machine. The worker is the last line of defence here — the server decides
  /// what to offer, but only the worker knows what its host can take.
  final int maxJobs;
}
