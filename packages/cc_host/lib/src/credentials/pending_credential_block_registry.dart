import 'dart:async';

import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';

/// A run parked because the credential it needs cannot serve it.
///
/// Created by [PendingCredentialBlockRegistry.register] when a dispatch reaches
/// a launch branch it would otherwise have failed on, published to every
/// connected client over `credential_gate.watchBlocked` and resolved by the
/// credential becoming usable again (the poll), by a `credential_gate.resolve`
/// call, or by the deadline.
class PendingCredentialBlock {
  /// Creates a [PendingCredentialBlock].
  const PendingCredentialBlock({
    required this.id,
    required this.request,
    required this.createdAt,
    this.expiresAt,
  });

  /// Stable id the client echoes back in `credential_gate.resolve`.
  final String id;

  /// What the run is waiting on.
  final RunCredentialBlockRequest request;

  /// When the block was raised (UTC, ISO-8601 on the wire).
  final DateTime createdAt;

  /// When the gate gives up and the run fails with its own message, or null
  /// when this host waits indefinitely.
  final DateTime? expiresAt;
}

/// Serializes a [PendingCredentialBlock] to its wire shape (one
/// `credential_gate.watchBlocked` snapshot entry).
Map<String, dynamic> pendingCredentialBlockToWire(PendingCredentialBlock b) => {
  'id': b.id,
  'lane': b.request.lane.wire,
  'reason': b.request.reason.wire,
  'detail': b.request.detail,
  if (b.request.runLogId != null) 'run_log_id': b.request.runLogId,
  'created_at': b.createdAt.toUtc().toIso8601String(),
  if (b.expiresAt != null) 'expires_at': b.expiresAt!.toUtc().toIso8601String(),
  if (b.request.providerId != null) 'provider_id': b.request.providerId,
  if (b.request.accountIds.isNotEmpty) 'account_ids': b.request.accountIds,
  if (b.request.availableAt != null)
    'available_at': b.request.availableAt!.toUtc().toIso8601String(),
  if (b.request.workspaceId != null) 'workspace_id': b.request.workspaceId,
  if (b.request.spaceId != null) 'space_id': b.request.spaceId,
  if (b.request.conversationId != null)
    'conversation_id': b.request.conversationId,
  if (b.request.agentId != null) 'agent_id': b.request.agentId,
  if (b.request.agentName != null) 'agent_name': b.request.agentName,
};

class _Entry {
  _Entry(this.pending, this.completer, this.recheck, this.timer);

  final PendingCredentialBlock pending;
  final Completer<RunCredentialOutcome> completer;

  /// Answers "can the run go now?". Owned by the caller (the dispatch session),
  /// because only it knows what its own launch branch tests.
  final Future<bool> Function() recheck;

  /// The deadline timer, or null when this host waits indefinitely.
  final Timer? timer;

  /// Whether a probe for this entry is already in flight, so a slow one is not
  /// stacked on by the next tick.
  bool probing = false;
}

/// Host-side registry of runs parked on a credential.
///
/// The bridge between a dispatch blocked server-side and the humans who can
/// unblock it. [register] mints an id and a future that resolves when the
/// credential starts working (the poll, or [nudge]), when a client answers
/// ([respond]), or when the deadline passes (→
/// [RunCredentialOutcome.timedOut]).
///
/// The poll is what makes this work at all. Most of the fixes happen OUTSIDE
/// the server — `claude auth login` runs in a terminal and writes the CLI's own
/// credential, a spent plan window reopens on Anthropic's clock — so there is no
/// write for the server to observe. [nudge] is the fast path for the fixes that
/// DO come through the server (a pasted API key, a completed OAuth), not a
/// replacement for the poll.
class PendingCredentialBlockRegistry {
  /// Creates a registry.
  ///
  /// [deadline] bounds how long a run may stay parked; null waits forever.
  /// Non-null is the server default and is what keeps an unattended run (a
  /// pipeline step, a cron trigger) from hanging on a human who is asleep — it
  /// falls through to exactly the failure it had before this feature existed.
  ///
  /// [pollInterval] is how often each entry's `recheck` is consulted.
  PendingCredentialBlockRegistry({
    this.deadline = const Duration(minutes: 15),
    this.pollInterval = const Duration(seconds: 8),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// How long a parked run waits before failing with its own message.
  final Duration? deadline;

  /// How often a parked run's credential is re-probed.
  final Duration pollInterval;

  final DateTime Function() _clock;

  final Map<String, _Entry> _entries = {};
  final StreamController<List<PendingCredentialBlock>> _blocked =
      StreamController<List<PendingCredentialBlock>>.broadcast();
  int _counter = 0;

  /// One timer for the whole registry, not one per entry: parked runs are rare
  /// and usually share a cause (one provider, one account), so a single tick
  /// that walks the map is both cheaper and easier to reason about.
  Timer? _pollTimer;

  /// A live snapshot stream of parked runs (full snapshot per change).
  Stream<List<PendingCredentialBlock>> get blocked => _blocked.stream;

  /// [blocked], but every subscriber is handed the CURRENT state first.
  ///
  /// This is what the RPC watch serves, and the plain stream is not a
  /// substitute for it. A parked run can sit for the whole gate deadline
  /// without the set changing once, so a client that connects mid-wait — a
  /// desktop that reconnected, a second window, a phone picked up — would
  /// otherwise see an empty list and offer the operator no way to unblock the
  /// run they are looking at.
  ///
  /// The subscription is attached BEFORE the snapshot is pushed, so a block
  /// registered in between is delivered rather than dropped. The cost is a
  /// possible duplicate frame, which a full-snapshot stream absorbs.
  Stream<List<PendingCredentialBlock>> get blockedWithSnapshot =>
      Stream<List<PendingCredentialBlock>>.multi((controller) {
        final sub = _blocked.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller
          ..onCancel = sub.cancel
          ..add(snapshot);
      });

  /// The currently parked runs.
  List<PendingCredentialBlock> get snapshot =>
      _entries.values.map((e) => e.pending).toList(growable: false);

  /// The parked entry for [id], or null when unknown/resolved.
  ///
  /// Lets `credential_gate.resolve` authorize against the block's workspace
  /// BEFORE resolving it — [respond] removes the entry on success, so the check
  /// cannot be made afterwards.
  PendingCredentialBlock? blockById(String id) => _entries[id]?.pending;

  /// Parks a run described by [request], returning its id and the future that
  /// resolves to how the parking ended. The returned future never throws.
  ///
  /// [recheck] is polled every [pollInterval]; a true answer resolves the run.
  /// [deadlineOverride] replaces the registry-wide [deadline] for this entry.
  ({String id, Future<RunCredentialOutcome> outcome}) register(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
    Duration? deadlineOverride,
  }) {
    final id = 'cg_${_clock().toUtc().microsecondsSinceEpoch}_${_counter++}';
    final completer = Completer<RunCredentialOutcome>();
    final limit = deadlineOverride ?? deadline;
    final entry = PendingCredentialBlock(
      id: id,
      request: request,
      createdAt: _clock().toUtc(),
      expiresAt: limit == null ? null : _clock().toUtc().add(limit),
    );
    final timer = limit == null
        ? null
        : Timer(limit, () => _finish(id, RunCredentialOutcome.timedOut));
    _entries[id] = _Entry(entry, completer, recheck, timer);
    _ensurePolling();
    _emit();
    return (id: id, outcome: completer.future);
  }

  /// Records a client decision for [id]: `retry` re-probes immediately (the
  /// operator says they have just fixed it), `cancel` gives up on the run.
  ///
  /// Returns true when [id] was parked. A `retry` that finds the credential
  /// still unusable leaves the run parked and returns true — the block is not a
  /// question with a wrong answer, it is a state.
  Future<bool> respond(String id, {required bool cancel}) async {
    final entry = _entries[id];
    if (entry == null) {
      return false;
    }
    if (cancel) {
      _finish(id, RunCredentialOutcome.cancelled);
      return true;
    }
    await _probe(id);
    return true;
  }

  /// Re-probes now instead of waiting for the next tick.
  ///
  /// Called from the server ops that WRITE a credential (a pasted API key, a
  /// completed OAuth), so the fix that does pass through the server lands
  /// immediately rather than up to [pollInterval] later. Pass [id] to probe one
  /// entry; omit it for all of them.
  Future<void> nudge({String? id}) async {
    if (id != null) {
      await _probe(id);
      return;
    }
    await Future.wait(_entries.keys.toList().map(_probe));
  }

  /// Resolves and drops every parked run as [RunCredentialOutcome.timedOut]
  /// (e.g. on shutdown), so each falls through to its own failure message
  /// rather than being left hanging on a dead registry.
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    for (final entry in _entries.values) {
      entry.timer?.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.complete(RunCredentialOutcome.timedOut);
      }
    }
    _entries.clear();
    if (!_blocked.isClosed) {
      _blocked.close();
    }
  }

  void _ensurePolling() {
    _pollTimer ??= Timer.periodic(pollInterval, (_) => nudge());
  }

  void _stopPollingIfIdle() {
    if (_entries.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _probe(String id) async {
    final entry = _entries[id];
    // Skipped rather than queued when a probe is already running: a `claude
    // auth status` probe can take seconds, and stacking ticks behind a slow one
    // would turn a single stuck host into an unbounded pile of subprocesses.
    if (entry == null || entry.probing) {
      return;
    }
    entry.probing = true;
    try {
      if (await entry.recheck()) {
        _finish(id, RunCredentialOutcome.resolved);
      }
    } on Object {
      // A throwing probe leaves the run parked. A transient failure (the
      // keychain is locked, the usage endpoint timed out) is neither "still
      // broken forever" nor "fixed", and guessing either way is worse than
      // waiting for the next tick.
    } finally {
      entry.probing = false;
    }
  }

  void _finish(String id, RunCredentialOutcome outcome) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return;
    }
    entry.timer?.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(outcome);
    }
    _stopPollingIfIdle();
    _emit();
  }

  void _emit() {
    if (!_blocked.isClosed) {
      _blocked.add(snapshot);
    }
  }
}

/// The [RunCredentialGatePort] the dispatch stack holds: every parked run is
/// registered for remote visibility and resolution.
class RemoteRunCredentialGate implements RunCredentialGatePort {
  /// Creates a [RemoteRunCredentialGate] over the given registry.
  const RemoteRunCredentialGate(this._registry);

  final PendingCredentialBlockRegistry _registry;

  @override
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  }) => _registry.register(request, recheck: recheck).outcome;
}
