import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart' show ServerConnectionPhase;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status of a single server service during shutdown.
enum ShutdownServiceStatus {
  /// The server has not yet confirmed this service torn down.
  pending,

  /// The server reported this service shut down.
  done,
}

/// One service the server reported (or is about to report) torn down.
class ShutdownService {
  /// Creates a [ShutdownService].
  const ShutdownService({required this.id, required this.status});

  /// The server-reported service id (e.g. `approvals`, `meetings`). Mapped to a
  /// localized label by the overlay.
  final String id;

  /// Whether the server confirmed this service is shut down.
  final ShutdownServiceStatus status;

  /// Returns a copy with [status] replaced.
  ShutdownService copyWith({ShutdownServiceStatus? status}) =>
      ShutdownService(id: id, status: status ?? this.status);
}

/// Snapshot of the shutdown overlay: whether it is showing, and the ordered
/// list of services with their per-service status.
class ShutdownProgressState {
  /// Creates a [ShutdownProgressState].
  const ShutdownProgressState({
    this.active = false,
    this.services = const [],
    this.complete = false,
  });

  /// Whether the overlay should be visible (a quit was initiated).
  final bool active;

  /// The services, in the order the server reported them. The first not-yet-
  /// `done` entry is the one currently shutting down (shown with a spinner).
  final List<ShutdownService> services;

  /// Whether the server reported the whole sequence complete.
  final bool complete;

  /// Returns a copy with the given fields replaced.
  ShutdownProgressState copyWith({
    bool? active,
    List<ShutdownService>? services,
    bool? complete,
  }) => ShutdownProgressState(
    active: active ?? this.active,
    services: services ?? this.services,
    complete: complete ?? this.complete,
  );
}

/// Subscribes to the server's `server/shutdown_progress` JSON-RPC notifications
/// and exposes them as ordered [ShutdownService]s for the shutdown overlay.
///
/// The overlay is driven entirely by what the server reports: a `begin` frame
/// seeds the full ordered list (all `pending`), each `step` frame flips one to
/// `done`, and a `complete` frame marks the sequence finished. [begin] flips
/// `active` on locally so the overlay appears the instant the user quits,
/// before the first frame arrives.
class ShutdownProgressNotifier extends Notifier<ShutdownProgressState> {
  StreamSubscription<JsonRpcNotification>? _sub;

  @override
  ShutdownProgressState build() {
    // `rpcClientProvider` is overridden with the connected client at the
    // composition root. Subscribing is best-effort: in tests a fake client may
    // not expose a usable stream, so guard rather than break the build.
    try {
      final client = ref.read(rpcClientProvider);
      _sub = client.notifications
          .where((n) => n.method == 'server/shutdown_progress')
          .listen(_onNotification);
    } on Object {
      _sub = null;
    }
    ref.onDispose(() => _sub?.cancel());
    // Once the connection to the shutting-down server actually drops, the
    // shutdown is over — clear the overlay state. Without this, `active` latches
    // true forever and the overlay pops back the instant the phase returns to
    // `connected` (e.g. the server is restarted and the client reconnects).
    ref.listen(serverConnectionStatusProvider, (_, next) {
      final phase = next.value?.phase;
      final gone =
          phase == ServerConnectionPhase.reconnecting ||
          phase == ServerConnectionPhase.closed;
      if (gone && state.active) {
        state = const ShutdownProgressState();
      }
    });
    return const ShutdownProgressState();
  }

  /// Show the overlay (the local server is being stopped).
  void begin() {
    if (!state.active) {
      state = state.copyWith(active: true);
    }
  }

  void _onNotification(JsonRpcNotification n) {
    final phase = n.params['phase'];
    switch (phase) {
      case 'begin':
        final services = (n.params['services'] as List?)
            ?.whereType<String>()
            .map(
              (id) => ShutdownService(
                id: id,
                status: ShutdownServiceStatus.pending,
              ),
            )
            .toList(growable: false);
        state = ShutdownProgressState(
          active: true,
          services: services ?? const [],
        );
      case 'step':
        final id = n.params['service'] as String?;
        if (id == null) {
          return;
        }
        final services = [
          for (final s in state.services)
            if (s.id == id)
              s.copyWith(status: ShutdownServiceStatus.done)
            else
              s,
        ];
        state = state.copyWith(active: true, services: services);
      case 'complete':
        state = state.copyWith(
          active: true,
          complete: true,
          services: [
            for (final s in state.services)
              s.copyWith(status: ShutdownServiceStatus.done),
          ],
        );
    }
  }
}

/// The live shutdown-progress state backing the app-wide overlay.
final shutdownProgressProvider =
    NotifierProvider<ShutdownProgressNotifier, ShutdownProgressState>(
      ShutdownProgressNotifier.new,
    );
