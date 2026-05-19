import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';

/// A pending agent-action confirmation surfaced for remote approval.
///
/// Created by [PendingConfirmationRegistry.register] when a privileged tool
/// needs human approval, published to remote clients over the
/// `confirmation.watchPending` subscription and resolved by a
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
  'space_id': p.request.spaceId,
  if (p.request.workspaceId != null) 'workspace_id': p.request.workspaceId,
  'title': p.request.title,
  'detail': p.request.detail,
  'severity': p.request.severity.name,
  if (p.request.command != null) 'command': p.request.command,
  // The remember offer. These travelled nowhere before, which is why the
  // "remember this decision" affordance could not be built: the client had
  // no way to know a request was rememberable, and the responder had nothing
  // to write a rule from.
  if (p.request.rememberChoice != null)
    'remember_scope': p.request.rememberChoice!.name,
  if (p.request.actionClasses.isNotEmpty)
    'action_classes': p.request.actionClasses,
  if (p.request.agentId != null) 'agent_id': p.request.agentId,
  if (p.request.fingerprint != null) 'fingerprint': p.request.fingerprint,
  'created_at': p.createdAt.toUtc().toIso8601String(),
};

class _Entry {
  _Entry(this.pending, this.completer, this.timer);
  final PendingConfirmation pending;
  final Completer<bool> completer;

  /// The auto-deny timer, or null when the registry waits indefinitely.
  final Timer? timer;
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
  /// Creates a registry. When [timeout] is null (the default) an unresolved
  /// request blocks the agent INDEFINITELY — it resolves only when a client
  /// approves or denies. Pass a non-null [timeout] to auto-deny after that long.
  PendingConfirmationRegistry({this.timeout, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// How long a request waits for any response before being auto-denied, or null
  /// to wait forever. Null is the server default: an approval-gated action hangs
  /// until the user decides, never silently timing out.
  final Duration? timeout;
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

  /// The pending entry for [id], or null when unknown/resolved. Lets the
  /// `confirmation.respond` op authorize against the request's workspace
  /// BEFORE resolving it ([respond] removes the entry on success).
  PendingConfirmation? pendingById(String id) => _entries[id]?.pending;

  /// Registers [request], returning the pending id and the future that resolves
  /// to the decision (true = approved, false = denied/timeout). The returned
  /// future never throws.
  ///
  /// [timeoutOverride] replaces the registry-wide [timeout] for this one
  /// request. A caller that BLOCKS work on the answer — the sandbox exec-grant
  /// prompt holds a dispatch until it resolves — wants a far shorter deadline
  /// than the registry's generous default, and resolving it here (rather than
  /// racing a local timer) is what removes the entry from the pending list, so
  /// no stale prompt is left on the operator's phone.
  ({String id, Future<bool> approved}) register(
    ConfirmationRequest request, {
    Duration? timeoutOverride,
  }) {
    final id = 'cf_${_clock().toUtc().microsecondsSinceEpoch}_${_counter++}';
    final completer = Completer<bool>();
    final entry = PendingConfirmation(
      id: id,
      request: request,
      createdAt: _clock().toUtc(),
    );
    final t = timeoutOverride ?? timeout;
    final timer = t == null
        ? null
        : Timer(t, () {
            final removed = _entries.remove(id);
            if (removed != null && !removed.completer.isCompleted) {
              removed.completer.complete(
                false,
              ); // Timeout → fail closed (deny).
              _emit();
            }
          });
    _entries[id] = _Entry(entry, completer, timer);
    _emit();
    return (id: id, approved: completer.future);
  }

  /// Records a remote decision for [id]. Returns true if [id] was pending (and
  /// is now resolved); false if it was already resolved or unknown.
  bool respond(String id, {required bool approved}) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return false;
    }
    entry.timer?.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(approved);
    }
    _emit();
    return true;
  }

  /// Resolves a pending entry to [approved] and removes it — used by the
  /// [RemoteAwareConfirmationPort] composite when the local desktop approver
  /// wins the race, so the remote view clears. No-op if already resolved.
  void cancel(String id, {required bool approved}) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return;
    }
    entry.timer?.cancel();
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
      entry.timer?.cancel();
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
  /// Creates a [RemoteConfirmationPort] backed by the given registry.
  ///
  /// [timeout] overrides the registry's deadline for requests raised through
  /// THIS port, so a caller that parks real work on an answer can share one
  /// registry (and one pending list) without inheriting a deadline sized for
  /// callers that do not.
  RemoteConfirmationPort(this._registry, {this.timeout});

  final PendingConfirmationRegistry _registry;

  /// Per-port deadline, or null to use the registry's.
  final Duration? timeout;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) =>
      _registry.register(request, timeoutOverride: timeout).approved;
}

/// A composite [ConfirmationPort]: a privileged action is approved if EITHER the
/// local port (the desktop's native dialog) OR a remote client responds. The
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
  }) : _local = local,
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
    _registry.cancel(reg.id, approved: approved);
    return approved;
  }
}
