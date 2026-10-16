import 'package:flutter/foundation.dart';

/// Desktop server startup and reconnect phases shared by pre-app and app UI.
enum ServerStartupPhase {
  /// Locating and launching the local server process.
  starting,

  /// Establishing the authenticated connection.
  connecting,

  /// The server connection is ready for use.
  ready,

  /// Startup or reconnection failed; retain the original cause.
  failed,
}

/// A single startup attempt's phase and, when failed, its original cause.
class ServerStartupStatus {
  /// Creates a status update for the current server connection attempt.
  const ServerStartupStatus({required this.phase, this.error});

  /// Current phase of the local server or remote connection.
  final ServerStartupPhase phase;

  /// Original error when [phase] is [ServerStartupPhase.failed].
  final Object? error;
}

/// Null until startup begins; ready status hides the startup indicator.
final ValueNotifier<ServerStartupStatus?> serverStartupStatus =
    ValueNotifier<ServerStartupStatus?>(null);
