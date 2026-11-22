import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show RunStatus;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';

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

/// A run has ended and its terminal run-log row is written.
///
/// The one fact every reader of a finished run builds on: published exactly
/// once per run, AFTER the terminal write that stamped [status] and
/// [endReason] (the write that won `completeIfActive`), so a listener reads
/// what happened from the event and never re-reads a row that may not be
/// final yet. A second terminal write for the same run publishes nothing.
///
/// Only top-level runs settle: a subagent's child row (one with a parent run)
/// ends inside its parent's run and publishes no event of its own.
class AgentRunSettled implements DomainEvent {
  /// Creates an [AgentRunSettled] event.
  const AgentRunSettled({
    required this.agentId,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.runId,
    required this.status,
    required this.endReason,
    required this.costMicros,
    required this.limitResetsAt,
    required this.wakeIds,
    required this.requestedByUserId,
    required this.wakeReason,
    required this.occurredAt,
  });

  /// Agent whose run ended.
  final String agentId;

  /// Workspace the run belongs to.
  final String workspaceId;

  /// Space the run worked in, if any.
  final String? spaceId;

  /// Conversation the run answered, if any.
  final String? conversationId;

  /// The run-log id.
  final String runId;

  /// The terminal status just written ([RunStatus.completed] or
  /// [RunStatus.error]).
  final RunStatus status;

  /// Why the run ended, as written in the same terminal write.
  final RunEndReason endReason;

  /// The run's final cost in micro-dollars, its subagents' included, read
  /// from the row just written.
  final int costMicros;

  /// When the provider said the limit resets, for a run that ended on a usage
  /// limit on its last account and whose provider reported a time.
  final DateTime? limitResetsAt;

  /// The wakes this run delivered, in delivery order.
  final List<String> wakeIds;

  /// The person who started the run; null for a run the server started.
  final String? requestedByUserId;

  /// Why the run was started (its dispatch-time `WakeContext.wakeReason`,
  /// read from the run row): `userMessage` for a person's own message. Null
  /// for a run started without one (a subagent).
  final WakeReason? wakeReason;

  @override
  final DateTime occurredAt;
}

/// A goal reached an outcome a person should hear about: it completed,
/// failed, was cancelled, exhausted its budget, or paused needing a person.
class GoalSettled implements DomainEvent {
  /// Creates a [GoalSettled] event.
  const GoalSettled({
    required this.goalId,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.status,
    required this.hold,
    required this.summary,
    required this.requestedByUserId,
    required this.occurredAt,
  });

  /// The goal.
  final String goalId;

  /// Workspace the goal belongs to.
  final String workspaceId;

  /// Space the goal runs in.
  final String spaceId;

  /// Conversation the goal runs in.
  final String conversationId;

  /// Agent pursuing the goal.
  final String agentId;

  /// The goal's status after the change: a terminal status, or
  /// [AgentGoalStatus.paused] for a pause that needs a person.
  final AgentGoalStatus status;

  /// Why a paused goal is held; null for a terminal status.
  final GoalHold? hold;

  /// The closing summary or the reason, when there is one.
  final String? summary;

  /// The person who started the goal; null when the server started it.
  final String? requestedByUserId;

  @override
  final DateTime occurredAt;
}

/// A wake rule (a schedule, loop or watch) ended for good: it fired its
/// one-off, ran out of runs, budget or time, its goal ended, its person left
/// the workspace, or someone deleted it. Its pending wake is already
/// cancelled when this is published.
class WakeRuleEnded implements DomainEvent {
  /// Creates a [WakeRuleEnded] event.
  const WakeRuleEnded({
    required this.ruleId,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.reason,
    required this.requestedByUserId,
    required this.occurredAt,
  });

  /// The rule.
  final String ruleId;

  /// Workspace the rule belongs to.
  final String workspaceId;

  /// The conversation's space.
  final String spaceId;

  /// Conversation the rule wakes.
  final String conversationId;

  /// Agent the rule wakes.
  final String agentId;

  /// Why it ended.
  final WakeRuleEndReason reason;

  /// The person the rule acted for; null for a bot's rule.
  final String? requestedByUserId;

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
    this.runId,
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

  /// The waiting run (run-log id), when known.
  final String? runId;

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

/// Policy refused an action an agent tried to take (PRD 24 §3/§5).
///
/// Deliberately NOT an [AgentAwaitingInput]: nothing is waiting on a human and
/// there is nothing to approve — the guard resolved the action to `deny`
/// without ever asking, so the run replans instead of parking. It is published
/// only for a refusal the human was never shown (a `deny` with `prompted`
/// false), which is exactly why answering an approval never produces one: that
/// action's prompt already announced it, and the answer ended that wait.
///
/// A rule doing its job silently is still a thing the operator has to be able
/// to find out about without reading the audit trail — "why did my agent
/// stop?" is the question the bell answers.
class AgentActionBlocked implements DomainEvent {
  /// Creates an [AgentActionBlocked].
  const AgentActionBlocked({
    required this.workspaceId,
    required this.reason,
    required this.occurredAt,
    this.spaceId,
    this.agentId,
    this.agentName,
    this.actionSummary = '',
    this.source,
  });

  /// Workspace the blocked action belonged to.
  final String workspaceId;

  /// The terminal reason the guard refused with, kept verbatim: the
  /// notification says what the rule says, not a paraphrase of it.
  final String reason;

  /// The space the agent was working in, when known — where the operator goes
  /// to change the work, or the rule.
  final String? spaceId;

  /// The agent that was refused, when known.
  final String? agentId;

  /// The refused agent's display name, when known.
  final String? agentName;

  /// A short description of the refused action (tool/op name + effect
  /// classes), when the guard had one. Empty when it did not.
  final String actionSummary;

  /// Provenance of the denying decision (space/agent/workspace/preset), when
  /// the guard resolved one.
  final String? source;

  @override
  final DateTime occurredAt;
}
