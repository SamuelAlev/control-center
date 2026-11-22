import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_host/cc_host.dart' show PendingConfirmationRegistry;
import 'package:cc_infra/cc_infra.dart'
    show
        AgentDispatchService,
        AgentQuestionService,
        ConversationCompactionService,
        GoalStore,
        GoalWakeReasons,
        MessagingService,
        SandboxedAgentDispatchAdapter,
        StillInFlightLines,
        StillInFlightNotes,
        StillInFlightPorts,
        TimezoneZoneConverter;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoCodeModeStoreRepository,
        DaoImprovementProposalRepository,
        DaoPeerAskRepository,
        DaoWakeRuleRepository,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/runtime/server_goal_wiring.dart';
import 'package:cc_server_core/src/runtime/server_wake_queue_wiring.dart';
import 'package:cc_server_core/src/unattended/unattended_requests.dart';
import 'package:cc_server_core/src/unattended/waiting_digest.dart';

/// What a person is told, and what an agent keeps, when nobody is watching
/// (plan section 12): the server's "Still in flight" block after every
/// compaction (the harness seam, the conversation compactor and a Claude
/// Code session's own compaction), the expiry of requests nobody answers
/// ([UnattendedRequests]) and the once-a-day digest of what waits
/// ([WaitingDigestService]).
///
/// Built once the goals, the wake queue and the messaging service exist:
/// [wire] sets the hooks and starts both services.
final class ServerUnattended {
  ServerUnattended._(this.requests, this.digest);

  /// The expiry of unanswered requests.
  final UnattendedRequests requests;

  /// The daily digest.
  final WaitingDigestService digest;

  /// Sets the "Still in flight" hooks on [adapter] and [compaction], and
  /// starts the expiry and the digest.
  static ServerUnattended wire({
    required DomainEventBus eventBus,
    required WorkspaceDatabaseManager workspaceDbs,
    required WorkspaceSettingsRepository settings,
    required AgentQuestionService questions,
    required PendingConfirmationRegistry confirmations,
    required AgentRunLogRepository runLogs,
    required AgentRepository agents,
    required ServerGoals goals,
    required WakeRepository wakes,
    required ServerRunQueues runQueues,
    required AgentDispatchService dispatch,
    required SandboxedAgentDispatchAdapter adapter,
    required MessagingService messagingService,
    required MessagingRepository messages,
    required ConversationCompactionService compaction,
    required WorkspaceMembershipRepository members,
    required Future<List<String>> Function() workspaceIds,
    required PrDataGate spaces,
  }) {
    final notes = StillInFlightNotes(
      messages: messages,
      lines: StillInFlightLines(
        ports: _inFlightPorts(
          workspaceDbs: workspaceDbs,
          goals: goals,
          agents: agents,
          messages: messages,
          questions: questions,
        ),
      ),
    );
    adapter.stillInFlight
      ..lines = notes.harnessLines
      ..claudeCompacted =
          ({
            required workspaceId,
            required spaceId,
            required agentId,
            required conversationId,
          }) => notes.writeAfterCompaction(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            agentId: agentId,
            claude: true,
          );
    compaction.stillInFlight = notes;

    final store = GoalStore(
      goals: goals.goals,
      wakes: wakes,
      wakeQueue: () => runQueues.wakeQueue,
      say:
          ({
            required workspaceId,
            required spaceId,
            required content,
            conversationId,
          }) => messagingService.postSystemMessage(
            workspaceId,
            spaceId,
            content,
            conversationId: conversationId,
          ),
      eventBus: eventBus,
      now: DateTime.now,
      startRefs: goals.turnTexts.changes.startRefs,
    );
    runQueues.bindGoalSteering(store, goals.goals);
    final requests = UnattendedRequests(
      eventBus: eventBus,
      ports: UnattendedRequestPorts(
        readSetting: settings.get,
        writeSetting: settings.set,
        runById: runLogs.getById,
        approval: (waitId) {
          final pending = confirmations.pendingById(waitId);
          if (pending == null) {
            return null;
          }
          return (
            title: pending.request.title,
            runId: pending.request.runId,
            createdAt: pending.createdAt,
          );
        },
        denyApprovalAfter: confirmations.denyAfter,
        // An expiry, not a person's deny: the producer stores no decision.
        denyApproval: confirmations.expire,
        questionWaitUntil: questions.waitUntil,
        questionPending: questions.isPending,
        releaseQuestion: questions.release,
        segmentGoalOf: goals.goals.getByActiveRunId,
        transitionGoal: store.transition,
        cancelGoalWakes: (goal) async {
          await store.cancelWakes(goal, GoalWakeReasons.held);
        },
        publishGoalSettled: store.publishSettled,
        postRow:
            ({
              required workspaceId,
              required spaceId,
              required conversationId,
              required content,
            }) => messagingService.postSystemMessage(
              workspaceId,
              spaceId,
              content,
              conversationId: conversationId,
            ),
        tellRun: (runId, notice) =>
            dispatch.steerRun(runId, notice, source: 'unattended'),
        stopping: () => runQueues.stopping,
      ),
    )..start();
    goals.supervisor.onPersonDecision = (goal) =>
        unawaited(requests.forgetGoal(goal).catchError((Object _) {}));
    // After a request of a run expired, its later requests are refused at
    // once, with no card or form.
    confirmations.refuseUnasked = requests.refuseApproval;
    questions.answerUnasked = requests.answerQuestion;

    final proposals = DaoImprovementProposalRepository(workspaceDbs);
    final zones = TimezoneZoneConverter.instance;
    final digest = WaitingDigestService(
      eventBus: eventBus,
      scheduler: zones.scheduler(),
      toLocal: zones.toLocal,
      ports: WaitingDigestPorts(
        workspaceIds: workspaceIds,
        readSetting: settings.get,
        writeSetting: settings.set,
        timeZoneOf: (workspaceId) async => WakeRuleLimits.fromSetting(
          await settings.get(workspaceId, wakeRuleLimitsSettingKey),
        ).defaultTimeZone,
        heldGoals: (workspaceId, hold) =>
            goals.goals.listHeld(workspaceId, hold: hold),
        heldWakes: (workspaceId) async => [
          for (final row
              in await workspaceDbs.of(workspaceId).wakeDao.listHeld())
            (
              id: row.id,
              spaceId: row.spaceId,
              conversationId: row.conversationId,
              agentId: row.agentId,
              requestedByUserId: row.requestedByUserId,
              summary: '${row.reason}: ${row.payload}',
            ),
        ],
        pendingProposals: (workspaceId) => proposals.listForWorkspace(
          workspaceId,
          statuses: {ImprovementStatus.proposed},
        ),
        pendingRequests: (workspaceId) async => [
          for (final r in requests.pendingIn(workspaceId))
            (
              id: r.waitId,
              summary: r.summary,
              agentId: r.agentId,
              requestedByUserId: r.requestedByUserId,
              goalId: r.goalId,
              spaceId: r.spaceId,
              conversationId: r.conversationId,
              deadline: r.deadline,
            ),
        ],
        goalById: goals.goals.getById,
        admins: (workspaceId) async => [
          for (final m in await members.getForWorkspace(workspaceId))
            if (m.role.isAdmin) m.userId,
        ],
        isMember: (workspaceId, userId) async =>
            await members.getMember(workspaceId, userId) != null,
        canReadSpace: (workspaceId, userId, spaceId) async {
          try {
            await spaces.requireSpace(workspaceId, userId, spaceId);
            return true;
          } on Object {
            return false;
          }
        },
        stopping: () => runQueues.stopping,
      ),
    )..start();
    return ServerUnattended._(requests, digest);
  }

  static StillInFlightPorts _inFlightPorts({
    required WorkspaceDatabaseManager workspaceDbs,
    required ServerGoals goals,
    required AgentRepository agents,
    required MessagingRepository messages,
    required AgentQuestionService questions,
  }) {
    final rules = DaoWakeRuleRepository(workspaceDbs);
    final asks = DaoPeerAskRepository(workspaceDbs);
    final store = DaoCodeModeStoreRepository(workspaceDbs);
    return StillInFlightPorts(
      activeGoal: goals.goals.getActiveForAgent,
      rules: rules.listForConversation,
      pendingAsks: (workspaceId, agentId, conversationId) => asks.listPending(
        workspaceId,
        askerAgentId: agentId,
        askerConversationId: conversationId,
      ),
      messageText: (workspaceId, messageId) async =>
          (await messages.getMessageById(workspaceId, messageId))?.content,
      agentName: (workspaceId, agentId) async =>
          (await agents.getById(workspaceId, agentId))?.name,
      personQuestions: (workspaceId, agentId, conversationId) async => [
        for (final row
            in await workspaceDbs
                .of(workspaceId)
                .messagingDao
                .watchPendingQuestions(workspaceId)
                .first)
          if (row.conversationId == conversationId &&
              row.senderId == agentId &&
              questions.isPending(row.id))
            (text: row.content, askedAt: row.createdAt),
      ],
      storedKeys: (workspaceId, agentId, conversationId) async => [
        ...(await store.readAll(
          workspaceId,
          conversationId: conversationId,
          agentId: agentId,
        )).keys,
      ],
    );
  }

  /// Stops the expiry and the digest (the requests keep their own
  /// deadlines).
  Future<void> dispose() async {
    await requests.dispose();
    await digest.dispose();
  }
}
