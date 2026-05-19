// SandboxManager owns proxy + bridge lifetimes; the sinks/processes are
// closed by `reset()` and `disposeSession()` — these lints flag false positives.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
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
  /// the caller supplies pre-built proxies, monitor and profiles dir.
  @visibleForTesting
  SandboxManager.test({
    SandboxHttpProxy? httpProxy,
    SandboxSocksProxy? socksProxy,
    SandboxViolationMonitor? violationMonitor,
    Directory? profilesDir,
  }) : _httpProxy = httpProxy,
       _socksProxy = socksProxy,
       _violationMonitor = violationMonitor,
       _profilesDir = profilesDir,
       _initFuture = Future.value();

  /// Test-injected proxies. In production these stay null: proxies are
  /// per-session (see [wrap]). `SandboxManager.test` keeps them so a test can
  /// hand in fakes without booting real listeners.
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

  /// The proxies a session is currently egressing through, if any. Exposed
  /// for diagnostics/tests — there is deliberately NO process-wide proxy: each
  /// restricted session owns its own, so one session's rules can never be
  /// applied to another's traffic.
  @visibleForTesting
  ({SandboxHttpProxy? http, SandboxSocksProxy? socks}) proxiesForSession(
    String sessionId,
  ) => (
    http: _sessions[sessionId]?.httpProxy,
    socks: _sessions[sessionId]?.socksProxy,
  );

  /// Directory under `$TMPDIR` where per-session Seatbelt profiles are kept.
  Directory get profilesDir => _profilesDir!;

  final Map<String, _SessionState> _sessions = {};

  /// Idempotent. Spins up the HTTP/SOCKS proxies and creates the per-app
  /// temp dir. Subsequent calls await the in-flight initialization.
  Future<void> ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    // No proxies are started here: they are per-session (see `wrap`), and a
    // pair of process-wide listeners nobody routes through is pure waste.
    final tmpRoot = Directory.systemTemp;
    // Seatbelt profiles describe exactly what an agent may touch, so the
    // directory is 0700 and owned by us. A predictable world-writable
    // `/tmp/control-center-sandbox` (mode 0755 by umask) can be pre-created or
    // enumerated by any local user — the rigs runtime dir already applies the
    // same 0700 discipline for the same reason.
    final profilesDir = Directory('${tmpRoot.path}/control-center-sandbox');
    if (!profilesDir.existsSync()) {
      profilesDir.createSync(recursive: true);
    }
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['700', profilesDir.path]);
      } on Object catch (e) {
        CcInfraLog.warning('sandbox: could not tighten profiles dir: $e');
      }
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
      SandboxViolation(action: 'unknown', target: line.trim(), raw: line),
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
    final session = _sessions.putIfAbsent(config.sessionId, _SessionState.new);
    // PER-SESSION proxies. These used to be process-wide singletons whose
    // rules were REWRITTEN on every wrap: a session with restricted egress
    // shared them with whatever wrapped next, so after an unrestricted spawn
    // the restricted agent's traffic was validated against `allowAll` — the
    // per-capability egress gate silently voided. The old comment claimed
    // sessions serialize ("the chat UI only runs one at a time per
    // conversation"), but this is a multi-agent server dispatching concurrent
    // runs across workspaces.
    //
    // Only a RESTRICTED session needs a proxy at all (`_proxyEnv` returns no
    // proxy env otherwise), so the unrestricted path allocates nothing.
    if (config.network.isRestricted) {
      await session.ensureProxies(
        network: config.network,
        parentProxy: config.parentProxy,
        injectedHttp: _httpProxy,
        injectedSocks: _socksProxy,
      );
    }

    if (Platform.isMacOS) {
      final result = MacosSandbox.wrapCommand(
        config: config,
        argv: argv,
        profilesDir: profilesDir,
        workingDirectory: workingDirectory,
        httpProxyPort: session.httpProxy?.port,
        socksProxyPort: session.socksProxy?.port,
      );
      session.profilePaths.add(result.profilePath);
      return SandboxWrapResult(
        executable: result.executable,
        argv: result.argv,
        environment: _proxyEnv(config: config, session: session),
      );
    }

    if (Platform.isLinux || LinuxSandbox.isWsl2()) {
      // bwrap's `--bind` refuses a missing source ("Can't find source path"),
      // and the runDir is bound so read-only modes keep their sanctioned
      // writable scratch. Nothing upstream pre-creates it (the harness makes
      // `.cc-runs/bash-output` lazily at WRITE time), so the sandbox itself
      // owns making the directory real before the argv references it.
      final runDir = config.policy?.runDir;
      if (runDir != null && runDir.isNotEmpty) {
        Directory(runDir).createSync(recursive: true);
      }
      final bridgeHandles = config.network.isRestricted
          ? await LinuxSandbox.startBridges(
              sessionId: config.sessionId,
              httpProxyPort: session.httpProxy!.port,
              socksProxyPort: session.socksProxy!.port,
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
          session: session,
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
    // Closing matters: each proxy owns a listener AND a long-lived upstream
    // `HttpClient`, so a session whose proxies are dropped without a close
    // leaks both for the process lifetime.
    await session.closeProxies();
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
    required _SessionState session,
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
    final httpPort = fromInsideSandbox ? 3128 : session.httpProxy!.port;
    final socksPort = fromInsideSandbox ? 1080 : session.socksProxy!.port;
    final httpUrl = 'http://127.0.0.1:$httpPort';
    final socksUrl = 'socks5://127.0.0.1:$socksPort';
    const noProxy =
        'localhost,127.0.0.1,::1,*.local,.local,'
        '169.254.0.0/16,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16';
    // Git-over-SSH through the SOCKS proxy so egress stays gated.
    final gitSsh =
        "ssh -o ProxyCommand='"
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

  /// This session's own egress proxies (restricted sessions only).
  SandboxHttpProxy? httpProxy;
  SandboxSocksProxy? socksProxy;

  /// Starts the proxies on first use, or re-applies [network] to the ones this
  /// session already owns (a re-wrap with changed capabilities). Rules never
  /// cross sessions.
  Future<void> ensureProxies({
    required NetworkConfig network,
    String? parentProxy,
    SandboxHttpProxy? injectedHttp,
    SandboxSocksProxy? injectedSocks,
  }) async {
    httpProxy ??=
        injectedHttp ?? await SandboxHttpProxy.start(network: network);
    httpProxy!.updateConfig(network: network, parentProxy: parentProxy);
    socksProxy ??=
        injectedSocks ?? await SandboxSocksProxy.start(network: network);
    socksProxy!.updateConfig(network: network);
    _ownsProxies = injectedHttp == null && injectedSocks == null;
  }

  /// Whether this session started its own proxies (and must therefore close
  /// them). A test-injected pair is owned by the test.
  bool _ownsProxies = true;

  /// Closes and forgets this session's proxies. Idempotent.
  Future<void> closeProxies() async {
    final http = httpProxy;
    final socks = socksProxy;
    httpProxy = null;
    socksProxy = null;
    if (!_ownsProxies) {
      return;
    }
    await http?.close();
    await socks?.close();
  }
}
