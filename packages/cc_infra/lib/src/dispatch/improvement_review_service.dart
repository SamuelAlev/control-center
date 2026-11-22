import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ImprovementRefusedException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/improvement_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// The wake detail field naming the goal an improvement review follows.
/// Not `WakeDetail.goalId`: that would make the goal supervisor treat the
/// review as the (finished) goal's own wake.
const String kImprovementGoalField = 'improvementGoalId';

/// What an attempt to enqueue an improvement review came to.
enum ImprovementReviewEnqueue {
  /// The review wake was written.
  queued,

  /// The agent is not an agent of the workspace.
  agentNotFound,

  /// The conversation had a review less than the cooldown ago.
  cooldown,

  /// A review wake with the same dedup key is already waiting.
  duplicate,
}

/// The cap of one improvement review run, in micro-dollars (1 USD), charged
/// to the agent.
const int improvementReviewCapMicros = 1000000;

/// The least time between two reviews in one conversation.
const Duration improvementReviewCooldown = Duration(minutes: 20);

/// Resolves a repository a proposal names (an id, a name or an
/// `owner/name`) among the repositories of [spaceId]'s checkout; null when
/// none matches.
typedef ImprovementRepositoryResolver =
    Future<String?> Function(
      String workspaceId,
      String spaceId,
      String reference,
    );

/// Whether the workspace skill [slug] exists.
typedef ImprovementSkillExists =
    Future<bool> Function(String workspaceId, String slug);

/// Learning from finished work (plan section 13): one read-only, fresh
/// review run after a verified goal or a person's `/refine`, whose
/// `submit_output` becomes at most three [ImprovementProposal] rows for a
/// person to accept or reject.
///
/// - [onGoalSettled]: a goal that completed with a passing verdict and was
///   not closed by a person gets one review (dedup key
///   `improve:goal:<goalId>`), unless its conversation had one within
///   [improvementReviewCooldown] or its agent is not a workspace agent (an
///   ephemeral subagent owns no goal).
/// - [refine]: a person's `/refine`, with the conversation's latest
///   verified goal when there is one.
/// - [onRunSettled]: the review run's answer, read from its run log once it
///   settles `completed`; a `serverStopped` settlement is ignored.
class ImprovementReviewService {
  /// Creates the service.
  ImprovementReviewService({
    required this._wakeQueue,
    required this._wakes,
    required this._goals,
    required this._agents,
    required this._runLogs,
    required this._proposals,
    required this._messages,
    required this._conversations,
    required this._facts,
    required this._policies,
    required this._resolveRepository,
    required this._skillExists,
    required this._eventBus,
    required this._now,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final WakeQueueService Function() _wakeQueue;
  final WakeRepository _wakes;
  final AgentGoalRunRepository _goals;
  final AgentRepository _agents;
  final AgentRunLogRepository _runLogs;
  final ImprovementProposalRepository _proposals;
  final MessagingRepository _messages;
  final ConversationRepository _conversations;
  final MemoryFactRepository _facts;
  final MemoryPolicyRepository _policies;
  final ImprovementRepositoryResolver _resolveRepository;
  final ImprovementSkillExists _skillExists;
  final DomainEventBus _eventBus;
  final DateTime Function() _now;
  final String Function() _newId;

  /// When each conversation's last review was enqueued (`ws\0conv`): a
  /// review that proposed nothing leaves no row for the cooldown to read.
  final Map<String, DateTime> _lastReview = {};
  final List<StreamSubscription<Object?>> _subs = [];

  /// Listens for goal and run settlements. Idempotent.
  void start() {
    if (_subs.isNotEmpty) {
      return;
    }
    _subs
      ..add(
        _eventBus.on<GoalSettled>().listen((e) => _safely(onGoalSettled(e))),
      )
      ..add(
        _eventBus.on<AgentRunSettled>().listen((e) => _safely(onRunSettled(e))),
      );
  }

  /// Stops listening.
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  void _safely(Future<void> work) => unawaited(
    work.catchError((Object e, StackTrace st) {
      CcInfraLog.warning('improvement review: $e\n$st');
    }),
  );

  /// Enqueues the review of [event]'s goal when it completed verified.
  /// Returns whether a review wake was written.
  Future<bool> onGoalSettled(GoalSettled event) async {
    if (event.status != AgentGoalStatus.completed) {
      return false;
    }
    final goal = await _goals.getById(event.workspaceId, event.goalId);
    if (goal == null || !isVerifiedGoal(goal)) {
      return false;
    }
    if ((await _proposals.listByGoal(goal.workspaceId, goal.id)).isNotEmpty) {
      return false;
    }
    return await _enqueue(
          workspaceId: goal.workspaceId,
          spaceId: goal.spaceId,
          conversationId: goal.conversationId,
          agentId: goal.agentId,
          goal: goal,
          requestedByUserId: goal.requestedByUserId,
          dedupKey: 'improve:goal:${goal.id}',
        ) ==
        ImprovementReviewEnqueue.queued;
  }

  /// A person's `/refine` in [conversationId]: a review of the
  /// conversation's work for [agentId], following its latest verified goal
  /// when it has one. Throws [ImprovementRefusedException] with the kind of
  /// what stopped it: `improvement_review_cooldown` (a review less than
  /// [improvementReviewCooldown] ago), `improvement_review_queued` (one is
  /// already waiting) or `improvement_agent_not_found` (not an agent of the
  /// workspace).
  Future<void> refine({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String requestedByUserId,
  }) async {
    final goal = await _latestVerifiedGoal(
      workspaceId,
      conversationId,
      agentId,
    );
    final queued = await _enqueue(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: agentId,
      goal: goal,
      requestedByUserId: requestedByUserId,
      dedupKey:
          'improve:refine:$conversationId:'
          '${_now().millisecondsSinceEpoch ~/ improvementReviewCooldown.inMilliseconds}',
    );
    switch (queued) {
      case ImprovementReviewEnqueue.queued:
        return;
      case ImprovementReviewEnqueue.cooldown:
        throw ImprovementRefusedException(
          'An improvement review ran in this conversation less than '
          '${improvementReviewCooldown.inMinutes} minutes ago; try again '
          'later.',
          kind: ImprovementRefusedException.cooldownKind,
        );
      case ImprovementReviewEnqueue.duplicate:
        throw const ImprovementRefusedException(
          'An improvement review of this conversation is already waiting to '
          'run.',
          kind: ImprovementRefusedException.reviewQueuedKind,
        );
      case ImprovementReviewEnqueue.agentNotFound:
        throw const ImprovementRefusedException(
          'That agent is not an agent of this workspace.',
          kind: ImprovementRefusedException.agentNotFoundKind,
        );
    }
  }

  /// A goal that completed with the reviewer's `pass` and was not closed by
  /// a person.
  static bool isVerifiedGoal(AgentGoalRun goal) {
    final v = goal.verification;
    return goal.status == AgentGoalStatus.completed &&
        v != null &&
        v.verdict?.verdict == GoalVerdictOutcome.pass &&
        v.approvedByUserId == null;
  }

  Future<AgentGoalRun?> _latestVerifiedGoal(
    String workspaceId,
    String conversationId,
    String agentId,
  ) async {
    final verified =
        (await _goals.listByWorkspace(workspaceId))
            .where(
              (g) =>
                  g.conversationId == conversationId &&
                  g.agentId == agentId &&
                  isVerifiedGoal(g),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return verified.firstOrNull;
  }

  Future<ImprovementReviewEnqueue> _enqueue({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required AgentGoalRun? goal,
    required String? requestedByUserId,
    required String dedupKey,
  }) async {
    final agent = await _agents.getById(workspaceId, agentId);
    if (agent == null || agent.workspaceId != workspaceId) {
      return ImprovementReviewEnqueue.agentNotFound;
    }
    final now = _now();
    final key = '$workspaceId\u0000$conversationId';
    final last = await _proposals.latestForConversation(
      workspaceId,
      conversationId,
    );
    for (final at in [_lastReview[key], last?.createdAt]) {
      if (at != null && now.difference(at) < improvementReviewCooldown) {
        return ImprovementReviewEnqueue.cooldown;
      }
    }
    final wake = Wake(
      id: _newId(),
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: agentId,
      reason: WakeReason.improvementReview,
      payload:
          'Finished work in this conversation is ready for an improvement '
          'review; the improvement review section says what to read and '
          'return.',
      detail: WakeDetail(fields: {kImprovementGoalField: ?goal?.id}),
      runOptions: WakeRunOptions(
        costCapMicros: improvementReviewCapMicros,
        freshHistory: true,
        readOnly: true,
        outputSchema: improvementReviewOutputSchema,
      ),
      dedupKey: dedupKey,
      notBefore: now,
      requestedByUserId: requestedByUserId,
      createdAt: now,
    );
    if (!await _wakeQueue().enqueue(wake)) {
      // The queue refuses only a wake whose dedup key is taken.
      return ImprovementReviewEnqueue.duplicate;
    }
    _lastReview[key] = now;
    return ImprovementReviewEnqueue.queued;
  }

  /// Turns a settled review run's answer into proposals. Returns how many
  /// were written.
  Future<int> onRunSettled(AgentRunSettled event) async {
    if (event.wakeReason != WakeReason.improvementReview) {
      return 0;
    }
    if (event.endReason == RunEndReason.serverStopped) {
      // The run did not answer; nothing failed.
      return 0;
    }
    if (event.status != RunStatus.completed ||
        event.endReason != RunEndReason.completed) {
      CcInfraLog.info(
        'improvement review ${event.runId} ended ${event.endReason.wire}',
      );
      return 0;
    }
    final ws = event.workspaceId;
    Wake? wake;
    for (final id in event.wakeIds) {
      final w = await _wakes.getById(ws, id);
      if (w != null &&
          w.workspaceId == ws &&
          w.reason == WakeReason.improvementReview) {
        wake = w;
        break;
      }
    }
    final log = await _runLogs.getById(ws, event.runId);
    if (wake == null || log == null || log.agentId != wake.agentId) {
      return 0;
    }
    final goalField = wake.detail.fields[kImprovementGoalField];
    final goal = goalField is String
        ? await _goals.getById(ws, goalField)
        : null;
    final parsed = parseImprovementReviewOutput(log.outputJson);
    var dropped = parsed.dropped;
    final now = _now();
    final written = <String>[];
    for (final draft in parsed.drafts) {
      final proposal = await _proposalOf(
        draft,
        wake: wake,
        goal: goal != null && goal.conversationId == wake.conversationId
            ? goal
            : null,
        reviewRunId: event.runId,
        now: now,
      );
      if (proposal == null) {
        dropped++;
        continue;
      }
      await _proposals.insert(proposal);
      written.add(proposal.id);
    }
    if (dropped > 0) {
      CcInfraLog.info(
        'improvement review ${event.runId}: dropped $dropped proposal(s)',
      );
    }
    if (written.isNotEmpty) {
      _eventBus.publish(
        ImprovementProposed(
          workspaceId: ws,
          spaceId: wake.spaceId,
          conversationId: wake.conversationId,
          agentId: wake.agentId,
          goalId: goal?.id,
          proposalIds: written,
          requestedByUserId: wake.requestedByUserId,
          occurredAt: now,
        ),
      );
    }
    return written.length;
  }

  /// The row for [draft], after resolving every id and name the model gave
  /// against the server's records; null when something does not resolve or
  /// no evidence is left.
  Future<ImprovementProposal?> _proposalOf(
    ImprovementDraft draft, {
    required Wake wake,
    required AgentGoalRun? goal,
    required String reviewRunId,
    required DateTime now,
  }) async {
    final ws = wake.workspaceId;
    final messageIds = <String>[];
    for (final id in draft.messageIds) {
      final m = await _messages.getMessageById(ws, id);
      if (m != null && m.conversationId == wake.conversationId) {
        messageIds.add(m.id);
      }
    }
    final runIds = <String>[];
    for (final id in draft.runIds) {
      final r = await _runLogs.getById(ws, id);
      if (r != null &&
          r.workspaceId == ws &&
          r.conversationId == wake.conversationId) {
        runIds.add(r.id);
      }
    }
    final checks = <GoalCheckResult>[
      for (final command in draft.checks)
        ?goal?.verification?.checks
            .where((c) => c.run.trim() == command)
            .firstOrNull,
    ];
    if (messageIds.isEmpty && runIds.isEmpty && checks.isEmpty) {
      return null;
    }
    String? scopeRef;
    if (draft.scope == ImprovementScope.repository) {
      scopeRef = await _resolveRepository(ws, wake.spaceId, draft.repository!);
      if (scopeRef == null) {
        return null;
      }
    }
    final skill = draft.skill;
    if (skill != null) {
      final exists = await _skillExists(ws, skill);
      if (exists != (draft.kind == ImprovementKind.skillEdit)) {
        return null;
      }
      scopeRef = skill;
    }
    final target = draft.target;
    if (target != null && draft.operation != ImprovementOperation.add) {
      final known = switch (draft.kind) {
        ImprovementKind.memoryFact => await _liveFact(ws, target),
        ImprovementKind.policy => await _livePolicy(ws, target),
        _ => true,
      };
      if (!known) {
        return null;
      }
    }
    final conversation = await _conversations.getById(
      workspaceId: ws,
      conversationId: wake.conversationId,
    );
    if (conversation == null || conversation.workspaceId != ws) {
      return null;
    }
    try {
      return ImprovementProposal(
        id: _newId(),
        workspaceId: ws,
        agentId: wake.agentId,
        spaceId: conversation.spaceId,
        conversationId: conversation.id,
        goalId: goal?.id,
        reviewRunId: reviewRunId,
        kind: draft.kind,
        scope: draft.scope,
        scopeRefId: scopeRef,
        operation: draft.operation,
        targetRef: target,
        change: draft.change,
        evidence: ImprovementEvidence(
          runIds: runIds,
          messageIds: messageIds,
          checkResults: checks,
        ),
        expected: draft.expected,
        createdAt: now,
        expiresAt: now.add(ImprovementProposal.lifetime),
      );
    } on ArgumentError catch (e) {
      CcInfraLog.warning('improvement review $reviewRunId: $e');
      return null;
    }
  }

  Future<bool> _liveFact(String ws, String id) async {
    final fact = await _facts.getById(ws, id);
    return fact != null && fact.workspaceId == ws && fact.supersededBy == null;
  }

  Future<bool> _livePolicy(String ws, String id) async {
    final policy = await _policies.getById(ws, id);
    return policy != null && policy.workspaceId == ws && policy.active;
  }
}
