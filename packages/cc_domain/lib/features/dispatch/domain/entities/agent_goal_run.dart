import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';

/// Which slash command spawned a durable goal ([AgentGoalRun]).
enum AgentGoalKind {
  /// `/goal` — pursue one objective until declared complete.
  goal,

  /// `/loop` — iterate on a task, refining until fully complete.
  loop,
}

/// Wire names for [AgentGoalKind] (persisted as TEXT).
extension AgentGoalKindWire on AgentGoalKind {
  /// Persisted wire name.
  String get wire => switch (this) {
    AgentGoalKind.goal => 'goal',
    AgentGoalKind.loop => 'loop',
  };

  /// Parses a wire name; unknown values degrade to [AgentGoalKind.goal].
  static AgentGoalKind fromWire(String? raw) =>
      raw == 'loop' ? AgentGoalKind.loop : AgentGoalKind.goal;
}

/// A durable, supervised objective: a `/goal` or `/loop` that keeps being
/// dispatched as bounded runs until the agent declares it complete, a human
/// stops it, or a budget wall (deadline, cost cap, run budget) is hit.
///
/// Unlike the in-session chain (which bridges a single run's turn ceiling),
/// the state here lives in SQLite, so the objective survives server restarts:
/// the startup reconciler re-dispatches any goal still [AgentGoalStatus.active].
///
/// Every goal belongs to exactly one workspace and one conversation and at
/// most one goal per agent is active at a time (enforced by the supervisor),
/// which lets the `complete_goal` tool resolve "my goal" without an id.
class AgentGoalRun {
  /// Creates an [AgentGoalRun].
  AgentGoalRun({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.userText,
    required this.kind,
    required this.costCapCents,
    this.deadlineAt,
    this.maxRuns,
    this.status = AgentGoalStatus.active,
    this.costCents = 0,
    this.runCount = 0,
    this.activeRunId,
    this.consecutiveFailures = 0,
    this.requestedByUserId,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('Goal id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (userText.isEmpty) {
      throw ArgumentError('Goal text must not be empty');
    }
    if (costCapCents <= 0) {
      throw ArgumentError('costCapCents must be positive');
    }
    final runs = maxRuns;
    if (runs != null && runs <= 0) {
      throw ArgumentError('maxRuns must be positive');
    }
    if (costCents < 0) {
      throw ArgumentError('costCents must not be negative');
    }
    if (runCount < 0) {
      throw ArgumentError('runCount must not be negative');
    }
    if (consecutiveFailures < 0) {
      throw ArgumentError('consecutiveFailures must not be negative');
    }
  }

  /// Unique goal identifier.
  final String id;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// Space the goal runs in (progress + control messages land here).
  final String spaceId;

  /// Conversation (stream) the runs see and post into.
  final String conversationId;

  /// Agent pursuing the goal.
  final String agentId;

  /// The objective, verbatim (the `/goal` body).
  final String userText;

  /// Which command spawned the goal.
  final AgentGoalKind kind;

  /// Lifecycle status.
  final AgentGoalStatus status;

  /// Wall-clock budget: no new run is dispatched past this instant. Null
  /// (the default) means NO deadline — the goal runs until completed,
  /// stopped, or its cost cap bites. Set via the `/goal --days N` flag.
  final DateTime? deadlineAt;

  /// Hard cost cap for the whole goal, in cents (priced models only).
  final int costCapCents;

  /// Cost accumulated across all runs so far, in cents.
  final int costCents;

  /// Run budget: no more than this many runs are dispatched for the goal.
  /// Null (the default) means NO iteration cap — a hard run count kills
  /// legitimate long-term goals; the cost cap is the budget that bounds the
  /// loop. Set via the `/goal --max N` flag.
  final int? maxRuns;

  /// Runs dispatched so far.
  final int runCount;

  /// Run-log id of the currently in-flight run, when known. Correlates
  /// `AgentRunCompleted` events to this goal; null between runs.
  final String? activeRunId;

  /// Consecutive failed runs; reset on any successful run. Drives the
  /// give-up threshold and the re-dispatch backoff.
  final int consecutiveFailures;

  /// Human who started the goal, when known.
  final String? requestedByUserId;

  /// The agent's completion summary (set when status becomes completed).
  final String? summary;

  /// When the goal was created.
  final DateTime createdAt;

  /// When the goal was last updated.
  final DateTime updatedAt;

  /// Whether the deadline has passed at [now]. No deadline → never passed.
  bool deadlinePassed(DateTime now) {
    final deadline = deadlineAt;
    return deadline != null && !now.isBefore(deadline);
  }

  /// Whether the cost cap has been reached.
  bool get costCapReached => costCents >= costCapCents;

  /// Whether the run budget has been exhausted. No cap → never exhausted.
  bool get runBudgetExhausted {
    final cap = maxRuns;
    return cap != null && runCount >= cap;
  }

  /// Returns a copy with the given fields replaced.
  AgentGoalRun copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? conversationId,
    String? agentId,
    String? userText,
    AgentGoalKind? kind,
    AgentGoalStatus? status,
    DateTime? deadlineAt,
    bool removeDeadlineAt = false,
    int? costCapCents,
    int? costCents,
    int? maxRuns,
    bool removeMaxRuns = false,
    int? runCount,
    String? activeRunId,
    bool removeActiveRunId = false,
    int? consecutiveFailures,
    String? requestedByUserId,
    bool removeRequestedByUserId = false,
    String? summary,
    bool removeSummary = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentGoalRun(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      spaceId: spaceId ?? this.spaceId,
      conversationId: conversationId ?? this.conversationId,
      agentId: agentId ?? this.agentId,
      userText: userText ?? this.userText,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      deadlineAt: removeDeadlineAt ? null : (deadlineAt ?? this.deadlineAt),
      costCapCents: costCapCents ?? this.costCapCents,
      costCents: costCents ?? this.costCents,
      maxRuns: removeMaxRuns ? null : (maxRuns ?? this.maxRuns),
      runCount: runCount ?? this.runCount,
      activeRunId: removeActiveRunId ? null : (activeRunId ?? this.activeRunId),
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      requestedByUserId: removeRequestedByUserId
          ? null
          : (requestedByUserId ?? this.requestedByUserId),
      summary: removeSummary ? null : (summary ?? this.summary),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentGoalRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          agentId == other.agentId &&
          userText == other.userText &&
          kind == other.kind &&
          status == other.status &&
          deadlineAt == other.deadlineAt &&
          costCapCents == other.costCapCents &&
          costCents == other.costCents &&
          maxRuns == other.maxRuns &&
          runCount == other.runCount &&
          activeRunId == other.activeRunId &&
          consecutiveFailures == other.consecutiveFailures &&
          requestedByUserId == other.requestedByUserId &&
          summary == other.summary &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    userText,
    kind,
    status,
    deadlineAt,
    costCapCents,
    costCents,
    maxRuns,
    runCount,
    activeRunId,
    consecutiveFailures,
    requestedByUserId,
    summary,
    createdAt,
    updatedAt,
  );
}
