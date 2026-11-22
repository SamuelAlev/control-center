/// The contracts around the wake queue that other parts of the server plug
/// into: an admission guard ([WakeAdmissionGuard]), what a producer gets
/// back from an immediate delivery ([WakeReceipt]), and what a settled-wake
/// handler hears ([WakeSettlement]).
library;

import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// A guard's answer for one wake at admission.
sealed class WakeAdmission {
  const WakeAdmission();

  /// Let it through.
  const factory WakeAdmission.admit() = WakeAdmit;

  /// Let it through, but the run it starts spends at most [capMicros]
  /// (positive): what a budget over the wake has left. The run's cap is the
  /// lowest of the wake's own and every guard's.
  const factory WakeAdmission.admitWithin(int capMicros) = WakeAdmit.within;

  /// Not now: the wake stays pending until [until] (a minute from now when
  /// null), with [reason] (1 to 100 characters) as its state reason. For a
  /// refusal that clears by itself.
  const factory WakeAdmission.defer({required String reason, DateTime? until}) =
      WakeDefer;

  /// Never: the wake is skipped with [kind] (1 to 100 characters) as its
  /// state reason, and the conversation gets one system row saying so.
  const factory WakeAdmission.skip(String kind) = WakeSkip;
}

/// See [WakeAdmission.admit].
final class WakeAdmit extends WakeAdmission {
  /// Creates the answer.
  const WakeAdmit() : capMicros = null;

  /// See [WakeAdmission.admitWithin].
  const WakeAdmit.within(int this.capMicros);

  /// The most the wake's run may spend, or null for the wake's own cap.
  final int? capMicros;
}

/// See [WakeAdmission.defer].
final class WakeDefer extends WakeAdmission {
  /// Creates the answer.
  const WakeDefer({required this.reason, this.until});

  /// The wake's state reason while it waits.
  final String reason;

  /// When to look again; null for a minute from now.
  final DateTime? until;
}

/// See [WakeAdmission.skip].
final class WakeSkip extends WakeAdmission {
  /// Creates the answer.
  const WakeSkip(this.kind);

  /// The skipped wake's state reason.
  final String kind;
}

/// A check a later part of the server adds to admission (a goal's own
/// state, a rule's cost cap). Guards run after the queue's own checks
/// (workspace, agent, requester, take-over, budget) and before the rate
/// caps, in the order they were registered; the first one that does not
/// admit decides.
abstract interface class WakeAdmissionGuard {
  /// Decides for [wake] at [now]. Must not throw; a throw is read as a
  /// deferral (`guard_failed`).
  Future<WakeAdmission> admit(Wake wake, {required DateTime now});
}

/// What [Wake] delivery came to, for a producer that delivers at once
/// (`WakeQueueService.enqueueAndDeliver`).
sealed class WakeReceipt {
  const WakeReceipt();
}

/// The wake started a run, [runId].
final class WakeStarted extends WakeReceipt {
  /// Creates the receipt.
  const WakeStarted(this.runId);

  /// The run the wake started.
  final String runId;
}

/// The wake was pushed into [runId]'s lane; it is delivered when that run
/// takes it.
final class WakePushed extends WakeReceipt {
  /// Creates the receipt.
  const WakePushed(this.runId);

  /// The live run whose lane holds the wake.
  final String runId;
}

/// The wake is waiting, for [kind]: `not_due`, `quiet_window`, a deferral
/// reason (`take_over`, `rate_cap_conversation`, `rate_cap_workspace`,
/// `live_run_no_input`, `live_run_other_options`, `live_run_other_person`,
/// `budget_blocked`, `agent_paused`, a guard's reason), `held`.
final class WakeWaiting extends WakeReceipt {
  /// Creates the receipt.
  const WakeWaiting(this.kind);

  /// Why it waits.
  final String kind;
}

/// The wake was skipped, for [kind] (its state reason).
final class WakeSkipped extends WakeReceipt {
  /// Creates the receipt.
  const WakeSkipped(this.kind);

  /// Why it was skipped.
  final String kind;
}

/// A wake with the same dedup key exists; nothing was inserted.
final class WakeDuplicate extends WakeReceipt {
  /// Creates the receipt.
  const WakeDuplicate();
}

/// A wake that reached a settled state, for a [WakeSettledHandler].
class WakeSettlement {
  /// Creates a settlement.
  const WakeSettlement({
    required this.wake,
    required this.state,
    this.runId,
    this.reason,
  });

  /// The wake as it was before it settled.
  final Wake wake;

  /// `delivered`, `skipped`, `expired` or `cancelled`.
  final WakeState state;

  /// The run that took it, for `delivered`.
  final String? runId;

  /// The state reason, for the other states.
  final String? reason;
}

/// Hears each wake once when it settles. Must not throw; a throw is logged.
typedef WakeSettledHandler = FutureOr<void> Function(WakeSettlement settled);

/// The refusal kind of `wakes.release` and `wakes.deliverNow` on a wake that
/// acts for another person: nobody acts with another person's sign-in.
const String wakeNotYoursKind = 'wake_not_yours';

/// The state reasons the queue writes itself. Each is 1 to 100 characters.
abstract final class WakeStateReasons {
  /// A person stopped the conversation's run: its pending wakes are held.
  static const String stopped = 'stopped';

  /// Delivery was tried three times.
  static const String attempts = 'attempts';

  /// The target agent no longer exists.
  static const String agentDeleted = 'agent_deleted';

  /// The target agent is retired (archived): the wake is skipped.
  static const String agentNotDispatchable = 'agent_not_dispatchable';

  /// The target agent is paused: the wake waits (it expires after its
  /// bound, `WakeQueueService.maxWaitOnRefusal`, with this kind).
  static const String agentPaused = 'agent_paused';

  /// The person the wake acts for is no longer a member.
  static const String personRemoved = 'person_removed';

  /// The agent's or workspace's budget blocks a run: the wake waits, as
  /// for [agentPaused].
  static const String budgetBlocked = 'budget_blocked';

  /// A person holds the conversation's worktree.
  static const String takeOver = 'take_over';

  /// 30 wake-started runs in the conversation in the last hour.
  static const String rateCapConversation = 'rate_cap_conversation';

  /// 300 wake-started runs in the workspace in the last hour.
  static const String rateCapWorkspace = 'rate_cap_workspace';

  /// The agent has a live run in the conversation that takes no input.
  static const String liveRunNoInput = 'live_run_no_input';

  /// The agent's live run in the conversation runs another way than the
  /// wake asks (read-only, fresh, capped, an output schema, on either side):
  /// the wake starts its own run when that one settles.
  static const String liveRunOtherOptions = 'live_run_other_options';

  /// The agent's live run in the conversation acts for another person (or
  /// for a person, the wake for nobody, or the reverse): the wake starts its
  /// own run when that one settles.
  static const String liveRunOtherPerson = 'live_run_other_person';

  /// The dispatch did not start a run.
  static const String dispatchRefused = 'dispatch_refused';

  /// A read-only run needs a sandbox the host does not have.
  static const String sandboxUnavailable = 'sandbox_unavailable';

  /// A read-only run asked of a backend that cannot hold it to reading
  /// (`ReadOnlyRunUnavailableException.backendKind`).
  static const String readOnlyUnavailable = 'read_only_unavailable';

  /// The run the wake started was stopped by a server restart.
  static const String serverStopped = 'server_stopped';

  /// A held recovery wake: a person's run was stopped by a server restart.
  static const String serverRestarted = 'server_restarted';

  /// A guard threw.
  static const String guardFailed = 'guard_failed';

  /// A held `limitReset` wake: a person's run reached the provider's usage
  /// limit and waits for that person's Resume (`LimitPark.heldReason`).
  static const String limit = 'limit';

  /// A `limitReset` wake waits while the run it would resume is still live
  /// (the credential park before a run starts holds it in memory).
  static const String limitRunLive = 'limit_run_live';
}
