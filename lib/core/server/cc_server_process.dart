import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The loopback endpoint a spawned [CcServerProcess] is listening on.
class CcServerEndpoint {
  /// Creates an endpoint for [host]:[port].
  const CcServerEndpoint({required this.host, required this.port});

  /// The bound host (loopback by default).
  final String host;

  /// The bound TCP port (resolved from the server's ready line; `0` becomes the
  /// real ephemeral port the OS assigned).
  final int port;

  /// The RPC WebSocket URI a `RemoteRpcClient` dials.
  Uri get rpcUri => Uri.parse('ws://$host:$port/rpc');

  @override
  String toString() => 'CcServerEndpoint($host:$port)';
}

/// Thrown when the spawned server fails to report readiness in time, or exits
/// before it ever became ready.
class CcServerStartException implements Exception {
  /// Creates a [CcServerStartException].
  const CcServerStartException(this.message);

  /// Human-readable detail.
  final String message;

  @override
  String toString() => 'CcServerStartException: $message';
}

/// Spawns and supervises the pure-Dart `cc_server` binary as a child process,
/// then exposes the loopback [CcServerEndpoint] it bound.
///
/// This is the desktop half of Fork A: instead of opening the database itself,
/// the desktop launches `cc_server` (which owns the data) and talks to it over
/// loopback RPC — the same thin-client path the web build uses. The binary is a
/// `dart build cli` native executable (see `apps/cc_server`); it prints a
/// `cc_server ready on <host>:<port>` line on stdout once listening, which is
/// how [start] learns the bound port (supporting `--port 0` ephemeral binding).
///
/// Lifecycle: [start] → [endpoint]/[exitCode] → [stop]. The supervisor does not
/// auto-restart; callers that want resilience watch [exitCode] and re-[start] a
/// fresh instance (a dead child means a new endpoint).
class CcServerProcess {
  /// Creates a supervisor that will run [executable] with [args].
  ///
  /// [onLog] receives every stdout/stderr line (level `'info'`/`'error'`) for
  /// surfacing in the desktop's diagnostics. [environment] and [workingDirectory]
  /// are passed through to [Process.start].
  CcServerProcess({
    required this.executable,
    required this.args,
    this.onLog,
    this.environment,
    this.workingDirectory,
  });

  /// The program to run (the `cc_server` binary, or a Dart SDK for `dart run`).
  final String executable;

  /// Arguments (e.g. `--data-dir`, `--port`, `--bind`).
  final List<String> args;

  /// Optional sink for the child's stdout/stderr lines.
  final void Function(String level, String message)? onLog;

  /// Optional process environment overrides.
  final Map<String, String>? environment;

  /// Optional working directory for the child process.
  final String? workingDirectory;

  static final RegExp _readyPattern = RegExp(
    r'cc_server ready on ([^\s:]+):(\d+)',
  );

  Process? _process;
  final Completer<CcServerEndpoint> _ready = Completer<CcServerEndpoint>();
  CcServerEndpoint? _endpoint;
  bool _stopRequested = false;
  bool _exited = false;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  /// The endpoint once the server is ready, else null.
  CcServerEndpoint? get endpoint => _endpoint;

  /// Whether the child process is currently running (became ready and has not
  /// exited or been stopped). Flips to `false` the moment the child exits on its
  /// own, not only when [stop] is called.
  bool get isRunning =>
      _process != null && _endpoint != null && !_stopRequested && !_exited;

  /// Resolves with the child's exit code (after [start] has spawned it).
  Future<int>? get exitCode => _process?.exitCode;

  /// Spawns the server and resolves once it reports the loopback endpoint it
  /// bound. Throws [CcServerStartException] on timeout or premature exit, after
  /// killing the child so no orphan is left behind.
  Future<CcServerEndpoint> start({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_process != null) {
      throw StateError('CcServerProcess already started');
    }
    final Process process;
    try {
      process = await Process.start(
        executable,
        args,
        environment: environment,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (e) {
      throw CcServerStartException('could not spawn cc_server: ${e.message}');
    }
    _process = process;

    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onStdoutLine);
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLog?.call('error', line));

    // Track child exit whether it dies before readiness (a startup failure) or
    // after (a crash): mark exited, release the stdout/stderr subscriptions so
    // they never leak, and surface a startup error if we were still waiting.
    unawaited(
      process.exitCode.then((code) {
        _exited = true;
        unawaited(_stdoutSub?.cancel());
        unawaited(_stderrSub?.cancel());
        if (!_ready.isCompleted) {
          _ready.completeError(
            CcServerStartException(
              'cc_server exited with code $code before becoming ready',
            ),
          );
        }
      }),
    );

    try {
      final endpoint = await _ready.future.timeout(timeout);
      _endpoint = endpoint;
      return endpoint;
    } on TimeoutException {
      await _kill();
      throw const CcServerStartException(
        'cc_server did not report readiness in time',
      );
    }
  }

  void _onStdoutLine(String line) {
    onLog?.call('info', line);
    if (_ready.isCompleted) {
      return;
    }
    final match = _readyPattern.firstMatch(line);
    if (match != null) {
      final port = int.tryParse(match.group(2) ?? '');
      if (port != null) {
        _ready.complete(
          CcServerEndpoint(host: match.group(1) ?? '127.0.0.1', port: port),
        );
      }
    }
  }

  /// Stops the server (SIGTERM, escalating to SIGKILL after a grace period) and
  /// awaits its exit. Idempotent.
  Future<void> stop({
    Duration grace = const Duration(seconds: 5),
  }) async {
    _stopRequested = true;
    final process = _process;
    if (process == null) {
      return;
    }
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(grace);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    } finally {
      await _stdoutSub?.cancel();
      await _stderrSub?.cancel();
      _process = null;
    }
  }

  /// Best-effort SYNCHRONOUS kill for use in `State.dispose()` (which cannot
  /// await [stop]). Sends SIGKILL immediately so a fast app-quit does not leave
  /// an orphaned cc_server holding the SQLite file open (which would then fail
  /// the next boot's seed). Idempotent.
  void killSync() {
    _stopRequested = true;
    _process?.kill(ProcessSignal.sigkill);
  }

  Future<void> _kill() async {
    final process = _process;
    if (process != null) {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _process = null;
  }
}

/// Builds a [CcServerProcess] for the real `cc_server`, resolving where the
/// binary lives.
///
/// Resolution order:
///   1. an explicit `binaryPath` (e.g. one bundled next to the desktop app);
///   2. the `dart build cli` output under `apps/cc_server/build/cli/.../bin`
///      (developer machines that have built it);
///   3. a dev fallback: `<dartSdk> run apps/cc_server/bin/cc_server.dart`.
///
/// Returns null when nothing is runnable (no binary and no Dart SDK), so the
/// desktop can fall back to its in-process path instead of crashing.
class CcServerLauncher {
  const CcServerLauncher._();

  /// Standard server args from a [dataDir] / [port] / [bind].
  static List<String> serverArgs({
    required String dataDir,
    int port = 0,
    String bind = 'loopback',
  }) => [
    '--data-dir',
    dataDir,
    '--port',
    '$port',
    '--bind',
    bind,
  ];

  /// A supervisor for an already-built binary at [binaryPath].
  static CcServerProcess fromBinary({
    required String binaryPath,
    required String dataDir,
    int port = 0,
    String bind = 'loopback',
    void Function(String level, String message)? onLog,
    Map<String, String>? environment,
  }) {
    return CcServerProcess(
      executable: binaryPath,
      args: serverArgs(dataDir: dataDir, port: port, bind: bind),
      onLog: onLog,
      environment: environment,
    );
  }

  /// Best-effort resolution of a runnable server for the desktop thin client.
  ///
  /// Tries, in order: a binary bundled beside the app (packaged release); a
  /// `dart build cli` binary under
  /// `<root>/apps/cc_server/build/cli/<os_arch>/bundle/bin/cc_server`; then a
  /// dev `dart run` via the repo's fvm-pinned SDK. Returns null when none is
  /// available so the caller can surface a clear message instead of crashing.
  ///
  /// `<root>` is [repoRoot] if given, else the repo root discovered by walking
  /// up from the running executable (see [_discoverRepoRoot]) — so a `flutter
  /// run` / unpackaged build resolves the source-tree server even though its
  /// working directory is not reliably the repo root — falling back to the
  /// current directory.
  static CcServerProcess? resolve({
    required String dataDir,
    String? repoRoot,
    int port = 0,
    String bind = 'loopback',
    void Function(String level, String message)? onLog,
    Map<String, String>? environment,
  }) {
    final root = repoRoot ?? _discoverRepoRoot() ?? Directory.current.path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    // First runnable prebuilt binary wins: the bundle copied next to a packaged
    // desktop app, then any `dart build cli` arch output under the repo. See
    // [_binaryCandidates] for the full probe order and rationale.
    for (final binary in _binaryCandidates(exeDir: exeDir, root: root)) {
      if (File(binary).existsSync()) {
        return fromBinary(
          binaryPath: binary,
          dataDir: dataDir,
          port: port,
          bind: bind,
          onLog: onLog,
          environment: environment,
        );
      }
    }

    // Dev fallback: run from source with the repo's fvm-pinned Dart SDK.
    final dart = _devDartPath(root);
    final entry = _devEntryPath(root);
    if (File(dart).existsSync() && File(entry).existsSync()) {
      return devRun(
        dartExecutable: dart,
        repoRoot: root,
        dataDir: dataDir,
        port: port,
        bind: bind,
        onLog: onLog,
        environment: environment,
      );
    }
    return null;
  }

  static String _devDartPath(String root) => '$root/.fvm/flutter_sdk/bin/dart';
  static String _devEntryPath(String root) =>
      '$root/apps/cc_server/bin/cc_server.dart';

  /// Walks up from the running executable — and the current directory — to find
  /// the repo root: the nearest ancestor containing the server's source entry
  /// (`apps/cc_server/bin/cc_server.dart`).
  ///
  /// Under `flutter run` the process working directory is not reliably the repo
  /// root, but the (debug/profile) executable lives *inside* the source tree
  /// (`build/<platform>/.../<app>`), so walking up from it recovers the root and
  /// lets [resolve] find the source-tree binary or dev `dart run` without a CWD
  /// assumption. Returns null for a packaged app installed outside the source
  /// tree (which resolves its bundled, exe-relative binary first regardless).
  static String? _discoverRepoRoot() {
    const marker = 'apps/cc_server/bin/cc_server.dart';
    final starts = <String>{
      File(Platform.resolvedExecutable).parent.path,
      Directory.current.path,
    };
    for (final start in starts) {
      for (var dir = Directory(start); ; dir = dir.parent) {
        if (File('${dir.path}/$marker').existsSync()) {
          return dir.path;
        }
        if (dir.parent.path == dir.path) {
          break; // reached the filesystem root
        }
      }
    }
    return null;
  }

  /// The concrete prebuilt-binary paths [resolve] probes, highest priority
  /// first:
  ///   1. the bundle copied beside a packaged desktop app (macOS
  ///      `Contents/Resources/cc_server`, Linux/Windows a `cc_server/` dir
  ///      beside the exe) — so a shipped app finds its server without the
  ///      source tree;
  ///   2. each `dart build cli` arch output under
  ///      `<root>/apps/cc_server/build/cli/<arch>/bundle/bin/cc_server`.
  ///
  /// Shared with [describeSearchedLocations] so the "could not locate" error
  /// reports exactly the paths a failed lookup probed.
  static List<String> _binaryCandidates({
    required String exeDir,
    required String root,
  }) {
    final candidates = <String>[
      '$exeDir/../Resources/cc_server/bin/cc_server', // macOS .app
      '$exeDir/cc_server/bin/cc_server', // Linux / Windows beside the exe
      '$exeDir/cc_server/bin/cc_server.exe', // Windows
    ];
    final cliDir = Directory('$root/apps/cc_server/build/cli');
    if (cliDir.existsSync()) {
      for (final arch in cliDir.listSync().whereType<Directory>()) {
        candidates.add('${arch.path}/bundle/bin/cc_server');
      }
    }
    return candidates;
  }

  /// A multi-line, human-readable account of every location [resolve] probes
  /// for a runnable server, each flagged `[found]`/`[missing]` by whether it
  /// exists right now, preceded by the working directory it resolved against.
  ///
  /// Surfaced verbatim in the "could not locate cc_server" error so a failed
  /// lookup shows exactly where it looked. When the binary *is* built but the
  /// lookup still fails, the usual cause is a working directory that is not the
  /// repo root — then `<root>/apps/cc_server/build/cli` does not exist and no
  /// arch candidate is probed; this lists that expected path explicitly so the
  /// wrong working directory is obvious.
  static String describeSearchedLocations({String? repoRoot}) {
    final root = repoRoot ?? _discoverRepoRoot() ?? Directory.current.path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    String line(String path, {required bool exists}) =>
        '  ${exists ? '[found]  ' : '[missing]'} $path';

    final lines = <String>['working directory: $root'];
    for (final binary in _binaryCandidates(exeDir: exeDir, root: root)) {
      lines.add(line(binary, exists: File(binary).existsSync()));
    }
    final cliDir = '$root/apps/cc_server/build/cli';
    if (!Directory(cliDir).existsSync()) {
      lines.add(line('$cliDir/<arch>/bundle/bin/cc_server', exists: false));
    }
    final dart = _devDartPath(root);
    final entry = _devEntryPath(root);
    final devOk = File(dart).existsSync() && File(entry).existsSync();
    lines.add(line('dev run: $dart $entry', exists: devOk));
    return lines.join('\n');
  }

  /// A supervisor that runs the server from source via the Dart SDK
  /// (`<dartExecutable> run <repoRoot>/apps/cc_server/bin/cc_server.dart`).
  static CcServerProcess devRun({
    required String dartExecutable,
    required String repoRoot,
    required String dataDir,
    int port = 0,
    String bind = 'loopback',
    void Function(String level, String message)? onLog,
    Map<String, String>? environment,
  }) {
    final entry = _devEntryPath(repoRoot);
    return CcServerProcess(
      executable: dartExecutable,
      args: ['run', entry, ...serverArgs(dataDir: dataDir, port: port, bind: bind)],
      workingDirectory: repoRoot,
      onLog: onLog,
      environment: environment,
    );
  }
}
