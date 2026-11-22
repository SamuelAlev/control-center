import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_turn_text_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog, RepoOp;
import 'package:cc_infra/cc_infra.dart'
    show
        GoalSupervisor,
        ImprovementReviewService,
        ImprovementReviewTurnTexts,
        PersonGoalCommand,
        WakeQueueService,
        personCommands;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoImprovementApply,
        DaoImprovementProposalRepository,
        DaoMemoryFactRepository,
        DaoOrchestrationRepository,
        DaoWakeRepository,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/evals/skill_evaluation_rpc_ops.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';
import 'package:cc_server_core/src/learning/improvement_adoption_service.dart';
import 'package:cc_server_core/src/runtime/server_goal_wiring.dart';
import 'package:cc_server_core/src/runtime/server_pipeline_goals.dart';
import 'package:cc_server_core/src/runtime/server_wake_queue_wiring.dart';

/// How often undecided proposals are checked for expiry and their skill
/// campaigns for an outcome.
const Duration kImprovementSweepInterval = Duration(days: 1);

/// The kind of the system row told when an accepted skill change could not
/// be finished at boot (`metadata.kind`; clients localize it).
const String kImprovementApplyIncompleteRow = 'improvement_apply_incomplete';

/// Learning from finished work (plan section 13) and the goals pipelines
/// pursue (section 14), wired beside the durable goals in three steps:
///
/// 1. [ServerLearning.new], right after [ServerGoals]: the proposals, the
///    orchestrations' cap raise, the per-turn text of a review run
///    ([turnTexts], which wraps the goals' own), the person commands
///    ([personCommand]: `/goal`, `/refine`, `/loop`, `/schedule`), the
///    adoption service and the pipeline goal pursuits.
/// 2. [attachSkillEvaluation], once the skill evaluation service is built.
/// 3. [attachWakeQueue], right after the goals attached theirs: the review
///    service, the review run's dispatch (never through a goal), and the
///    pursued goals' budget guard.
///
/// [start] runs with the boot recovery: the review service's listeners and
/// the proposal sweep (at boot, then daily).
class ServerLearning {
  /// Step 1.
  ServerLearning({
    required ServerGoals goals,
    required WorkspaceDatabaseManager workspaceDbs,
    required this._conversations,
    required this._messages,
    required this._agents,
    required this._runLogs,
    required DaoMemoryFactRepository facts,
    required MemoryPolicyRepository policies,
    required AgentWorkingMemoryRepository notes,
    required RepoRepository repos,
    required this._reposExposedBy,
    required this.pipelineRuns,
    required WorkspaceFilesystemPort filesystem,
    required SkillScanPort? scanner,
    required DomainEventBus eventBus,
    required this._workspaceIds,
  }) : _goals = goals,
       _facts = facts,
       _policies = policies,
       _repos = repos,
       _filesystem = filesystem,
       _eventBus = eventBus,
       proposals = DaoImprovementProposalRepository(workspaceDbs),
       orchestrations = DaoOrchestrationRepository(workspaceDbs),
       turnTexts = ImprovementReviewTurnTexts(
         goals: goals.turnTexts,
         goalRows: goals.goals,
       ),
       pipelineGoals = PipelineGoalPursuits(
         supervisor: () => goals.supervisor,
         goals: goals.goals,
         wakes: DaoWakeRepository(workspaceDbs),
         eventBus: eventBus,
       ) {
    adoption = ImprovementAdoptionService(
      proposals: proposals,
      apply: DaoImprovementApply(workspaceDbs, facts: facts),
      facts: facts,
      policies: policies,
      notes: notes,
      repos: repos,
      filesystem: filesystem,
      scanner: scanner,
      evaluation: () => skillEvaluation,
      now: DateTime.now,
      recoveryWait: kImprovementRecoveryWait,
    );
  }

  final ServerGoals _goals;
  final ConversationRepository _conversations;
  final MessagingRepository _messages;
  final AgentRepository _agents;
  final AgentRunLogRepository _runLogs;
  final DaoMemoryFactRepository _facts;
  final MemoryPolicyRepository _policies;
  final RepoRepository _repos;
  final Future<List<String>> Function(String workspaceId, String spaceId)
  _reposExposedBy;
  final WorkspaceFilesystemPort _filesystem;
  final DomainEventBus _eventBus;
  final Future<List<String>> Function() _workspaceIds;

  /// The improvement proposals.
  final ImprovementProposalRepository proposals;

  /// The orchestrations, and the raise of their cost cap
  /// (`orchestration.raiseCap`).
  final DaoOrchestrationRepository orchestrations;

  /// The pipeline runs (a run's requester and spend, for a cap raise).
  final PipelineRunRepository pipelineRuns;

  /// What a wake-started run's per-turn prompt says: a review run's
  /// instructions, else the goals' text.
  final GoalTurnTextPort turnTexts;

  /// The goals pipelines pursue (`goal.pursue`) and their cost cap.
  final PipelineGoalPursuits pipelineGoals;

  /// A person's decisions on proposals.
  late final ImprovementAdoptionService adoption;

  /// Step 2: the skill evaluation service a skill proposal is measured
  /// with; null until it is built (a skill campaign is refused meanwhile).
  SkillEvaluationService? skillEvaluation;

  /// Step 2: sets [skillEvaluation] to [service] and returns its ops, whose
  /// campaign cancel follows the improvement's rule for a campaign a
  /// proposal owns ([ImprovementAdoptionService.guardCampaignCancel]).
  List<RepoOp> attachSkillEvaluation(SkillEvaluationService service) {
    skillEvaluation = service;
    return buildSkillEvaluationOps(
      service,
      guardCancel: adoption.guardCampaignCancel,
    );
  }

  ImprovementReviewService? _review;
  Timer? _sweep;

  /// The review service, once [attachWakeQueue] ran.
  ImprovementReviewService get review =>
      _review ?? (throw StateError('The improvement review is not attached'));

  /// The handler of every person command: `/loop` and `/schedule` go to
  /// [wakeRules], `/refine` to the review, everything else starts a goal
  /// through [supervisor] (the body after the slash-token is the
  /// objective). With no conversation named, the space's standing one is
  /// ensured (no main-id aliasing). Refusals are thrown with their kind.
  PersonGoalCommand personCommand({
    required GoalSupervisor Function() supervisor,
    required PersonGoalCommand wakeRules,
  }) {
    Future<String> conversationOf(
      String workspaceId,
      String spaceId,
      String? conversationId,
    ) async =>
        conversationId ??
        (await _conversations.ensure(
          workspaceId: workspaceId,
          spaceId: spaceId,
        )).id;
    return personCommands(
      wakeRules: wakeRules,
      goals:
          ({
            required workspaceId,
            required spaceId,
            required agentId,
            required prompt,
            required requestedByUserId,
            conversationId,
          }) async {
            final trimmed = prompt.trimLeft();
            final split = trimmed.indexOf(' ');
            final goal = await supervisor().startGoal(
              workspaceId: workspaceId,
              spaceId: spaceId,
              conversationId: await conversationOf(
                workspaceId,
                spaceId,
                conversationId,
              ),
              agentId: agentId,
              userText: split < 0 ? '' : trimmed.substring(split + 1).trim(),
              requestedByUserId: requestedByUserId,
            );
            // The first run's id; null when it did not start at once.
            return goal?.activeRunId;
          },
      refine:
          ({
            required workspaceId,
            required spaceId,
            required agentId,
            required prompt,
            required requestedByUserId,
            conversationId,
          }) async {
            await review.refine(
              workspaceId: workspaceId,
              spaceId: spaceId,
              conversationId: await conversationOf(
                workspaceId,
                spaceId,
                conversationId,
              ),
              agentId: agentId,
              requestedByUserId: requestedByUserId,
            );
            // The review run is a wake: it starts when the queue delivers it.
            return null;
          },
    );
  }

  /// Step 3: builds the review service over [queue], sends a review run
  /// straight to the plain dispatch (a review is never a goal's segment,
  /// even when its agent pursues one), and holds a pursued goal's wakes at
  /// its orchestration's cap.
  void attachWakeQueue(
    ServerRunQueues runQueues,
    WakeQueueService queue, {
    required WakeRepository wakes,
  }) {
    _review = ImprovementReviewService(
      wakeQueue: () => queue,
      wakes: wakes,
      goals: _goals.goals,
      agents: _agents,
      runLogs: _runLogs,
      proposals: proposals,
      messages: _messages,
      conversations: _conversations,
      facts: _facts,
      policies: _policies,
      resolveRepository: _resolveRepository,
      skillExists: (workspaceId, slug) async =>
          await _filesystem.readSkillFile(workspaceId, slug) != null,
      eventBus: _eventBus,
      now: DateTime.now,
    );
    final through = runQueues.dispatchThrough;
    runQueues.dispatchThrough = (run, plain) =>
        run.wakeContext.wakeReason == WakeReason.improvementReview ||
            through == null
        ? plain(run)
        : through(run, plain);
    queue.registerGuard(pipelineGoals);
  }

  /// The id of the repository [reference] names (its id, `owner/name` or
  /// name) among those [spaceId] exposes; null when it names none.
  Future<String?> _resolveRepository(
    String workspaceId,
    String spaceId,
    String reference,
  ) async {
    final wanted = reference.trim().toLowerCase();
    for (final id in await _reposExposedBy(workspaceId, spaceId)) {
      final repo = await _repos.getById(workspaceId, id);
      if (repo == null) {
        continue;
      }
      if (repo.id.toLowerCase() == wanted ||
          repo.fullName.toLowerCase() == wanted ||
          repo.name.toLowerCase() == wanted) {
        return repo.id;
      }
    }
    return null;
  }

  /// Boot recovery: unfinished proposal moves are finished or reported
  /// first (the improvement ops wait for it, [ImprovementAdoptionService.
  /// markRecovered]), then the review listens, held pipeline runs are
  /// watched again, and the proposals are swept now and then daily.
  Future<void> start() async {
    try {
      await _recoverProposals();
    } finally {
      adoption.markRecovered();
    }
    review.start();
    await pipelineGoals.recover();
    await sweep();
    _sweep ??= Timer.periodic(kImprovementSweepInterval, (_) {
      unawaited(sweep());
    });
  }

  /// [ImprovementAdoptionService.recover] in every registered workspace; an
  /// accepted skill change whose write could not be finished is rolled back
  /// and told in its space with a row of kind
  /// [kImprovementApplyIncompleteRow].
  Future<void> _recoverProposals() async {
    for (final workspaceId in await _workspaceIds()) {
      try {
        for (final p in await adoption.recover(workspaceId)) {
          final spaceId = p.spaceId;
          if (spaceId == null) {
            continue;
          }
          await _messages.sendMessage(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: p.conversationId,
            content:
                'An accepted improvement to the skill ${p.scopeRefId} was '
                'not applied before the server stopped, and the skill has '
                'changed since. It is rolled back; review it again.',
            senderId: 'system',
            senderType: 'system',
            messageType: 'system',
            metadata: {
              'kind': kImprovementApplyIncompleteRow,
              'proposal_id': p.id,
              'skill_slug': ?p.scopeRefId,
              'decided_by_user_id': ?p.decidedByUserId,
            },
          );
        }
      } on Object catch (e) {
        CcHostLog.warning('improvements: recovery of $workspaceId failed: $e');
      }
    }
  }

  /// Expires undecided proposals past their 30 days and records the outcome
  /// of finished skill campaigns, in every registered workspace.
  Future<void> sweep() async {
    for (final workspaceId in await _workspaceIds()) {
      try {
        final expired = await adoption.sweep(workspaceId);
        if (expired > 0) {
          CcHostLog.info('improvements: $expired expired in $workspaceId');
        }
      } on Object catch (e) {
        CcHostLog.warning('improvements: sweep of $workspaceId failed: $e');
      }
    }
  }

  /// Stops the sweep and the listeners.
  Future<void> dispose() async {
    _sweep?.cancel();
    _sweep = null;
    await _review?.dispose();
  }
}
