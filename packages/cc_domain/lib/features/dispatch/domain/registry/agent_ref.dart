/// Runtime role of an agent in the process-global tree.
///
/// * [main] / [sub] — the user-facing agent tree (the driving agent plus any
///   task subagents). Both are addressable peers.
/// * [advisor] — a passive shadow-reviewer transcript persisted like a
///   subagent for usage attribution and observability, but never a peer:
///   hidden from agent-facing rosters and not messageable.
enum AgentKind {
  /// A top-level driving agent run.
  main,

  /// A subagent spawned by another agent.
  sub,

  /// A passive shadow reviewer — observability only, never a peer.
  advisor,
}

/// Lifecycle status of a tracked agent.
///
/// * [running] — a turn is in flight; the agent has a live dispatch.
/// * [idle] — finished a turn but still tracked, awaiting more work. Finished
///   agents become [idle], they are NOT removed.
/// * [parked] — live dispatch released; the [AgentRef] + `sessionFile` are
///   retained so the agent can be revived later.
/// * [aborted] — hard-killed; terminal.
enum AgentStatus {
  /// A turn is in flight.
  running,

  /// Live but awaiting work.
  idle,

  /// Dispatch released; revivable from `sessionFile`.
  parked,

  /// Hard-killed; terminal.
  aborted;

  /// Whether an agent in this status is "alive" — currently running or idle
  /// and available as a peer (as opposed to parked or aborted).
  bool get isAlive => this == AgentStatus.running || this == AgentStatus.idle;
}

/// An immutable snapshot of one agent in the process-global `AgentRegistry`.
///
/// Tracks the main session plus every subagent, keyed by stable id, so peers
/// can be addressed by id and the work-aware roster can render who is alive
/// and what they are doing right now.
///
/// Every ref carries a non-empty `workspaceId`: the registry is process-global
/// and spans every open workspace, so workspace is the isolation boundary for
/// every roster / peer query (see `AgentRegistry.listVisibleTo`).
class AgentRef {
  /// Creates an [AgentRef].
  AgentRef({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.lastActivity,
    this.parentId,
    this.conversationId,
    this.dispatchId,
    this.sessionFile,
    this.activity,
  })  : assert(id.isNotEmpty, 'AgentRef.id must not be empty'),
        assert(
          displayName.isNotEmpty,
          'AgentRef.displayName must not be empty',
        ),
        assert(
          workspaceId.isNotEmpty,
          'AgentRef.workspaceId must not be empty — workspace is the '
          'isolation boundary and is never optional',
        );

  /// Stable agent id (the `Agent.id` of a tracked agent).
  final String id;

  /// One-line, length-capped display label for the roster.
  final String displayName;

  /// Runtime role (main / sub / advisor).
  final AgentKind kind;

  /// Owning workspace — the isolation boundary. Never empty.
  final String workspaceId;

  /// Current lifecycle status.
  final AgentStatus status;

  /// When the agent was first registered.
  final DateTime createdAt;

  /// When the agent last did observable work (status change or heartbeat).
  final DateTime lastActivity;

  /// Id of the agent that spawned this one, if any.
  final String? parentId;

  /// Conversation / channel this agent is currently working in, if any.
  final String? conversationId;

  /// Id of the live dispatch backing a running agent. Null exactly when the
  /// agent is idle / parked / aborted.
  final String? dispatchId;

  /// Path to the persisted session, retained while parked so the agent can be
  /// cold-revived. Reserved for the lifecycle manager (later phase).
  final String? sessionFile;

  /// Short gist of what the agent is doing right now (latest tool or intent),
  /// for the work-aware roster. Display-only; meaningful only while running.
  final String? activity;

  /// Whether this agent is alive (running or idle).
  bool get isAlive => status.isAlive;

  /// Returns a copy with the given fields replaced. Pass the `clear*` flags to
  /// null out the nullable fields (a plain `null` argument means "unchanged").
  AgentRef copyWith({
    String? displayName,
    AgentKind? kind,
    AgentStatus? status,
    DateTime? createdAt,
    DateTime? lastActivity,
    String? parentId,
    String? conversationId,
    String? dispatchId,
    bool clearDispatchId = false,
    String? sessionFile,
    bool clearSessionFile = false,
    String? activity,
    bool clearActivity = false,
  }) {
    return AgentRef(
      id: id,
      workspaceId: workspaceId,
      displayName: displayName ?? this.displayName,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      parentId: parentId ?? this.parentId,
      conversationId: conversationId ?? this.conversationId,
      dispatchId: clearDispatchId ? null : (dispatchId ?? this.dispatchId),
      sessionFile: clearSessionFile ? null : (sessionFile ?? this.sessionFile),
      activity: clearActivity ? null : (activity ?? this.activity),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentRef &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          kind == other.kind &&
          workspaceId == other.workspaceId &&
          status == other.status &&
          createdAt == other.createdAt &&
          lastActivity == other.lastActivity &&
          parentId == other.parentId &&
          conversationId == other.conversationId &&
          dispatchId == other.dispatchId &&
          sessionFile == other.sessionFile &&
          activity == other.activity;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        kind,
        workspaceId,
        status,
        createdAt,
        lastActivity,
        parentId,
        conversationId,
        dispatchId,
        sessionFile,
        activity,
      );

  @override
  String toString() =>
      'AgentRef($id, $displayName, $kind, ws=$workspaceId, $status'
      '${activity == null ? '' : ', "$activity"'})';
}
