import 'dart:io';

import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/pair_device.dart';
import 'package:cc_server_core/src/pairing_qr.dart';
import 'package:cc_server_core/src/process_environment_guard.dart';
import 'package:cc_server_core/src/runtime/server_native_preflight.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:cc_server_core/src/update/server_update_runner.dart';

/// The exit code of a command the server refuses to run (`EX_CONFIG`): a
/// refused boot, `pair`, `update` and `connect` all end with it.
const int refusedExitCode = 78;

/// The exit code of an error before the server is ready that is not a
/// refusal (`EX_SOFTWARE`), and of a command that failed the same way.
const int failedExitCode = 70;

/// The one line an error before the server is ready ends the process with
/// ([failedExitCode]): redacted, printable and bounded ([printableError]);
/// [logged] when its stack went to the log file.
String bootFailureLine(Object error, {required bool logged}) =>
    'cc_server: cannot start \u2014 ${printableError(error)}'
    '${logged ? ' (the stack is in the log)' : ''}';

/// The line a command (`pair`, `update`, `connect`) that failed with
/// [error], not a refusal, ends with ([failedExitCode]).
String commandFailureLine(Object error) =>
    'cc_server: ${printableError(error)}';

/// The line a shutdown that failed with [error] leaves.
String shutdownFailureLine(Object error) =>
    'cc_server: shutdown did not complete cleanly: ${printableError(error)}';

/// The lines a bind that failed with [error] ends the boot with.
String bindFailureLines(SocketException error) => terminalLine(
  'cc_server: cannot start \u2014 ${error.osError?.message ?? error.message} '
  '(${error.address?.host}:${error.port}).\n'
  'Another cc_server is already running on that port \u2014 either the '
  "desktop app's embedded server or a previous run. Stop it, or pass "
  '--port.',
);

/// The line to print for [error] when it is a refusal the operator has to
/// resolve (a configuration the server does not accept, a missing native,
/// an exported provider secret, an unusable `CC_CONNECT_URL`), or null for
/// any other error.
String? refusalMessage(Object error) => switch (error) {
  ServerBootRefusal() => error.message,
  ProviderSecretInEnvironmentException() => error.message,
  ConnectEnvironmentInvalid() => error.message,
  _ => null,
};

/// Runs [body] and returns what it returns, or, when it is refused
/// ([refusalMessage]), writes the refusal to [err] (stderr by default) and
/// returns null, so the command ends with [refusedExitCode] and no stack.
/// Any other error is rethrown.
Future<T?> runOrRefuse<T extends Object>(
  Future<T> Function() body, {
  IOSink? err,
}) async {
  try {
    return await body();
  } on Object catch (e) {
    final message = refusalMessage(e);
    if (message == null) {
      rethrow;
    }
    (err ?? stderr).writeln(terminalLine(message));
    return null;
  }
}

/// `cc_server pair`: provisions a paired device against the data dir and
/// prints the pairing key, plus a deep link and a terminal QR when a
/// `--client-url` (the web client's origin) is supplied, for a thin client
/// to connect. Returns the process exit code: [refusedExitCode] when the
/// configuration or a missing native ([checkNatives]) refuses it, before
/// anything is created.
Future<int> runPairCommand({
  required List<String> args,
  IOSink? out,
  IOSink? err,
  Future<void> Function(String dataDir) checkNatives = refuseMissingNatives,
}) async {
  // The process's stdout (or the caller's sink): never ours to close.
  // ignore: close_sinks
  final o = out ?? stdout;
  final paired = await runOrRefuse(() async {
    final config = CcServerConfig.resolve(args);
    final result = await pairDevice(
      config: config,
      deviceId: _flag(args, 'device') ?? 'web-client',
      label: _flag(args, 'label'),
      checkNatives: checkNatives,
    );
    return (config, result);
  }, err: err);
  if (paired == null) {
    return refusedExitCode;
  }
  final (config, result) = paired;

  // `any`-bind requires TLS (LocalRpcServer refuses plaintext off-loopback), so
  // a reachable URL is wss; loopback is plain ws. `--host` overrides the host
  // in the printed/encoded URL (loopback can't be reached from a phone; pass
  // the Mac's LAN IP or a tunnel host).
  final scheme = config.bindAny ? 'wss' : 'ws';
  final host =
      _flag(args, 'host') ?? (config.bindAny ? '<this-host>' : 'localhost');
  final serverUrl = '$scheme://$host:${config.port}/rpc';

  // What the operator passed (the data directory, `--host`, `--device`,
  // `--client-url`) is printed redacted and printable ([terminalLine]). The
  // pairing key, the deep link that carries it and its QR code are printed
  // as they are: they are this command's output, the deep link's own text
  // is made printable, and the QR code is drawn with terminal colours.
  void line(String text) => o.writeln(terminalLine(text));
  line('Paired a device in ${result.dataDir}');
  line('');
  line('Connect a thin client (paste into its connect form):');
  line('  Server      $serverUrl');
  line('  Device id   ${result.deviceId}');
  o
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
    o
      ..writeln('Scan to open the web client and connect:')
      ..writeln('')
      ..write(renderQrToAnsi(deepLink))
      ..writeln('')
      ..writeln(printableUnredacted(deepLink, max: 4096))
      ..writeln('');
  } else {
    line(
      'Tip: pass --client-url <web app origin> (and --bind any --host '
      '<LAN ip>) to print a scannable QR a phone can open.',
    );
  }

  line(
    'Start the server: cc_server --data-dir ${result.dataDir} '
    '--port ${config.port}${config.bindAny ? ' --bind any' : ''}',
  );
  if (config.bindAny) {
    o.writeln(
      '  A public (--bind any) bind needs TLS: pass --tls-cert <pem> '
      '--tls-key <pem> for direct wss://, or run behind a TLS-terminating '
      'reverse proxy and add --insecure (plaintext on a trusted network only).',
    );
  }
  return 0;
}

/// `cc_server update`: the standalone-server self-update flow. Opt-in and
/// never silent: without `--apply` it only checks for, downloads and
/// verifies a newer release into a staging directory next to the install;
/// `--apply` additionally refuses while a live server answers on the
/// configured port (unless `--force` is passed with eyes open). A published
/// release OLDER than this binary is refused unless `--allow-downgrade` is
/// passed. Returns the process exit code: [refusedExitCode] when the
/// configuration refuses it. A missing native does not stop it: a release
/// is what brings one back.
Future<int> runUpdateCommand({
  required List<String> args,
  IOSink? out,
  IOSink? err,
}) async {
  // ignore: close_sinks
  final o = out ?? stdout;
  final config = await runOrRefuse(
    () async => CcServerConfig.resolve(args),
    err: err,
  );
  if (config == null) {
    return refusedExitCode;
  }
  final runner = ServerUpdateRunner(
    log: (line) => o.writeln(terminalLine(line)),
    probeUri: Uri.parse('http://127.0.0.1:${config.port}/healthz'),
  );
  return runner.run(
    apply: _flagBool(args, 'apply'),
    force: _flagBool(args, 'force'),
    allowDowngrade: _flagBool(args, 'allow-downgrade'),
  );
}

/// Reads `--name` (bare boolean flag) from [args].
bool _flagBool(List<String> args, String name) {
  return args.contains('--$name') || args.any((a) => a == '--$name=true');
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
