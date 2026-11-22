import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// Posts a system message into the goal's conversation. Wired by the runtime
/// to `MessagingService.postSystemMessage` (sender and type `system`).
typedef GoalSystemMessageSender =
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
      required String content,
      String? conversationId,
    });

/// The commit each checkout of a conversation is at now (`GoalChanges`);
/// null when it has none or one could not be read.
typedef GoalStartRefsReader =
    Future<GoalStartRefs?> Function(String workspaceId, String conversationId);

/// The wake reasons whose wakes run a goal's own segment (a `limitReset`
/// wake of a goal resumes the segment its provider's usage limit parked,
/// unless it is the review's: [isGoalReviewWake]).
const Set<WakeReason> goalSegmentReasons = {
  WakeReason.goalContinuation,
  WakeReason.goalVerification,
  WakeReason.limitReset,
};

/// Whether [wake] asks for the review of a goal's claim: its `goalReview`
/// wake, or the `limitReset` wake ([WakeFields.review]) that asks for it
/// again after the reviewer's usage limit reset.
bool isGoalReviewWake(Wake wake) =>
    wake.detail.goalId != null &&
    (wake.reason == WakeReason.goalReview ||
        (wake.reason == WakeReason.limitReset &&
            wake.detail.fields[WakeFields.review] == true));

/// Whether [wake] starts a segment of its goal.
bool isGoalSegmentWake(Wake wake) =>
    wake.detail.goalId != null &&
    goalSegmentReasons.contains(wake.reason) &&
    !isGoalReviewWake(wake);

/// What the goal supervisor and the verifier share: the goal's writes (a
/// compare-and-set on the whole row, retried on a fresh read), its wakes
/// (with the dedup key reissued once a wake with it settled), the messages
/// in its conversation and its [GoalSettled] announcements.
class GoalStore {
  /// Creates the store.
  GoalStore({
    required this.goals,
    required this.wakes,
    required WakeQueueService Function() wakeQueue,
    required this._say,
    required this._eventBus,
    required this._now,
    required this._startRefs,
    String Function()? newId,
  }) : _queue = wakeQueue,
       _newId = newId ?? const Uuid().v4;

  /// The goal rows.
  final AgentGoalRunRepository goals;

  /// The wake rows (dedup lookups, a goal's open wakes).
  final WakeRepository wakes;

  final WakeQueueService Function() _queue;
  final GoalSystemMessageSender _say;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;
  final GoalStartRefsReader _startRefs;
  final String Function() _newId;

  /// How often a transition re-reads and retries after losing its write.
  static const int transitionAttempts = 5;

  /// How many times a settled dedup key is reissued with a suffix before
  /// the store gives up on the wake.
  static const int maxReissues = 50;

  /// The clock.
  DateTime now() => _now();

  /// A new goal id.
  String newGoalId() => _newId();

  /// Where each checkout of [goal]'s conversation starts from; null when
  /// that could not be read (the goal then has no "what changed" summary).
  Future<GoalStartRefs?> startRefsOf(AgentGoalRun goal) async {
    try {
      return await _startRefs(goal.workspaceId, goal.conversationId);
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: start refs not read: $e');
      return null;
    }
  }

  /// The wake queue.
  WakeQueueService get queue => _queue();

  /// Called after [transition] moved a goal out of `active` (paused or
  /// ended): the steering queue holds the cards its review kept queued for
  /// a next segment that will not come by itself. Late-bound by the server.
  Future<void> Function(AgentGoalRun goal)? onLeftActive;

  /// Moves [goal] to what [next] makes of the stored goal, with a write that
  /// lands only on the exact row [next] saw
  /// ([AgentGoalRunRepository.replaceIf]). A write that lost re-reads the
  /// goal and asks [next] again; [next] returns null when the move no longer
  /// applies. Returns the goal as written, or null when nothing was written.
  Future<AgentGoalRun?> transition(
    AgentGoalRun goal,
    FutureOr<AgentGoalRun?> Function(AgentGoalRun current) next,
  ) async {
    AgentGoalRun? current = goal;
    for (var attempt = 0; attempt < transitionAttempts; attempt++) {
      if (current == null) {
        return null;
      }
      final moved = await next(current);
      if (moved == null) {
        return null;
      }
      if (await goals.replaceIf(moved, expected: current)) {
        final left = onLeftActive;
        if (left != null &&
            current.status == AgentGoalStatus.active &&
            moved.status != AgentGoalStatus.active) {
          try {
            await left(moved);
          } on Object catch (e) {
            CcInfraLog.warning('GoalStore: kept cards not held: $e');
          }
        }
        return moved;
      }
      current = await goals.getById(goal.workspaceId, goal.id);
    }
    return null;
  }

  /// Posts [content] into [goal]'s conversation. A failure is logged: the
  /// goal's state is already written.
  Future<void> say(AgentGoalRun goal, String content) => sayIn(
    workspaceId: goal.workspaceId,
    spaceId: goal.spaceId,
    conversationId: goal.conversationId,
    content: content,
  );

  /// Posts [content] into [conversationId] (a goal not stored yet).
  Future<void> sayIn({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  }) async {
    try {
      await _say(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        content: content,
      );
    } on Object catch (e) {
      CcInfraLog.warning('goal system message failed: $e');
    }
  }

  /// Announces [goal]'s outcome: a terminal status, or a pause whose hold
  /// needs a person ([GoalHold.person], [GoalHold.needsReview]). A pause a
  /// person made themselves ([GoalHold.byPerson]) announces nothing.
  void publishSettled(AgentGoalRun goal, {String? summary}) {
    final hold = goal.status.isTerminal ? null : goal.hold;
    if (!goal.status.isTerminal &&
        hold != GoalHold.person &&
        hold != GoalHold.needsReview) {
      return;
    }
    _eventBus?.publish(
      GoalSettled(
        goalId: goal.id,
        workspaceId: goal.workspaceId,
        spaceId: goal.spaceId,
        conversationId: goal.conversationId,
        agentId: goal.agentId,
        status: goal.status,
        hold: hold,
        summary: summary,
        requestedByUserId: goal.requestedByUserId,
        occurredAt: _now(),
      ),
    );
  }

  /// Inserts the wake that starts [goal]'s next segment, due at
  /// [notBefore] (now when null): a `goalContinuation`, or a
  /// `goalVerification` when [verificationRound] is given (the worker's
  /// segment after a failed verification). Dedup key `goal:<id>:<runCount>`
  /// (`goal:<id>:verify:<round>` for a verification). [deliver]: delivered
  /// at once, with no quiet window ([WakeQueueService.enqueueAndDeliver]).
  /// [quiet]: the run leaves no "Woke …" row (the first segment).
  ///
  /// Returns the wake inserted, or null when an open wake with its key
  /// already exists (or the workspace is gone).
  Future<Wake?> insertSegmentWake(
    AgentGoalRun goal, {
    DateTime? notBefore,
    int? verificationRound,
    bool deliver = false,
    bool quiet = false,
  }) {
    final segment = goal.runCount + 1;
    final reason = verificationRound == null
        ? WakeReason.goalContinuation
        : WakeReason.goalVerification;
    final baseKey = verificationRound == null
        ? 'goal:${goal.id}:${goal.runCount}'
        : 'goal:${goal.id}:verify:$verificationRound';
    final at = notBefore ?? _now();
    return _insert(
      goal.workspaceId,
      baseKey,
      deliver: deliver,
      build: (key) => Wake(
        id: _newId(),
        workspaceId: goal.workspaceId,
        spaceId: goal.spaceId,
        conversationId: goal.conversationId,
        agentId: goal.agentId,
        reason: reason,
        payload: verificationRound == null
            ? ''
            : 'Your completion claim did not pass verification.',
        detail: WakeDetail(
          goalId: goal.id,
          fields: {
            WakeFields.segment: segment,
            if (verificationRound != null) ...{
              WakeFields.round: verificationRound,
              WakeFields.maxRounds: goalMaxVerificationRounds,
            },
            if (quiet) WakeFields.quietDelivery: true,
          },
        ),
        runOptions: WakeRunOptions(
          costCapMicros: goalSegmentCapMicros(goal),
          freshHistory: goal.fresh,
        ),
        dedupKey: key,
        notBefore: at,
        requestedByUserId: goal.requestedByUserId,
        createdAt: _now(),
      ),
    );
  }

  /// Inserts the `limitReset` wake that resumes [goal] after the provider's
  /// usage limit parked its segment [runId]: due at [reset] plus
  /// [LimitPark.resetSlack], dedup key `limit:<runId>`, run like a segment
  /// (its cap, fresh when the goal is), for the goal's requester. Its detail
  /// carries `goalId`, `sourceRunId` and [LimitPark.wakeFields].
  ///
  /// Returns the wake (or the open one already written for [runId]), or
  /// null when nothing could be written.
  Future<Wake?> insertLimitWake(
    AgentGoalRun goal, {
    required String runId,
    required DateTime reset,
    required String provider,
  }) async {
    final baseKey = LimitPark.dedupKey(runId);
    final inserted = await _insert(
      goal.workspaceId,
      baseKey,
      deliver: false,
      build: (key) => Wake(
        id: _newId(),
        workspaceId: goal.workspaceId,
        spaceId: goal.spaceId,
        conversationId: goal.conversationId,
        agentId: goal.agentId,
        reason: WakeReason.limitReset,
        payload: '',
        detail: WakeDetail(
          goalId: goal.id,
          sourceRunId: runId,
          fields: {
            WakeFields.segment: goal.runCount + 1,
            ...LimitPark.wakeFields(provider: provider, reset: reset),
          },
        ),
        runOptions: WakeRunOptions(
          costCapMicros: goalSegmentCapMicros(goal),
          freshHistory: goal.fresh,
        ),
        dedupKey: key,
        notBefore: LimitPark.resumeAt(reset),
        requestedByUserId: goal.requestedByUserId,
        createdAt: _now(),
      ),
    );
    if (inserted != null) {
      return inserted;
    }
    final open = await wakes.getByDedupKey(goal.workspaceId, baseKey);
    return open != null && _open(open.state) && open.detail.goalId == goal.id
        ? open
        : null;
  }

  /// A new wake id (the verifier records a review wake's id before the
  /// wake is written).
  String newWakeId() => _newId();

  /// Inserts the `goalReview` wake [wakeId] of [goal]'s verification round
  /// [round] for [reviewerAgentId] in the goal's conversation: a fresh,
  /// read-only run capped at [goalReviewCapMicros] that answers with
  /// [outputSchema]. Dedup key `goal:<id>:review:<round>` (reissued once a
  /// wake with it settled). Null when it could not be written.
  Future<Wake?> insertReviewWake(
    AgentGoalRun goal, {
    required String wakeId,
    required int round,
    required String reviewerAgentId,
    required String? goalAgentName,
    required Map<String, Object?> outputSchema,
  }) => _insert(
    goal.workspaceId,
    'goal:${goal.id}:review:$round',
    deliver: false,
    build: (key) => _reviewWake(
      goal,
      id: wakeId,
      reason: WakeReason.goalReview,
      dedupKey: key,
      notBefore: _now(),
      round: round,
      reviewerAgentId: reviewerAgentId,
      goalAgentName: goalAgentName,
      outputSchema: outputSchema,
    ),
  );

  /// Inserts the `limitReset` wake that asks for the review of [goal]'s
  /// claim again after the reviewer's run [runId] reached its provider's
  /// usage limit: the review wake's run (fresh, read-only, capped, the
  /// reviewer's) due at [reset] plus [LimitPark.resetSlack], dedup key
  /// `limit:<runId>`, marked [WakeFields.review] with the round. Returns the
  /// wake (or the open one already written for [runId]), or null.
  Future<Wake?> insertReviewLimitWake(
    AgentGoalRun goal, {
    required String runId,
    required DateTime reset,
    required String provider,
    required int round,
    required String reviewerAgentId,
    required String? goalAgentName,
    required Map<String, Object?> outputSchema,
  }) async {
    final baseKey = LimitPark.dedupKey(runId);
    final inserted = await _insert(
      goal.workspaceId,
      baseKey,
      deliver: false,
      build: (key) => _reviewWake(
        goal,
        id: _newId(),
        reason: WakeReason.limitReset,
        dedupKey: key,
        notBefore: LimitPark.resumeAt(reset),
        round: round,
        reviewerAgentId: reviewerAgentId,
        goalAgentName: goalAgentName,
        outputSchema: outputSchema,
        sourceRunId: runId,
        extra: {
          WakeFields.review: true,
          ...LimitPark.wakeFields(provider: provider, reset: reset),
        },
      ),
    );
    if (inserted != null) {
      return inserted;
    }
    final open = await wakes.getByDedupKey(goal.workspaceId, baseKey);
    return open != null && _open(open.state) && isGoalReviewWake(open)
        ? open
        : null;
  }

  Wake _reviewWake(
    AgentGoalRun goal, {
    required String id,
    required WakeReason reason,
    required String dedupKey,
    required DateTime notBefore,
    required int round,
    required String reviewerAgentId,
    required String? goalAgentName,
    required Map<String, Object?> outputSchema,
    String? sourceRunId,
    Map<String, Object?> extra = const {},
  }) => Wake(
    id: id,
    workspaceId: goal.workspaceId,
    spaceId: goal.spaceId,
    conversationId: goal.conversationId,
    agentId: reviewerAgentId,
    reason: reason,
    payload:
        'A goal in this conversation is claimed complete; the goal review '
        'section has the claim and the checks.',
    detail: WakeDetail(
      goalId: goal.id,
      sourceAgentId: goal.agentId,
      sourceConversationId: goal.conversationId,
      sourceRunId: sourceRunId,
      fields: {
        WakeFields.round: round,
        WakeFields.maxRounds: goalMaxVerificationRounds,
        WakeFields.goalAgentName: ?goalAgentName,
        ...extra,
      },
    ),
    runOptions: WakeRunOptions(
      costCapMicros: goalReviewCapMicros(goal),
      freshHistory: true,
      readOnly: true,
      outputSchema: outputSchema,
    ),
    dedupKey: dedupKey,
    notBefore: notBefore,
    requestedByUserId: goal.requestedByUserId,
    createdAt: _now(),
  );

  /// Cancels every pending or held wake of [goal] with [reason]. Returns how
  /// many.
  Future<int> cancelWakes(AgentGoalRun goal, String reason) async {
    try {
      return await queue.cancelWhere(
        goal.workspaceId,
        goalId: goal.id,
        reason: reason,
      );
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: cancelling its wakes failed: $e');
      return 0;
    }
  }

  /// [goal]'s wakes that will still be delivered (pending or claimed). A
  /// held wake is not: nothing delivers it until a person releases it, and
  /// a goal's wakes are the goal's to govern.
  Future<List<Wake>> openWakes(AgentGoalRun goal) async => [
    for (final wake in await wakes.listForConversation(
      goal.workspaceId,
      goal.conversationId,
      states: const {WakeState.pending, WakeState.claimed},
    ))
      if (wake.detail.goalId == goal.id) wake,
  ];

  /// Inserts the wake [build] makes for [baseKey], or for `<baseKey>:r<n>`
  /// when a wake with the key already settled (a cancelled fallback, a
  /// skipped wake) or is held: a dedup key stays taken after its wake
  /// settles. Null when a wake with the key is still pending or claimed, or
  /// nothing could be inserted.
  Future<Wake?> _insert(
    String workspaceId,
    String baseKey, {
    required bool deliver,
    required Wake Function(String dedupKey) build,
  }) async {
    for (var attempt = 0; attempt <= maxReissues; attempt++) {
      final key = attempt == 0 ? baseKey : '$baseKey:r$attempt';
      final wake = build(key);
      try {
        if (deliver) {
          final receipt = await queue.enqueueAndDeliver(wake);
          if (receipt is! WakeDuplicate) {
            return wake;
          }
        } else if (await queue.enqueue(wake)) {
          return wake;
        }
      } on WorkspaceMismatchException catch (e) {
        CcInfraLog.warning('goal wake $baseKey not inserted: $e');
        return null;
      }
      final existing = await wakes.getByDedupKey(workspaceId, key);
      if (existing != null && _open(existing.state)) {
        return null;
      }
    }
    CcInfraLog.warning('goal wake $baseKey: every reissue key is taken');
    return null;
  }

  static bool _open(WakeState state) =>
      state == WakeState.pending || state == WakeState.claimed;
}
