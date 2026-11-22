import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_progress_marks.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';

/// A durable, supervised objective (`/goal`) that one agent pursues in one
/// conversation across as many runs (segments) as it takes, inside a budget,
/// until verification passes or a person stops it.
///
/// Unlike the in-session chain (which bridges a single run's turn ceiling),
/// the state here lives in SQLite, so the objective survives server restarts:
/// the startup reconciler re-dispatches any goal still [AgentGoalStatus.active].
///
/// Every goal belongs to exactly one workspace and one conversation, and at
/// most one goal per agent is active at a time (enforced by a partial unique
/// index; a second one is refused with `GoalAlreadyActiveException`), which
/// lets the `complete_goal` tool resolve "my goal" without an id.
///
/// [status] says whether the goal is alive; [hold] says what an active or
/// paused goal is waiting on.
class AgentGoalRun {
  /// Creates an [AgentGoalRun].
  AgentGoalRun({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.userText,
    required this.costCapMicros,
    DateTime? deadlineAt,
    this.maxRuns,
    this.status = AgentGoalStatus.active,
    this.costMicros = 0,
    this.runCount = 0,
    this.activeRunId,
    this.consecutiveFailures = 0,
    this.requestedByUserId,
    this.summary,
    this.contract,
    this.hold,
    DateTime? holdUntil,
    this.holdDetail,
    this.noProgressStreak = 0,
    this.verificationRounds = 0,
    this.lastFingerprint,
    this.lastActivityDigest,
    this.startRefs,
    this.parkCount = 0,
    this.fresh = false,
    this.unattended = GoalUnattendedPolicy.wait,
    this.checkerAgentId,
    this.verification,
    this.pipeline,
    this.progressMarks,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : deadlineAt = storedInstant(deadlineAt),
       holdUntil = storedInstant(holdUntil),
       createdAt = storedInstant(createdAt)!,
       updatedAt = storedInstant(updatedAt)! {
    if (id.isEmpty) {
      throw ArgumentError('Goal id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (userText.isEmpty) {
      throw ArgumentError('Goal text must not be empty');
    }
    if (costCapMicros <= 0) {
      throw ArgumentError('costCapMicros must be positive');
    }
    final runs = maxRuns;
    if (runs != null && runs <= 0) {
      throw ArgumentError('maxRuns must be positive');
    }
    if (costMicros < 0) {
      throw ArgumentError('costMicros must not be negative');
    }
    if (runCount < 0) {
      throw ArgumentError('runCount must not be negative');
    }
    if (consecutiveFailures < 0) {
      throw ArgumentError('consecutiveFailures must not be negative');
    }
    if (noProgressStreak < 0) {
      throw ArgumentError('noProgressStreak must not be negative');
    }
    if (verificationRounds < 0) {
      throw ArgumentError('verificationRounds must not be negative');
    }
    if (parkCount < 0) {
      throw ArgumentError('parkCount must not be negative');
    }
    final detail = holdDetail;
    if (detail != null && detail.length > maxHoldDetailLength) {
      throw ArgumentError(
        'holdDetail must be at most $maxHoldDetailLength characters',
      );
    }
    if (checkerAgentId != null && checkerAgentId!.isEmpty) {
      throw ArgumentError('checkerAgentId must not be empty');
    }
    final digest = lastActivityDigest;
    if (digest != null &&
        (digest.isEmpty || digest.length > maxActivityDigestLength)) {
      throw ArgumentError(
        'lastActivityDigest must be 1 to $maxActivityDigestLength characters',
      );
    }
  }

  /// The longest [holdDetail], in characters.
  static const int maxHoldDetailLength = 2000;

  /// [time] as the goal's row stores it: UTC, whole seconds. Every time of a
  /// goal is normalised so, so that a goal built in memory equals the same
  /// goal read back (the store's compare-and-set compares whole goals) and
  /// nothing depends on a precision or a time zone the row does not keep.
  static DateTime? storedInstant(DateTime? time) => time == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          time.millisecondsSinceEpoch - time.millisecondsSinceEpoch % 1000,
          isUtc: true,
        );

  /// The longest [lastActivityDigest], in characters.
  static const int maxActivityDigestLength = 128;

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

  /// Lifecycle status.
  final AgentGoalStatus status;

  /// Wall-clock budget: no new run is dispatched past this instant. Null
  /// (the default) means NO deadline — the goal runs until completed,
  /// stopped, or its cost cap bites. Set via the `/goal --days N` flag.
  final DateTime? deadlineAt;

  /// Hard cost cap for the whole goal, in micro-dollars (priced models only).
  final int costCapMicros;

  /// Cost accumulated across all runs so far, in micro-dollars.
  final int costMicros;

  /// Run budget: no more than this many runs are dispatched for the goal.
  /// Null (the default) means NO iteration cap — a hard run count kills
  /// legitimate long-term goals; the cost cap is the budget that bounds the
  /// loop. Set via the `/goal --max N` flag.
  final int? maxRuns;

  /// Runs dispatched so far.
  final int runCount;

  /// Run-log id of the currently in-flight run, when known. Correlates
  /// `AgentRunSettled` events to this goal; null between runs.
  final String? activeRunId;

  /// Consecutive failed runs; reset on any successful run. Drives the
  /// give-up threshold and the re-dispatch backoff.
  final int consecutiveFailures;

  /// Human who started the goal, when known.
  final String? requestedByUserId;

  /// The agent's completion summary (set when status becomes completed).
  final String? summary;

  /// What "done" means: criteria, checks, boundaries, stop conditions. Null
  /// for a goal started without one.
  final GoalContract? contract;

  /// What the goal is waiting on; null when nothing is held (a segment is
  /// running or the next one is queued).
  final GoalHold? hold;

  /// When the hold lifts by itself (a provider limit's reset, the fallback
  /// wake), when it does.
  final DateTime? holdUntil;

  /// A short explanation of the hold (`stalled`, `sandbox_unavailable`, the
  /// limit's provider).
  final String? holdDetail;

  /// Consecutive segments without observed progress; three pause the goal.
  final int noProgressStreak;

  /// Verification rounds that failed so far; three pause the goal.
  final int verificationRounds;

  /// The worktree fingerprint after the previous segment (progress
  /// detection, and skipping checks on an unchanged worktree).
  final String? lastFingerprint;

  /// A digest of what the previous segment did (its tool calls and their
  /// results), so progress detection also sees work that leaves the worktree
  /// unchanged. Null before the first segment ends.
  final String? lastActivityDigest;

  /// The commit each checkout of the conversation was at when the goal
  /// started; null for a goal whose start was not recorded (an upgraded
  /// install's), which then has no "what changed" summary.
  final GoalStartRefs? startRefs;

  /// How many times the goal parked on a provider limit; eight send it to
  /// review.
  final int parkCount;

  /// Whether every segment starts without the conversation's history.
  final bool fresh;

  /// What happens when a segment asks a question and nobody answers.
  final GoalUnattendedPolicy unattended;

  /// The agent that reviews completion claims; null for the space's checker
  /// or, without one, the goal's own agent.
  final String? checkerAgentId;

  /// The pipeline step that started the goal (`goal.pursue`); null for a
  /// goal a person or an agent started. Never changes.
  final GoalPipelineLink? pipeline;

  /// The progress marks it has had and the wait it is in
  /// (`progress_marks`); null before its first segment ended.
  final GoalProgressMarks? progressMarks;

  /// The last verification: claim, check results, verdict, reviewer.
  final GoalVerification? verification;

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
  bool get costCapReached => costMicros >= costCapMicros;

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
    AgentGoalStatus? status,
    DateTime? deadlineAt,
    bool removeDeadlineAt = false,
    int? costCapMicros,
    int? costMicros,
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
    GoalContract? contract,
    bool removeContract = false,
    GoalHold? hold,
    bool removeHold = false,
    DateTime? holdUntil,
    bool removeHoldUntil = false,
    String? holdDetail,
    bool removeHoldDetail = false,
    int? noProgressStreak,
    int? verificationRounds,
    String? lastFingerprint,
    bool removeLastFingerprint = false,
    String? lastActivityDigest,
    bool removeLastActivityDigest = false,
    GoalStartRefs? startRefs,
    int? parkCount,
    bool? fresh,
    GoalUnattendedPolicy? unattended,
    String? checkerAgentId,
    bool removeCheckerAgentId = false,
    GoalVerification? verification,
    bool removeVerification = false,
    GoalPipelineLink? pipeline,
    GoalProgressMarks? progressMarks,
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
      status: status ?? this.status,
      deadlineAt: removeDeadlineAt ? null : (deadlineAt ?? this.deadlineAt),
      costCapMicros: costCapMicros ?? this.costCapMicros,
      costMicros: costMicros ?? this.costMicros,
      maxRuns: removeMaxRuns ? null : (maxRuns ?? this.maxRuns),
      runCount: runCount ?? this.runCount,
      activeRunId: removeActiveRunId ? null : (activeRunId ?? this.activeRunId),
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      requestedByUserId: removeRequestedByUserId
          ? null
          : (requestedByUserId ?? this.requestedByUserId),
      summary: removeSummary ? null : (summary ?? this.summary),
      contract: removeContract ? null : (contract ?? this.contract),
      hold: removeHold ? null : (hold ?? this.hold),
      holdUntil: removeHoldUntil ? null : (holdUntil ?? this.holdUntil),
      holdDetail: removeHoldDetail ? null : (holdDetail ?? this.holdDetail),
      noProgressStreak: noProgressStreak ?? this.noProgressStreak,
      verificationRounds: verificationRounds ?? this.verificationRounds,
      lastFingerprint: removeLastFingerprint
          ? null
          : (lastFingerprint ?? this.lastFingerprint),
      lastActivityDigest: removeLastActivityDigest
          ? null
          : (lastActivityDigest ?? this.lastActivityDigest),
      startRefs: startRefs ?? this.startRefs,
      parkCount: parkCount ?? this.parkCount,
      fresh: fresh ?? this.fresh,
      unattended: unattended ?? this.unattended,
      checkerAgentId: removeCheckerAgentId
          ? null
          : (checkerAgentId ?? this.checkerAgentId),
      verification: removeVerification
          ? null
          : (verification ?? this.verification),
      pipeline: pipeline ?? this.pipeline,
      progressMarks: progressMarks ?? this.progressMarks,
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
          status == other.status &&
          deadlineAt == other.deadlineAt &&
          costCapMicros == other.costCapMicros &&
          costMicros == other.costMicros &&
          maxRuns == other.maxRuns &&
          runCount == other.runCount &&
          activeRunId == other.activeRunId &&
          consecutiveFailures == other.consecutiveFailures &&
          requestedByUserId == other.requestedByUserId &&
          summary == other.summary &&
          contract == other.contract &&
          hold == other.hold &&
          holdUntil == other.holdUntil &&
          holdDetail == other.holdDetail &&
          noProgressStreak == other.noProgressStreak &&
          verificationRounds == other.verificationRounds &&
          lastFingerprint == other.lastFingerprint &&
          lastActivityDigest == other.lastActivityDigest &&
          startRefs == other.startRefs &&
          parkCount == other.parkCount &&
          fresh == other.fresh &&
          unattended == other.unattended &&
          checkerAgentId == other.checkerAgentId &&
          verification == other.verification &&
          pipeline == other.pipeline &&
          progressMarks == other.progressMarks &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    userText,
    status,
    deadlineAt,
    costCapMicros,
    costMicros,
    maxRuns,
    runCount,
    activeRunId,
    consecutiveFailures,
    requestedByUserId,
    summary,
    contract,
    hold,
    holdUntil,
    holdDetail,
    noProgressStreak,
    verificationRounds,
    lastFingerprint,
    lastActivityDigest,
    startRefs,
    parkCount,
    fresh,
    unattended,
    checkerAgentId,
    verification,
    pipeline,
    progressMarks,
    createdAt,
    updatedAt,
  ]);
}
