import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_natives/cc_natives.dart' show nativeLibDirEnvVar;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, connectRemoteRpc;
import 'package:control_center/core/config/env_config.dart';
import 'package:control_center/core/server/cc_server_process.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:path/path.dart' as p;

/// The desktop's thin-client backend: a spawned `cc_server` subprocess plus the
/// connected RPC client the whole UI talks to. The desktop owns NO database —
/// the spawned server does; the desktop is a pure renderer over RPC (the same
/// path the web build uses, but against a locally-spawned server).
class ThinClientBackend {
  /// Creates the backend handle.
  ThinClientBackend({
    required this.process,
    required this.client,
    this.mediaProxy,
  });

  /// The supervised `cc_server` child process.
  final CcServerProcess process;

  /// The connected RPC client (override `rpcClientProvider` with this).
  final RemoteRpcClient client;

  /// Routes remote media through the spawned server's `/proxy/media` endpoint,
  /// so even the desktop fetches avatars/feed images/PR media via `cc_server`
  /// rather than hitting upstream hosts directly. Null only if the loopback
  /// endpoint can't be expressed as a proxy base (should not happen).
  final MediaProxyConfig? mediaProxy;
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
/// env (the server upserts it as an active paired device on boot), and connects
/// a [RemoteRpcClient] over the loopback endpoint it reports.
///
/// The server's data dir is the app-support root, so it opens the SAME
/// `control_center.db` the desktop created before the thin-client flip — no
/// data migration, single-owner access (the desktop never opens the file).
///
/// Throws on failure: the desktop is a pure client and cannot self-serve, so a
/// missing/failed server is surfaced to the boot path rather than silently
/// degraded.
Future<ThinClientBackend> startThinClientBackend() async {
  final dataDir = (await controlCenterRootDir()).path;
  final psk = _generatePsk();
  final server = CcServerLauncher.resolve(
    dataDir: dataDir,
    port: 0,
    environment: {
      'CC_BOOTSTRAP_DEVICE_ID': localDesktopDeviceId,
      'CC_BOOTSTRAP_PSK': psk,
      // Pass the desktop's Klipy app key (from a repo-root `.env` /
      // --dart-define) through to the spawned server so the composer's GIF
      // picker works server-side. Omitted when unset (the picker shows empty).
      if (EnvConfig.klipyAppKey.isNotEmpty)
        'CC_KLIPY_APP_KEY': EnvConfig.klipyAppKey,
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

  final endpoint = await server.start();
  // Best-effort: tear the child down when this process is signalled to quit so
  // no orphan keeps the SQLite file open (which would fail the next boot).
  for (final sig in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    try {
      sig.watch().listen((_) => server.killSync());
    } on Object {
      // Some signals can't be watched on every platform — ignore.
    }
  }

  final client = await connectRemoteRpc(
    uri: endpoint.rpcUri,
    deviceId: localDesktopDeviceId,
    psk: psk,
  );
  AppLog.i('cc_server', 'thin client connected on ${endpoint.rpcUri}');
  return ThinClientBackend(
    process: server,
    client: client,
    mediaProxy: MediaProxyConfig.fromConnection(
      serverUri: endpoint.rpcUri,
      deviceId: localDesktopDeviceId,
      psk: psk,
    ),
  );
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
