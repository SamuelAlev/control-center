// SandboxManager owns proxy + bridge lifetimes; the sinks/processes are
// closed by `reset()` and `disposeSession()` — these lints flag false positives.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/socks_proxy.dart';
import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:meta/meta.dart';

/// Process-wide singleton that owns the in-process HTTP/SOCKS proxies and
/// the per-session temp files (Seatbelt profiles on macOS, socket bridges on
/// Linux/WSL2).
///
/// Lifecycle:
/// 1. `initialize()` is called once at app start — spawns the proxies.
/// 2. `wrap(config, argv, workdir)` produces the executable+argv list that
///    runs the user command inside the sandbox. Per-session temp files are
///    tracked under the session id so `disposeSession` can clean them up.
/// 3. `reset()` is called at app shutdown.
class SandboxManager {
  /// Creates a new manager. Resources (proxies, temp dir) are lazily acquired
  /// on the first call to [wrap]; construction itself is cheap so Riverpod
  /// can keep using a synchronous `Provider`.
  SandboxManager();
  /// Injectable constructor for tests. Bypasses lazy initialization —
  /// the caller supplies pre-built proxies, monitor, and profiles dir.
  @visibleForTesting
  SandboxManager.test({
    SandboxHttpProxy? httpProxy,
    SandboxSocksProxy? socksProxy,
    SandboxViolationMonitor? violationMonitor,
    Directory? profilesDir,
  })  : _httpProxy = httpProxy,
        _socksProxy = socksProxy,
        _violationMonitor = violationMonitor,
        _profilesDir = profilesDir,
        _initFuture = Future.value();

  SandboxHttpProxy? _httpProxy;
  SandboxSocksProxy? _socksProxy;
  Directory? _profilesDir;
  Future<void>? _initFuture;
  SandboxViolationMonitor? _violationMonitor;
  final StreamController<SandboxViolation> _violations =
      StreamController<SandboxViolation>.broadcast();

  /// Broadcast stream of OS-level sandbox denials.
  ///
  /// On macOS this is fed by `log stream` (see [SandboxViolationMonitor]).
  /// On Linux/WSL2 the adapter feeds it via [reportLinuxStderr].
  Stream<SandboxViolation> get violations => _violations.stream;

  /// In-process HTTP proxy listening on `127.0.0.1`. Throws if accessed
  /// before the first [wrap] / [ensureInitialized] call.
  SandboxHttpProxy get httpProxy => _httpProxy!;

  /// In-process SOCKS5 proxy listening on `127.0.0.1`. Throws if accessed
  /// before the first [wrap] / [ensureInitialized] call.
  SandboxSocksProxy get socksProxy => _socksProxy!;

  /// Directory under `$TMPDIR` where per-session Seatbelt profiles are kept.
  Directory get profilesDir => _profilesDir!;

  final Map<String, _SessionState> _sessions = {};

  /// Idempotent. Spins up the HTTP/SOCKS proxies and creates the per-app
  /// temp dir. Subsequent calls await the in-flight initialization.
  Future<void> ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _httpProxy = await SandboxHttpProxy.start();
    _socksProxy = await SandboxSocksProxy.start();
    final tmpRoot = Directory.systemTemp;
    final profilesDir = Directory('${tmpRoot.path}/control-center-sandbox');
    if (!profilesDir.existsSync()) {
      profilesDir.createSync(recursive: true);
    }
    _profilesDir = profilesDir;
    _violationMonitor = await SandboxViolationMonitor.start();
    _violationMonitor?.stream.listen(_violations.add);
  }

  /// Parses a stderr line from a sandboxed process for `EPERM` /
  /// `Operation not permitted` patterns and forwards a corresponding
  /// violation if recognised. Linux/WSL2 entry point — see [violations].
  void reportLinuxStderr(String line) {
    if (!line.contains('Operation not permitted') &&
        !line.contains('EPERM') &&
        !line.contains('Permission denied')) {
      return;
    }
    _violations.add(
      SandboxViolation(
        action: 'unknown',
        target: line.trim(),
        raw: line,
      ),
    );
  }

  /// Returns the argv to spawn that runs [argv] inside the sandbox described
  /// by [config], plus the environment variables the caller should merge
  /// into the child's `Process.start` environment.
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async {
    await ensureInitialized();
    // Apply the per-session network rules to the shared proxies *before*
    // spawning the user command. If two sessions need different rules, they
    // must serialize their invocations — the chat UI only runs one at a time
    // per conversation, so this is fine in practice.
    httpProxy.updateConfig(
      network: config.network,
      parentProxy: config.parentProxy,
    );
    socksProxy.updateConfig(network: config.network);

    final session = _sessions.putIfAbsent(
      config.sessionId,
      _SessionState.new,
    );

    if (Platform.isMacOS) {
      final result = MacosSandbox.wrapCommand(
        config: config,
        argv: argv,
        profilesDir: profilesDir,
        workingDirectory: workingDirectory,
        httpProxyPort: config.network.isRestricted ? httpProxy.port : null,
        socksProxyPort: config.network.isRestricted ? socksProxy.port : null,
      );
      session.profilePaths.add(result.profilePath);
      return SandboxWrapResult(
        executable: result.executable,
        argv: result.argv,
        environment: _proxyEnv(config: config),
      );
    }

    if (Platform.isLinux || LinuxSandbox.isWsl2()) {
      final bridgeHandles = config.network.isRestricted
          ? await LinuxSandbox.startBridges(
              sessionId: config.sessionId,
              httpProxyPort: httpProxy.port,
              socksProxyPort: socksProxy.port,
            )
          : const LinuxBridgeHandles(processes: [], bridges: []);
      session.linuxBridges.add(bridgeHandles);
      final result = LinuxSandbox.wrapCommand(
        config: config,
        argv: argv,
        bridges: bridgeHandles.bridges,
        workingDirectory: workingDirectory,
      );
      return SandboxWrapResult(
        executable: result.executable,
        argv: result.argv,
        environment: _proxyEnv(
          config: config,
          fromInsideSandbox: bridgeHandles.bridges.isNotEmpty,
          bridges: bridgeHandles.bridges,
        ),
      );
    }

    throw UnsupportedError(
      'Native sandbox is not available on ${Platform.operatingSystem}',
    );
  }

  /// Releases per-session resources (Seatbelt profile files, Linux socket
  /// bridges). Safe to call multiple times.
  Future<void> disposeSession(String sessionId) async {
    final session = _sessions.remove(sessionId);
    if (session == null) {
      return;
    }
    for (final path in session.profilePaths) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    for (final h in session.linuxBridges) {
      await h.dispose();
    }
  }

  /// Tears down proxies and clears every session.
  Future<void> reset() async {
    for (final id in _sessions.keys.toList()) {
      await disposeSession(id);
    }
    await _httpProxy?.close();
    await _socksProxy?.close();
    await _violationMonitor?.close();
    await _violations.close();
    _httpProxy = null;
    _socksProxy = null;
    _profilesDir = null;
    _violationMonitor = null;
    _initFuture = null;
  }

  Map<String, String> _proxyEnv({
    required SandboxConfig config,
    bool fromInsideSandbox = false,
    List<dynamic> bridges = const [],
  }) {
    if (!config.network.isRestricted) {
      return const {};
    }
    // On Linux/WSL2 the sandboxed process reaches the proxy through an
    // in-sandbox `socat` listener on a fixed loopback port (3128 for HTTP,
    // 1080 for SOCKS — see LinuxSandbox.startBridges). On macOS the sandbox
    // shares the host loopback, so it talks to the proxy directly.
    final httpPort = fromInsideSandbox ? 3128 : httpProxy.port;
    final socksPort = fromInsideSandbox ? 1080 : socksProxy.port;
    final httpUrl = 'http://127.0.0.1:$httpPort';
    final socksUrl = 'socks5://127.0.0.1:$socksPort';
    final noProxy = 'localhost,127.0.0.1,::1,*.local,.local,'
        '169.254.0.0/16,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16';
    // Git-over-SSH through the SOCKS proxy so egress stays gated.
    final gitSsh = "ssh -o ProxyCommand='"
        "nc -X 5 -x localhost:$socksPort %h %p'";
    return {
      'HTTP_PROXY': httpUrl,
      'HTTPS_PROXY': httpUrl,
      'http_proxy': httpUrl,
      'https_proxy': httpUrl,
      'FTP_PROXY': httpUrl,
      'ftp_proxy': httpUrl,
      'ALL_PROXY': socksUrl,
      'all_proxy': socksUrl,
      'NO_PROXY': noProxy,
      'no_proxy': noProxy,
      'GIT_SSH_COMMAND': gitSsh,
    };
  }
}

/// Result of [SandboxManager.wrap]. Caller is expected to spawn
/// [executable] with [argv] and merge [environment] into the child env.
class SandboxWrapResult {
  /// Creates a [SandboxWrapResult].
  const SandboxWrapResult({
    required this.executable,
    required this.argv,
    required this.environment,
  });

  /// Executable to spawn (e.g. `/usr/bin/sandbox-exec` or `bwrap`).
  final String executable;

  /// Argv list passed to [Process.start].
  final List<String> argv;

  /// Environment to merge into the spawned process. Keys are uppercase +
  /// lowercase variants of the proxy vars to maximise compatibility with
  /// tools that only honour one casing convention.
  final Map<String, String> environment;
}

class _SessionState {
  final List<String> profilePaths = [];
  final List<LinuxBridgeHandles> linuxBridges = [];
}
