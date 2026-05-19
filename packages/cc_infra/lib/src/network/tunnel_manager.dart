import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:crypto/crypto.dart';

/// Managed tunnel providers supported by [TunnelManager] (PRD 15 §5 — "Share
/// this server").
enum TunnelProvider {
  /// Cloudflare Tunnel (`cloudflared`). A quick tunnel prints a
  /// `https://<name>.trycloudflare.com` URL on startup; a named tunnel (extra
  /// args present) may print no URL at all because its hostname is
  /// operator-configured DNS.
  cloudflared,

  /// ngrok (`ngrok http <port>`). The public URL is parsed from its JSON
  /// stdout log (the `started tunnel` event).
  ngrok,

  /// Tailscale — DETECTION mode. No child tunnel process is spawned; the
  /// node's MagicDNS name is polled via `tailscale status --json` and exposed
  /// with the `tailnet://` pseudo-scheme so the wiring can distinguish a
  /// tailnet address from a public `wss`/`https` one.
  tailscale,
}

/// Lifecycle state of a managed tunnel.
enum TunnelState {
  /// Not running (never started, or stopped).
  off,

  /// Child spawned (or detection begun) but no public address confirmed yet.
  starting,

  /// The tunnel is reachable — [TunnelStatus.publicUrl] carries the address
  /// (null for a cloudflared named tunnel whose DNS is operator-configured).
  up,

  /// Something is wrong — [TunnelStatus.error] carries the message. The
  /// supervisor may still be retrying (crash loop) unless the failure is
  /// terminal (missing binary, checksum mismatch).
  error,
}

/// Immutable snapshot of a [TunnelManager]'s state, safe to send over RPC via
/// [toWire].
class TunnelStatus {
  /// Creates a status snapshot.
  const TunnelStatus({
    required this.provider,
    required this.state,
    this.publicUrl,
    this.error,
    this.restarts = 0,
    this.since,
  });

  /// Which tunnel provider this status describes.
  final TunnelProvider provider;

  /// Current lifecycle state.
  final TunnelState state;

  /// The public address when [state] is [TunnelState.up] — `https://host[:port]`
  /// for cloudflared/ngrok, `tailnet://host:port` for tailscale. Null while
  /// starting/off/error and for a cloudflared named tunnel whose hostname is
  /// operator-configured DNS (the tunnel is up but prints no URL).
  final String? publicUrl;

  /// Human-readable failure description when [state] is [TunnelState.error].
  final String? error;

  /// How many times the supervisor restarted the child since [TunnelManager.start].
  final int restarts;

  /// When the current [state] began (null before the first transition).
  final DateTime? since;

  /// Wire-format map for RPC/status endpoints.
  Map<String, Object?> toWire() => <String, Object?>{
    'provider': provider.name,
    'state': state.name,
    'publicUrl': publicUrl,
    'error': error,
    'restarts': restarts,
    'since': since?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is TunnelStatus &&
      other.provider == provider &&
      other.state == state &&
      other.publicUrl == publicUrl &&
      other.error == error &&
      other.restarts == restarts &&
      other.since == since;

  @override
  int get hashCode =>
      Object.hash(provider, state, publicUrl, error, restarts, since);

  @override
  String toString() =>
      'TunnelStatus(provider: ${provider.name}, state: ${state.name}, '
      'publicUrl: $publicUrl, restarts: $restarts, error: $error)';
}

/// A tunnel's public address as handed to [TunnelManager.onAddress].
class TunnelAddress {
  /// Creates an address wrapper.
  const TunnelAddress({required this.publicUrl});

  /// `https://host[:port]` for cloudflared/ngrok; `tailnet://host:port` for
  /// tailscale (the caller builds a tailnet path from the MagicDNS host).
  final String publicUrl;

  @override
  bool operator ==(Object other) =>
      other is TunnelAddress && other.publicUrl == publicUrl;

  @override
  int get hashCode => publicUrl.hashCode;

  @override
  String toString() => 'TunnelAddress($publicUrl)';
}

/// Supervised manager for a "Share this server" tunnel binary (PRD 15 §5).
///
/// Spawns and babysits one tunnel child process (`cloudflared` / `ngrok`),
/// parsing its output for the public URL and restarting it with jittered
/// exponential backoff ([baseBackoff]‥[maxBackoff]) on unexpected exit — each
/// restart re-parses the (possibly rotated) URL. `tailscale` is different: no
/// child is spawned; the node's MagicDNS name is polled via
/// `tailscale status --json` every [tailscalePollInterval].
///
/// Supply-chain pin: when [expectedSha256] is set, the binary file is hashed
/// and compared (case-insensitively) BEFORE every spawn; a mismatch refuses to
/// spawn with a loud [TunnelState.error]. Auto-update is never enabled —
/// cloudflared always gets `--no-autoupdate` and any update-related
/// [extraArgs] are dropped.
///
/// Terminal failures (binary not found, checksum mismatch) leave the manager
/// in [TunnelState.error] without retrying; call [stop] then [start] to try
/// again. [start] and [stop] are idempotent.
///
/// Modeled on `CodeServerService` (spawn + readiness parse + SIGTERM → 3s →
/// SIGKILL) and `resolveBinaryPath` (PATH/prefix probing).
class TunnelManager {
  /// Creates a manager for [provider] exposing local port [localPort].
  ///
  /// [binaryPath] pins an explicit binary; when empty the provider's binary
  /// name is looked up via [resolveBinaryPath]. [expectedSha256] (64 hex
  /// chars) enables the pre-spawn checksum pin. [extraArgs] are appended to
  /// the provider's base arguments (update-related flags are stripped).
  /// [onAddress] fires with the public address when the tunnel comes up and
  /// with null when it goes down. [log] receives diagnostics (falls back to
  /// [CcInfraLog] when null). [baseBackoff]/[maxBackoff]/[urlWaitTimeout]/
  /// [tailscalePollInterval] are injectable so tests run fast.
  TunnelManager({
    required this.provider,
    required this.localPort,
    this.binaryPath = '',
    this.expectedSha256 = '',
    this.extraArgs = const [],
    this.log,
    this.onAddress,
    this.baseBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.urlWaitTimeout = const Duration(seconds: 30),
    this.tailscalePollInterval = const Duration(seconds: 60),
  }) {
    if (localPort < 1 || localPort > 65535) {
      throw ArgumentError.value(
        localPort,
        'localPort',
        'must be a valid TCP port',
      );
    }
    if (expectedSha256.isNotEmpty && !_sha256Hex.hasMatch(expectedSha256)) {
      throw ArgumentError.value(
        expectedSha256,
        'expectedSha256',
        'must be 64 hex characters (a SHA-256 digest)',
      );
    }
  }

  /// Which tunnel provider this manager drives.
  final TunnelProvider provider;

  /// The local TCP port being exposed (cc_server's RPC/WSS port).
  final int localPort;

  /// Explicit binary path; when empty the provider's binary name is resolved
  /// on PATH / common install prefixes via [resolveBinaryPath].
  final String binaryPath;

  /// When non-empty: SHA-256 hex the binary file must hash to before EVERY
  /// spawn (case-insensitive). Mismatch → [TunnelState.error], never spawned.
  final String expectedSha256;

  /// Extra arguments appended to the provider's base invocation. Any
  /// update-related flags are stripped (auto-update is never enabled).
  final List<String> extraArgs;

  /// Diagnostic sink; falls back to [CcInfraLog.info] when null.
  final void Function(String message)? log;

  /// Fired with the public address when the tunnel comes up (or the URL
  /// rotates after a restart) and with null when the tunnel goes down.
  final void Function(TunnelAddress? address)? onAddress;

  /// First restart delay; doubles per consecutive failure up to [maxBackoff].
  final Duration baseBackoff;

  /// Backoff cap (spec: 30s). Jitter keeps the actual delay in
  /// `[0.5, 1.0] × capped`.
  final Duration maxBackoff;

  /// How long a cloudflared NAMED tunnel (extra args present) may stay silent
  /// before it is considered up with a null URL (operator-configured DNS).
  final Duration urlWaitTimeout;

  /// How often `tailscale status --json` is re-run in detection mode.
  final Duration tailscalePollInterval;

  final StreamController<TunnelStatus> _statusController =
      StreamController<TunnelStatus>.broadcast();
  final Random _random = Random();

  late TunnelStatus _status = TunnelStatus(
    provider: provider,
    state: TunnelState.off,
  );
  bool _active = false;
  int _restarts = 0;
  Completer<void> _stopSignal = Completer<void>()..complete();
  Process? _process;
  Future<void>? _superviseFuture;
  Timer? _pollTimer;
  String? _tailscaleBinary;
  String? _lastAddress;

  /// The PATH binary name for [provider].
  static String binaryNameFor(TunnelProvider provider) => switch (provider) {
    TunnelProvider.cloudflared => 'cloudflared',
    TunnelProvider.ngrok => 'ngrok',
    TunnelProvider.tailscale => 'tailscale',
  };

  /// Current status snapshot.
  TunnelStatus get status => _status;

  /// Broadcast stream emitting a [TunnelStatus] on every state change.
  Stream<TunnelStatus> get statusStream => _statusController.stream;

  /// Starts (and supervises) the tunnel. Idempotent: a second call while
  /// active is a no-op. Returns once supervision is underway — watch
  /// [statusStream] for [TunnelState.up] / [TunnelState.error].
  Future<void> start() async {
    if (_active) {
      return;
    }
    _active = true;
    _restarts = 0;
    _stopSignal = Completer<void>();
    if (provider == TunnelProvider.tailscale) {
      await _startTailscaleDetection();
    } else {
      _superviseFuture = _supervise().catchError((Object e, StackTrace st) {
        _setStatus(
          state: TunnelState.error,
          publicUrl: null,
          error: 'tunnel supervisor crashed: $e',
        );
        CcInfraLog.error('TunnelManager supervisor crashed', e, st);
      });
    }
  }

  /// Stops the tunnel: SIGTERM, 3s grace, then SIGKILL; cancels the tailscale
  /// poll timer; no restart happens after stop. Idempotent.
  Future<void> stop() async {
    if (!_active) {
      return;
    }
    _active = false;
    if (!_stopSignal.isCompleted) {
      _stopSignal.complete();
    }
    _pollTimer?.cancel();
    _pollTimer = null;

    final process = _process;
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      try {
        await process.exitCode.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
      }
    }
    final supervise = _superviseFuture;
    if (supervise != null) {
      await supervise;
      _superviseFuture = null;
    }
    _dropAddress();
    _setStatus(state: TunnelState.off, publicUrl: null, error: null);
    _log('tunnel stopped');
  }

  // ── Output parsing (pure, unit-testable) ──────────────────────────────────

  /// Extracts the quick-tunnel URL from one line of cloudflared output
  /// (`https://<name>.trycloudflare.com`, printed inside a banner box).
  /// Returns null when the line carries no tunnel URL.
  static String? parseCloudflaredUrl(String line) =>
      _cloudflaredUrl.firstMatch(line)?.group(0);

  /// Extracts the public URL from one line of ngrok output. Primary format:
  /// the `--log-format json` `started tunnel` event carrying a `"url"` field.
  /// Falls back to the legacy `url=https://…` key-value text format and a raw
  /// `"url":"https://…"` regex for partially structured lines.
  static String? parseNgrokUrl(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final url = decoded['url'];
          if (url is String && url.startsWith('https://')) {
            return url;
          }
          return null;
        }
      } catch (_) {
        // Not valid JSON — fall through to the regex formats.
      }
    }
    final kv = _ngrokKvUrl.firstMatch(line);
    if (kv != null) {
      return kv.group(1);
    }
    return _ngrokJsonUrl.firstMatch(line)?.group(1);
  }

  /// Parses `tailscale status --json` output into the node's MagicDNS name
  /// (trailing dot stripped) and whether Self is online. Returns null when the
  /// output is not parseable or carries no DNS name.
  static ({String dnsName, bool online})? parseTailscaleStatus(
    String jsonText,
  ) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final self = decoded['Self'];
      if (self is! Map<String, dynamic>) {
        return null;
      }
      final rawDnsName = self['DNSName'];
      if (rawDnsName is! String || rawDnsName.isEmpty) {
        return null;
      }
      final dnsName = rawDnsName.endsWith('.')
          ? rawDnsName.substring(0, rawDnsName.length - 1)
          : rawDnsName;
      if (dnsName.isEmpty) {
        return null;
      }
      return (dnsName: dnsName, online: self['Online'] == true);
    } catch (_) {
      return null;
    }
  }

  // ── Spawn supervision (cloudflared / ngrok) ───────────────────────────────

  Future<void> _supervise() async {
    var attempt = 0;
    while (_active) {
      _setStatus(state: TunnelState.starting, publicUrl: null, error: null);

      final binary = await _resolveBinary();
      if (binary == null) {
        _failTerminal(_missingBinaryMessage());
        return;
      }
      final checksumError = await _checksumError(binary);
      if (checksumError != null) {
        _failTerminal(checksumError);
        return;
      }
      if (!_active) {
        break;
      }

      final args = _spawnArgs();
      final tail = <String>[];
      final startedAt = DateTime.now();
      final Process process;
      try {
        process = await Process.start(binary, args);
      } on ProcessException catch (e) {
        _restarts++;
        _setStatus(
          state: TunnelState.error,
          publicUrl: null,
          error: 'failed to spawn tunnel binary $binary: ${e.message}',
        );
        attempt = await _backoff(attempt);
        continue;
      }
      if (!_active) {
        // stop() raced the spawn — kill the fresh child, exit the loop.
        process.kill(ProcessSignal.sigterm);
        unawaited(process.exitCode);
        break;
      }
      _process = process;
      _log('spawned $binary ${args.join(' ')} (pid ${process.pid})');

      // A cloudflared NAMED tunnel (extra args present) may never print a URL
      // (operator-configured DNS): after [urlWaitTimeout] of silence with the
      // child still running, report up with a null publicUrl.
      Timer? namedTunnelTimer;
      if (provider == TunnelProvider.cloudflared &&
          _sanitizedExtraArgs.isNotEmpty) {
        namedTunnelTimer = Timer(urlWaitTimeout, () {
          if (_active &&
              identical(_process, process) &&
              _status.state == TunnelState.starting) {
            _setStatus(state: TunnelState.up, publicUrl: null, error: null);
            _log(
              'tunnel is up (named tunnel — hostname is operator-configured '
              'DNS, no URL printed)',
            );
          }
        });
      }

      // Drain BOTH pipes fully for the child's whole life (a full pipe blocks
      // the child); keep the last 20 lines for error reporting.
      final stdoutDone = _drainLines(process.stdout, tail);
      final stderrDone = _drainLines(process.stderr, tail);
      final exitCode = await process.exitCode;
      await Future.wait([stdoutDone, stderrDone]);
      namedTunnelTimer?.cancel();
      _process = null;

      // The child died (expectedly or not) — the address is gone either way.
      _dropAddress();
      if (!_active) {
        break;
      }

      _restarts++;
      final tailNote = tail.isEmpty ? '' : ' — ${tail.join(' | ')}';
      _setStatus(
        state: TunnelState.error,
        publicUrl: null,
        error: 'tunnel process exited unexpectedly (code $exitCode)$tailNote',
      );
      // A child that stayed up past the backoff cap earned a fresh window.
      if (DateTime.now().difference(startedAt) > maxBackoff) {
        attempt = 0;
      }
      attempt = await _backoff(attempt);
    }
    _setStatus(state: TunnelState.off, publicUrl: null, error: null);
  }

  /// Base arguments per provider, plus the sanitized [extraArgs]. Auto-update
  /// is never enabled: cloudflared always gets `--no-autoupdate`.
  List<String> _spawnArgs() => switch (provider) {
    TunnelProvider.cloudflared => [
      'tunnel',
      '--url',
      'http://127.0.0.1:$localPort',
      '--no-autoupdate',
      ..._sanitizedExtraArgs,
    ],
    TunnelProvider.ngrok => [
      'http',
      '$localPort',
      '--log',
      'stdout',
      '--log-format',
      'json',
      ..._sanitizedExtraArgs,
    ],
    TunnelProvider.tailscale => throw StateError(
      'tailscale runs in detection mode — no child process is spawned',
    ),
  };

  /// [extraArgs] with any update-related flags stripped — the supply-chain pin
  /// ([expectedSha256]) is meaningless if the binary can replace itself.
  late final List<String> _sanitizedExtraArgs = extraArgs
      .where((arg) {
        final lower = arg.toLowerCase();
        return !lower.contains('autoupdate') &&
            !lower.contains('auto-update') &&
            !lower.contains('update-check');
      })
      .toList(growable: false);

  Future<void> _drainLines(Stream<List<int>> stream, List<String> tail) {
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) => _handleLine(line, tail))
        .catchError((Object _) {});
  }

  void _handleLine(String line, List<String> tail) {
    if (tail.length >= _tailLines) {
      tail.removeAt(0);
    }
    tail.add(line);
    if (!_active) {
      return;
    }
    final url = switch (provider) {
      TunnelProvider.cloudflared => parseCloudflaredUrl(line),
      TunnelProvider.ngrok => parseNgrokUrl(line),
      TunnelProvider.tailscale => null,
    };
    if (url == null || url == _lastAddress) {
      return;
    }
    _lastAddress = url;
    _setStatus(state: TunnelState.up, publicUrl: url, error: null);
    onAddress?.call(TunnelAddress(publicUrl: url));
    _log('tunnel up at $url');
  }

  /// Jittered exponential backoff: `min(base × 2^attempt, cap) × [0.5, 1.0]`.
  /// Interruptible by [stop] so shutdown never waits out a sleep.
  Future<int> _backoff(int attempt) async {
    final exponential = baseBackoff * (1 << min(attempt, 10));
    final capped = exponential > maxBackoff ? maxBackoff : exponential;
    final jittered = capped * (0.5 + _random.nextDouble() * 0.5);
    _log(
      'restarting tunnel in ${jittered.inMilliseconds}ms (restart #$_restarts)',
    );
    await Future.any(<Future<void>>[
      Future<void>.delayed(jittered),
      _stopSignal.future,
    ]);
    return attempt + 1;
  }

  // ── Tailscale detection mode ──────────────────────────────────────────────

  Future<void> _startTailscaleDetection() async {
    _setStatus(state: TunnelState.starting, publicUrl: null, error: null);
    final binary = await _resolveBinary();
    if (binary == null) {
      _failTerminal(_missingBinaryMessage());
      return;
    }
    _tailscaleBinary = binary;
    await _pollTailscaleOnce();
    if (!_active) {
      return;
    }
    _pollTimer = Timer.periodic(
      tailscalePollInterval,
      (_) => unawaited(_pollTailscaleOnce()),
    );
  }

  Future<void> _pollTailscaleOnce() async {
    if (!_active) {
      return;
    }
    final binary = _tailscaleBinary!;
    // The checksum pin holds for detection mode too: verify before EVERY
    // `tailscale status` run (the binary could be swapped between polls).
    final checksumError = await _checksumError(binary);
    if (checksumError != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _dropAddress();
      _failTerminal(checksumError);
      return;
    }
    final ProcessResult result;
    try {
      result = await Process.run(binary, const ['status', '--json']);
    } on ProcessException catch (e) {
      _tailscaleDown('failed to run tailscale status: ${e.message}');
      return;
    }
    if (!_active) {
      return;
    }
    if (result.exitCode != 0) {
      final stderrText = (result.stderr as String).trim();
      _tailscaleDown(
        'tailscale status failed (exit ${result.exitCode})'
        '${stderrText.isEmpty ? '' : ': $stderrText'}',
      );
      return;
    }
    final parsed = parseTailscaleStatus(result.stdout as String);
    if (parsed == null) {
      _tailscaleDown('could not parse `tailscale status --json` output');
      return;
    }
    if (!parsed.online) {
      _tailscaleDown(
        'tailscale is installed but this node is offline '
        '(not connected to the tailnet)',
      );
      return;
    }
    final url = 'tailnet://${parsed.dnsName}:$localPort';
    if (url != _lastAddress) {
      _lastAddress = url;
      _setStatus(state: TunnelState.up, publicUrl: url, error: null);
      onAddress?.call(TunnelAddress(publicUrl: url));
      _log('tailnet address: $url');
    }
  }

  void _tailscaleDown(String message) {
    _dropAddress();
    _setStatus(state: TunnelState.error, publicUrl: null, error: message);
    _log(message);
  }

  // ── Shared plumbing ───────────────────────────────────────────────────────

  /// The explicit [binaryPath] when set (must exist), else a PATH / install-
  /// prefix lookup of the provider's binary name.
  Future<String?> _resolveBinary() async {
    if (binaryPath.isNotEmpty) {
      return File(binaryPath).existsSync() ? binaryPath : null;
    }
    return resolveBinaryPath(binaryNameFor(provider));
  }

  String _missingBinaryMessage() => binaryPath.isNotEmpty
      ? 'tunnel binary not found at $binaryPath'
      : 'tunnel binary "${binaryNameFor(provider)}" not found on PATH or in '
            'common install prefixes — install it or set an explicit path';

  /// The `(path, mtime, size)` the last successful verification was for, so an
  /// unchanged binary is not re-hashed on every 60s poll.
  ///
  /// The pin's purpose is "the binary must not be swapped between polls", and a
  /// swap necessarily changes mtime or size — replacing a file in place with
  /// byte-identical metadata means writing the same length at the same second
  /// AND resetting mtime, which is not something an ordinary upgrade does. What
  /// this drops is re-reading and SHA-256ing 30–100 MB every 60 seconds
  /// forever: ~100–200 ms of main-isolate CPU per poll, for the life of the
  /// process.
  ({String path, DateTime mtime, int size})? _verifiedBinaryStamp;

  /// Null when the checksum pin is off or matches; otherwise the loud error.
  /// Fail-closed: an unreadable binary is treated as a verification failure.
  Future<String?> _checksumError(String binary) async {
    if (expectedSha256.isEmpty) {
      return null;
    }
    final file = File(binary);
    FileStat? stat;
    try {
      // Sync: a single stat is microseconds, and the lint is right that the
      // async variant costs more than it saves here.
      stat = file.statSync();
      final cached = _verifiedBinaryStamp;
      if (cached != null &&
          cached.path == binary &&
          cached.mtime == stat.modified &&
          cached.size == stat.size) {
        return null;
      }
    } on FileSystemException {
      // Fall through to the read, which produces the proper error message.
    }
    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException catch (e) {
      _verifiedBinaryStamp = null;
      return 'could not read tunnel binary for checksum verification '
          '($binary): ${e.message}';
    }
    final got = sha256.convert(bytes).toString();
    if (got != expectedSha256.toLowerCase()) {
      _verifiedBinaryStamp = null;
      return 'tunnel binary checksum mismatch '
          '(expected ${expectedSha256.toLowerCase()}, got $got) — '
          'refusing to spawn $binary';
    }
    if (stat != null) {
      _verifiedBinaryStamp = (
        path: binary,
        mtime: stat.modified,
        size: stat.size,
      );
    }
    return null;
  }

  /// Terminal failure: loud error state, no retry. [stop] then [start] to try
  /// again.
  void _failTerminal(String message) {
    _setStatus(state: TunnelState.error, publicUrl: null, error: message);
    _log(message);
  }

  void _dropAddress() {
    if (_lastAddress == null) {
      return;
    }
    _lastAddress = null;
    onAddress?.call(null);
  }

  void _setStatus({
    required TunnelState state,
    required String? publicUrl,
    required String? error,
  }) {
    final previous = _status;
    final next = TunnelStatus(
      provider: provider,
      state: state,
      publicUrl: publicUrl,
      error: error,
      restarts: _restarts,
      since: state == previous.state ? previous.since : DateTime.now(),
    );
    if (next.state == previous.state &&
        next.publicUrl == previous.publicUrl &&
        next.error == previous.error &&
        next.restarts == previous.restarts) {
      return;
    }
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  void _log(String message) {
    final sink = log;
    if (sink != null) {
      sink(message);
    } else {
      CcInfraLog.info('TunnelManager[${provider.name}]: $message');
    }
  }
}

/// Lines of child output retained for error reporting.
const int _tailLines = 20;

/// Matches a cloudflared quick-tunnel URL (`https://<name>.trycloudflare.com`).
final RegExp _cloudflaredUrl = RegExp(
  r'https://[a-z0-9-]+\.trycloudflare\.com',
);

/// Matches ngrok's legacy key-value text log format (`url=https://…`).
final RegExp _ngrokKvUrl = RegExp(r'url=(https://\S+)');

/// Matches a `"url":"https://…"` field embedded in a partially structured line.
final RegExp _ngrokJsonUrl = RegExp(r'"url"\s*:\s*"(https://[^"]+)"');

/// A SHA-256 digest as 64 hex characters.
final RegExp _sha256Hex = RegExp(r'^[0-9a-fA-F]{64}$');
