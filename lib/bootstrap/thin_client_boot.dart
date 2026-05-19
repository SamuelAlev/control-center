import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_natives/native_library_paths.dart' show nativeLibDirEnvVar;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/cc_server_process.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/theme/font_loader_install.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:path/path.dart' as p;

/// The desktop's thin-client backend against a locally-spawned `cc_server`:
/// the supervised child process plus the resilient RPC client the whole UI
/// talks to. The desktop owns NO database — the spawned server does; the
/// desktop is a pure renderer over RPC (the same path the web build uses,
/// but against a local server).
class ThinClientBackend {
  /// Creates the backend handle.
  ThinClientBackend({
    required this._holder,
    required this.client,
    required this.supervisor,
    this.mediaProxy,
  });

  final LocalServerProcessHolder _holder;

  /// The currently supervised `cc_server` child (replaced on respawn).
  CcServerProcess get process => _holder.process;

  /// The resilient RPC client (override `rpcClientProvider` with this). It
  /// survives server restarts: the supervisor respawns the child and the
  /// client re-registers every subscription transparently.
  final ResilientRpcClient client;

  /// The connection supervisor (status stream for the connection pill).
  final ServerConnectionSupervisor supervisor;

  /// Routes remote media through the spawned server's `/proxy/media`
  /// endpoint, so even the desktop fetches avatars/feed images/PR media via
  /// `cc_server` rather than hitting upstream hosts directly.
  final MediaProxyConfig? mediaProxy;

  /// Gracefully stops the local `cc_server` child WITHOUT closing the RPC
  /// client first, so the UI keeps receiving the server's
  /// `server/shutdown_progress` notifications during its teardown. Resolves
  /// once the child has exited (SIGTERM, then SIGKILL after the grace period).
  /// Call [dispose] afterwards to close the client.
  Future<void> stopServer() => _holder.process.stop();

  /// Stops the client and the child process.
  Future<void> dispose() async {
    await client.close();
    await _holder.stopWatchingQuitSignals();
    await _holder.process.stop();
  }
}

/// Mutable owner of the current child process (replaced on respawn), shared
/// between the supervisor's reconnect hook and the backend handle.
class LocalServerProcessHolder {
  /// Creates a holder for the first spawned [process].
  LocalServerProcessHolder(this.process);

  /// The live child process (replaced when the supervisor respawns it).
  CcServerProcess process;

  final List<StreamSubscription<ProcessSignal>> _signalSubs = [];

  /// Best-effort: SIGKILL whatever child is CURRENT when this app is signalled
  /// to quit, so no orphan keeps the SQLite file open against the next boot.
  ///
  /// Registered ONCE per holder, reading [process] at delivery time. Arming it
  /// inside the spawn helper instead meant every respawn added two more
  /// subscriptions, each closing over that generation's (already dead)
  /// `CcServerProcess` — 2N live listeners and N retained `Process` objects
  /// after N restarts, plus N pointless `killSync` calls on quit.
  void watchQuitSignals() {
    if (_signalSubs.isNotEmpty) {
      return;
    }
    for (final sig in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
      try {
        _signalSubs.add(sig.watch().listen((_) => process.killSync()));
      } on Object {
        // Some signals can't be watched on every platform — ignore.
      }
    }
  }

  /// Releases the quit-signal listeners (paired with [watchQuitSignals]).
  Future<void> stopWatchingQuitSignals() async {
    final subs = List.of(_signalSubs);
    _signalSubs.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
  }
}

/// Stable device id the desktop presents to its locally-spawned server. The
/// PSK is freshly generated each boot and handed to the server via env, so
/// nothing secret is persisted on the desktop side.
const String localDesktopDeviceId = 'desktop-thin-local';

String _generatePsk() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
  return base64Url.encode(bytes);
}

/// Spawns a local `cc_server`, provisions a one-time loopback credential via
/// env (the server upserts it as an active paired device on boot) and wires
/// a [ServerConnectionSupervisor] + [ResilientRpcClient] over the loopback
/// endpoint — including automatic respawn: if the child dies, the supervisor
/// restarts it and the UI reconnects without losing its subscriptions.
///
/// The server's data dir is the app-support root, so it opens the SAME
/// `control_center.db` the desktop created before the thin-client flip.
///
/// Throws on failure: the desktop is a pure client and cannot self-serve, so
/// a missing/failed server is surfaced to the boot path rather than silently
/// degraded.
Future<ThinClientBackend> startThinClientBackend() async {
  final dataDir = (await controlCenterRootDir()).path;
  // One PSK per app boot, reused across respawns so the supervisor's stored
  // credential keeps working when the child is restarted.
  final psk = _generatePsk();

  final holder = LocalServerProcessHolder(
    await _spawnLocalServer(dataDir: dataDir, psk: psk),
  )..watchQuitSignals();
  final endpoint = holder.process.endpoint!;

  // Learn the server's identity (id + fingerprint) from its health endpoint;
  // the Ed25519 handshake then proves it on every connect.
  final probe = await probeServerIdentity(
    Uri.parse('http://127.0.0.1:${endpoint.port}'),
  );
  if (probe == null) {
    holder.process.killSync();
    throw StateError(
      'The spawned cc_server did not report its identity on /healthz.',
    );
  }

  // The desktop launches a PREBUILT cc_server in preference to source, so the
  // binary can silently lag the app it ships inside (the classic "works in
  // tests, not in the running app" symptom: a new RPC op returns opUnknown).
  // The probe already carries the server's build identity — say so at boot
  // rather than leaving it to be discovered as a mystery failure. Not fatal:
  // an older server still serves everything it knows how to serve.
  if (probe.gitSha != null && probe.gitSha != BuildInfo.buildGitSha) {
    AppLog.w(
      'ThinClientBoot',
      'cc_server build ${probe.version ?? '?'} (${probe.gitSha}) differs from '
          'this app ${BuildInfo.buildVersion} (${BuildInfo.buildGitSha}). '
          'Rebuild it with: cd apps/cc_server && dart build cli',
    );
  }

  ConnectionDescriptor loopbackDescriptor(int port) => ConnectionDescriptor(
    serverId: probe.serverId,
    serverName: probe.serverName,
    fingerprint: probe.fingerprint,
    paths: [LoopbackPath(port: port)],
  );

  late final ServerConnectionSupervisor supervisor;
  supervisor = ServerConnectionSupervisor(
    descriptor: loopbackDescriptor(endpoint.port),
    deviceId: localDesktopDeviceId,
    psk: psk,
    pinnedFingerprint: probe.fingerprint,
    beforeReconnect: () async {
      if (holder.process.isRunning) {
        return;
      }
      AppLog.w('cc_server', 'local cc_server exited — respawning');
      holder.process = await _spawnLocalServer(dataDir: dataDir, psk: psk);
      supervisor.adoptDescriptor(
        loopbackDescriptor(holder.process.endpoint!.port),
      );
    },
  );
  await supervisor.start();
  final client = ResilientRpcClient(supervisor);
  AppLog.i('cc_server', 'thin client connected on ${endpoint.rpcUri}');
  final mediaProxy = MediaProxyConfig.fromConnection(
    serverUri: endpoint.rpcUri,
    deviceId: localDesktopDeviceId,
    psk: psk,
  );
  // A user-selected font's bytes come from the host too (see
  // `installHostFontLoader`), so it is armed with the same connection.
  installHostFontLoader(mediaProxy);
  return ThinClientBackend(
    holder: holder,
    client: client,
    supervisor: supervisor,
    mediaProxy: mediaProxy,
  );
}

/// Locates, spawns and readies one `cc_server` child.
Future<CcServerProcess> _spawnLocalServer({
  required String dataDir,
  required String psk,
}) async {
  final server = CcServerLauncher.resolve(
    dataDir: dataDir,
    port: 0,
    environment: {
      'CC_BOOTSTRAP_DEVICE_ID': localDesktopDeviceId,
      'CC_BOOTSTRAP_PSK': psk,
      // The desktop's embedded server is managed by the app bundle: updating
      // it means updating the app (which swaps the whole tree). `cc_server
      // update` refuses with an explanatory no-op when this is set.
      'CC_EMBEDDED': '1',
      // No credentials are forwarded from here. The server reads the
      // repo-root `.env` itself (`environmentWithDotenv`), which is what makes
      // the same file work for a server this app did NOT spawn — a packaged
      // binary, a systemd unit, docker.
      // Exit when this desktop (our parent) dies. The server watches its stdin
      // pipe for EOF — robust against SIGKILL / a `flutter run` teardown that
      // never lets our SIGINT/SIGTERM handler run — so it never orphans and
      // holds control_center.db open against the next boot.
      'CC_EXIT_WITH_PARENT': '1',
      // Point the pure-Dart server at THIS app's bundled native-library dir so
      // it can load the sherpa-onnx / onnxruntime dylibs Flutter shipped with
      // the desktop (the server has no plugin bundling of its own). Without it
      // meeting transcription + diarization fail silently host-side.
      ...?_bundledNativeLibDirEnv(),
    },
    onLog: (level, message) => level == 'error'
        ? AppLog.w('cc_server', message)
        : AppLog.i('cc_server', message),
  );
  if (server == null) {
    throw StateError(
      'Could not locate a runnable cc_server.\n\n'
      'Searched these locations:\n'
      '${CcServerLauncher.describeSearchedLocations()}\n\n'
      'Fix: build the binary with `dart build cli` inside apps/cc_server, or '
      'launch the app with the repo root as the working directory so the built '
      'binary (or the dev `dart run` fallback) resolves. To skip the local '
      'server entirely, choose "Connect to a remote instance" on the setup '
      'screen.',
    );
  }

  await server.start();
  // NOTE: quit-signal teardown is armed ONCE by the holder
  // (`LocalServerProcessHolder.watchQuitSignals`), not here — arming it per
  // spawn leaked a subscription pair per respawn.
  return server;
}

/// The `{[nativeLibDirEnvVar]: <dir>}` entry for the spawned server's
/// environment, where `<dir>` is THIS desktop app's bundled native-library
/// directory (macOS `Contents/Frameworks`, Linux `<exeDir>/lib`, Windows beside
/// the exe). The server reads it to load the sherpa-onnx / onnxruntime dylibs
/// Flutter bundled with the app.
///
/// Returns null when the directory can't be derived or doesn't exist (e.g. a
/// platform with no bundled natives), so the spread adds nothing and the server
/// falls back to its own resolution.
Map<String, String>? _bundledNativeLibDirEnv() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final String dir;
  if (Platform.isMacOS) {
    dir = p.normalize(p.join(exeDir, '..', 'Frameworks'));
  } else if (Platform.isLinux) {
    dir = p.join(exeDir, 'lib');
  } else if (Platform.isWindows) {
    dir = exeDir;
  } else {
    return null;
  }
  if (!Directory(dir).existsSync()) {
    return null;
  }
  return {nativeLibDirEnvVar: dir};
}
