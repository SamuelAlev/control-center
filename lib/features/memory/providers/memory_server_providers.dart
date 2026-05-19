// VM-only memory providers (server-side execution half of `memory_providers.dart`).
//
// The memory-harvest listener is a global keep-alive that reacts to local
// pipeline-run-completed domain events and writes harvested facts into the
// local database — it owns the Drift `dao*` repository directly (not the
// RPC-flipped public repo). It runs only on the server, so it lives here,
// kept alive by `bootstrap_io.dart` and never reached from the web graph. The
// web-safe UI providers (fact/policy/grant/domain streams + panel config) stay
// in `memory_providers.dart`.
library;

import 'package:cc_domain/features/memory/domain/services/memory_harvest_listener.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keep-alive listener that harvests schema-validated ticket outputs into
/// workspace memory when a pipeline-dispatched run completes (decisions,
/// outcomes, facts).
final memoryHarvestListenerProvider = Provider<MemoryHarvestListener>((ref) {
  final listener = MemoryHarvestListener(
    eventBus: ref.watch(domainEventBusProvider),
    // Global keep-alive listener (server-execution) — owns the DB directly via
    // dao*, never the active-workspace-bound RPC path.
    runLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
    recordFact: ref.watch(recordMemoryFactUseCaseProvider),
    // Passive extraction: mine a run's free-text summary for additional facts.
    extractMemory: ref.watch(extractMemoryUseCaseProvider),
  )..start();
  ref.onDispose(listener.dispose);
  return listener;
});
