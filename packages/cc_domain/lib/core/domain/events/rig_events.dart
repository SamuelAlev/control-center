import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// A rig finished booting and is accepting actions.
class RigOpened implements DomainEvent {
  /// Creates a [RigOpened].
  const RigOpened({
    required this.workspaceId,
    required this.rigId,
    required this.surface,
    required this.openedBy,
    this.conversationId,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The rig.
  final String rigId;

  /// Which machine it is.
  final RigSurface surface;

  /// Who opened it.
  final Principal openedBy;

  /// The conversation it belongs to, when opened from one.
  final String? conversationId;

  @override
  final DateTime occurredAt;
}

/// A rig went away.
///
/// Consumed by `RigEventListener` and the notification wire, both of which act
/// ONLY on [RigCloseReason.backendFailure]. Every other reason is either
/// something somebody asked for or is published alongside a [RigReaped]
/// carrying the same reason plus the driving agent — acting on both would
/// steer and notify twice for one machine.
/// Named `RigClosedEvent`, not `RigClosed`, unlike its siblings [RigOpened] /
/// [RigControlChanged] / [RigReaped]. `RigClosed` is already taken by the
/// TERMINAL STATUS in `rig_status.dart`, and two types one letter apart —
/// one a lifecycle state, one an event — is a mistake waiting in every
/// import list. The asymmetry is deliberate; do not "fix" it.
class RigClosedEvent implements DomainEvent {
  /// Creates a [RigClosedEvent].
  const RigClosedEvent({
    required this.workspaceId,
    required this.rigId,
    required this.reason,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The rig.
  final String rigId;

  /// Why it closed — the difference between "you closed it" and "it ran out
  /// of time", which the UI must not blur.
  final RigCloseReason reason;

  @override
  final DateTime occurredAt;
}

/// A human took exclusive control of a rig, or handed it back.
///
/// Two consumers, both server-side:
///
///  - `RigEventListener` resolves the rig's driving agent and injects a notice
///    onto its steering lane, so the agent is TOLD it no longer has the wheel
///    instead of discovering it through refused actions. The refusal itself is
///    still enforced at the `RigService.act` chokepoint — this event only
///    explains it.
///  - The notification wire (`rigControlChangedFrame`) forwards it to every
///    entitled client and records it in the durable feed. The frame carries
///    the controller principal so the person who took the wheel is not told
///    they took the wheel.
///
/// Presence does NOT consume it: the roster is synthesized from run/lifecycle
/// events, and who holds a rig's lock is read from the rig row the `rig.*` ops
/// already push.
///
/// A release carries a null [controller] — the event does not record who let
/// go — so nothing downstream can attribute one.
class RigControlChanged implements DomainEvent {
  /// Creates a [RigControlChanged].
  const RigControlChanged({
    required this.workspaceId,
    required this.rigId,
    required this.controller,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The rig.
  final String rigId;

  /// Who holds control now, or null when it was released.
  final Principal? controller;

  /// Whether a human currently holds it.
  bool get isTakeOver => controller?.isUser ?? false;

  @override
  final DateTime occurredAt;
}

/// A rig was reaped for being idle or outliving its TTL.
///
/// Distinct from [RigClosedEvent] (which it accompanies) because "the system
/// took your machine away" is worth surfacing differently from "it closed":
/// an agent mid-task needs to know its rig is gone and why.
///
/// Consumed by `RigEventListener` (steers the driving agent) and the
/// notification wire. Memory-pressure eviction reports
/// [RigCloseReason.idleTimeout] — the eviction sweep picks least-recently-used
/// machines, so the reason it records is the one that made a rig a candidate,
/// not "the host ran low".
class RigReaped implements DomainEvent {
  /// Creates a [RigReaped].
  const RigReaped({
    required this.workspaceId,
    required this.rigId,
    required this.reason,
    required this.occurredAt,
    this.agentId,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The rig.
  final String rigId;

  /// Idle timeout or TTL.
  final RigCloseReason reason;

  /// The agent that was driving it, when there was one.
  final String? agentId;

  @override
  final DateTime occurredAt;
}
