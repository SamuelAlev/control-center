import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/newsfeed/domain/default_feeds.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/repositories/dao_calendar_repository.dart';
import 'package:cc_persistence/repositories/dao_meeting_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_policy_repository.dart';
import 'package:cc_server_core/src/demo/demo_pr_cache.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:cc_server_core/src/demo/fixtures/demo_fixtures.g.dart';
import 'package:drift/drift.dart' as drift;

/// Writes the demo's fictional world into a freshly created workspace.
///
/// Two entry points, because the databases split two ways:
///  * [seedWorkspace] runs at POOL-FILL time against one workspace file;
///  * [seedUser] runs at CLAIM time for the lanes keyed by user in the GLOBAL
///    database (the newsfeed), which no workspace file can reach.
///
/// Everything is written through the same repositories and DAOs the product
/// uses, with a required `workspaceId` on every call — the demo is not allowed
/// its own back door into persistence.
///
/// Every timestamp is relative to seed time, so a demo is always "today" and
/// every row sits inside the retention windows `DatabaseRetentionService`
/// sweeps (caches 21d, run transcripts 30d, activity 90d) — the retention
/// service is deliberately left RUNNING in demo mode, and seeding a row older
/// than its window would have it vanish mid-session.
///
/// The world is **Parced**, a real-estate closing platform: the cast builds
/// escrow timelines, offer/contingency tooling and broker reporting, and every
/// ticket, PR, meeting and memory fact is about that domain.
class DemoSeeder {
  /// Creates a seeder over the server's repositories.
  DemoSeeder({
    required GlobalDatabase globalDb,
    required WorkspaceDatabaseManager workspaceDbs,
    required String dataDir,
    required UserRepository userRepository,
    required WorkspaceMembershipRepository membershipRepository,
    required WorkspaceRepository workspaceRepository,
    required AgentRepository agentRepository,
    required RepoRepository repoRepository,
    required MessagingRepository messagingRepository,
    required TicketRepository ticketRepository,
    required ProjectRepository projectRepository,
    required TodoRepository todoRepository,
    required AgentRunLogRepository runLogRepository,
    required PipelineRunRepository pipelineRunRepository,
    required PipelineTemplateRepository pipelineTemplateRepository,
    required TicketSyncLogRepository syncLogRepository,
    required WorkProductRepository workProductRepository,
    required ReviewCohortRepository reviewCohortRepository,
    required ReviewSpaceRepository reviewSpaceRepository,
    required ReviewAxisResultRepository reviewAxisResultRepository,
    Future<void> Function(String workspaceId)? baseSeed,
    void Function(ConfirmationRequest request)? registerConfirmation,
    Future<void> Function(String userId)? refreshNewsfeed,
    void Function(String message)? log,
    DateTime Function()? now,
  }) : _globalDb = globalDb,
       _dbs = workspaceDbs,
       _dataDir = dataDir,
       _users = userRepository,
       _members = membershipRepository,
       _workspaces = workspaceRepository,
       _agents = agentRepository,
       _repos = repoRepository,
       _messaging = messagingRepository,
       _tickets = ticketRepository,
       _projects = projectRepository,
       _todos = todoRepository,
       _runLogs = runLogRepository,
       _pipelineRuns = pipelineRunRepository,
       _pipelineTemplates = pipelineTemplateRepository,
       _syncLog = syncLogRepository,
       _workProducts = workProductRepository,
       _reviewCohorts = reviewCohortRepository,
       _reviewSpaces = reviewSpaceRepository,
       _reviewAxes = reviewAxisResultRepository,
       _baseSeed = baseSeed,
       _registerConfirmation = registerConfirmation,
       _refreshNewsfeed = refreshNewsfeed,
       _log = log ?? _noop,
       _now = now ?? DateTime.now;

  static void _noop(String _) {}

  final GlobalDatabase _globalDb;
  final WorkspaceDatabaseManager _dbs;
  final String _dataDir;
  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final WorkspaceRepository _workspaces;
  final AgentRepository _agents;
  final RepoRepository _repos;
  final MessagingRepository _messaging;
  final TicketRepository _tickets;
  final ProjectRepository _projects;
  final TodoRepository _todos;
  final AgentRunLogRepository _runLogs;
  final PipelineRunRepository _pipelineRuns;
  final PipelineTemplateRepository _pipelineTemplates;
  final TicketSyncLogRepository _syncLog;
  final WorkProductRepository _workProducts;
  final ReviewCohortRepository _reviewCohorts;
  final ReviewSpaceRepository _reviewSpaces;
  final ReviewAxisResultRepository _reviewAxes;

  /// The product's own `WorkspaceSeeder` (CEO + specialists + pipeline
  /// templates). Run first so the demo's flavour data sits on top of a
  /// workspace that looks like any other.
  final Future<void> Function(String workspaceId)? _baseSeed;

  /// Registers a PENDING approval in the host's live confirmation registry,
  /// which is what the inbox's "agent is waiting on you" lane reads. Null on
  /// hosts without the registry.
  final void Function(ConfirmationRequest request)? _registerConfirmation;

  /// Kicks a newsfeed refresh for one user at CLAIM time, so a visitor sees
  /// real articles within seconds instead of waiting for the 30-minute sweep.
  final Future<void> Function(String userId)? _refreshNewsfeed;

  final void Function(String) _log;
  final DateTime Function() _now;

  /// Creates the fictional teammates as real global `users` rows.
  ///
  /// Idempotent and shared across every pooled workspace: they are fixtures,
  /// not sessions, so the visitor reaper leaves them alone.
  Future<void> ensureCast() async {
    for (final person in kDemoCast) {
      if (await _users.getById(person.id) != null) {
        continue;
      }
      await _users.upsert(
        User(
          id: person.id,
          handle: person.handle,
          displayName: person.displayName,
          createdAt: _now().subtract(const Duration(days: 240)),
          onboardingFinishedAt: _now().subtract(const Duration(days: 240)),
        ),
      );
    }
  }

  // ── Per-workspace ────────────────────────────────────────────────────────

  /// Seeds one workspace with the whole fictional world.
  Future<void> seedWorkspace(String workspaceId) async {
    await ensureCast();
    await _baseSeed?.call(workspaceId);
    await _prunePipelineTemplates(workspaceId);
    await _seedMembers(workspaceId);
    await _seedRepo(workspaceId);
    final agents = await _seedAgents(workspaceId);
    await _seedPullRequests(workspaceId);
    final spaces = await _seedSpaces(workspaceId, agents);
    await _seedWorkspaceLogo(workspaceId);
    await _seedRuns(workspaceId, agents, spaces);
    await _seedPipelineRuns(workspaceId, spaces);
    await _seedTodos(workspaceId, spaces);
    await _seedTickets(workspaceId, agents);
    await _seedMemory(workspaceId, agents);
    await _seedMemoryPolicies(workspaceId);
    await _seedCalendar(workspaceId);
    await _seedMeetings(workspaceId);
    await _seedArtifacts(workspaceId, agents);
    await _seedActivity(workspaceId, agents);
    await _seedNotifications(workspaceId);
    await _seedInboxAttention(workspaceId, spaces);
    await _seedAiReview(workspaceId, spaces);
    _log('seeded workspace $workspaceId');
  }

  /// The fictional team joins the workspace, so attribution and the roster
  /// render like a team rather than a single anonymous actor.
  Future<void> _seedMembers(String workspaceId) async {
    for (final person in kDemoCast) {
      await _members.upsert(
        WorkspaceMember(
          id: '$workspaceId-${person.id}',
          workspaceId: workspaceId,
          userId: person.id,
          role: WorkspaceRole.member,
          joinedAt: _now().subtract(const Duration(days: 120)),
        ),
      );
    }
  }

  /// One repo row for `parced/closing`.
  ///
  /// It is REQUIRED, not optional: `resolvePrReviewRepository` looks the linked
  /// repo up by `(owner, name)` and throws `Repository is not linked to this
  /// workspace` when it finds none — so without this row every PR page is an
  /// error rather than a demo.
  ///
  /// It is also inert. The path points at nothing, every git-touching port is
  /// null in demo mode, `repos.*` is denied at the op layer and no worktree is
  /// ever provisioned (every seeded space selects zero repos), so nothing
  /// resolves this path on disk.
  Future<void> _seedRepo(String workspaceId) async {
    await _repos.upsert(
      workspaceId,
      Repo(
        id: 'demo-repo-closing',
        name: kDemoRepoFullName,
        path: '/demo/$kDemoRepoName',
        remoteOwner: kDemoRepoOwner,
        remoteName: kDemoRepoName,
        forge: ForgeHost.github,
        createdAt: _now().subtract(const Duration(days: 200)),
        updatedAt: _now().subtract(const Duration(hours: 4)),
      ),
    );
  }

  /// Three flavour agents on top of whatever the product's own seeder created.
  Future<List<Agent>> _seedAgents(String workspaceId) async {
    final specs = <({String id, String name, String title, List<String> skills})>[
      (
        id: 'demo-agent-reviewer',
        name: 'Ravi',
        title: 'Code reviewer',
        skills: ['review', 'dart', 'testing'],
      ),
      (
        id: 'demo-agent-triage',
        name: 'Juno',
        title: 'Triage',
        skills: ['triage', 'support', 'reproduction'],
      ),
      (
        id: 'demo-agent-builder',
        name: 'Wren',
        title: 'Feature work',
        skills: ['implementation', 'refactoring'],
      ),
    ];
    final agents = <Agent>[];
    for (final spec in specs) {
      final agent = Agent(
        id: spec.id,
        name: spec.name,
        title: spec.title,
        agentMdPath: 'agents/${spec.name.toLowerCase()}/AGENTS.md',
        workspaceId: workspaceId,
        skills: AgentSkills(spec.skills),
        createdAt: _now().subtract(const Duration(days: 90)),
        adapterId: 'cc-harness',
      );
      await _agents.upsert(agent);
      agents.add(agent);
    }
    return agents;
  }

  /// Spaces with their conversations and message history.
  ///
  /// Every space selects ZERO repos (`repoIds: const []`), which is what sets
  /// `spaces.no_repos` and short-circuits provisioning to `ready` — no
  /// worktree, no git, no rift. The status is then forced to `ready` directly,
  /// because the background provisioner is not what a pooled workspace should
  /// be waiting on.
  Future<List<({String id, String name})>> _seedSpaces(
    String workspaceId,
    List<Agent> agents,
  ) async {
    final maya = kDemoCast[0];
    final diego = kDemoCast[1];
    final priya = kDemoCast[2];
    final tom = kDemoCast[3];

    final seeds = <({
      String name,
      List<String> agentIds,
      List<({DemoPerson? person, String? agentId, String text, int minutesAgo})>
      messages,
    })>[
      (
        name: 'escrow-review',
        agentIds: [agents[0].id],
        messages: [
          (
            person: maya,
            agentId: null,
            text:
                'Ravi, can you take a first pass on #412? Diego wants to land '
                'it before the release cut.',
            minutesAgo: 340,
          ),
          (
            person: null,
            agentId: agents[0].id,
            text:
              'Reading it now. The deadline calculator itself is clean, but '
              'two closings can share one acceptance date and the extension '
              'path mutates the shared timeline — I think that is the '
              '"deadlines moved on their own" report.\n\nI left a blocking '
              'comment and approved the rest.',
            minutesAgo: 332,
          ),
          (
            person: diego,
            agentId: null,
            text:
                'Good catch. Key the calculator by acceptance event id, or a '
                'lock around the whole timeline?',
            minutesAgo: 300,
          ),
          (
            person: null,
            agentId: agents[0].id,
            text:
                'The key. A lock serializes every closing on the timeline '
                'including the ones whose deadlines are nowhere near expiry, '
                'and the calculator runs on every render of the closing desk.',
            minutesAgo: 296,
          ),
          (
            person: maya,
            agentId: null,
            text: 'Agreed. Diego, want to fold it into this PR?',
            minutesAgo: 240,
          ),
        ],
      ),
      (
        name: 'offer-uploads',
        agentIds: [agents[1].id],
        messages: [
          (
            person: tom,
            agentId: null,
            text:
                'Two brokerages on PD-118 now. Both say inspection PDFs hang '
                'at 99% on big scans. Can we get a read before the broker '
                'sync call?',
            minutesAgo: 1500,
          ),
          (
            person: null,
            agentId: agents[1].id,
            text:
              'It is not hanging. Progress reaches 100% when the last byte '
              'leaves the client, then `_finalize()` waits on a server-side '
              'notarization check — about 30s on a 1GB scan. The bar sits at '
              '99% with no signal that anything is still happening, so '
              'agents cancel an upload that is actually fine.\n\nThat also '
              'explains why the "failed" packets are all present in the '
              'vault.',
            minutesAgo: 1480,
          ),
          (
            person: priya,
            agentId: null,
            text:
              'So it is a reporting bug. I will add a distinct '
              'notarization-pending state rather than a percentage — #401 is '
              'up.',
            minutesAgo: 1400,
          ),
          (
            person: tom,
            agentId: null,
            text:
              'Perfect. I will tell both brokerages their packets are safe.',
            minutesAgo: 1380,
          ),
        ],
      ),
      (
        name: 'closing-digests',
        agentIds: [agents[2].id],
        messages: [
          (
            person: tom,
            agentId: null,
            text:
              'Scheduled closing-date exports is next up — brokers want the '
              'week\'s closings in their inbox. A weekly digest too, if it '
              'is cheap.',
            minutesAgo: 2900,
          ),
          (
            person: null,
            agentId: agents[2].id,
            text:
              'Storage and execution are mostly wiring — `CsvExporter` and '
              '`ClosingExportJob` already exist, and the cron parser from the '
              'pipeline triggers handles the timezone cases.\n\nDelivery is '
              'the only genuinely new piece, and it is where the risk is: an '
              'email to a broker that silently fails is worse than no '
              'feature.',
            minutesAgo: 2880,
          ),
          (
            person: null,
            agentId: agents[2].id,
            text:
              'I would push back on the digest. It sounds small, but one '
              'spanning several closings needs its own composition step and '
              'a different failure story. Single-report schedules first.',
            minutesAgo: 2875,
          ),
          (
            person: tom,
            agentId: null,
            text: 'Fine by me. Ship the simple one.',
            minutesAgo: 2700,
          ),
        ],
      ),
      (
        name: 'general',
        agentIds: const [],
        messages: [
          (
            person: maya,
            agentId: null,
            text:
                'Release cut is Thursday. #412 and #401 are the two I want in.',
            minutesAgo: 90,
          ),
          (
            person: priya,
            agentId: null,
            text:
              '#401 has a failing test — the phase ordering Diego flagged.',
            minutesAgo: 72,
          ),
        ],
      ),
    ];

    final created = <({String id, String name})>[];
    for (final seed in seeds) {
      final space = await _messaging.createSpace(
        workspaceId,
        seed.name,
        seed.agentIds,
        // Explicitly NO repos: this is what sets `no_repos` and keeps
        // provisioning (and therefore git) entirely out of the picture.
        repoIds: const [],
        createdByUserId: kDemoCast.first.id,
      );
      // The background provisioner would get here eventually; a pooled
      // workspace must be ready the moment it is claimed.
      await _dbs
          .of(workspaceId)
          .messagingDao
          .updateSpaceProvisioningStatus(space.id, 'ready');

      for (final person in kDemoCast) {
        await _messaging.addParticipant(
          workspaceId,
          space.id,
          person.id,
          participantType: PrincipalType.user,
        );
      }

      for (final message in seed.messages) {
        await _messaging.sendMessage(
          workspaceId: workspaceId,
          spaceId: space.id,
          content: message.text,
          // A user message needs a REAL user id — the `'user'` sentinel was
          // removed, and messaging throws without one.
          senderId: message.agentId ?? message.person!.id,
          senderType: message.agentId != null ? 'agent' : 'user',
        );
      }
      created.add((id: space.id, name: seed.name));
    }
    return created;
  }

  /// Brands the workspace with the Parced logo.
  ///
  /// One small file per workspace (`<dataDir>/<workspaceId>/logo.png`) and the
  /// `logo_path` the signed `/workspace/logo` endpoint already serves — the
  /// title-bar chip, the workspace switcher and the picker all render the
  /// brand with no outbound fetch and no per-request work.
  Future<void> _seedWorkspaceLogo(String workspaceId) async {
    if (kDemoLogoBase64.isEmpty) {
      return;
    }
    try {
      final dir = Directory('$_dataDir/$workspaceId');
      await dir.create(recursive: true);
      final logo = File('${dir.path}/logo.png');
      if (!logo.existsSync()) {
        await logo.writeAsBytes(base64Decode(kDemoLogoBase64));
      }
      final existing = await _workspaces.getById(workspaceId);
      if (existing == null || existing.logoPath == logo.path) {
        return;
      }
      await _workspaces.upsert(existing.copyWith(logoPath: logo.path));
    } on Object catch (e) {
      _log('demo: could not seed workspace logo: $e');
    }
  }

  /// Finished runs, so the dashboard, cost and observability surfaces have
  /// history rather than a zero state.
  Future<void> _seedRuns(
    String workspaceId,
    List<Agent> agents,
    List<({String id, String name})> spaces,
  ) async {
    final runs = <({Agent agent, int hoursAgo, int seconds, RunCost cost, String summary})>[
      (
        agent: agents[0],
        hoursAgo: 6,
        seconds: 74,
        cost: const RunCost(
          inputTokens: 14820,
          outputTokens: 386,
          cachedReadTokens: 9600,
          cachedWriteTokens: 1280,
          thoughtTokens: 210,
          estimatedCostCents: 6,
        ),
        summary: 'Reviewed #412: 1 blocking comment, 3 nits',
      ),
      (
        agent: agents[1],
        hoursAgo: 25,
        seconds: 131,
        cost: const RunCost(
          inputTokens: 12600,
          outputTokens: 358,
          cachedReadTokens: 8400,
          cachedWriteTokens: 1020,
          thoughtTokens: 140,
          estimatedCostCents: 5,
        ),
        summary: 'Triaged PD-118 to a progress-reporting bug',
      ),
      (
        agent: agents[2],
        hoursAgo: 48,
        seconds: 96,
        cost: const RunCost(
          inputTokens: 9880,
          outputTokens: 420,
          cachedReadTokens: 6100,
          cachedWriteTokens: 1100,
          thoughtTokens: 180,
          estimatedCostCents: 4,
        ),
        summary: 'Broke closing-date exports into four plan nodes',
      ),
      (
        agent: agents[0],
        hoursAgo: 73,
        seconds: 42,
        cost: const RunCost(
          inputTokens: 5200,
          outputTokens: 140,
          cachedReadTokens: 3900,
          estimatedCostCents: 2,
        ),
        summary: 'Reviewed #397: approved',
      ),
    ];

    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      final startedAt = _now().subtract(Duration(hours: run.hoursAgo));
      await _runLogs.upsert(
        AgentRunLog(
          id: 'demo-run-$i',
          agentId: run.agent.id,
          workspaceId: workspaceId,
          spaceId: spaces.isEmpty ? null : spaces[i % spaces.length].id,
          startedAt: startedAt,
          completedAt: startedAt.add(Duration(seconds: run.seconds)),
          status: RunStatus.completed,
          summary: run.summary,
          adapter: 'cc-harness',
          modelId: 'anthropic/claude-sonnet-4-5',
          cost: run.cost,
        ),
      );
    }
  }

  /// Prunes the product's built-in pipeline templates down to the demo's two.
  ///
  /// The base seeder installs thirteen; a demo shows two so the Pipelines
  /// screen reads like a curated example rather than a catalogue. The boot
  /// reconcile is pointed at the SAME whitelist in demo mode (see
  /// `runCcServer`), so it cannot quietly re-add the rest.
  Future<void> _prunePipelineTemplates(String workspaceId) async {
    final templates = await _pipelineTemplates.forWorkspace(workspaceId);
    for (final template in templates) {
      if (!kDemoPipelineTemplateIds.contains(template.templateId)) {
        await _pipelineTemplates.deleteById(
          workspaceId,
          template.templateId,
        );
      }
    }
  }

  /// Finished pipeline runs with real step rows, so the Pipelines surfaces
  /// show history, cost and per-step output instead of an empty state.
  ///
  /// Steps are fabricated against the template's REAL step ids (read back
  /// after pruning), so a run page resolves every step to its definition.
  Future<void> _seedPipelineRuns(
    String workspaceId,
    List<({String id, String name})> spaces,
  ) async {
    final spaceId = spaces.isEmpty ? null : spaces.first.id;
    final byId = <String, PipelineDefinition>{};
    for (final template in await _pipelineTemplates.forWorkspace(workspaceId)) {
      byId[template.templateId] = template;
    }

    final specs = <({
      String runId,
      String templateId,
      int hoursAgo,
      PipelineRunStatus status,
      int costCents,
      int tokens,
      String? error,
    })>[
      (
        runId: 'demo-pipeline-run-0',
        templateId: 'pr_review',
        hoursAgo: 6,
        status: PipelineRunStatus.completed,
        costCents: 6,
        tokens: 15200,
        error: null,
      ),
      (
        runId: 'demo-pipeline-run-1',
        templateId: 'ticket_to_pr',
        hoursAgo: 49,
        status: PipelineRunStatus.failed,
        costCents: 2,
        tokens: 4100,
        error:
            'Step `open_pr` failed: no linked forge credential on this host '
            '(demo) — the ticket branch was left on the workspace.',
      ),
    ];

    for (final spec in specs) {
      final template = byId[spec.templateId];
      if (template == null) {
        continue;
      }
      final startedAt = _now().subtract(Duration(hours: spec.hoursAgo));
      final finishedAt = startedAt.add(const Duration(minutes: 3));
      await _pipelineRuns.insertRun(
        PipelineRun(
          // Globally routed by id, exactly like a ticket — see the note on
          // the ticket seeding above. A fixed id per workspace collided in
          // `workspace_routes` and sent step rows into the wrong database.
          id: '$workspaceId:${spec.runId}',
          templateId: spec.templateId,
          workspaceId: workspaceId,
          status: spec.status,
          triggerEventType: spec.templateId == 'pr_review'
              ? 'PullRequestPublished'
              : null,
          startedAt: startedAt,
          finishedAt: finishedAt,
          activeMs: const Duration(minutes: 3).inMilliseconds,
          errorMessage: spec.error,
          totalCostCents: spec.costCents,
          totalTokens: spec.tokens,
        ),
      );
      final steps = template.steps;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final stepStarted = startedAt.add(Duration(seconds: 20 * i));
        final failedHere = spec.status == PipelineRunStatus.failed &&
            i == steps.length - 1;
        await _pipelineRuns.insertStepRun(
          PipelineStepRun(
            id: '$workspaceId:${spec.runId}-step-$i',
            pipelineRunId: '$workspaceId:${spec.runId}',
            stepId: step.id,
            status: failedHere
                ? PipelineStepStatus.failed
                : PipelineStepStatus.completed,
            inputJson: jsonEncode({
              'source': spec.templateId == 'pr_review' ? '#412' : 'PD-129',
            }),
            outputJson: failedHere
                ? null
                : jsonEncode({
                  'note':
                      spec.templateId == 'pr_review'
                          ? 'review posted, 1 blocking comment'
                          : 'branch created, PR step skipped on demo host',
                }),
            spaceId: spaceId,
            errorMessage: failedHere ? spec.error : null,
            attemptCount: 1,
            startedAt: stepStarted,
            finishedAt: failedHere ? null : stepStarted.add(
              const Duration(seconds: 18),
            ),
          ),
        );
      }
    }
  }

  /// A todo list mid-flight, which is what the accordion is for.
  Future<void> _seedTodos(
    String workspaceId,
    List<({String id, String name})> spaces,
  ) async {
    if (spaces.isEmpty) {
      return;
    }
    final spaceId = spaces.first.id;
    await _todos.setGoal(workspaceId, spaceId, 'Land #412 before the cut');
    final items = <({String text, TodoStatus status})>[
      (text: 'Read the diff on #412', status: TodoStatus.completed),
      (
        text: 'Check the deadline calculator against county holidays',
        status: TodoStatus.completed,
      ),
      (
        text: 'Leave the blocking comment on escrow/timeline.dart',
        status: TodoStatus.completed,
      ),
      (
        text: 'Re-review once acceptance-event keying lands',
        status: TodoStatus.inProgress,
      ),
      (
        text: 'Confirm the shared-acceptance case has a test',
        status: TodoStatus.pending,
      ),
    ];
    for (final item in items) {
      final created = await _todos.append(workspaceId, spaceId, item.text);
      if (item.status != TodoStatus.pending) {
        await _todos.updateStatus(workspaceId, spaceId, created.id, item.status);
      }
    }
  }

  /// A project and its tickets, including the one the triage script resolves.
  Future<void> _seedTickets(String workspaceId, List<Agent> agents) async {
    final now = _now();
    await _projects.insert(
      Project(
        id: 'demo-project-parced',
        workspaceId: workspaceId,
        name: 'Parced Q3',
        description: 'Closing-day readiness.',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
    );

    final tickets = <({
      String key,
      String title,
      String body,
      TicketStatus status,
      TicketPriority priority,
      String? agentId,
      int daysAgo,
    })>[
      (
        key: 'PD-118',
        title: 'Inspection PDFs hang at 99% on large scans',
        body:
            'Two brokerages reported inspection and disclosure packets '
            'hanging at 99% on scans over 1GB.\n\n'
            'Not a transfer bug: progress reaches 100% when the last byte '
            'leaves the client, then `_finalize()` waits on a server-side '
            'notarization check for ~30s with no signal. The uploads '
            'complete; the bar just stops moving, so agents cancel.\n\nFix '
            'is a distinct "notarization pending" state rather than a '
            'percentage.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        agentId: agents[1].id,
        daysAgo: 6,
      ),
      (
        key: 'PD-121',
        title: 'Upload appears stuck near the end (duplicate of PD-118)',
        body: 'Same root cause as PD-118. Linked and closed.',
        status: TicketStatus.cancelled,
        priority: TicketPriority.low,
        agentId: null,
        daysAgo: 5,
      ),
      (
        key: 'PD-124',
        title: 'Contingency deadlines should warn before they lapse',
        body:
            'Deadlines are computed on render, so nobody sees a financing '
            'contingency lapse until the day of. #412 moves them onto the '
            'escrow timeline with a days-remaining chip.',
        status: TicketStatus.inReview,
        priority: TicketPriority.high,
        agentId: agents[0].id,
        daysAgo: 4,
      ),
      (
        key: 'PD-129',
        title: 'Scheduled closing-date exports for brokers',
        body:
            'Save a schedule against the week\'s closings and deliver it to '
            'the broker. Delivery needs its own log and a visible failure '
            'state — a silent email failure to a broker is worse than no '
            'feature.',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        agentId: agents[2].id,
        daysAgo: 3,
      ),
      (
        key: 'PD-131',
        title: 'Escrow window test is flaky across the business-day boundary',
        body:
            'The test calls `DateTime.now()` directly, so a run that crosses '
            'a real business-day boundary drops the first record out of the '
            'window.',
        status: TicketStatus.done,
        priority: TicketPriority.low,
        agentId: agents[2].id,
        daysAgo: 2,
      ),
      (
        key: 'PD-136',
        title: 'Weekly broker digest spanning multiple closings',
        body:
            'Deliberately split out of PD-129. Needs its own composition step.',
        status: TicketStatus.backlog,
        priority: TicketPriority.none,
        agentId: null,
        daysAgo: 1,
      ),
    ];

    for (final ticket in tickets) {
      final createdAt = now.subtract(Duration(days: ticket.daysAgo));
      await _tickets.insert(
        Ticket(
          // The id must be unique ACROSS WORKSPACES, not just within one.
          // Ticket ids resolve through the global `workspace_routes` index
          // (and a route cache), so seeding the same `PD-124` into every
          // pooled workspace pointed that key at whichever workspace wrote it
          // first — one visitor's ticket writes landing in another's database.
          // The KEY stays human-readable; it is what the wire's `key` field
          // and the UI show.
          id: '$workspaceId:${ticket.key}',
          externalKey: ticket.key,
          workspaceId: workspaceId,
          title: ticket.title,
          description: ticket.body,
          status: ticket.status,
          priority: ticket.priority,
          projectId: 'demo-project-parced',
          assignedAgentId: ticket.agentId,
          createdAt: createdAt,
          updatedAt: now.subtract(const Duration(hours: 2)),
          completedAt: ticket.status == TicketStatus.done
              ? now.subtract(const Duration(hours: 20))
              : null,
        ),
      );
    }
  }

  /// Facts the agents have accumulated, so the memory surface has substance.
  ///
  /// No embeddings: the demo runs FTS-only, which is the documented degrade
  /// while the on-device model is absent.
  Future<void> _seedMemory(String workspaceId, List<Agent> agents) async {
    final facts = <({String domain, String topic, String content})>[
      (
        domain: 'codebase',
        topic: 'escrow timeline',
        content:
            'The escrow timeline in lib/escrow/ is shared by the broker '
            'portal and the closing desk. Changes there need both suites run.',
      ),
      (
        domain: 'codebase',
        topic: 'batch size',
        content:
            'MLS sync batch size is 256 since #397 — 41s to 12s on the '
            '40k-listing corpus with unchanged peak RSS.',
      ),
      (
        domain: 'team',
        topic: 'release cadence',
        content: 'Release cuts are Thursdays. Maya decides what makes the cut.',
      ),
      (
        domain: 'team',
        topic: 'review norms',
        content:
            'Diego prefers a blocking comment with a concrete alternative over '
            'a request-changes with no suggestion.',
      ),
      (
        domain: 'law',
        topic: 'contingency windows',
        content:
            'Contingency windows are business days and skip county holidays: '
            'inspection 10, financing 21, title 14 — all counted from offer '
            'acceptance, never from list date.',
      ),
      (
        domain: 'product',
        topic: 'upload finalizing',
        content:
            'Inspection packets over ~1GB spend up to 30s in server-side '
            'notarization after the transfer completes. Any progress UI must '
            'show that phase.',
      ),
      (
        domain: 'product',
        topic: 'digest scope',
        content:
            'Weekly broker digests were split out of closing exports (PD-136): '
            'a digest spanning several closings needs its own composition and '
            'failure story.',
      ),
    ];
    final repo = _dbs.of(workspaceId).memoryFactDao;
    for (var i = 0; i < facts.length; i++) {
      final fact = facts[i];
      final createdAt = _now().subtract(Duration(days: 20 - i));
      await repo.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'demo-fact-$i',
          workspaceId: workspaceId,
          domain: fact.domain,
          topic: fact.topic,
          content: fact.content,
          createdAt: drift.Value(createdAt),
          updatedAt: drift.Value(createdAt),
          authoredByAgentId: drift.Value(agents[i % agents.length].id),
        ),
      );
    }
  }

  /// The rules the team has agreed about how memory is used.
  ///
  /// Policies are the governance half of the memory surface: facts are what an
  /// agent learned, policies are what it is allowed to do with them. Seeding
  /// only facts left that half as an empty state.
  Future<void> _seedMemoryPolicies(String workspaceId) async {
    final policies = <({String domain, String rule, AgentRole? role})>[
      (
        domain: 'product',
        rule:
            'Client names, property addresses and account identifiers never '
            'enter a memory fact. Describe the case and the county, not the '
            'closing.',
        role: null,
      ),
      (
        domain: 'codebase',
        rule:
            'A performance claim needs the measurement that produced it — the '
            'corpus, the before and the after. An unmeasured claim is an '
            'opinion and should be recorded as one.',
        role: null,
      ),
      (
        domain: 'team',
        rule:
            'Facts about how a person prefers to work are recorded only when '
            'they said so themselves, never inferred from behaviour.',
        role: null,
      ),
      (
        domain: 'product',
        rule:
            'A closing-date commitment is only durable once the escrow '
            'officer has confirmed it; anything earlier is recorded as a '
            'proposal.',
        role: AgentRole.ceo,
      ),
    ];
    final repo = DaoMemoryPolicyRepository(_dbs);
    for (var i = 0; i < policies.length; i++) {
      final policy = policies[i];
      final at = _now().subtract(Duration(days: 30 - i * 3));
      await repo.upsert(
        MemoryPolicy(
          id: 'demo-policy-$i',
          workspaceId: workspaceId,
          domain: policy.domain,
          rule: policy.rule,
          requiredRole: policy.role,
          createdAt: at,
          updatedAt: at,
        ),
      );
    }
  }

  /// A working week around today.
  ///
  /// The account is `providerId: 'local'` and there is exactly one — a source
  /// and an event both FK to `calendar_accounts`, so a demo cannot seed a
  /// calendar without one. `'local'` is what keeps the Google stack from ever
  /// being constructed for it, and calendar sync is not started in demo mode
  /// anyway.
  Future<void> _seedCalendar(String workspaceId) async {
    final repo = DaoCalendarRepository(_dbs);
    const accountId = 'demo-calendar-account';
    const calendarId = 'demo-calendar-primary';

    await repo.upsertAccount(
      CalendarAccount(
        id: accountId,
        workspaceId: workspaceId,
        providerId: 'local',
        accountEmail: 'ops@parced.invalid',
        displayName: 'Parced',
        lastSyncedAt: _now().subtract(const Duration(minutes: 12)),
      ),
    );
    await repo.upsertSources(
      workspaceId: workspaceId,
      accountId: accountId,
      sources: const [
        CalendarSource(
          workspaceId: '',
          accountId: accountId,
          id: calendarId,
          summary: 'Parced',
          primary: true,
          writable: true,
        ),
      ],
    );

    // Anchored to the START OF TODAY rather than to "now", so the week reads
    // like a calendar week whatever hour a visitor arrives — a stand-up at
    // "three hours from now" at 23:00 is not a demo, it is a puzzle.
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);

    final events =
        <({
          String id,
          String title,
          int dayOffset,
          int startHour,
          int minutes,
          String? location,
          String? meetingUrl,
          String? description,
        })>[
          (
            id: 'standup-mon',
            title: 'Daily stand-up',
            dayOffset: -1,
            startHour: 9,
            minutes: 15,
            location: null,
            meetingUrl: 'https://meet.invalid/parced-standup',
            description: 'What landed, what is blocked.',
          ),
          (
            id: 'standup-today',
            title: 'Daily stand-up',
            dayOffset: 0,
            startHour: 9,
            minutes: 15,
            location: null,
            meetingUrl: 'https://meet.invalid/parced-standup',
            description: 'What landed, what is blocked.',
          ),
          (
            id: 'escrow-review',
            title: 'Escrow review — Parced Q3',
            dayOffset: 0,
            startHour: 14,
            minutes: 45,
            location: 'The long room',
            meetingUrl: null,
            description:
                'Cut list: #412 (contingency deadlines) and #401 '
                '(notarization state). #408 is draft and will not make it.',
          ),
          (
            id: 'design-sync',
            title: 'Upload states — design sync',
            dayOffset: 1,
            startHour: 11,
            minutes: 30,
            location: null,
            meetingUrl: 'https://meet.invalid/parced-design',
            description:
                'Deciding the copy for the notarization-pending state on '
                'PD-118.',
          ),
          (
            id: 'walkthrough',
            title: 'Final walkthrough — 482 Pine St #4',
            dayOffset: 2,
            startHour: 10,
            minutes: 60,
            location: '482 Pine Street',
            meetingUrl: null,
            description: 'Buyer walkthrough before the Thursday closing.',
          ),
          (
            id: 'cut',
            title: 'Release cut',
            dayOffset: 4,
            startHour: 16,
            minutes: 30,
            location: null,
            meetingUrl: null,
            description: 'Tag and ship whatever is green.',
          ),
          (
            id: 'retro',
            title: 'Retro',
            dayOffset: 6,
            startHour: 15,
            minutes: 60,
            location: 'The long room',
            meetingUrl: null,
            description: null,
          ),
          (
            id: 'onboarding',
            title: 'Onboarding — new escrow ops hire',
            dayOffset: 8,
            startHour: 10,
            minutes: 90,
            location: null,
            meetingUrl: 'https://meet.invalid/parced-onboarding',
            description: null,
          ),
        ];

    await repo.upsertEvents([
      for (final event in events)
        CalendarEvent(
          id: 'demo-event-${event.id}',
          workspaceId: workspaceId,
          accountId: accountId,
          externalEventId: 'demo-${event.id}',
          calendarId: calendarId,
          title: event.title,
          description: event.description,
          location: event.location,
          meetingUrl: event.meetingUrl,
          startTime: today
              .add(Duration(days: event.dayOffset))
              .add(Duration(hours: event.startHour)),
          endTime: today
              .add(Duration(days: event.dayOffset))
              .add(Duration(hours: event.startHour, minutes: event.minutes)),
          updatedAt: now.subtract(const Duration(hours: 3)),
          attendees: [
            for (final person in kDemoCast)
              CalendarAttendee(
                email: '${person.handle}@parced.invalid',
                displayName: person.displayName,
                responseStatus: 'accepted',
                organizer: person.id == kDemoCast.first.id,
              ),
          ],
        ),
    ]);
  }

  /// Two finished meetings with transcripts, speakers, decisions and actions.
  ///
  /// `audioPath` is deliberately NULL: the recording lane needs a WAV on disk
  /// and a speech model, the demo ships neither, and `/meeting/audio` 404ing
  /// into the client's documented no-playback fallback is the honest outcome —
  /// far better than shipping audio bytes in the image.
  Future<void> _seedMeetings(String workspaceId) async {
    final repo = DaoMeetingRepository(_dbs);
    final now = _now();

    final meetings =
        <({
          String id,
          String title,
          int hoursAgo,
          int minutes,
          String summary,
          List<({bool me, String label, String text})> transcript,
          List<String> decisions,
          List<({String content, String owner, bool done})> actions,
        })>[
          (
            id: 'escrow-review',
            title: 'Escrow review — Parced Q3',
            hoursAgo: 26,
            minutes: 42,
            summary:
                'Agreed the Q3 cut is #412 and #401. #408 stays draft. The '
                'open question on #412 — two closings sharing one acceptance '
                'date — is a blocker, and Diego is keying the calculator by '
                'acceptance event rather than deferring it. PD-118 turned out '
                'to be a progress-reporting bug, so the fix is copy and a new '
                'upload phase rather than transfer work.',
            transcript: [
              (
                me: true,
                label: 'Maya',
                text:
                    'Let us start with the cut. I want 412 and 401 in, and I '
                    'do not want 408 anywhere near it.',
              ),
              (
                me: false,
                label: 'Diego',
                text:
                    '412 has Ravi\'s blocking comment on it. Two closings can '
                    'share an acceptance date, and an extension on one shifts '
                    'the other\'s deadlines.',
              ),
              (
                me: true,
                label: 'Maya',
                text: 'Is that the "deadlines moved on their own" report?',
              ),
              (
                me: false,
                label: 'Diego',
                text:
                    'I think so. It only shows up when a broker re-accepts '
                    'after an amendment, which is exactly when both closings '
                    'recompute at once.',
              ),
              (
                me: true,
                label: 'Maya',
                text:
                    'Then it is a blocker. Key the calculator by acceptance '
                    'event in this PR — I do not want to ship the fix for a '
                    'bug and the bug in the same release.',
              ),
              (
                me: false,
                label: 'Priya',
                text:
                    'On 401 — it is not a transfer bug at all. Progress hits '
                    'a hundred percent when the last byte leaves, then the '
                    'server notarization check runs for thirty seconds with '
                    'no signal.',
              ),
              (
                me: false,
                label: 'Tom',
                text:
                    'So the packets brokers cancelled were fine the whole '
                    'time. I can tell both of them today.',
              ),
              (
                me: false,
                label: 'Priya',
                text:
                    'Right. I am adding an explicit notarization-pending '
                    'phase instead of a percentage. The copy is the part I '
                    'want a second opinion on.',
              ),
            ],
            decisions: [
              'Parced Q3 ships #412 and #401. #408 stays draft.',
              'The acceptance-event keying lands in #412, not a follow-up.',
              'PD-118 is fixed with an explicit upload phase, not transfer work.',
            ],
            actions: [
              (
                content: 'Key the deadline calculator by acceptance event in #412',
                owner: 'Diego',
                done: false,
              ),
              (
                content: 'Tell both PD-118 brokerages their packets completed',
                owner: 'Tom',
                done: true,
              ),
              (
                content: 'Write the notarization-pending copy for review',
                owner: 'Priya',
                done: false,
              ),
            ],
          ),
          (
            id: 'closing-digests-kickoff',
            title: 'Closing-date exports — scoping',
            hoursAgo: 74,
            minutes: 28,
            summary:
                'Scheduled closing-date exports is mostly wiring over the '
                'existing exporter and cron parser. Delivery is the only new '
                'piece and needs its own log and a visible failure state. The '
                'weekly broker digest was split out as PD-136 rather than '
                'folded in.',
            transcript: [
              (
                me: false,
                label: 'Tom',
                text:
                    'Scheduled closing exports is next. And a weekly digest '
                    'too, if it is cheap.',
              ),
              (
                me: true,
                label: 'Maya',
                text:
                    'Storage and execution are nearly free — the exporter and '
                    'the job already exist, and the cron parser from the '
                    'pipeline triggers handles the timezone cases.',
              ),
              (
                me: true,
                label: 'Maya',
                text:
                    'Delivery is where the risk is. An email to a broker that '
                    'silently fails is worse than not having the feature.',
              ),
              (
                me: false,
                label: 'Tom',
                text: 'What does that cost us?',
              ),
              (
                me: true,
                label: 'Maya',
                text:
                    'A delivery log and a failure state people can see. Which '
                    'is also why I want the digest separate — a digest across '
                    'several closings has a different failure story.',
              ),
              (
                me: false,
                label: 'Tom',
                text: 'Fine. Ship the simple one first.',
              ),
            ],
            decisions: [
              'Single-closing schedules ship first; the digest is PD-136.',
              'Delivery gets its own log and a visible failure state.',
            ],
            actions: [
              (
                content: 'Break closing exports into plan nodes',
                owner: 'Maya',
                done: true,
              ),
              (
                content: 'Spec the delivery failure state',
                owner: 'Maya',
                done: false,
              ),
            ],
          ),
        ];

    for (final meeting in meetings) {
      final startedAt = now.subtract(Duration(hours: meeting.hoursAgo));
      final endedAt = startedAt.add(Duration(minutes: meeting.minutes));
      final meetingId = 'demo-meeting-${meeting.id}';

      await repo.upsert(
        Meeting(
          id: meetingId,
          workspaceId: workspaceId,
          title: meeting.title,
          titleIsCustom: true,
          status: MeetingStatus.done,
          mode: MeetingMode.remote,
          sourceApp: 'Meet',
          startedAt: startedAt,
          endedAt: endedAt,
          createdAt: startedAt,
          updatedAt: endedAt,
          summary: meeting.summary,
          // No audio ships with the demo — see the method doc.
          audioPath: null,
        ),
      );

      // Segments are paced across the real duration so the transcript scrubber
      // has something proportionate to scrub.
      final step = (meeting.minutes * 60 * 1000) ~/ (meeting.transcript.length + 1);
      for (var i = 0; i < meeting.transcript.length; i++) {
        final line = meeting.transcript[i];
        await repo.appendSegment(
          MeetingSegment(
            id: '$meetingId-segment-$i',
            meetingId: meetingId,
            workspaceId: workspaceId,
            speaker: line.me ? MeetingSpeaker.me : MeetingSpeaker.them,
            speakerLabel: line.label,
            text: line.text,
            startMs: step * i,
            endMs: step * (i + 1),
            createdAt: startedAt.add(Duration(milliseconds: step * i)),
          ),
        );
      }

      final labels = <String>{
        for (final line in meeting.transcript) line.label,
      }.toList();
      await repo.replaceSpeakers(workspaceId, meetingId, [
        for (var i = 0; i < labels.length; i++)
          MeetingSpeakerLabel(
            id: '$meetingId-speaker-$i',
            meetingId: meetingId,
            workspaceId: workspaceId,
            channel: labels[i] == 'Maya'
                ? MeetingSpeaker.me
                : MeetingSpeaker.them,
            label: labels[i],
            displayName: labels[i],
            createdAt: startedAt,
          ),
      ]);

      for (var i = 0; i < meeting.decisions.length; i++) {
        await repo.addDecision(
          MeetingDecision(
            id: '$meetingId-decision-$i',
            meetingId: meetingId,
            workspaceId: workspaceId,
            content: meeting.decisions[i],
            sortOrder: i,
            createdAt: endedAt,
          ),
        );
      }
      for (var i = 0; i < meeting.actions.length; i++) {
        final action = meeting.actions[i];
        await repo.addActionItem(
          MeetingActionItem(
            id: '$meetingId-action-$i',
            meetingId: meetingId,
            workspaceId: workspaceId,
            content: action.content,
            owner: action.owner,
            done: action.done,
            sortOrder: i,
            createdAt: endedAt,
          ),
        );
      }
    }
  }

  /// Work products (the artifacts surface): versioned documents an agent
  /// produced against a ticket, with one human revision on top so the
  /// revision history renders.
  Future<void> _seedArtifacts(String workspaceId, List<Agent> agents) async {
    final now = _now();
    final artifacts = <({
      String id,
      String title,
      WorkProductType type,
      String ticketId,
      String agentId,
      String content,
      String humanEdit,
      int hoursAgo,
    })>[
      (
        id: 'demo-artifact-checklist',
        title: 'Closing checklist — 482 Pine St #4',
        type: WorkProductType.document,
        ticketId: '$workspaceId:PD-124',
        agentId: agents[2].id,
        content:
            '# Closing checklist — 482 Pine St #4\n\n'
            '## Contingencies\n\n'
            '- [x] Inspection (lapsed @-2d — waived in writing)\n'
            '- [x] Financing commitment received\n'
            '- [ ] Title exceptions reviewed by county counsel\n\n'
            '## Paperwork\n\n'
            '- [x] Purchase agreement (v3, countersigned)\n'
            '- [ ] Escrow instructions — awaiting broker signature\n'
            '- [ ] Owner\'s title policy ordered\n\n'
            '## Notes\n\n'
            'Acceptance date is the anchor for every deadline on the file. '
            'The financing contingency window skips the county holiday on '
            'the 14th.',
        humanEdit:
            '# Closing checklist — 482 Pine St #4\n\n'
            '## Contingencies\n\n'
            '- [x] Inspection (lapsed @-2d — waived in writing)\n'
            '- [x] Financing commitment received\n'
            '- [ ] Title exceptions reviewed by county counsel\n\n'
            '## Paperwork\n\n'
            '- [x] Purchase agreement (v3, countersigned)\n'
            '- [ ] Escrow instructions — awaiting broker signature\n'
            '- [ ] Owner\'s title policy ordered\n\n'
            '## Notes\n\n'
            'Acceptance date is the anchor for every deadline on the file. '
            'The financing contingency window skips the county holiday on '
            'the 14th.\n\n'
            '> Escrow officer confirmed the closing slot by phone — keep the '
            'paper trail in the file, not in memory.',
        hoursAgo: 30,
      ),
      (
        id: 'demo-artifact-comps',
        title: 'Comparable sales analysis — 1150 Elm St',
        type: WorkProductType.report,
        ticketId: '$workspaceId:PD-129',
        agentId: agents[0].id,
        content:
            '# Comparable sales — 1150 Elm St\n\n'
            'Five closed comparables within 0.4 mi over the last 90 days:\n\n'
            '| Address | Closed | Beds/Baths | Sq ft | USD/sq ft |\n'
            '|---|---|---|---|---|\n'
            '| 482 Pine St #4 | @-2d | 3/2 | 1,410 | 426 |\n'
            '| 911 Alder Ave | @-9d | 3/1.5 | 1,280 | 402 |\n'
            '| 30 Birch Ln | @-12d | 4/2 | 1,660 | 398 |\n'
            '| 1240 Fir St | @-13d | 2/2 | 1,050 | 411 |\n'
            '| 77 Cedar Ct | @-13d | 3/2 | 1,390 | 389 |\n\n'
            'Subject lists at 418 USD per sq ft — inside the band, slightly '
            'the street median. No price-change history in the last 60 days.',
        humanEdit: '',
        hoursAgo: 77,
      ),
    ];

    for (final artifact in artifacts) {
      final createdAt = now.subtract(Duration(hours: artifact.hoursAgo));
      final rev1Id = '${artifact.id}-rev-1';
      final rev2Id = '${artifact.id}-rev-2';
      final humanEdited = artifact.humanEdit.isNotEmpty;
      await _workProducts.upsert(
        WorkProduct(
          id: artifact.id,
          workspaceId: workspaceId,
          title: artifact.title,
          artifactType: artifact.type,
          ticketId: artifact.ticketId,
          agentId: artifact.agentId,
          currentRevisionId: humanEdited ? rev2Id : rev1Id,
          createdAt: createdAt,
          updatedAt: now.subtract(const Duration(hours: 6)),
        ),
      );
      await _workProducts.addRevision(
        WorkProductRevision(
          id: rev1Id,
          workProductId: artifact.id,
          workspaceId: workspaceId,
          revisionNumber: 1,
          content: artifact.content,
          authorType: 'agent',
          authorId: artifact.agentId,
          summary: 'Initial draft',
          createdAt: createdAt,
        ),
      );
      if (humanEdited) {
        await _workProducts.addRevision(
          WorkProductRevision(
            id: rev2Id,
            workProductId: artifact.id,
            workspaceId: workspaceId,
            revisionNumber: 2,
            content: artifact.humanEdit,
            baseRevisionId: rev1Id,
            authorType: 'user',
            authorId: kDemoCast.first.id,
            summary: 'Added escrow-officer confirmation note',
            createdAt: now.subtract(const Duration(hours: 6)),
          ),
        );
      }
    }
  }

  /// An audit trail across the last two weeks.
  Future<void> _seedActivity(String workspaceId, List<Agent> agents) async {
    final dao = _dbs.of(workspaceId).activityLogDao;
    final entries = <({String action, String entityType, String entityId, int hoursAgo})>[
      (action: 'run.completed', entityType: 'agent_run', entityId: 'demo-run-0', hoursAgo: 6),
      (action: 'ticket.status_changed', entityType: 'ticket', entityId: 'PD-118', hoursAgo: 25),
      (action: 'review.submitted', entityType: 'pull_request', entityId: 'PR_412', hoursAgo: 6),
      (action: 'run.completed', entityType: 'agent_run', entityId: 'demo-run-1', hoursAgo: 25),
      (action: 'ticket.created', entityType: 'ticket', entityId: 'PD-129', hoursAgo: 72),
      (action: 'run.completed', entityType: 'agent_run', entityId: 'demo-run-2', hoursAgo: 48),
      (action: 'pr.merged', entityType: 'pull_request', entityId: 'PR_397', hoursAgo: 216),
    ];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      await dao.insertEntry(
        ActivityLogTableCompanion.insert(
          id: 'demo-activity-$i',
          workspaceId: drift.Value(workspaceId),
          actorType: 'agent',
          // `actorId` FKs `agents.id`, so it must name a row that exists.
          actorId: drift.Value(agents[i % agents.length].id),
          action: entry.action,
          entityType: entry.entityType,
          entityId: drift.Value(entry.entityId),
          createdAt: drift.Value(_now().subtract(Duration(hours: entry.hoursAgo))),
        ),
      );
    }
  }

  /// A few unread notifications, so the inbox is not an empty state.
  Future<void> _seedNotifications(String workspaceId) async {
    final dao = _dbs.of(workspaceId).notificationFeedDao;
    final items = <({String method, Map<String, dynamic> params, int hoursAgo})>[
      (
        method: 'pr.review_requested',
        params: {
          'title': 'Maya requested your review on #412',
          'repo': kDemoRepoFullName,
          'pr_number': 412,
        },
        hoursAgo: 5,
      ),
      (
        method: 'ticket.assigned',
        params: {'title': 'PD-129 assigned to Wren', 'ticket_key': 'PD-129'},
        hoursAgo: 30,
      ),
      (
        method: 'pr.checks_failed',
        params: {
          'title': 'Checks failed on #401',
          'repo': kDemoRepoFullName,
          'pr_number': 401,
        },
        hoursAgo: 26,
      ),
      (
        method: 'meeting.summary_ready',
        params: {
          'title': 'Summary ready — Escrow review',
          'meeting_id': 'demo-meeting-escrow-review',
        },
        hoursAgo: 25,
      ),
      (
        method: 'agent.run_completed',
        params: {
          'title': 'Ravi finished reviewing #412',
          'agent_id': 'demo-agent-reviewer',
          'run_id': 'demo-run-0',
        },
        hoursAgo: 6,
      ),
      (
        method: 'calendar.starting_soon',
        params: {
          'title': 'Daily stand-up starts in 10 minutes',
          'event_id': 'demo-event-standup-today',
        },
        hoursAgo: 2,
      ),
      (
        method: 'memory.conflict_detected',
        params: {
          'title': 'Two facts disagree about the MLS batch size',
          'domain': 'codebase',
        },
        hoursAgo: 48,
      ),
    ];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await dao.insertAndPrune(
        NotificationFeedTableCompanion.insert(
          id: 'demo-notification-$i',
          workspaceId: workspaceId,
          method: item.method,
          paramsJson: jsonEncode(item.params),
          createdAt: drift.Value(_now().subtract(Duration(hours: item.hoursAgo))),
        ),
      );
    }
  }

  /// The inbox's attention strip: one agent BLOCKED on an approval (the live
  /// confirmation registry the phone and inbox both read) and one ticket-sync
  /// failure log row.
  ///
  /// The confirmation is registered with NO timeout so it stays pending until
  /// a visitor approves or denies it — `confirmation.respond` is allowed in
  /// the demo profile, and resolving it is exactly the interaction the inbox
  /// lane exists to showcase. It is in-memory by design (it is a LIVE lane),
  /// so a server restart simply drops it; the next pooled workspace brings a
  /// fresh one.
  Future<void> _seedInboxAttention(
    String workspaceId,
    List<({String id, String name})> spaces,
  ) async {
    final reviewSpace = spaces
        .where((s) => s.name == 'escrow-review')
        .firstOrNull;
    final register = _registerConfirmation;
    if (register != null && reviewSpace != null) {
      register(
        ConfirmationRequest(
          spaceId: reviewSpace.id,
          workspaceId: workspaceId,
          title: 'Juno wants to run the title-exception sweep on 1150 Elm St',
          detail:
              'The sweep reads county records for the title report on '
              'PD-124. It makes about 40 paginated requests to the county '
              'recorder site — approve to let it run once.',
          severity: ConfirmationSeverity.warning,
          command:
              'bin/title_sweep --county multnomah --file 1150-elm '
              '--years 2019..2026',
        ),
      );
    }

    await _syncLog.append(
      TicketSyncLogEntry(
        id: 'demo-synclog-0',
        workspaceId: workspaceId,
        ticketId: '$workspaceId:PD-124',
        vendor: 'linear',
        direction: SyncDirection.push,
        outcome: SyncOutcome.failed,
        message:
            'Push failed: Linear issue was closed on the vendor side '
            '(PD-124 mirrors as ESC-418). Reopen there or relink before the '
            'next sync.',
        createdAt: _now().subtract(const Duration(hours: 20)),
      ),
    );
  }

  // ── Pull requests ────────────────────────────────────────────────────────

  /// Writes the authored PR world into the `caches` table.
  ///
  /// The rows are stored under the SAME kinds and keys the production cache
  /// uses, so `DemoPrReviewRepository` decodes them with the real
  /// `PrCacheCodec.*FromCache` functions.
  Future<void> _seedPullRequests(String workspaceId) async {
    final world = jsonDecode(kDemoPullRequestsJson) as Map<String, dynamic>;
    final cache = _dbs.of(workspaceId).cacheDao;
    final resolved = _resolveDates(world) as Map<String, dynamic>;

    Future<void> put(String kind, String key, Object? payload) => cache.put(
      workspaceId,
      kind,
      key,
      payload is String ? payload : jsonEncode(payload),
    );

    await put(
      DemoPrCacheKind.assignableUsers,
      kDemoRepoFullName,
      resolved['assignable_users'],
    );
    await put(
      DemoPrCacheKind.requestableTeams,
      kDemoRepoFullName,
      resolved['requestable_teams'],
    );

    final openList = <Map<String, dynamic>>[];
    for (final raw in resolved['pull_requests'] as List) {
      final pr = Map<String, dynamic>.from(raw as Map);
      final detail = Map<String, dynamic>.from(pr['detail'] as Map);
      final number = detail['number'] as int;
      final key = demoPrCacheKey(kDemoRepoFullName, number);

      await put(DemoPrCacheKind.detail, key, detail);
      // The diff is stored as RAW text, matching the production cache.
      await put(DemoPrCacheKind.diff, key, pr['diff'] as String? ?? '');
      await put(DemoPrCacheKind.files, key, pr['files']);
      await put(DemoPrCacheKind.commits, key, pr['commits']);
      await put(DemoPrCacheKind.reviews, key, pr['reviews']);
      await put(DemoPrCacheKind.reviewComments, key, pr['review_comments']);
      await put(DemoPrCacheKind.issueComments, key, pr['issue_comments']);
      await put(DemoPrCacheKind.timelineEvents, key, pr['timeline']);
      await put(DemoPrCacheKind.checkRuns, key, pr['check_runs']);
      await put(DemoPrCacheKind.commitStatuses, key, pr['commit_statuses']);
      await put(DemoPrCacheKind.reviewerState, key, pr['reviewers']);

      if (detail['state'] == 'open') {
        openList.add(detail);
      }
    }

    // The snapshot `pr.watchOpenForWorkspace` follows. Without the demo's
    // no-op poller this row would never be read (a null poller short-circuits
    // to a signed-out empty list before touching the cache) and without the
    // row the poller would emit an authenticated-but-empty list.
    await put(DemoPrCacheKind.openPrList, DemoPrCacheKind.openPrListKey, {
      'authenticated': true,
      'repos': [
        {
          'repo_id': 'demo-repo-closing',
          'repo_full_name': kDemoRepoFullName,
          'pull_requests': openList,
        },
      ],
    });
  }

  // ── Per-visitor, in the GLOBAL database ──────────────────────────────────

  /// Seeds the newsfeed, which is keyed by USER rather than by workspace.
  ///
  /// The feeds are REAL: the demo fetches actual articles server-side (see
  /// the refresh hook wired from the runtime), and the feed-management verbs
  /// stay denied at the op layer so a visitor reads but never edits. The one
  /// fictional feed carries fallback articles so the surface never renders
  /// empty when the container has no egress. It lives in `global.db`, so
  /// dropping a visitor's workspace file cannot reach it — the reaper deletes
  /// these rows explicitly (and the `users` FK cascades as a second net).
  Future<void> seedUser(String userId, String workspaceId) async {
    // The product's OWN default feeds, verbatim — no demo-specific list.
    // A fictional in-house feed used to sit at the top carrying two hardcoded
    // articles, so the surface would render without egress. It cost a
    // guaranteed-failing DNS lookup per visitor (its host is `.invalid`, which
    // by RFC 2606 never resolves) and it showed a visitor two posts that no
    // link opened. Real feeds are both honest and better-looking: they arrive
    // with images.
    for (final feed in kDefaultFeeds) {
      await _globalDb.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: '$userId-feed-${_slug(feed.url)}',
          // FKs `users.id ON DELETE CASCADE` — the visitor's row already
          // exists by the time this runs.
          userId: userId,
          name: feed.name,
          url: feed.url,
        ),
      );
    }

    // Articles within seconds of the claim, not on the next 30-minute sweep.
    // Fire-and-forget: nothing downstream waits on it, and a container with no
    // egress simply opens on an empty newsfeed rather than a broken one.
    final refresh = _refreshNewsfeed;
    if (refresh != null) {
      unawaited(
        refresh(userId).catchError((Object _) {}),
      );
    }
  }

  /// The AI review on PR #412 — cohorts (what changed, grouped) plus the axis
  /// verdicts the merge gate reads.
  ///
  /// Without these rows the review tab renders its own empty state, which on a
  /// demo reads as "the feature does nothing" rather than "no review has been
  /// run". The verdicts are deliberately NOT all green: an axis panel where
  /// everything passes shows none of the triage the surface exists for, so
  /// `testGap` warns (the PR is where the reviewer thread already argues about
  /// a missing business-day case) and `correctness` carries the one finding
  /// that #412's blocking comment is about.
  Future<void> _seedAiReview(
    String workspaceId,
    List<({String id, String name})> spaces,
  ) async {
    const prExternalId = kDemoReviewPrExternalId;

    // The association FIRST, and not as decoration: `resolvePrExternalId` is
    // association-first and falls back to a live `getPullRequest` against the
    // forge. A demo has no forge, so without this row every studio watch ends
    // in `NetworkException(not_found)` — the seeded rows would sit in the
    // database and the review tab would still show nothing.
    final reviewSpace = spaces
        .where((s) => s.name == 'escrow-review')
        .firstOrNull;
    if (reviewSpace != null) {
      await _reviewSpaces.create(
        spaceId: reviewSpace.id,
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        prNumber: 412,
        repoFullName: kDemoRepoFullName,
      );
    }

    await _reviewCohorts.replaceForPr(workspaceId, prExternalId, [
      ReviewCohort(
        id: '$workspaceId:$prExternalId:escrow',
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        cohortKey: 'escrow-timeline',
        title: 'Contingency deadlines on the timeline',
        orderIndex: 0,
        impactScore: 82,
        summaryMarkdown:
            'Adds contingency deadlines to `EscrowTimeline` and renders them '
            'as their own milestone band.\n\n'
            'The deadline itself is derived from the accepted-offer date plus '
            'the contingency window, which means it moves whenever the offer '
            'is amended — worth confirming that is intended for a **counter '
            'offer** and not only for a correction.',
        filePaths: const ['lib/escrow/timeline.dart'],
      ),
      ReviewCohort(
        id: '$workspaceId:$prExternalId:tests',
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        cohortKey: 'tests',
        title: 'Timeline tests',
        orderIndex: 1,
        impactScore: 34,
        summaryMarkdown:
            '96 lines of new coverage over the deadline arithmetic. The '
            'weekend and county-holiday cases are covered; a deadline that '
            'lands on the closing date itself is not.',
        filePaths: const ['test/escrow/timeline_test.dart'],
      ),
    ]);

    const axes = [
      (
        axis: ReviewAxis.correctness,
        verdict: ReviewAxisVerdict.warn,
        findings: 1,
        gated: true,
        confidence: 0.86,
        note: 'Deadline moves when an accepted offer is amended',
      ),
      (
        axis: ReviewAxis.testGap,
        verdict: ReviewAxisVerdict.warn,
        findings: 1,
        gated: false,
        confidence: 0.91,
        note: 'No case for a deadline landing on the closing date',
      ),
      (
        axis: ReviewAxis.security,
        verdict: ReviewAxisVerdict.pass,
        findings: 0,
        gated: true,
        confidence: 0.97,
        note: '',
      ),
      (
        axis: ReviewAxis.performance,
        verdict: ReviewAxisVerdict.pass,
        findings: 0,
        gated: false,
        confidence: 0.88,
        note: 'Deadline set is computed once per timeline build',
      ),
      (
        axis: ReviewAxis.apiContract,
        verdict: ReviewAxisVerdict.pass,
        findings: 0,
        gated: true,
        confidence: 0.94,
        note: 'EscrowTimeline gains a field; nothing removed',
      ),
      (
        axis: ReviewAxis.visual,
        verdict: ReviewAxisVerdict.unavailable,
        findings: 0,
        gated: false,
        confidence: 1,
        note: 'No screenshot target configured for this repo',
      ),
    ];

    for (final a in axes) {
      await _reviewAxes.upsert(
        workspaceId,
        prExternalId,
        ReviewAxisResult(
          axis: a.axis,
          verdict: a.verdict,
          findingsCount: a.findings,
          gated: a.gated,
          confidence: a.confidence.toDouble(),
          note: a.note,
        ),
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// A stable, filesystem-safe fragment of [url] for composing a row id.
  ///
  /// The feed id has to be derived from the URL rather than an index: the
  /// default list is edited over time, and an index-keyed id would silently
  /// re-point an existing visitor's feed at a different publication.
  static String _slug(String url) => url
      .replaceAll(RegExp(r'^https?://'), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
      .toLowerCase();

  /// Replaces `@-<n><unit>` markers with ISO-8601 timestamps relative to now.
  ///
  /// Fixtures carry relative markers rather than fixed dates so a demo is
  /// always "today", and so every row lands inside the retention windows the
  /// (still running) retention service sweeps.
  Object? _resolveDates(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key as String: _resolveDates(entry.value),
      };
    }
    if (value is List) {
      return [for (final item in value) _resolveDates(item)];
    }
    if (value is String) {
      final match = RegExp(r'^@-(\d+)([mhd])$').firstMatch(value);
      if (match == null) {
        return value;
      }
      final amount = int.parse(match.group(1)!);
      final delta = switch (match.group(2)) {
        'm' => Duration(minutes: amount),
        'h' => Duration(hours: amount),
        _ => Duration(days: amount),
      };
      return _now().subtract(delta).toIso8601String();
    }
    return value;
  }
}
