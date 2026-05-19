import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cc_worker/cc_worker.dart';

/// Entry point for the headless fleet worker binary.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'server',
      help: 'cc_server URL to dial (ws:// or wss://). Required.',
    )
    ..addOption(
      'name',
      help: 'Operator-facing worker name. Defaults to the host name.',
    )
    ..addOption(
      'device-id',
      help: 'Stable paired-device id, also used as the worker id.',
      defaultsTo: 'cc-worker',
    )
    ..addOption(
      'psk',
      help:
          'Paired-device pre-shared key. Prefer --psk-file or CC_WORKER_PSK: '
          'a key passed here is visible in `ps` and shell history.',
    )
    ..addOption(
      'psk-file',
      help:
          'File containing the pre-shared key (first line). Preferred over '
          '--psk — mirrors the rig broker secret, which is passed by '
          'reference for the same reason.',
    )
    ..addOption(
      'max-jobs',
      help: 'Maximum jobs to execute concurrently.',
      defaultsTo: '4',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('cc_worker: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run cc_worker --server <url> [options]\n');
    stdout.writeln(parser.usage);
    return;
  }

  final server = results.option('server');
  if (server == null || server.isEmpty) {
    stderr.writeln('cc_worker: --server <url> is required.');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final String? psk;
  final int maxJobs;
  try {
    psk = resolveWorkerPsk(
      pskFile: results.option('psk-file'),
      pskFlag: results.option('psk'),
      environment: Platform.environment,
      onInsecureSource: (message) => stderr.writeln('cc_worker: $message'),
    );
    maxJobs = parseMaxJobs(results.option('max-jobs'));
  } on WorkerCliException catch (e) {
    stderr.writeln('cc_worker: ${e.message}');
    exitCode = e.exitCode;
    return;
  }

  final config = WorkerConfig(
    serverUrl: server,
    name: results.option('name') ?? Platform.localHostname,
    deviceId: results.option('device-id') ?? 'cc-worker',
    psk: psk,
    maxJobs: maxJobs,
  );

  final runner = WorkerRunner(config);
  final signals = <StreamSubscription<ProcessSignal>>[
    ProcessSignal.sigint.watch().listen((_) => unawaited(runner.stop())),
  ];
  if (!Platform.isWindows) {
    signals.add(
      ProcessSignal.sigterm.watch().listen((_) => unawaited(runner.stop())),
    );
  }

  try {
    exitCode = await runner.run();
  } catch (e) {
    stderr.writeln('cc_worker: fatal: $e');
    exitCode = 1;
  } finally {
    for (final sub in signals) {
      await sub.cancel();
    }
    await runner.stop();
  }
}
