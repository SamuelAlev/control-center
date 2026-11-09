import 'dart:async';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';

/// Entry point for the `cc-connect` service.
///
/// Every setting comes from `CONNECT_*` environment variables (see the
/// README); secrets may come from `<NAME>_FILE` mounts instead. The service
/// refuses to start on an open, unsafe or half-configured setup and exits
/// with status 78 (`EX_CONFIG`).
///
/// `--healthcheck` probes `GET /healthz` on `127.0.0.1:$CONNECT_PORT` and
/// exits 0 when healthy (the container `HEALTHCHECK`).
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }
  if (arguments.contains('--healthcheck')) {
    exitCode = await _healthcheck();
    return;
  }
  if (arguments.isNotEmpty) {
    stderr.writeln('error: unknown argument "${arguments.first}"\n$_usage');
    exitCode = 64;
    return;
  }
  final ConnectServerHandle handle;
  final ConnectServiceConfig config;
  try {
    config = ConnectServiceConfig.fromEnvironment(Platform.environment);
    final service = await ConnectService.start(config);
    handle = await serveConnect(service, host: config.host, port: config.port);
  } on ConnectConfigException catch (error) {
    stderr.writeln('cc-connect: ${error.message}');
    exitCode = 78;
    return;
  }
  stdout.writeln(
    'cc-connect listening on ${config.host}:${handle.port} '
    'for ${config.publicBaseUrl}',
  );
  await _waitForShutdown();
  stdout.writeln('cc-connect shutting down');
  await handle.close();
}

const String _usage =
    'usage: cc-connect [--healthcheck]\n'
    '  Configured entirely through CONNECT_* environment variables; see\n'
    '  apps/cc_connect/README.md. --healthcheck probes /healthz locally.';

Future<int> _healthcheck() async {
  final port = int.tryParse(Platform.environment['CONNECT_PORT'] ?? '') ?? 8790;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client
        .get('127.0.0.1', port, '/healthz')
        .timeout(const Duration(seconds: 2));
    final response = await request.close().timeout(const Duration(seconds: 2));
    await response.drain<void>();
    return response.statusCode == 200 ? 0 : 1;
  } on Object {
    return 1;
  } finally {
    client.close(force: true);
  }
}

Future<void> _waitForShutdown() async {
  final stop = Completer<void>();
  final signals = <ProcessSignal>[
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  // Cancel every watcher once the first signal fires: a watcher left
  // subscribed pins the event loop and keeps the AOT binary from exiting.
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  for (final signal in signals) {
    subscriptions.add(
      signal.watch().listen((_) {
        if (!stop.isCompleted) {
          stop.complete();
        }
      }),
    );
  }
  try {
    await stop.future;
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }
}
