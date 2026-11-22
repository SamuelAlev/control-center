import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';

/// Reason an agent was woken / dispatched.
///
/// Every run the server starts carries one. A run that has a cause of its own
/// (a person's message, an assignment, a pipeline step) keeps that reason;
/// every other run is started by a wake (`agent_wakes`) and carries the
/// wake's reason.
enum WakeReason {
  /// User sent a message or mentioned the agent.
  userMessage,

  /// Ticket was assigned to the agent.
  assignment,

  /// Recovery system re-dispatched after a failure.
  recovery,

  /// Work the agent delegated (a ticket, a team member's run) settled.
  childCompleted,

  /// A wake rule's time trigger fired (at, every, cron, self-paced).
  schedule,

  /// Pipeline step triggered the dispatch.
  pipelineStep,

  /// The next segment of the agent's active goal.
  goalContinuation,

  /// The goal's verification failed and the agent is told what failed.
  goalVerification,

  /// The independent reviewer's run that checks a goal's completion claim.
  goalReview,

  /// A watched event (`on:<event>` rule) settled.
  watch,

  /// Another agent sent this agent a message.
  peerMessage,

  /// An agent this agent asked answered (or failed, or the ask expired).
  peerReply,

  /// A provider usage limit the run was parked on has reset.
  limitReset,

  /// The learning review's run after a goal passed verification.
  improvementReview,
}

/// Wire names for [WakeReason] (persisted as TEXT in `agent_wakes.reason`).
extension WakeReasonWire on WakeReason {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeReason.userMessage => 'user_message',
    WakeReason.assignment => 'assignment',
    WakeReason.recovery => 'recovery',
    WakeReason.childCompleted => 'child_completed',
    WakeReason.schedule => 'schedule',
    WakeReason.pipelineStep => 'pipeline_step',
    WakeReason.goalContinuation => 'goal_continuation',
    WakeReason.goalVerification => 'goal_verification',
    WakeReason.goalReview => 'goal_review',
    WakeReason.watch => 'watch',
    WakeReason.peerMessage => 'peer_message',
    WakeReason.peerReply => 'peer_reply',
    WakeReason.limitReset => 'limit_reset',
    WakeReason.improvementReview => 'improvement_review',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final reason in WakeReason.values) reason.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeReason? tryParse(String? raw) {
    for (final reason in WakeReason.values) {
      if (reason.wire == raw) {
        return reason;
      }
    }
    return null;
  }
}

/// Why a run exists: every run the server starts carries one (D1).
///
/// A run with a cause of its own (a person's message, an assignment, a
/// pipeline step) carries that reason and no wakes. A run the wake queue
/// starts carries the wakes it delivers ([wakes], in delivery order), the
/// per-run [nonce] their payloads are framed with, and the first wake's
/// reason. The prompt's "Why you were woken" section is rendered from the
/// wakes (`renderWakeItems`); nothing a client sends can name a reason.
///
/// The run's own identity (run id, agent, workspace) is not part of the
/// context: it is minted by the dispatch, and [toEnvironment] takes it.
class WakeContext {
  /// A context for a run with a cause of its own: no wakes, no nonce.
  /// [startedByRunId] is the run whose tool call starts this one by a direct
  /// dispatch; null from a person's operation and from a pipeline step.
  const WakeContext({
    required this.wakeReason,
    required this.startedByRunId,
    this.ticketId,
    this.spaceId,
    this.messageId,
    this.pipelineRunId,
  }) : wakes = const [],
       nonce = null;

  /// A person's message (the composer, a retry, a refine, an operation a
  /// signed-in person triggers).
  const WakeContext.userMessage()
    : this(wakeReason: WakeReason.userMessage, startedByRunId: null);

  /// The context of a run that delivers [wakes] (one agent, one
  /// conversation), framed with [nonce] (lowercase base36, at least five
  /// characters). The reason is the first wake's.
  ///
  /// Throws [ArgumentError] for no wakes, wakes aimed at different agents
  /// or conversations, or a malformed nonce.
  factory WakeContext.fromWakes(List<Wake> wakes, {required String nonce}) {
    if (wakes.isEmpty) {
      throw ArgumentError.value(wakes, 'wakes', 'must not be empty');
    }
    final first = wakes.first;
    for (final wake in wakes) {
      if (wake.agentId != first.agentId ||
          wake.conversationId != first.conversationId ||
          wake.workspaceId != first.workspaceId) {
        throw ArgumentError.value(
          wakes,
          'wakes',
          'must all target one agent in one conversation',
        );
      }
    }
    if (!RegExp(r'^[0-9a-z]{5,}$').hasMatch(nonce)) {
      throw ArgumentError.value(nonce, 'nonce', 'lowercase base36, 5 or more');
    }
    return WakeContext._wakes(
      wakeReason: first.reason,
      spaceId: first.spaceId,
      ticketId: first.detail.ticketId,
      messageId: first.detail.messageId,
      pipelineRunId: first.detail.pipelineRunId,
      wakes: List.unmodifiable(wakes),
      nonce: nonce,
    );
  }

  const WakeContext._wakes({
    required this.wakeReason,
    required this.spaceId,
    required this.ticketId,
    required this.messageId,
    required this.pipelineRunId,
    required this.wakes,
    required this.nonce,
  }) : startedByRunId = null;

  /// Ticket the agent was dispatched to handle, if any.
  final String? ticketId;

  /// Space where the trigger originated, if any.
  final String? spaceId;

  /// Why the agent was woken.
  final WakeReason wakeReason;

  /// The triggering message ID, if applicable.
  final String? messageId;

  /// Pipeline run ID, if this is a pipeline-triggered dispatch.
  final String? pipelineRunId;

  /// The run whose tool call started this run by a direct dispatch (a
  /// reviewer `dispatch_reviewers` started, a team leader an agent's
  /// `assign_ticket` routed to): the run log's `started_by_run_id`. Null for
  /// a person's operation, a pipeline step and a run that delivers wakes
  /// (a wake carries its own lineage). Not a parent link: it nests nothing,
  /// changes no cost rollup, and the run settles like any other.
  final String? startedByRunId;

  /// The wakes this run delivers, in delivery order (empty for a run with
  /// a cause of its own).
  final List<Wake> wakes;

  /// The per-run nonce the wakes' payloads are framed with; null when the
  /// context carries no wakes.
  final String? nonce;

  /// The ids of [wakes], in delivery order (the run log's `wake_ids`).
  List<String> get wakeIds => [for (final wake in wakes) wake.id];

  /// Whether the run delivers wakes (the wake queue started it).
  bool get hasWakes => wakes.isNotEmpty;

  /// The goal the delivered wakes belong to, when one does.
  String? get goalId => _firstDetail((w) => w.detail.goalId);

  /// The wake rule the delivered wakes belong to, when one does.
  String? get ruleId => _firstDetail((w) => w.detail.ruleId);

  String? _firstDetail(String? Function(Wake wake) read) {
    for (final wake in wakes) {
      final value = read(wake);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  /// Whether the run's text may act as a command (`/goal`, `/plan`,
  /// `/vibe`, `/skill:…`, magic keywords): only a person's message with a
  /// signed-in [requestedByUserId]. Every other run's text is data.
  bool allowsCommands({required String? requestedByUserId}) =>
      wakeReason == WakeReason.userMessage &&
      !hasWakes &&
      requestedByUserId != null &&
      requestedByUserId.isNotEmpty;

  /// Environment variables an agent CLI can read, for the run [runId] of
  /// [agentId] in [workspaceId]. `CC_WAKE_REASON` is the reason's wire name.
  Map<String, String> toEnvironment({
    required String runId,
    required String agentId,
    required String workspaceId,
  }) {
    return {
      'CC_TASK_ID': ticketId ?? '',
      'CC_RUN_ID': runId,
      'CC_AGENT_ID': agentId,
      'CC_WORKSPACE_ID': workspaceId,
      'CC_WAKE_REASON': wakeReason.wire,
      'CC_SPACE_ID': ?spaceId,
      'CC_MESSAGE_ID': ?messageId,
      'CC_PIPELINE_RUN_ID': ?pipelineRunId,
      if (hasWakes) 'CC_WAKE_IDS': wakeIds.join(','),
    };
  }

  @override
  /// Human-readable summary of this wake context.
  String toString() =>
      'WakeContext(reason=${wakeReason.wire}, wakes=${wakeIds.join(',')})';

  @override
  /// Structural equality based on all fields.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeContext &&
          ticketId == other.ticketId &&
          spaceId == other.spaceId &&
          wakeReason == other.wakeReason &&
          messageId == other.messageId &&
          pipelineRunId == other.pipelineRunId &&
          startedByRunId == other.startedByRunId &&
          nonce == other.nonce &&
          _sameWakes(wakes, other.wakes);

  static bool _sameWakes(List<Wake> a, List<Wake> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  /// Hash based on all fields.
  int get hashCode => Object.hash(
    ticketId,
    spaceId,
    wakeReason,
    messageId,
    pipelineRunId,
    startedByRunId,
    nonce,
    Object.hashAll(wakes),
  );
}
