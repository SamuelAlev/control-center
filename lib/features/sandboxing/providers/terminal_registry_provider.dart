// App-level terminal keep-alive registry.
//
// The messaging IDE unmounts every `TerminalSessionView` on a space switch;
// the sessions must survive that. This registry owns one
// `TerminalSessionController` per client-side session id (minted into the tab
// args at tab creation) so a controller — its server-side PTY, its 10k-line
// xterm buffer, its subscriptions — lives across layout swaps. Views come and
// go; the shell keeps running.
//
// Footprint stays bounded: one PTY ≈ one shell process + one 10k-line xterm
// buffer + two subscriptions. `kMaxLiveTerminalSessions` caps live shells
// app-wide at what a handful of recently-used spaces need; the
// least-recently-touched controller NOT claimed by a live tab of the active
// space is evicted past the cap (its space respawns a blank shell on next
// visit — today's behaviour for every space). On-screen tabs are never
// evicted: if the user genuinely has more open than the cap, the cap yields.
library;

import 'dart:async';

import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many shells stay alive app-wide, LRU-evicted among spaces not on
/// screen. See the library doc for the footprint math.
const kMaxLiveTerminalSessions = 6;

/// Snapshot of the registry: live controllers (insertion order = LRU touch
/// order, most-recent last) and the session ids claimed by live tabs of the
/// active space (eviction-protected).
class TerminalRegistryState {
  /// Creates a [TerminalRegistryState].
  const TerminalRegistryState({
    this.controllers = const {},
    this.claimedIds = const {},
  });

  /// Live controllers keyed by `session.sessionId`, in LRU-touched order.
  final Map<String, TerminalSessionController> controllers;

  /// Session ids claimed by live terminal tabs of the active space.
  final Set<String> claimedIds;
}

/// Owns the app-level terminal keep-alive registry. See the library doc.
final terminalRegistryProvider =
    NotifierProvider<TerminalRegistryNotifier, TerminalRegistryState>(
      TerminalRegistryNotifier.new,
    );

/// Registry of live terminal session controllers with an LRU cap.
class TerminalRegistryNotifier extends Notifier<TerminalRegistryState> {
  @override
  TerminalRegistryState build() => const TerminalRegistryState();

  /// Returns the controller for [session]'s id, creating + booting nothing on
  /// a miss (the caller boots via `controller.ensureBooted()`). An existing
  /// entry is touched (moved to most-recent). A new insert runs eviction.
  TerminalSessionController obtain(TerminalSession session) {
    final existing = state.controllers[session.sessionId];
    if (existing != null) {
      // Touch: remove + reinsert so insertion order tracks recency.
      final next = Map<String, TerminalSessionController>.of(state.controllers)
        ..remove(session.sessionId)
        ..[session.sessionId] = existing;
      state = TerminalRegistryState(
        controllers: next,
        claimedIds: state.claimedIds,
      );
      return existing;
    }
    final controller = TerminalSessionController(
      session: session,
      rpcClient: ref.read(rpcClientProvider),
    );
    final next = Map<String, TerminalSessionController>.of(state.controllers)
      ..[session.sessionId] = controller;
    state = TerminalRegistryState(
      controllers: next,
      claimedIds: state.claimedIds,
    );
    // The fresh entry is not yet claimed (its tab claims it post-frame) —
    // protect it, or it would evict ITSELF as the only unclaimed entry.
    _evictPastCap(protectId: session.sessionId);
    return controller;
  }

  /// Replaces the eviction-protected set (the live terminal tabs' session ids
  /// of the active space).
  void syncClaims(Set<String> ids) {
    state = TerminalRegistryState(
      controllers: state.controllers,
      claimedIds: ids,
    );
  }

  /// Removes [sessionId]'s controller and disposes it (kills the server PTY).
  /// No-op for an unknown id.
  void kill(String sessionId) {
    final controller = state.controllers[sessionId];
    if (controller == null) {
      return;
    }
    final next = Map<String, TerminalSessionController>.of(state.controllers)
      ..remove(sessionId);
    final claims = Set<String>.of(state.claimedIds)..remove(sessionId);
    state = TerminalRegistryState(controllers: next, claimedIds: claims);
    unawaited(controller.dispose());
  }

  /// Disposes + removes least-recently-touched unclaimed controllers until the
  /// count fits the cap. [protectId] (the just-obtained entry, not yet claimed
  /// by its tab) is never evicted. All-claimed overflows stand — never kill an
  /// on-screen shell.
  void _evictPastCap({String? protectId}) {
    while (state.controllers.length > kMaxLiveTerminalSessions) {
      String? evictId;
      for (final id in state.controllers.keys) {
        if (id != protectId && !state.claimedIds.contains(id)) {
          evictId = id;
          break;
        }
      }
      if (evictId == null) {
        return;
      }
      kill(evictId);
    }
  }
}
