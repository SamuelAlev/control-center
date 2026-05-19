import 'dart:async';
import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';

/// Entrypoint for the Control Center headless server — a pure-Dart binary
/// (no Flutter engine). Build a native executable with `dart build cli` from
/// this package dir; the bundle ships `libsqlite3` alongside it.
///
/// Subcommands:
///  * `pair` — provision a device + PSK so a thin client can connect, print the
///    pairing key (and, with `--client-url`, a scannable QR), then exit. Run it
///    once against a fresh `--data-dir` before starting the server.
///  * `calendar connect --workspace <id>` — connect a Google account to a
///    workspace via the device-code flow (prints a code + URL to approve on
///    another device), store its refresh token server-side, then exit.
///  * (default) — run the server until SIGINT/SIGTERM, then shut down cleanly.
///
/// Config via flags/env (see [CcServerConfig]): `--data-dir`, `--port`,
/// `--bind`. `pair` also accepts `--device`, `--label`, `--workspace-name`,
/// `--host`, and `--client-url`.
Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args.first == 'pair') {
    await _pair(args.sublist(1));
    return;
  }

  if (args.isNotEmpty && args.first == 'calendar') {
    await _calendar(args.sublist(1));
    return;
  }

  final server = await runCcServer(args: args);

  final done = Completer<void>();
  void requestShutdown() {
    if (!done.isCompleted) {
      done.complete();
    }
  }

  for (final sig in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    sig.watch().listen((_) => requestShutdown());
  }

  // Parent-death watchdog. When the desktop spawns us as a supervised child it
  // sets CC_EXIT_WITH_PARENT and holds the write end of our stdin pipe. If that
  // parent dies — even via SIGKILL, a `flutter run` teardown, or a crash that
  // never delivers US a signal — the pipe closes and stdin hits EOF, so we shut
  // down instead of orphaning and holding control_center.db open (which would
  // fail the next boot's seed). Gated by the env var so a standalone / headless
  // run with no stdin attached does not exit immediately.
  if (Platform.environment['CC_EXIT_WITH_PARENT'] == '1') {
    stdin.listen(
      (_) {},
      onDone: requestShutdown,
      onError: (_) => requestShutdown(),
      cancelOnError: true,
    );
  }

  await done.future;
  // Watching SIGINT/SIGTERM overrides their default "terminate the process"
  // behaviour, so once we are asked to stop we MUST exit ourselves. Even after a
  // clean shutdown the VM would otherwise linger: the runtime's reconcilers /
  // pipeline-engine timers and drift's background isolate keep the event loop
  // alive, so `main` returning never terminates the process (the symptom: Ctrl+C
  // logs "LocalRpcServer stopped" but you still need `kill -9`). Shut down
  // best-effort with a cap, then hard-exit.
  try {
    await server.shutdown().timeout(const Duration(seconds: 5));
  } on Object catch (e) {
    stderr.writeln('cc_server: shutdown did not complete cleanly: $e');
  }
  await stdout.flush();
  exit(0);
}

/// Provisions a paired device against the data dir and prints the pairing key —
/// plus a deep link + terminal QR when a `--client-url` (the web client's
/// origin) is supplied — for a thin client to connect.
Future<void> _pair(List<String> args) async {
  final config = CcServerConfig.resolve(args);
  final result = await pairDevice(
    config: config,
    deviceId: _flag(args, 'device') ?? 'web-client',
    label: _flag(args, 'label'),
    workspaceName: _flag(args, 'workspace-name'),
  );

  // `any`-bind requires TLS (LocalRpcServer refuses plaintext off-loopback), so
  // a reachable URL is wss; loopback is plain ws. `--host` overrides the host
  // in the printed/encoded URL (loopback can't be reached from a phone — pass
  // the Mac's LAN IP or a tunnel host).
  final scheme = config.bindAny ? 'wss' : 'ws';
  final host = _flag(args, 'host') ?? (config.bindAny ? '<this-host>' : 'localhost');
  final serverUrl = '$scheme://$host:${config.port}/rpc';

  stdout.writeln('Paired a device in ${result.dataDir}');
  if (result.createdWorkspace) {
    stdout.writeln('  created workspace "${result.workspaceName}"');
  } else {
    stdout.writeln('  workspace: ${result.workspaceName}');
  }
  stdout
    ..writeln('')
    ..writeln('Connect a thin client (paste into its connect form):')
    ..writeln('  Server      $serverUrl')
    ..writeln('  Device id   ${result.deviceId}')
    ..writeln('  Pairing key ${result.psk}')
    ..writeln('');

  final clientUrl = _flag(args, 'client-url');
  if (clientUrl != null && clientUrl.isNotEmpty) {
    final deepLink = buildWebClientDeepLink(
      clientUrl: clientUrl,
      serverUrl: serverUrl,
      deviceId: result.deviceId,
      psk: result.psk,
    );
    stdout
      ..writeln('Scan to open the web client and connect:')
      ..writeln('')
      ..write(renderQrToAnsi(deepLink))
      ..writeln('')
      ..writeln(deepLink)
      ..writeln('');
  } else {
    stdout.writeln(
      'Tip: pass --client-url <web app origin> (and --bind any --host '
      '<LAN ip>) to print a scannable QR a phone can open.',
    );
  }

  stdout.writeln(
    'Start the server: cc_server --data-dir ${result.dataDir} '
    '--port ${config.port}${config.bindAny ? ' --bind any' : ''}',
  );
  if (config.bindAny) {
    stdout.writeln(
      '  A public (--bind any) bind needs TLS: pass --tls-cert <pem> '
      '--tls-key <pem> for direct wss://, or run behind a TLS-terminating '
      'reverse proxy and add --insecure (plaintext on a trusted network only).',
    );
  }
}

/// Connects a Google account to a workspace via the headless device-code flow,
/// stores its refresh token server-side, then exits. Run once per account.
///
/// Usage: `cc_server calendar connect --workspace <id>` (plus `--data-dir` and
/// the `--google-client-id` / `--google-client-secret` config, or their
/// `CC_GOOGLE_OAUTH_CLIENT_ID` / `CC_GOOGLE_OAUTH_CLIENT_SECRET` env vars).
Future<void> _calendar(List<String> args) async {
  if (args.isEmpty || args.first != 'connect') {
    stderr.writeln('usage: cc_server calendar connect --workspace <id>');
    exit(2);
  }
  final rest = args.sublist(1);
  final config = CcServerConfig.resolve(rest);
  final workspaceId = _flag(rest, 'workspace');
  if (workspaceId == null || workspaceId.isEmpty) {
    stderr.writeln('cc_server calendar connect: --workspace <id> is required');
    exit(2);
  }
  try {
    await connectGoogleCalendar(
      config: config,
      workspaceId: workspaceId,
      log: stdout.writeln,
    );
  } on Object catch (e) {
    stderr.writeln('cc_server calendar connect failed: $e');
    await stdout.flush();
    exit(1);
  }
  await stdout.flush();
  exit(0);
}

/// Reads `--name value` or `--name=value` from [args]; null if absent.
String? _flag(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--$name' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (a.startsWith('--$name=')) {
      return a.substring(name.length + 3);
    }
  }
  return null;
}
