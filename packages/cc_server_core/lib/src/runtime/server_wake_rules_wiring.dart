import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        PersonGoalCommand,
        TimezoneZoneConverter,
        WakeQueueService,
        WakeRulePorts,
        WakeRuleService,
        WakeWatchAccess,
        WakeWatchRefusal,
        wakeRuleCommands;
import 'package:cc_mcp/cc_mcp.dart'
    show CancelWakeTool, ListWakesTool, McpRunToolSurface, WakeMeTool;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoIsolatedRepoRepository,
        DaoPeerAskRepository,
        DaoReviewSpaceRepository,
        DaoWakeRuleRepository,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';

/// The run whose tool call started the run [runId] of [workspaceId] by a
/// direct dispatch (its run log's `started_by_run_id`), for the wake rules'
/// lineage lookup and settlement charge. Null for a run with wakes (they
/// carry their own lineage), for a run nothing started that way, and when
/// the named run is not a run of [workspaceId]: a run id from another
/// workspace starts no lineage here.
Future<String?> startedByRunOf(
  AgentRunLogRepository runLogs,
  String workspaceId,
  String runId,
) async {
  final log = await runLogs.getById(workspaceId, runId);
  final from = log?.startedByRunId;
  if (log == null ||
      (log.workspaceId != null && log.workspaceId != workspaceId) ||
      log.wakeIds.isNotEmpty ||
      from == null ||
      from == runId) {
    return null;
  }
  final starter = await runLogs.getById(workspaceId, from);
  if (starter == null ||
      (starter.workspaceId != null && starter.workspaceId != workspaceId)) {
    return null;
  }
  return from;
}

/// Schedules, loops and event watches (plan section 9) as the server wires
/// them, built in two steps like the run queues: the constructor (before
/// the messaging service, which needs [command] for a person's `/loop` and
/// `/schedule`), then [attach] once the wake queue exists, which builds the
/// [WakeRuleService] and registers `wake_me`, `list_wakes` and
/// `cancel_wake`. [start] runs after the wake queue starts.
class ServerWakeRules {
  /// Creates the wiring.
  ServerWakeRules({
    required WorkspaceDatabaseManager workspaceDbs,
    required this._workspaceActive,
    required this._conversations,
    required this._agents,
    required this._messaging,
    required this._settings,
    required this._goals,
    required this._runLogs,
    required RepoRepository repos,
    required PrDataGate spaceData,
    required RepoAccessRegistry repoAccess,
    required TicketRepository tickets,
    required PipelineRunRepository pipelineRuns,
    required this._eventBus,
    required this._mcpRegistry,
    required this._cacheTtl,
  }) : rules = DaoWakeRuleRepository(workspaceDbs),
       _asks = DaoPeerAskRepository(workspaceDbs),
       _access = _ServerWatchAccess(
         repos: repos,
         spaceData: spaceData,
         repoAccess: repoAccess,
         isolated: DaoIsolatedRepoRepository(workspaceDbs),
         reviewSpaces: DaoReviewSpaceRepository(workspaceDbs),
         tickets: tickets,
         pipelineRuns: pipelineRuns,
       ) {
    command = wakeRuleCommands(
      service: () => service,
      standingConversation: (workspaceId, spaceId) async =>
          (await _conversations.ensure(
            workspaceId: workspaceId,
            spaceId: spaceId,
          )).id,
      conversationSpace: _conversationSpace,
      postRow: _postRow,
    );
  }

  /// The stored rules.
  final WakeRuleRepository rules;
  final PeerAskRepository _asks;
  final Future<bool> Function(String workspaceId) _workspaceActive;
  final ConversationRepository _conversations;
  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final WorkspaceSettingsRepository _settings;
  final AgentGoalRunRepository _goals;
  final AgentRunLogRepository _runLogs;
  final DomainEventBus _eventBus;
  final McpToolRegistry _mcpRegistry;
  final Duration? Function(String, String) _cacheTtl;
  final WakeWatchAccess _access;
  WakeRuleService? _service;

  /// A signed-in person's `/loop …` and `/schedule …`.
  late final PersonGoalCommand command;

  /// The rule service, once [attach] ran.
  WakeRuleService get service =>
      _service ?? (throw StateError('Wake rules are not attached yet'));

  Future<String?> _conversationSpace(
    String workspaceId,
    String conversationId,
  ) async {
    final c = await _conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    return c == null || c.workspaceId != workspaceId ? null : c.spaceId;
  }

  Future<String?> _postRow({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required Map<String, Object?> metadata,
  }) => _messaging.sendMessage(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    content: content,
    senderId: 'system',
    senderType: 'system',
    messageType: 'system',
    metadata: metadata,
  );

  /// Builds the rule service on [queue] and registers the agents' tools.
  WakeRuleService attach({
    required WakeRepository wakes,
    required WakeQueueService queue,
  }) {
    final zones = TimezoneZoneConverter.instance;
    final service = _service = WakeRuleService(
      rules: rules,
      wakes: wakes,
      queue: queue,
      eventBus: _eventBus,
      scheduler: zones.scheduler(),
      ports: WakeRulePorts(
        workspaceActive: _workspaceActive,
        conversationSpace: _conversationSpace,
        agentInWorkspace: (workspaceId, agentId) async =>
            (await _agents.getById(workspaceId, agentId))?.workspaceId ==
            workspaceId,
        agentName: (workspaceId, agentId) async {
          final agent = await _agents.getById(workspaceId, agentId);
          return agent?.workspaceId == workspaceId ? agent?.name : null;
        },
        // A run live only for its background tasks yields to the wake: it
        // does not make the agent busy.
        agentBusy: queue.agentBusy,
        postRow: _postRow,
        readSetting: _settings.get,
        writeSetting: _settings.set,
        isKnownZone: zones.isKnown,
        goalOfRun: (workspaceId, runId) async =>
            (await _goals.getByActiveRunId(workspaceId, runId))?.id,
        runWakeIds: (workspaceId, runId) async =>
            (await _runLogs.getById(workspaceId, runId))?.wakeIds ?? const [],
        goalTerminal: (workspaceId, goalId) async =>
            (await _goals.getById(workspaceId, goalId))?.status.isTerminal,
        watchAccess: _access,
        runProvider: (workspaceId, runId) async {
          final log = await _runLogs.getById(workspaceId, runId);
          return LimitPark.providerLabel(
            adapter: log?.adapter,
            modelId: log?.modelId,
          );
        },
        runFacts: (workspaceId, runId) async {
          final log = await _runLogs.getById(workspaceId, runId);
          // The workspace's own database; a row naming another is not it.
          if (log == null ||
              (log.workspaceId != null && log.workspaceId != workspaceId)) {
            return null;
          }
          return (
            id: log.id,
            status: log.status.name,
            endReason: log.endReason?.wire,
            costMicros: log.cost.costMicros + log.childCostMicros,
            startedAt: log.startedAt.toUtc(),
            endedAt: log.completedAt?.toUtc(),
          );
        },
        startedByRun: (workspaceId, runId) =>
            startedByRunOf(_runLogs, workspaceId, runId),
      ),
    );
    _mcpRegistry
      ..register(
        WakeMeTool(
          service: service,
          runs: _runLogs,
          cacheTtl: _cacheTtl,
          // `repl` is a shared tool, so the shared view decides it.
          hasRepl: (scope) => McpRunToolSurface(
            registry: _mcpRegistry,
          ).hasRepl(scope, McpToolView.shared),
        ),
      )
      ..register(
        ListWakesTool(
          service: service,
          wakes: wakes,
          asks: _asks,
          runs: _runLogs,
        ),
      )
      ..register(
        CancelWakeTool(service: service, wakes: wakes, runs: _runLogs),
      );
    return service;
  }

  /// Subscribes the service and re-arms every active rule (after the wake
  /// queue started).
  Future<void> start() => service.start();
}

/// Watch targets as the server sees them: pull requests through the
/// space's repositories, its worktrees' branches, the pull requests it
/// reviews and the space read gate; tickets and pipeline runs through their
/// workspace's records.
///
/// A pull request watch hears what the open-PR poller reads: every open pull
/// request of every linked repository with a forge remote that the server
/// can read (GitHub through a one-repository App token, the other forges
/// through the workspace's automation token), whoever opened it. A
/// repository the access registry blocks is not read, so a watch on it is
/// refused rather than left waiting.
final class _ServerWatchAccess implements WakeWatchAccess {
  _ServerWatchAccess({
    required this.repos,
    required this.spaceData,
    required this.repoAccess,
    required this.isolated,
    required this.reviewSpaces,
    required this.tickets,
    required this.pipelineRuns,
  });

  final RepoRepository repos;
  final PrDataGate spaceData;
  final RepoAccessRegistry repoAccess;
  final IsolatedRepoRepository isolated;
  final ReviewSpaceRepository reviewSpaces;
  final TicketRepository tickets;
  final PipelineRunReader pipelineRuns;

  // The person passes the space's read gate (a pull request it reviews they
  // can see, a read grant and their own forge read on every repository it
  // exposes); a bot's rule has no person.
  Future<bool> _personReads(
    String workspaceId,
    String spaceId,
    String? userId,
  ) async {
    if (userId == null) {
      return true;
    }
    try {
      await spaceData.requireSpace(workspaceId, userId, spaceId);
      return true;
    } on Object {
      return false;
    }
  }

  /// The repositories [spaceId] exposes that the poll reads.
  Future<List<Repo>> _polled(String workspaceId, String spaceId) async {
    final out = <Repo>[];
    for (final id in await spaceData.reposExposedBy(workspaceId, spaceId)) {
      final repo = await repos.getById(workspaceId, id);
      if (repo == null || !repo.hasForgeRemote) {
        continue;
      }
      final issue = await repoAccess.issueFor(
        workspaceId,
        forge: repo.forge,
        owner: repo.remoteOwner,
        name: repo.remoteName,
      );
      if (!(issue?.state.blocksAutomation ?? false)) {
        out.add(repo);
      }
    }
    return out;
  }

  static bool _sameRepo(Repo repo, String owner, String name) =>
      repo.remoteOwner.toLowerCase() == owner.toLowerCase() &&
      repo.remoteName.toLowerCase() == name.toLowerCase();

  @override
  Future<WakeWatchRefusal?> prWatchRefusal({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
  }) async {
    if (!await _personReads(workspaceId, spaceId, userId)) {
      return (
        kind: WakeRuleRefusals.watchRefused,
        message:
            'The person this run acts for cannot read this space\'s '
            'repositories, so it cannot watch their pull requests.',
      );
    }
    final polled = await _polled(workspaceId, spaceId);
    if (target == null) {
      return polled.isEmpty
          ? (
              kind: WakeRuleRefusals.watchTargetUnreadable,
              message:
                  'This space exposes no forge repository the server can '
                  'read now, so no pull request of it could ever be seen. '
                  'Name one in a repository it exposes '
                  '(on:pr_checks:owner/name#12), or ask a person to link '
                  'the repository or fix its access.',
            )
          : null;
    }
    if (polled.any((r) => _sameRepo(r, target.owner, target.name))) {
      return null;
    }
    return (
      kind: WakeRuleRefusals.watchTargetUnreadable,
      message:
          '${target.owner}/${target.name} is not a repository this space '
          'exposes that the server can read now, so $target could never '
          'be seen. Watch a pull request of a repository this space '
          'exposes, or ask a person to add it.',
    );
  }

  @override
  Future<bool> prWatched({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
    required String repoOwner,
    required String repoName,
    required int number,
    required String headRef,
  }) async {
    if (target != null && !target.names(repoOwner, repoName, number)) {
      return false;
    }
    Repo? repo;
    for (final id in await spaceData.reposExposedBy(workspaceId, spaceId)) {
      final r = await repos.getById(workspaceId, id);
      if (r != null && r.hasForgeRemote && _sameRepo(r, repoOwner, repoName)) {
        repo = r;
        break;
      }
    }
    if (repo == null || !await _personReads(workspaceId, spaceId, userId)) {
      return false;
    }
    if (target != null) {
      return true;
    }
    // The space's own: its worktree of the repository is on the pull
    // request's head branch, or the space reviews that pull request.
    final checkout = await isolated.forUnitRepo(workspaceId, spaceId, repo.id);
    if (checkout != null &&
        headRef.isNotEmpty &&
        checkout.branch == headRef) {
      return true;
    }
    final fullName = '$repoOwner/$repoName'.toLowerCase();
    return (await reviewSpaces.watchAllBySpace(workspaceId, spaceId).first)
        .any(
          (a) =>
              a.prNumber == number && a.repoFullName.toLowerCase() == fullName,
        );
  }

  @override
  Future<bool> ticketWatchable({
    required String workspaceId,
    required String agentId,
    required String ticketId,
  }) async {
    final ticket = await tickets.getById(workspaceId, ticketId);
    return ticket != null &&
        ticket.workspaceId == workspaceId &&
        (ticket.assignedAgentId == agentId ||
            ticket.delegatedByAgentId == agentId);
  }

  @override
  Future<bool> pipelineRunWatchable({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required String runId,
  }) async {
    // Resolved through the run's own workspace route, then held to this
    // workspace.
    final run = await pipelineRuns.getRun(runId);
    if (run == null || run.workspaceId != workspaceId) {
      return false;
    }
    final runSpace = switch (run.state['space_id'] ??
        run.triggerPayload?['space_id']) {
      final String id when id.isNotEmpty => id,
      _ => null,
    };
    if (runSpace == spaceId) {
      return true;
    }
    if (userId == null) {
      return false;
    }
    try {
      await spaceData.requireRun(workspaceId, userId, run);
      if (runSpace != null) {
        await spaceData.requireSpace(workspaceId, userId, runSpace);
      }
      return true;
    } on Object {
      return false;
    }
  }

}
