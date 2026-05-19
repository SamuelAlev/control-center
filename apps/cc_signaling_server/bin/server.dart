import 'dart:async';
import 'dart:io';

import 'package:cc_signaling_server/cc_signaling_server.dart';

/// Entry point for the `signaling-server` CLI.
///
/// Binds an [HttpServer], upgrades WebSocket requests at any path, and relays
/// signaling through a [SignalingBroker]. Defaults to `0.0.0.0:8788`.
Future<void> main(List<String> arguments) async {
  final settings = _parse(arguments);
  if (settings == null) {
    return;
  }
  final handle = await serveSignaling(host: settings.host, port: settings.port);
  stdout.writeln('listening on ${settings.host}:${handle.port}');

  await _waitForShutdown();
  stdout.writeln('shutting down');
  await handle.close();
}

Future<void> _waitForShutdown() async {
  final stop = Completer<void>();
  final signals = <ProcessSignal>[
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  // Subscribe to every shutdown signal, then cancel ALL of them once the first
  // one fires. Leaving the un-fired watcher subscribed pins the event loop and
  // prevents the AOT-compiled binary from exiting after shutdown (the JIT VM
  // happens to exit anyway, which is why this only bites the deployed binary).
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

class _Settings {
  _Settings(this.host, this.port);

  final String host;

  final int port;
}

const String _usage =
    'usage: dart run bin/server.dart [--host <address>] [--port <0-65535>]';

_Settings? _parse(List<String> arguments) {
  var host = defaultSignalingHost;
  var port = defaultSignalingPort;
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      stdout.writeln(_usage);
      stdout.writeln('  --host <address>  interface to bind (default $host)');
      stdout.writeln('  --port <0-65535>  port to bind (default $port)');
      return null;
    } else if (arg == '--host') {
      if (i + 1 == arguments.length) {
        stderr.writeln('error: --host requires a value\n$_usage');
        return null;
      }
      host = arguments[++i];
    } else if (arg == '--port') {
      if (i + 1 == arguments.length) {
        stderr.writeln('error: --port requires a value\n$_usage');
        return null;
      }
      final parsed = int.tryParse(arguments[++i]);
      if (parsed == null || parsed < 0 || parsed > 65535) {
        stderr.writeln('error: --port must be an integer in 0..65535\n$_usage');
        return null;
      }
      port = parsed;
    } else {
      stderr.writeln('error: unknown argument "$arg"\n$_usage');
      return null;
    }
  }
  return _Settings(host, port);
}
