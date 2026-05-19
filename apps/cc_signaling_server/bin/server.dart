import 'dart:async';
import 'dart:io';

import 'package:cc_signaling_server/cc_signaling_server.dart';

/// Entry point for the `signaling-server` CLI.
///
/// Binds an [HttpServer], upgrades WebSocket requests at any path and relays
/// signaling through a [SignalingBroker]. Defaults to `0.0.0.0:8788`.
///
/// TURN credential minting (PRD 15 §3) activates when `--turn-secret` (or
/// `CC_TURN_SECRET`) and `--turn-uris` (or `CC_TURN_URIS`, comma-separated)
/// are supplied — pair them with a coturn instance configured with the same
/// `static-auth-secret`.
Future<void> main(List<String> arguments) async {
  final settings = _parse(arguments);
  if (settings == null) {
    return;
  }
  final broker = SignalingBroker(
    maxPeersPerRoom: settings.maxPeers,
    turnSecret: settings.turnSecret,
    turnUris: settings.turnUris,
    log: (m) => stderr.writeln(m),
  )..start();
  final handle = await serveSignaling(
    host: settings.host,
    port: settings.port,
    broker: broker,
  );
  stdout.writeln('listening on ${settings.host}:${handle.port}');
  if (settings.turnSecret.isNotEmpty && settings.turnUris.isNotEmpty) {
    stdout.writeln('TURN credential minting enabled (${settings.turnUris.join(', ')})');
  }

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
  _Settings({
    required this.host,
    required this.port,
    required this.maxPeers,
    required this.turnSecret,
    required this.turnUris,
  });

  final String host;

  final int port;

  final int maxPeers;

  final String turnSecret;

  final List<String> turnUris;
}

const String _usage =
    'usage: dart run bin/server.dart [--host <address>] [--port <0-65535>] '
    '[--max-peers <n>] [--turn-secret <secret>] [--turn-uris <uri,uri>]';

_Settings? _parse(List<String> arguments) {
  final env = Platform.environment;
  var host = defaultSignalingHost;
  var port = defaultSignalingPort;
  var maxPeers = 16;
  var turnSecret = env['CC_TURN_SECRET'] ?? '';
  var turnUris = _splitUris(env['CC_TURN_URIS'] ?? '');

  String? value(List<String> args, int i, String flag) {
    if (i + 1 == args.length) {
      stderr.writeln('error: $flag requires a value\n$_usage');
      return null;
    }
    return args[i + 1];
  }

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      stdout.writeln(_usage);
      stdout.writeln('  --host <address>       interface to bind (default $host)');
      stdout.writeln('  --port <0-65535>       port to bind (default $port)');
      stdout.writeln('  --max-peers <n>        room capacity (default $maxPeers)');
      stdout.writeln('  --turn-secret <secret> coturn static-auth-secret (or CC_TURN_SECRET)');
      stdout.writeln('  --turn-uris <uris>     comma-separated TURN URIs (or CC_TURN_URIS)');
      return null;
    } else if (arg == '--host') {
      final v = value(arguments, i, arg);
      if (v == null) {
        return null;
      }
      host = v;
      i++;
    } else if (arg == '--port') {
      final v = value(arguments, i, arg);
      if (v == null) {
        return null;
      }
      final parsed = int.tryParse(v);
      if (parsed == null || parsed < 0 || parsed > 65535) {
        stderr.writeln('error: --port must be an integer in 0..65535\n$_usage');
        return null;
      }
      port = parsed;
      i++;
    } else if (arg == '--max-peers') {
      final v = value(arguments, i, arg);
      if (v == null) {
        return null;
      }
      final parsed = int.tryParse(v);
      if (parsed == null || parsed < 2 || parsed > 256) {
        stderr.writeln('error: --max-peers must be an integer in 2..256\n$_usage');
        return null;
      }
      maxPeers = parsed;
      i++;
    } else if (arg == '--turn-secret') {
      final v = value(arguments, i, arg);
      if (v == null) {
        return null;
      }
      turnSecret = v;
      i++;
    } else if (arg == '--turn-uris') {
      final v = value(arguments, i, arg);
      if (v == null) {
        return null;
      }
      turnUris = _splitUris(v);
      i++;
    } else {
      stderr.writeln('error: unknown argument "$arg"\n$_usage');
      return null;
    }
  }
  return _Settings(
    host: host,
    port: port,
    maxPeers: maxPeers,
    turnSecret: turnSecret,
    turnUris: turnUris,
  );
}

List<String> _splitUris(String raw) => raw
    .split(',')
    .map((u) => u.trim())
    .where((u) => u.isNotEmpty)
    .toList();
