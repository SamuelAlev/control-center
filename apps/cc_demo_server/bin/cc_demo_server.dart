import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/cc_server_core.dart';

/// Entrypoint for the Control Center **public demo** server.
///
/// Real `cc_server` composition via [buildDemoWiring] (not a mock). Separate
/// binary (not `--demo`) so fixtures never ship in desktop installs and a
/// forgotten env flag cannot arm a public endpoint.
///
/// Execution ports are null (ops never built → `opUnknown`); `DemoProfile`
/// default-denies the rest; a ratchet forces new ops to be classified. Agent
/// runs use `ScriptedAgentLoop` (no tools, no model). Optional demo env:
/// `CC_SERVER_DEMO_TTL_MINUTES`, `CC_SERVER_DEMO_MAX_VISITORS`,
/// `CC_SERVER_DEMO_POOL_SIZE`, `CC_SERVER_DEMO_DISK_BUDGET_MB`,
/// `CC_SERVER_DEMO_MAX_PER_IP`, `CC_SERVER_DEMO_INVITE_CODE`.
Future<void> main(List<String> args) async {
  if (args.isNotEmpty && (args.first == '--version' || args.first == '-v')) {
    stdout.writeln(
      'cc_demo_server ${BuildInfo.buildVersion} (${BuildInfo.buildGitSha})',
    );
    exit(0);
  }

  // Same guarded zone as cc_server: an uncaught async error in a reaper or a
  // pool fill is recorded to the rotating on-disk log instead of vanishing.
  await runZonedGuarded(() => _run(args), recordUncaughtServerError);
}

Future<void> _run(List<String> args) async {
  final CcServer server;
  try {
    server = await runCcServer(args: args, demoBuilder: buildDemoWiring);
  } on SocketException catch (e) {
    stderr.writeln(
      'cc_demo_server: cannot start — ${e.osError?.message ?? e.message} '
      '(${e.address?.host}:${e.port}). Another server is already on that '
      'port — stop it, or pass --port.',
    );
    exit(1);
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

  await done.future;
  // Watching the signals overrides their default terminate behaviour, so we
  // must exit ourselves; the reconcilers and drift's isolate otherwise keep
  // the event loop alive forever. Teardown reaps every live visitor first.
  try {
    await server.shutdown().timeout(const Duration(seconds: 12));
  } on Object catch (e) {
    stderr.writeln('cc_demo_server: shutdown did not complete cleanly: $e');
  }
  await stdout.flush();
  exit(0);
}
