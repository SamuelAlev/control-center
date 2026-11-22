import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server/embedded_connect_host.dart';
import 'package:cc_server_core/cc_server_core.dart';

/// Entrypoint for the Control Center headless server (pure Dart, no Flutter).
/// Build with `scripts/build_server.sh` to include FFI libraries and media tools.
///
/// Subcommands: `pair` (device + PSK, optional QR); `update` (stage/apply
/// standalone release; never silent); `connect` (which Connect this server
/// uses); `agent-run` (internal: the agent run client a run's shims start);
/// default runs until SIGINT/SIGTERM.
/// Config: `--data-dir`, `--port`, `--bind` (see [CcServerConfig]).
Future<void> main(List<String> args) async {
  // Before anything else: an agent run's shims and hooks start this binary
  // inside the run's sandbox, many times a turn, to ask the gateway one thing.
  if (args.isNotEmpty && args.first == 'agent-run') {
    exit(await runAgentRunClient(args.sublist(1)));
  }

  if (args.isNotEmpty && (args.first == '--help' || args.first == '-h')) {
    stdout.writeln('''
Usage: cc_server [--data-dir PATH] [--port PORT] [--bind loopback|any]

Run the headless server until SIGINT or SIGTERM. Port 0 selects an ephemeral
port. Non-loopback binding requires TLS configuration.

Commands:
  pair               Provision a paired device; stop the server first.
  update             Stage or apply a standalone server release.
  connect            Show or change which Control Center Connect this server
                     uses (status | enable [--url URL] | disable).

Code mode (a value the server does not accept stops it at start):
  --code-mode-max-processes N
                     Runner slots on this server, 1 to 64: scripts that
                     start tools at once; up to four times as many may be
                     parked on a person besides
                     (CC_SERVER_CODE_MODE_MAX_PROCESSES).
  --code-mode-max-heap-mb N
                     The most heap one script may use, 16 to 1024 MiB;
                     workspace limits above it are lowered to it
                     (CC_SERVER_CODE_MODE_MAX_HEAP_MB).

Information (does not open databases or start services):
  --help, -h         Show this help.
  --version, -v      Print the build version.

Internal:
  agent-run          The agent run client that an agent run's shims start
                     inside its sandbox. Not for direct use.

Configuration and pairing:
https://github.com/SamuelAlev/control-center/tree/main/apps/cc_server
''');
    return;
  }

  // `--version` / `-v` / `version`: print the CI-stamped build identity and
  // exit. Same values /healthz and the RPC handshake advertise.
  if (args.isNotEmpty && (args.first == '--version' || args.first == '-v')) {
    stdout.writeln(
      'cc_server ${BuildInfo.buildVersion} (${BuildInfo.buildGitSha})',
    );
    exit(0);
  }

  // A refusal (a configuration the server does not accept, a missing
  // native) ends every command the same way: one line on stderr, exit 78,
  // nothing created.
  if (args.isNotEmpty && args.first == 'pair') {
    await _exitWith(() => runPairCommand(args: args.sublist(1)));
  }

  if (args.isNotEmpty && args.first == 'update') {
    await _exitWith(() => runUpdateCommand(args: args.sublist(1)));
  }

  if (args.isNotEmpty && args.first == 'connect') {
    await _exitWith(() => runConnectCommand(args: args.sublist(1)));
  }

  // Run the whole server under a guarded zone so an uncaught async error in a
  // reconciler / pipeline timer / listener is recorded to the rotating on-disk
  // log instead of silently killing the process (FINDINGS §130). We keep the
  // guard thin — it only records; it does not swallow shutdown.
  await runZonedGuarded(() => _runServer(args), recordUncaughtServerError);
}

/// Boots the server, waits for a shutdown signal, then tears down and exits.
Future<void> _runServer(List<String> args) async {
  final CcServer? server;
  try {
    // An exported provider secret, a data dir others can read, a missing
    // native, a setting the server does not accept: the operator has to
    // resolve it, and the message says how, on one line and without a
    // stack ([runOrRefuse]).
    server = await runOrRefuse(
      () => runCcServer(args: args, connectHost: buildEmbeddedConnect),
    );
  } on SocketException catch (e) {
    // A failed bind must END the process. The guarded zone only RECORDS an
    // uncaught error, so without this the server stayed alive with no listener
    // while every background job — code indexing above all — kept running
    // against the same database as the instance that owns the port. That reads
    // as "started but stuck": no ready banner, nothing to connect to and two
    // processes fighting over SQLite.
    stderr.writeln(bindFailureLines(e));
    exit(1);
  } on Object catch (e, stack) {
    // Anything else before ready ends the process too, non-zero and in one
    // line: the guarded zone only records an error, so one that escaped
    // here left a process that ended with status 0 and printed a stack.
    // The stack goes to the log file when it is open by then.
    final logged = recordBootFailure(e, stack);
    stderr.writeln(bootFailureLine(e, logged: logged));
    exit(failedExitCode);
  }
  if (server == null) {
    exit(refusedExitCode);
  }

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
  //
  // `shutdown()` already bounds and isolates each teardown step internally (a
  // stuck service is logged by name and skipped), so this outer cap is only a
  // backstop for the whole sequence. It is generous enough that a single slow
  // step plus the guarded DB close still both run before it fires.
  try {
    await server.shutdown().timeout(const Duration(seconds: 12));
  } on Object catch (e) {
    stderr.writeln(shutdownFailureLine(e));
  }
  await stdout.flush();
  exit(0);
}

/// Runs a command (`pair`, `update`, `connect`) and ends the process with
/// its exit code. A refusal it returns as 78 with one line; any other error
/// ends it with 70 (`EX_SOFTWARE`) and one line, never an unhandled
/// exception's stack.
Future<Never> _exitWith(Future<int> Function() command) async {
  int code;
  try {
    code = await command();
  } on Object catch (e) {
    stderr.writeln(commandFailureLine(e));
    code = failedExitCode;
  }
  await stdout.flush();
  exit(code);
}
