/// The coarse lifecycle phase of a rig — the part that is persisted and
/// indexed. [RigStatus] carries the detail.
enum RigPhase {
  /// Booting: image overlay created, guest starting, agent not yet reachable.
  provisioning,

  /// Reachable and accepting actions.
  ready,

  /// Idle-parked. The guest is stopped (zero CPU) but still resident; the next
  /// action wakes it. Parking is NOT free: a parked guest still holds its RAM,
  /// which is why the reaper counts memory, not sessions.
  parked,

  /// Shutting down.
  closing,

  /// Gone. The overlay is discarded and the id is only good for the audit log.
  closed,

  /// Died or failed to boot. Terminal, like [closed], but distinguishable so
  /// the UI can offer "retry" instead of "reopen".
  failed;

  /// Stable wire/storage string.
  String get wire => name;

  /// Whether the rig can still accept actions (possibly after a wake).
  bool get isLive => this == RigPhase.ready || this == RigPhase.parked;

  /// Whether a machine exists (or is being built) for this phase.
  ///
  /// Deliberately WIDER than [isLive] and used for reuse lookups: a boot takes
  /// a minute or more, and a model that is told "still starting, try again"
  /// will try again. If reuse only matched [isLive], every one of those
  /// retries would boot another 2 GB VM — a poll loop turns into a VM
  /// stampede that evicts its own predecessors and never converges.
  bool get holdsMachine => !isTerminal;

  /// Whether this phase is terminal.
  bool get isTerminal => this == RigPhase.closed || this == RigPhase.failed;

  /// Parses [value] back into a phase, or null when unknown.
  static RigPhase? fromWire(String? value) {
    for (final p in RigPhase.values) {
      if (p.wire == value) {
        return p;
      }
    }
    return null;
  }
}

/// Why a rig was closed. Recorded so "it disappeared" is always answerable.
enum RigCloseReason {
  /// A human or agent asked for it.
  requested,

  /// Nothing touched it for its idle timeout.
  idleTimeout,

  /// It outlived its hard TTL. The TTL is not negotiable by the guest: a rig
  /// that could extend its own life indefinitely is not ephemeral.
  ttlExpired,

  /// The conversation that owned it ended.
  conversationEnded,

  /// The workspace was deleted, or the viewer lost membership of it.
  workspaceGone,

  /// The server is shutting down.
  serverShutdown,

  /// The backend failed underneath it (hypervisor died, worker lease lost).
  backendFailure;

  /// Stable wire/storage string.
  String get wire => name;

  /// Parses [value] back into a reason, or null when unknown.
  static RigCloseReason? fromWire(String? value) {
    for (final r in RigCloseReason.values) {
      if (r.wire == value) {
        return r;
      }
    }
    return null;
  }
}

/// The status of a rig, with the detail that belongs to each phase.
///
/// Sealed rather than a bare enum because the interesting states carry
/// payload: what a boot is currently doing, why a rig closed, what killed it.
/// A UI that only has "failed" has to make the reason up.
sealed class RigStatus {
  /// Const base constructor.
  const RigStatus();

  /// Rebuilds a status from its persisted [phase] plus the stored detail
  /// columns. Unknown phases resolve to [RigFailed] rather than throwing — a
  /// row written by a newer build must still be readable enough to close.
  factory RigStatus.fromStorage({
    required String? phase,
    String? detail,
    String? closeReason,
  }) {
    switch (RigPhase.fromWire(phase)) {
      case RigPhase.provisioning:
        return RigProvisioning(step: detail ?? 'Starting');
      case RigPhase.ready:
        return const RigReady();
      case RigPhase.parked:
        return const RigParked();
      case RigPhase.closing:
        return const RigClosing();
      case RigPhase.closed:
        return RigClosed(
          RigCloseReason.fromWire(closeReason) ?? RigCloseReason.requested,
        );
      case RigPhase.failed:
        return RigFailed(detail ?? 'Unknown failure');
      case null:
        return RigFailed('Unknown rig phase "$phase"');
    }
  }

  /// The persisted phase.
  RigPhase get phase;

  /// Free-form detail persisted alongside the phase (boot step, failure
  /// message). Null when the phase carries none.
  String? get detail => null;

  /// The close reason, when this status is [RigClosed].
  RigCloseReason? get closeReason => null;

  /// Whether the rig can accept an action now or after a wake.
  bool get isLive => phase.isLive;
}

/// Booting.
class RigProvisioning extends RigStatus {
  /// Creates a [RigProvisioning] describing the current boot [step].
  const RigProvisioning({required this.step});

  /// What the boot is doing right now ("Creating overlay", "Waiting for
  /// guest agent", "Syncing worktree"). Shown verbatim in the UI, so it is
  /// written for a human.
  final String step;

  @override
  RigPhase get phase => RigPhase.provisioning;

  @override
  String? get detail => step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RigProvisioning && other.step == step;

  @override
  int get hashCode => step.hashCode;
}

/// Reachable and accepting actions.
class RigReady extends RigStatus {
  /// Creates a [RigReady].
  const RigReady();

  @override
  RigPhase get phase => RigPhase.ready;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RigReady;

  @override
  int get hashCode => RigPhase.ready.hashCode;
}

/// Idle-parked: stopped, still resident, wakes on the next action.
class RigParked extends RigStatus {
  /// Creates a [RigParked].
  const RigParked();

  @override
  RigPhase get phase => RigPhase.parked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RigParked;

  @override
  int get hashCode => RigPhase.parked.hashCode;
}

/// Shutting down.
class RigClosing extends RigStatus {
  /// Creates a [RigClosing].
  const RigClosing();

  @override
  RigPhase get phase => RigPhase.closing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RigClosing;

  @override
  int get hashCode => RigPhase.closing.hashCode;
}

/// Gone, for a stated reason.
class RigClosed extends RigStatus {
  /// Creates a [RigClosed] with the [reason] it went away.
  const RigClosed(this.reason);

  /// Why it closed.
  final RigCloseReason reason;

  @override
  RigPhase get phase => RigPhase.closed;

  @override
  RigCloseReason? get closeReason => reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RigClosed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Died, or never came up.
class RigFailed extends RigStatus {
  /// Creates a [RigFailed] carrying the operator-facing [message].
  const RigFailed(this.message);

  /// What went wrong, phrased for the person reading it.
  final String message;

  @override
  RigPhase get phase => RigPhase.failed;

  @override
  String? get detail => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RigFailed && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
