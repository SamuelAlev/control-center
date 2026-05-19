import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';

/// A pending agent-action confirmation surfaced for remote approval.
///
/// Created by [PendingConfirmationRegistry.register] when a privileged tool
/// needs human approval, published to remote clients over the
/// `confirmation.watchPending` subscription, and resolved by a
/// `confirmation.respond` call (or a timeout → deny).
class PendingConfirmation {
  /// Creates a [PendingConfirmation].
  const PendingConfirmation({
    required this.id,
    required this.request,
    required this.createdAt,
  });

  /// Stable id the remote client echoes back in `confirmation.respond`.
  final String id;

  /// The originating approval request.
  final ConfirmationRequest request;

  /// When the request entered the registry (UTC, ISO-8601 on the wire).
  final DateTime createdAt;
}

/// Serializes a [PendingConfirmation] to its wire shape (the
/// `confirmation.watchPending` snapshot payload per entry).
Map<String, dynamic> pendingConfirmationToWire(PendingConfirmation p) => {
      'id': p.id,
      'conversation_id': p.request.conversationId,
      'title': p.request.title,
      'detail': p.request.detail,
      'severity': p.request.severity.name,
      if (p.request.command != null) 'command': p.request.command,
      'created_at': p.createdAt.toUtc().toIso8601String(),
    };

class _Entry {
  _Entry(this.pending, this.completer, this.timer);
  final PendingConfirmation pending;
  final Completer<bool> completer;
  final Timer timer;
}

/// Host-side registry of in-flight agent-action approvals.
///
/// The bridge that lets a remote client (the `cc_remote` phone) see and resolve
/// approvals for agent actions that run server-side. `register` mints an id and
/// a future that resolves on [respond] (remote decision), [cancel] (the local
/// desktop dialog won the race), or the [timeout] (→ deny). The registry is
/// deliberately VM/host-side only — clients interact through the
/// `confirmation.respond` op and `confirmation.watchPending` query.
class PendingConfirmationRegistry {
  /// Creates a registry that auto-denies unresolved requests after [timeout].
  PendingConfirmationRegistry({
    this.timeout = const Duration(minutes: 15),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// How long a request waits for any response before being auto-denied. Long
  /// enough that a slow local approver is not penalized, short enough that a
  /// forgotten remote request does not block an agent indefinitely.
  final Duration timeout;
  final DateTime Function() _clock;

  final Map<String, _Entry> _entries = {};
  final StreamController<List<PendingConfirmation>> _pending =
      StreamController<List<PendingConfirmation>>.broadcast();
  int _counter = 0;

  /// A live snapshot stream of pending approvals (full snapshot per change).
  Stream<List<PendingConfirmation>> get pending => _pending.stream;

  /// The current pending approvals.
  List<PendingConfirmation> get snapshot =>
      _entries.values.map((e) => e.pending).toList(growable: false);

  /// Registers [request], returning the pending id and the future that resolves
  /// to the decision (true = approved, false = denied/timeout). The returned
  /// future never throws.
  ({String id, Future<bool> approved}) register(ConfirmationRequest request) {
    final id = 'cf_${_clock().toUtc().microsecondsSinceEpoch}_${_counter++}';
    final completer = Completer<bool>();
    final entry = PendingConfirmation(
      id: id,
      request: request,
      createdAt: _clock().toUtc(),
    );
    final timer = Timer(timeout, () {
      final removed = _entries.remove(id);
      if (removed != null && !removed.completer.isCompleted) {
        removed.completer.complete(false); // Timeout → fail closed (deny).
        _emit();
      }
    });
    _entries[id] = _Entry(entry, completer, timer);
    _emit();
    return (id: id, approved: completer.future);
  }

  /// Records a remote decision for [id]. Returns true if [id] was pending (and
  /// is now resolved); false if it was already resolved or unknown.
  bool respond(String id, bool approved) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return false;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(approved);
    }
    _emit();
    return true;
  }

  /// Resolves a pending entry to [approved] and removes it — used by the
  /// [RemoteAwareConfirmationPort] composite when the local desktop approver
  /// wins the race, so the remote view clears. No-op if already resolved.
  void cancel(String id, bool approved) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(approved);
    }
    _emit();
  }

  void _emit() {
    if (!_pending.isClosed) {
      _pending.add(snapshot);
    }
  }

  /// Denies and drops every pending request (e.g. on shutdown).
  void dispose() {
    for (final entry in _entries.values) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.complete(false);
      }
    }
    _entries.clear();
    _pending.close();
  }
}

/// A [ConfirmationPort] that bridges agent-action approvals to remote clients:
/// every [requestApproval] is registered for remote visibility + response, with
/// no local approver. Use on a host that has no local UI (or where remote is the
/// sole approver).
class RemoteConfirmationPort implements ConfirmationPort {
  /// Creates a [RemoteConfirmationPort] backed by [registry].
  RemoteConfirmationPort(this._registry);

  final PendingConfirmationRegistry _registry;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) =>
      _registry.register(request).approved;
}

/// A composite [ConfirmationPort]: a privileged action is approved if EITHER the
/// [local] port (the desktop's native dialog) OR a remote client responds. The
/// first responder wins; the losing side is cleaned up so neither the desktop
/// dialog nor the remote pending view lingers.
///
/// This preserves the existing desktop behavior (the Mac dialog still shows and
/// still works) while ADDING the phone as an approver — the desktop user can
/// approve locally, or step away and approve from the phone.
class RemoteAwareConfirmationPort implements ConfirmationPort {
  /// Creates a [RemoteAwareConfirmationPort] over [local], publishing pending
  /// requests to [registry].
  RemoteAwareConfirmationPort({
    required ConfirmationPort local,
    required PendingConfirmationRegistry registry,
  })  : _local = local,
        _registry = registry;

  final ConfirmationPort _local;
  final PendingConfirmationRegistry _registry;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    final reg = _registry.register(request);
    final localDecision = _local.requestApproval(request);
    // First responder wins; clear the pending entry with the winning value
    // (no-op if the remote already responded and removed it).
    final approved = await Future.any([reg.approved, localDecision]);
    _registry.cancel(reg.id, approved);
    return approved;
  }
}
