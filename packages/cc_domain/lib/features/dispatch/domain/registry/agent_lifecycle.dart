import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/registry/registry_event.dart';

/// A handle to a live agent session, owned by the [AgentLifecycleManager].
///
/// In Control Center a "live session" is a re-dispatchable run produced by an
/// [AgentReviver]. The manager disposes it when it parks or releases the agent;
/// the integration decides what dispose means (stop the dispatch, close the
/// relay, …). [dispatchId] lets the manager mirror the live dispatch into the
/// registry so the roster shows the revived run.
abstract interface class AgentSessionController {
  /// The id of the live dispatch backing this session, if known.
  String? get dispatchId;

  /// Tears down the live session. Called on park and release. Must not throw
  /// in a way that wedges the lifecycle loop — the manager swallows errors.
  Future<void> dispose();
}

/// Recreates a live session for a parked/idle agent on demand. Supplied at
/// `AgentLifecycleManager.adopt` time (for an in-memory adoption) or built by a
/// [PersistedSubagentReviverFactory] for a ref restored from disk.
typedef AgentReviver = Future<AgentSessionController> Function();

/// Builds a reviver for a `parked` ref that carries a `sessionFile` but no
/// in-memory adoption (e.g. restored after a process restart). Returns null
/// when the ref cannot be faithfully rebuilt (no persisted contract, or its
/// workspace is gone — a merged/moved worktree). Injected by the integration so
/// the manager stays free of dispatch-runtime imports — this is Feature #3,
/// persisted cold-revive.
typedef PersistedSubagentReviverFactory = Future<AgentReviver?> Function(
  AgentRef ref,
);

class _AdoptedAgent {
  _AdoptedAgent({required this.idleTtlMs, this.reviver, this.session});

  final int idleTtlMs;
  AgentReviver? reviver;
  AgentSessionController? session;
  Timer? timer;
}

/// Owns the idle → parked → revived lifecycle of adopted agents.
///
/// When a dispatch finishes the integration [adopt]s the agent with an
/// `idleTtlMs`; the manager arms a TTL timer whenever the agent is idle, parks
/// it on expiry (disposing any live session, retaining the [AgentRef] +
/// `sessionFile`), and revives it on demand through [ensureLive]. Only this
/// manager flips `parked` ↔ `idle`/`running`; the dispatch service owns the
/// `running` ↔ `idle` transitions.
///
/// Pure Dart: it coordinates timers and an injected [AgentRegistry], so it is
/// fully testable without the dispatch runtime.
class AgentLifecycleManager {
  /// Creates a manager bound to the given registry. Subscribes to registry
  /// changes to arm/disarm idle-TTL timers; call [dispose] to unsubscribe.
  AgentLifecycleManager(this._registry) {
    _subscription = _registry.changes.listen(_onRegistryEvent);
  }

  final AgentRegistry _registry;
  final Map<String, _AdoptedAgent> _adopted = {};

  /// Ids whose session is being disposed by [park] right now.
  final Set<String> _parking = {};

  /// In-flight revives, so concurrent [ensureLive] calls coalesce.
  final Map<String, Future<AgentSessionController>> _revivals = {};

  StreamSubscription<RegistryEvent>? _subscription;
  PersistedSubagentReviverFactory? _persistedReviverFactory;
  int _persistedReviveTtlMs = 0;

  /// Installs the factory used to cold-revive `parked` refs restored from disk.
  /// Set by the integration, which owns the dispatch context the factory needs.
  void setPersistedSubagentReviverFactory(
    PersistedSubagentReviverFactory factory,
    int idleTtlMs,
  ) {
    _persistedReviverFactory = factory;
    _persistedReviveTtlMs = idleTtlMs;
  }

  /// Takes ownership of an agent's lifecycle. [idleTtlMs] `<= 0` adopts without
  /// a parking timer. An optional already-live [session] is held so the next
  /// [ensureLive] returns it without reviving; [reviver] recreates the session
  /// after a park. Arms the TTL timer immediately when the agent is idle.
  void adopt(
    String id, {
    required int idleTtlMs,
    AgentReviver? reviver,
    AgentSessionController? session,
  }) {
    if (_registry.get(id) == null) {
      return;
    }
    final existing = _adopted[id];
    existing?.timer?.cancel();
    final adopted = _AdoptedAgent(
      idleTtlMs: idleTtlMs,
      reviver: reviver,
      session: session,
    );
    _adopted[id] = adopted;
    if (_registry.get(id)?.status == AgentStatus.idle) {
      _armTimer(id, adopted);
    }
  }

  /// True if the id is adopted (live or parked).
  bool has(String id) => _adopted.containsKey(id);

  /// True while [park] is disposing this agent's session, letting dispose hooks
  /// distinguish a park from a teardown.
  bool isParking(String id) => _parking.contains(id);

  /// Parks an idle agent: disposes any live session, detaches its dispatch, and
  /// marks it `parked`. No-op unless the agent is adopted and currently idle.
  Future<void> park(String id) async {
    final adopted = _adopted[id];
    if (adopted == null) {
      return;
    }
    if (_registry.get(id)?.status != AgentStatus.idle) {
      return;
    }
    adopted.timer?.cancel();
    adopted.timer = null;
    _parking.add(id);
    try {
      final session = adopted.session;
      if (session != null) {
        try {
          await session.dispose();
        } on Object {
          // A dispose failure must not strand the agent as un-parkable.
        }
        adopted.session = null;
      }
      _registry.detachDispatch(id);
      _registry.setStatus(id, AgentStatus.parked);
    } finally {
      _parking.remove(id);
    }
  }

  /// Returns a live session, reviving from the reviver (or the persisted
  /// factory) when the agent has none. Concurrent calls share one in-flight
  /// revive. Throws when the id is unknown or cannot be revived.
  Future<AgentSessionController> ensureLive(String id) async {
    final ref = _registry.get(id);
    if (ref == null) {
      throw StateError(
        'Unknown agent "$id" — never registered or already released.',
      );
    }
    final live = _adopted[id]?.session;
    if (live != null) {
      return live;
    }
    final inflight = _revivals[id];
    if (inflight != null) {
      return inflight;
    }
    final revival = _resolveAndRevive(id, ref);
    _revivals[id] = revival;
    try {
      return await revival;
    } finally {
      // The removed value is `revival` itself, already awaited above; dropping
      // the in-flight entry here is intentional, not a discarded future.
      // ignore: unawaited_futures
      _revivals.remove(id);
    }
  }

  /// Hard removal: dispose the live session if any, drop timers, and unregister
  /// the agent from the registry.
  Future<void> release(String id) async {
    final adopted = _adopted.remove(id);
    adopted?.timer?.cancel();
    final session = adopted?.session;
    if (session != null) {
      try {
        await session.dispose();
      } on Object {
        // Best-effort teardown.
      }
    }
    _registry.unregister(id);
  }

  /// Tears everything down (process exit / shutdown). Releases every adopted
  /// agent and unsubscribes from the registry.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    final ids = [..._adopted.keys];
    for (final id in ids) {
      await release(id);
    }
    _revivals.clear();
    _parking.clear();
    _persistedReviverFactory = null;
  }

  Future<AgentSessionController> _resolveAndRevive(
    String id,
    AgentRef ref,
  ) async {
    var reviver = _adopted[id]?.reviver;
    var coldAdopted = false;
    final factory = _persistedReviverFactory;
    if (reviver == null &&
        ref.status == AgentStatus.parked &&
        ref.sessionFile != null &&
        factory != null) {
      reviver = await factory(ref);
      if (reviver != null) {
        _adopted[id] = _AdoptedAgent(
          idleTtlMs: _persistedReviveTtlMs,
          reviver: reviver,
        );
        coldAdopted = true;
      }
    }
    if (reviver == null) {
      throw StateError(
        'Agent "$id" is ${ref.status.name} and cannot be revived '
        '(no reviver registered).',
      );
    }
    try {
      return await _revive(id, reviver);
    } on Object {
      // A failed cold revive must not leave a poisoned reviver stuck in the
      // adoption map — drop it so a later ensureLive rebuilds via the factory.
      if (coldAdopted) {
        _adopted.remove(id);
      }
      rethrow;
    }
  }

  Future<AgentSessionController> _revive(String id, AgentReviver reviver) async {
    final session = await reviver();
    final adopted = _adopted[id];
    if (adopted != null) {
      adopted.session = session;
    }
    // Flip to idle FIRST (emits status_changed → idle, re-arming the TTL timer
    // via onChange). setStatus clears any dispatch on a non-running status, so
    // the revived dispatch must be (re)attached AFTER, not before.
    _registry.setStatus(id, AgentStatus.idle);
    final dispatchId = session.dispatchId;
    if (dispatchId != null) {
      _registry.attachDispatch(id, dispatchId);
    }
    return session;
  }

  void _armTimer(String id, _AdoptedAgent adopted) {
    if (adopted.idleTtlMs <= 0) {
      return;
    }
    adopted.timer?.cancel();
    adopted.timer = Timer(
      Duration(milliseconds: adopted.idleTtlMs),
      () {
        adopted.timer = null;
        unawaited(park(id));
      },
    );
  }

  void _onRegistryEvent(RegistryEvent event) {
    final adopted = _adopted[event.ref.id];
    if (adopted == null) {
      return;
    }
    if (event is AgentRemoved) {
      adopted.timer?.cancel();
      _adopted.remove(event.ref.id);
      return;
    }
    if (event is! AgentStatusChanged) {
      return;
    }
    switch (event.ref.status) {
      case AgentStatus.running:
        adopted.timer?.cancel();
        adopted.timer = null;
      case AgentStatus.idle:
        _armTimer(event.ref.id, adopted);
      case AgentStatus.parked:
      case AgentStatus.aborted:
        adopted.timer?.cancel();
        adopted.timer = null;
    }
  }
}
