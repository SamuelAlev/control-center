import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when an agent finishes a run (success or failure).
class AgentRunCompleted implements DomainEvent {
  /// Creates an [AgentRunCompleted] event.
  const AgentRunCompleted({
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.occurredAt,
    this.runId,
  });

  /// Run-log id of the finished run, when known. Lets listeners read the run
  /// log directly (exact cost rollup, audit) instead of re-deriving it from
  /// the agent's most-recent log.
  final String? runId;

  /// Agent that finished the run.
  final String agentId;

  /// Workspace the run was executed in.
  ///
  /// `Agent.workspaceId` is non-null and no production site passes null here.
  ///
  /// `required` but still nullable, and the second half is deliberate rather
  /// than forgotten: the DISPATCH CHAIN cannot yet prove non-null.
  /// `AgentDispatchPort.start` takes `String? workspaceId` and
  /// `DispatchSession` stores it as `String?`, so tightening the event without
  /// tightening that chain would only move the `!` to the publisher. What `required` buys today is that a publisher has to SAY
  /// `null` rather than omit the argument, which is what let sites drift.
  final String? workspaceId;

  /// Conversation tied to the run, if any.
  final String? conversationId;

  @override
  final DateTime occurredAt;
}

/// What an agent stopped to wait on a human for.
enum AgentInputKind {
  /// An action it wants to take needs approval.
  approval,

  /// It asked a question (`ask_user`).
  question,

  /// The credential its run needs cannot serve it (signed out, spent plan
  /// window, missing key), so the run is parked until someone fixes it.
  credential;

  /// Wire value in `notifications/agent_awaiting_input` frames.
  String get wire => name;
}

/// An agent stopped and is waiting on a human before it can continue.
///
/// Published once per wait, when it starts: a pending approval, a posted
/// question, a run parked on a credential. The end of the same wait is
/// [AgentInputResolved], keyed by the same [waitId].
class AgentAwaitingInput implements DomainEvent {
  /// Creates an [AgentAwaitingInput].
  const AgentAwaitingInput({
    required this.workspaceId,
    required this.waitId,
    required this.kind,
    required this.summary,
    required this.occurredAt,
    this.spaceId,
    this.conversationId,
    this.agentId,
    this.agentName,
  });

  /// Workspace the waiting run belongs to.
  final String workspaceId;

  /// Identifies this wait: the pending approval's or credential block's id,
  /// or the question's message id.
  final String waitId;

  /// What it is waiting for.
  final AgentInputKind kind;

  /// One line saying what is being asked: the question, the action awaiting
  /// approval, or why the credential cannot serve the run.
  final String summary;

  /// The space where the wait can be answered, when known.
  final String? spaceId;

  /// The conversation within [spaceId], when known.
  final String? conversationId;

  /// The waiting agent, when known.
  final String? agentId;

  /// The waiting agent's display name, when known.
  final String? agentName;

  @override
  final DateTime occurredAt;
}

/// The wait an [AgentAwaitingInput] announced is over: the approval was
/// answered, the question answered or abandoned, the credential fixed or the
/// parked run given up on. Either way nobody needs to act on it any more.
class AgentInputResolved implements DomainEvent {
  /// Creates an [AgentInputResolved].
  const AgentInputResolved({
    required this.workspaceId,
    required this.waitId,
    required this.occurredAt,
  });

  /// Workspace the wait belonged to.
  final String workspaceId;

  /// The [AgentAwaitingInput.waitId] of the wait that ended.
  final String waitId;

  @override
  final DateTime occurredAt;
}
