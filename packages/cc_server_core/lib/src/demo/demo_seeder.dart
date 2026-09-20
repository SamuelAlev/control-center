import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
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
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
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
import 'package:cc_server_core/src/demo/demo_repo_files.dart';
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
/// The world is **Helix**, an applied LLM / data-science lab: the cast builds
/// eval harnesses, retrieval pipelines, a feature store and fine-tuning, and
/// every ticket, PR, meeting and memory fact is about that domain.
class DemoSeeder {
  /// Creates a seeder over the server's repositories.
  DemoSeeder({
    required this._globalDb,
    required WorkspaceDatabaseManager workspaceDbs,
    required this._dataDir,
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
    required TeamRepository teamRepository,
    required OrchestrationRepository orchestrationRepository,
    required PlanDocumentRepository planDocumentRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
    this._baseSeed,
    this._registerConfirmation,
    this._refreshNewsfeed,
    void Function(String message)? log,
    DateTime Function()? now,
  }) : _dbs = workspaceDbs,
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
       _teams = teamRepository,
       _orchestrations = orchestrationRepository,
       _planDocuments = planDocumentRepository,
       _isolatedRepos = isolatedRepoRepository,
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
  final TeamRepository _teams;
  final OrchestrationRepository _orchestrations;
  final PlanDocumentRepository _planDocuments;
  final IsolatedRepoRepository _isolatedRepos;

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
    await _seedRepos(workspaceId);
    final agents = await _seedAgents(workspaceId);
    await _seedTeam(workspaceId, agents);
    await _seedPullRequests(workspaceId);
    final spaces = await _seedSpaces(workspaceId, agents);
    await _seedIsolatedRepos(workspaceId, spaces);
    await _seedWorkspaceLogo(workspaceId);
    await _seedRuns(workspaceId, agents, spaces);
    await _seedPipelineRuns(workspaceId, spaces);
    await _seedTodos(workspaceId, spaces);
    await _seedTickets(workspaceId, agents);
    await _seedOrchestration(workspaceId, agents, spaces);
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

  /// Linked repo rows for every Helix repository.
  ///
  /// They are REQUIRED, not optional: `resolvePrReviewRepository` looks the
  /// linked repo up by `(owner, name)` and throws `Repository is not linked
  /// to this workspace` when it finds none — so without these rows every PR
  /// page is an error rather than a demo. The open-PR snapshot also joins
  /// groups back to these ids, so a missing row silently empties the list.
  ///
  /// The path is a short file snapshot under the workspace data dir, not a
  /// git checkout: demo mode never clones, and every seeded space still
  /// selects zero repos so the provisioner never runs rift. `repos.readFile`
  /// / `listDirectory` and the Explorer follow this directory.
  Future<void> _seedRepos(String workspaceId) async {
    for (final spec in kDemoRepos) {
      final path = _snapshotPath(workspaceId, spec.name);
      await _writeSnapshot(path, spec.name);
      await _repos.upsert(
        workspaceId,
        Repo(
          id: spec.id,
          name: spec.fullName,
          path: path,
          remoteOwner: kDemoRepoOwner,
          remoteName: spec.name,
          forge: ForgeHost.github,
          createdAt: _now().subtract(const Duration(days: 200)),
          updatedAt: _now().subtract(const Duration(hours: 4)),
        ),
      );
    }
  }

  /// Three flavour agents on top of whatever the product's own seeder created.
  Future<List<Agent>> _seedAgents(String workspaceId) async {
    final specs =
        <({String id, String name, String title, List<String> skills})>[
          (
            id: 'demo-agent-reviewer',
            name: 'Ravi',
            title: 'Code reviewer',
            skills: ['review', 'python', 'testing'],
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

  /// The in-product agent team review requests address as `helix/ml-eng`.
  ///
  /// Teams are agents, not humans: Ravi leads, Juno and Wren sit as members.
  /// The forge slug on the PR fixtures is independent — this is what Settings
  /// → Teams and a team-routed dispatch show.
  Future<void> _seedTeam(String workspaceId, List<Agent> agents) async {
    final ravi = agents[0];
    final juno = agents[1];
    final wren = agents[2];
    final team = Team(
      id: '$workspaceId:team-ml-eng',
      workspaceId: workspaceId,
      name: kDemoTeamName,
      description:
          'Eval harnesses, retrieval, the feature store and fine-tuning. '
          'Ravi routes; Juno triages; Wren implements.',
      leaderId: ravi.id,
      instructions:
          'Prefer a blocking comment with a concrete alternative over a '
          'request-changes with no suggestion. Release cuts are Thursdays; '
          'Maya decides what makes the cut.',
      createdAt: _now().subtract(const Duration(days: 90)),
    );
    await _teams.insertTeam(team);
    await _teams.addMember(
      workspaceId,
      TeamMember(
        teamId: team.id,
        agentId: ravi.id,
        role: TeamMemberRole.leader,
      ),
    );
    await _teams.addMember(
      workspaceId,
      TeamMember(teamId: team.id, agentId: juno.id),
    );
    await _teams.addMember(
      workspaceId,
      TeamMember(teamId: team.id, agentId: wren.id),
    );
  }

  /// Snapshot trees the conversation Explorer lists, without setting
  /// `space.repoIds` (that would send the provisioner at git/rift).
  Future<void> _seedIsolatedRepos(
    String workspaceId,
    List<({String id, String name})> spaces,
  ) async {
    final evalkit = kDemoRepos.first;
    final path = _snapshotPath(workspaceId, evalkit.name);
    Future<void> put({required String spaceName, String? ticketId}) async {
      final space = spaces.where((s) => s.name == spaceName).firstOrNull;
      if (space == null) {
        return;
      }
      await _isolatedRepos.upsert(
        IsolatedRepo(
          id: '$workspaceId:iso-${space.id}-${evalkit.name}',
          workspaceId: workspaceId,
          spaceId: space.id,
          repoId: evalkit.id,
          path: path,
          branch: 'main',
          backend: RepoIsolationBackend.rift,
          sourcePath: path,
          ticketId: ticketId,
          createdAt: _now().subtract(const Duration(days: 6)),
        ),
      );
    }

    await put(spaceName: kDemoAgentSpaceName);
    await put(
      spaceName: 'eval-progress',
      ticketId: '$workspaceId:$kDemoTicketId',
    );
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

    final seeds =
        <
          ({
            String name,
            List<String> agentIds,
            List<
              ({
                DemoPerson? person,
                String? agentId,
                String text,
                int minutesAgo,
              })
            >
            messages,
          })
        >[
          (
            name: 'eval-review',
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
                    'Reading it now. The budget calculator itself is clean, but '
                    'two evals can share one run-group id and the retry path '
                    'mutates the shared ledger — I think that is the '
                    '"budget moved on its own" report.\n\nI left a blocking '
                    'comment and approved the rest.',
                minutesAgo: 332,
              ),
              (
                person: diego,
                agentId: null,
                text:
                    'Good catch. Key the ledger by run-group id, or a lock '
                    'around the whole budget?',
                minutesAgo: 300,
              ),
              (
                person: null,
                agentId: agents[0].id,
                text:
                    'The key. A lock serializes every eval on the ledger '
                    'including the ones whose remaining tokens are nowhere near '
                    'the cap, and the calculator runs on every render of the '
                    'run card.',
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
            name: 'eval-progress',
            agentIds: [agents[1].id],
            messages: [
              (
                person: tom,
                agentId: null,
                text:
                    'Two eval suites on HX-118 now. Both say long traces hang '
                    'at 99% while the grader is still running. Can we get a '
                    'read before the weekly report goes out?',
                minutesAgo: 1500,
              ),
              (
                person: null,
                agentId: agents[1].id,
                text:
                    'It is not hanging. Progress reaches 100% when the last token '
                    'leaves the model, then `_finalize()` waits on a server-side '
                    'grader pass — about 30s on a long trace. The bar sits at '
                    '99% with no signal that anything is still happening, so '
                    'people cancel a run that is actually fine.\n\nThat also '
                    'explains why the "failed" traces are all present in the '
                    'store.',
                minutesAgo: 1480,
              ),
              (
                person: priya,
                agentId: null,
                text:
                    'So it is a reporting bug. I will add a distinct '
                    'grading-pending state rather than a percentage — hybrid '
                    'retrieval #88 is the other one I want in this cut.',
                minutesAgo: 1400,
              ),
              (
                person: tom,
                agentId: null,
                text:
                    'Perfect. I will tell both suites their traces completed.',
                minutesAgo: 1380,
              ),
            ],
          ),
          (
            name: 'eval-reports',
            agentIds: [agents[2].id],
            messages: [
              (
                person: tom,
                agentId: null,
                text:
                    'Scheduled eval-score exports is next up — the research team '
                    'wants the week\'s runs in their inbox. A weekly digest too, '
                    'if it is cheap.',
                minutesAgo: 2900,
              ),
              (
                person: null,
                agentId: agents[2].id,
                text:
                    'Storage and execution are mostly wiring — `CsvExporter` and '
                    '`EvalExportJob` already exist, and the cron parser from the '
                    'pipeline triggers handles the timezone cases.\n\nDelivery is '
                    'the only genuinely new piece, and it is where the risk is: an '
                    'email to research that silently fails is worse than no '
                    'feature.',
                minutesAgo: 2880,
              ),
              (
                person: null,
                agentId: agents[2].id,
                text:
                    'I would push back on the digest. It sounds small, but one '
                    'spanning several eval suites needs its own composition step '
                    'and a different failure story. Single-report schedules first.',
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
                    'Release cut is Thursday. #412 and retriever #88 are the two '
                    'I want in. #409 stays draft.',
                minutesAgo: 90,
              ),
              (
                person: priya,
                agentId: null,
                text:
                    '#81 has a failing test — the reranker timeout Diego flagged.',
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

  /// Brands the workspace with the Helix logo.
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
    final runs =
        <
          ({
            Agent agent,
            int hoursAgo,
            int seconds,
            RunCost cost,
            String summary,
          })
        >[
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
            summary: 'Triaged HX-118 to a progress-reporting bug',
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
            summary: 'Broke eval-score exports into four plan nodes',
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
            summary: 'Reviewed features #49: approved',
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
        await _pipelineTemplates.deleteById(workspaceId, template.templateId);
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

    final specs =
        <
          ({
            String runId,
            String templateId,
            int hoursAgo,
            PipelineRunStatus status,
            int costCents,
            int tokens,
            String? error,
          })
        >[
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
        final failedHere =
            spec.status == PipelineRunStatus.failed && i == steps.length - 1;
        await _pipelineRuns.insertStepRun(
          PipelineStepRun(
            id: '$workspaceId:${spec.runId}-step-$i',
            pipelineRunId: '$workspaceId:${spec.runId}',
            stepId: step.id,
            status: failedHere
                ? PipelineStepStatus.failed
                : PipelineStepStatus.completed,
            inputJson: jsonEncode({
              'source': spec.templateId == 'pr_review' ? '#412' : 'HX-129',
            }),
            outputJson: failedHere
                ? null
                : jsonEncode({
                    'note': spec.templateId == 'pr_review'
                        ? 'review posted, 1 blocking comment'
                        : 'branch created, PR step skipped on demo host',
                  }),
            spaceId: spaceId,
            errorMessage: failedHere ? spec.error : null,
            attemptCount: 1,
            startedAt: stepStarted,
            finishedAt: failedHere
                ? null
                : stepStarted.add(const Duration(seconds: 18)),
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
        text: 'Check the budget calculator against shared run-groups',
        status: TodoStatus.completed,
      ),
      (
        text: 'Leave the blocking comment on evalkit/budget.py',
        status: TodoStatus.completed,
      ),
      (
        text: 'Re-review once run-group keying lands',
        status: TodoStatus.inProgress,
      ),
      (
        text: 'Confirm the shared run-group case has a test',
        status: TodoStatus.pending,
      ),
    ];
    for (final item in items) {
      final created = await _todos.append(workspaceId, spaceId, item.text);
      if (item.status != TodoStatus.pending) {
        await _todos.updateStatus(
          workspaceId,
          spaceId,
          created.id,
          item.status,
        );
      }
    }
  }

  /// A project and its tickets, including the one the triage script resolves.
  Future<void> _seedTickets(String workspaceId, List<Agent> agents) async {
    final now = _now();
    await _projects.insert(
      Project(
        id: 'demo-project-helix',
        workspaceId: workspaceId,
        name: 'Helix Q3',
        description: 'Eval-bench readiness.',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
    );

    final tickets =
        <
          ({
            String key,
            String title,
            String body,
            TicketStatus status,
            TicketPriority priority,
            String? agentId,
            int daysAgo,
          })
        >[
          (
            key: 'HX-118',
            title: 'Eval runs hang at 99% on long traces',
            body:
                'Two eval suites reported grading jobs hanging at 99% on traces '
                'over ~50k tokens.\n\n'
                'Not a transfer bug: progress reaches 100% when the last token '
                'leaves the model, then `_finalize()` waits on a server-side '
                'grader pass for ~30s with no signal. The runs complete; the bar '
                'just stops moving, so people cancel.\n\nFix is a distinct '
                '"grading pending" state rather than a percentage.',
            status: TicketStatus.inProgress,
            priority: TicketPriority.high,
            agentId: agents[1].id,
            daysAgo: 6,
          ),
          (
            key: 'HX-121',
            title: 'Eval appears stuck near the end (duplicate of HX-118)',
            body: 'Same root cause as HX-118. Linked and closed.',
            status: TicketStatus.cancelled,
            priority: TicketPriority.low,
            agentId: null,
            daysAgo: 5,
          ),
          (
            key: 'HX-124',
            title: 'Eval budgets should warn before they exhaust',
            body:
                'Remaining tokens are computed on render, so nobody sees a Haiku '
                'sweep exhaust until the run card is open. #412 moves them onto '
                'the run card with a remaining-tokens chip.',
            status: TicketStatus.inReview,
            priority: TicketPriority.high,
            agentId: agents[0].id,
            daysAgo: 4,
          ),
          (
            key: 'HX-129',
            title: 'Scheduled eval-score exports for research',
            body:
                'Save a schedule against the week\'s eval runs and deliver it to '
                'research. Delivery needs its own log and a visible failure '
                'state — a silent email failure is worse than no feature.',
            status: TicketStatus.open,
            priority: TicketPriority.medium,
            agentId: agents[2].id,
            daysAgo: 3,
          ),
          (
            key: 'HX-131',
            title: 'Budget window test is flaky across the UTC-day boundary',
            body:
                'The test calls `datetime.now()` directly, so a run that crosses '
                'a real UTC-day boundary drops the first record out of the '
                'window.',
            status: TicketStatus.done,
            priority: TicketPriority.low,
            agentId: agents[2].id,
            daysAgo: 2,
          ),
          (
            key: 'HX-136',
            title: 'Weekly eval digest spanning multiple suites',
            body:
                'Deliberately split out of HX-129. Needs its own composition step.',
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
          // (and a route cache), so seeding the same `HX-124` into every
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
          projectId: 'demo-project-helix',
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

  /// Wren's HX-129 plan: four work nodes in Plan Studio and an executing
  /// orchestration on `eval-reports`. Status is `executing` rather than
  /// `approved` so the cross-workspace materialization resume query does not
  /// pick it up — there is no pipeline to resume.
  Future<void> _seedOrchestration(
    String workspaceId,
    List<Agent> agents,
    List<({String id, String name})> spaces,
  ) async {
    final wren = agents[2];
    final ravi = agents[0];
    final space = spaces.where((s) => s.name == kDemoPlanSpaceName).firstOrNull;
    if (space == null) {
      return;
    }
    final proposal = _hx129Proposal(builderId: wren.id, reviewerId: ravi.id);
    final createdAt = _now().subtract(const Duration(hours: 48));
    await _orchestrations.insert(
      Orchestration(
        id: '$workspaceId:orch-hx129',
        workspaceId: workspaceId,
        proposal: proposal,
        createdAt: createdAt,
        updatedAt: _now().subtract(const Duration(hours: 2)),
        parentTicketId: '$workspaceId:HX-129',
        spaceId: space.id,
        orchestratorAgentId: wren.id,
        status: OrchestrationStatus.executing,
        revision: 1,
        approvedRevision: 1,
        teamId: '$workspaceId:team-ml-eng',
        projectId: 'demo-project-helix',
        estimatedCostCents: 42,
        maxCostCents: 200,
      ),
    );
    await _planDocuments.upsert(
      PlanDocument(
        id: '$workspaceId:plan-hx129',
        workspaceId: workspaceId,
        conversationId: space.id,
        agentId: wren.id,
        goal: proposal.goal,
        graph: PlanGraph(
          nodes: [
            for (final t in proposal.subTickets) PlanNode.fromSubTicket(t),
          ],
        ),
        clarifications: const [
          PlanClarification(
            question:
                'Should the weekly digest spanning multiple suites ship in this cut?',
            answer: 'No — single-report schedules first. The digest is HX-136.',
          ),
        ],
        status: PlanDocumentStatus.approved,
        revision: 1,
        createdAt: createdAt,
        updatedAt: _now().subtract(const Duration(hours: 2)),
      ),
    );
  }

  /// Facts the agents have accumulated, so the memory surface has substance.
  ///
  /// No embeddings: the demo runs FTS-only, which is the documented degrade
  /// while the on-device model is absent.
  Future<void> _seedMemory(String workspaceId, List<Agent> agents) async {
    final facts = <({String domain, String topic, String content})>[
      (
        domain: 'codebase',
        topic: 'eval budget',
        content:
            'The eval budget in evalkit/budget.py is shared by the run card '
            'and the grader. Changes there need both suites run.',
      ),
      (
        domain: 'codebase',
        topic: 'retrieval',
        content:
            'Retriever #88 unions BM25 with dense search via reciprocal rank '
            'fusion. Identifier queries (dataset ids, citation keys) must '
            'rank the named chunk first.',
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
        domain: 'evals',
        topic: 'token caps',
        content:
            'Eval token caps are per model family: Haiku 80k, Sonnet 200k, '
            'Opus 400k — counted from the run-group id, never from the org '
            'pool.',
      ),
      (
        domain: 'product',
        topic: 'eval finalizing',
        content:
            'Eval traces over ~50k tokens spend up to 30s in server-side '
            'grading after generation completes. Any progress UI must show '
            'that phase.',
      ),
      (
        domain: 'product',
        topic: 'digest scope',
        content:
            'Weekly eval digests were split out of score exports (HX-136): '
            'a digest spanning several suites needs its own composition and '
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
            'Prompt text, user utterances and dataset rows never enter a '
            'memory fact. Describe the eval suite and the model family, not '
            'the example.',
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
            'A token-budget commitment is only durable once the run-group id '
            'is in the ledger key; anything earlier is recorded as a '
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
        accountEmail: 'ops@helix.invalid',
        displayName: 'Helix',
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
          summary: 'Helix',
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
        <
          ({
            String id,
            String title,
            int dayOffset,
            int startHour,
            int minutes,
            String? location,
            String? meetingUrl,
            String? description,
          })
        >[
          (
            id: 'standup-mon',
            title: 'Daily stand-up',
            dayOffset: -1,
            startHour: 9,
            minutes: 15,
            location: null,
            meetingUrl: 'https://meet.invalid/helix-standup',
            description: 'What landed, what is blocked.',
          ),
          (
            id: 'standup-today',
            title: 'Daily stand-up',
            dayOffset: 0,
            startHour: 9,
            minutes: 15,
            location: null,
            meetingUrl: 'https://meet.invalid/helix-standup',
            description: 'What landed, what is blocked.',
          ),
          (
            id: 'eval-review',
            title: 'Eval review — Helix Q3',
            dayOffset: 0,
            startHour: 14,
            minutes: 45,
            location: 'The long room',
            meetingUrl: null,
            description:
                'Cut list: #412 (eval token budgets) and retriever #88 '
                '(hybrid retrieval). #409 is draft and will not make it.',
          ),
          (
            id: 'design-sync',
            title: 'Eval states — design sync',
            dayOffset: 1,
            startHour: 11,
            minutes: 30,
            location: null,
            meetingUrl: 'https://meet.invalid/helix-design',
            description:
                'Deciding the copy for the grading-pending state on '
                'HX-118.',
          ),
          (
            id: 'walkthrough',
            title: 'Eval-bench walkthrough — nightly suite',
            dayOffset: 2,
            startHour: 10,
            minutes: 60,
            location: 'Lab 4',
            meetingUrl: null,
            description: 'Walk the nightly suite before the Thursday cut.',
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
            title: 'Onboarding — new eval-ops hire',
            dayOffset: 8,
            startHour: 10,
            minutes: 90,
            location: null,
            meetingUrl: 'https://meet.invalid/helix-onboarding',
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
                email: '${person.handle}@helix.invalid',
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
        <
          ({
            String id,
            String title,
            int hoursAgo,
            int minutes,
            String summary,
            List<({bool me, String label, String text})> transcript,
            List<String> decisions,
            List<({String content, String owner, bool done})> actions,
          })
        >[
          (
            id: 'eval-review',
            title: 'Eval review — Helix Q3',
            hoursAgo: 26,
            minutes: 42,
            summary:
                'Agreed the Q3 cut is #412 and retriever #88. #409 stays '
                'draft. The open question on #412 — two evals sharing one '
                'run-group id — is a blocker, and Diego is keying the ledger '
                'by run-group rather than deferring it. HX-118 turned out '
                'to be a progress-reporting bug, so the fix is copy and a new '
                'grading phase rather than transfer work.',
            transcript: [
              (
                me: true,
                label: 'Maya',
                text:
                    'Let us start with the cut. I want 412 and retriever 88 '
                    'in, and I do not want 409 anywhere near it.',
              ),
              (
                me: false,
                label: 'Diego',
                text:
                    '412 has Ravi\'s blocking comment on it. Two evals can '
                    'share a run-group id, and a retry on one burns the '
                    'other\'s remaining tokens.',
              ),
              (
                me: true,
                label: 'Maya',
                text: 'Is that the "budget moved on its own" report?',
              ),
              (
                me: false,
                label: 'Diego',
                text:
                    'I think so. It only shows up when a nightly sweep and an '
                    'ad-hoc grade start in the same hour, which is exactly '
                    'when both ledgers recompute at once.',
              ),
              (
                me: true,
                label: 'Maya',
                text:
                    'Then it is a blocker. Key the ledger by run-group id '
                    'in this PR — I do not want to ship the fix for a '
                    'bug and the bug in the same release.',
              ),
              (
                me: false,
                label: 'Priya',
                text:
                    'On the progress bar — it is not a transfer bug at all. '
                    'Progress hits a hundred percent when the last token '
                    'leaves, then the grader runs for thirty seconds with '
                    'no signal.',
              ),
              (
                me: false,
                label: 'Tom',
                text:
                    'So the traces people cancelled were fine the whole '
                    'time. I can tell both suites today.',
              ),
              (
                me: false,
                label: 'Priya',
                text:
                    'Right. I am adding an explicit grading-pending '
                    'phase instead of a percentage. The copy is the part I '
                    'want a second opinion on.',
              ),
            ],
            decisions: [
              'Helix Q3 ships #412 and retriever #88. #409 stays draft.',
              'The run-group keying lands in #412, not a follow-up.',
              'HX-118 is fixed with an explicit grading phase, not transfer work.',
            ],
            actions: [
              (
                content: 'Key the token ledger by run-group id in #412',
                owner: 'Diego',
                done: false,
              ),
              (
                content: 'Tell both HX-118 suites their traces completed',
                owner: 'Tom',
                done: true,
              ),
              (
                content: 'Write the grading-pending copy for review',
                owner: 'Priya',
                done: false,
              ),
            ],
          ),
          (
            id: 'eval-reports-kickoff',
            title: 'Eval-score exports — scoping',
            hoursAgo: 74,
            minutes: 28,
            summary:
                'Scheduled eval-score exports is mostly wiring over the '
                'existing exporter and cron parser. Delivery is the only new '
                'piece and needs its own log and a visible failure state. The '
                'weekly eval digest was split out as HX-136 rather than '
                'folded in.',
            transcript: [
              (
                me: false,
                label: 'Tom',
                text:
                    'Scheduled eval exports is next. And a weekly digest '
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
                    'Delivery is where the risk is. An email to research that '
                    'silently fails is worse than not having the feature.',
              ),
              (me: false, label: 'Tom', text: 'What does that cost us?'),
              (
                me: true,
                label: 'Maya',
                text:
                    'A delivery log and a failure state people can see. Which '
                    'is also why I want the digest separate — a digest across '
                    'several eval suites has a different failure story.',
              ),
              (
                me: false,
                label: 'Tom',
                text: 'Fine. Ship the simple one first.',
              ),
            ],
            decisions: [
              'Single-suite schedules ship first; the digest is HX-136.',
              'Delivery gets its own log and a visible failure state.',
            ],
            actions: [
              (
                content: 'Break eval exports into plan nodes',
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
      final step =
          (meeting.minutes * 60 * 1000) ~/ (meeting.transcript.length + 1);
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
    final artifacts =
        <
          ({
            String id,
            String title,
            WorkProductType type,
            String ticketId,
            String agentId,
            String content,
            String humanEdit,
            int hoursAgo,
          })
        >[
          (
            id: 'demo-artifact-checklist',
            title: 'Eval-bench checklist — nightly suite',
            type: WorkProductType.document,
            ticketId: '$workspaceId:HX-124',
            agentId: agents[2].id,
            content:
                '# Eval-bench checklist — nightly suite\n\n'
                '## Caps\n\n'
                '- [x] Haiku 80k (pinned)\n'
                '- [x] Opus 400k (pinned)\n'
                '- [ ] Sonnet 200k — needs a pinning test\n\n'
                '## Paperwork\n\n'
                '- [x] Run-group id in the ledger key (agreed)\n'
                '- [ ] Remaining-tokens chip copy\n'
                '- [ ] Exhausted-budget danger tone\n\n'
                '## Notes\n\n'
                'Run-group id is the anchor for every remaining-token chip. '
                'A nightly sweep and an ad-hoc grade in the same hour must '
                'not share spend.',
            humanEdit:
                '# Eval-bench checklist — nightly suite\n\n'
                '## Caps\n\n'
                '- [x] Haiku 80k (pinned)\n'
                '- [x] Opus 400k (pinned)\n'
                '- [ ] Sonnet 200k — needs a pinning test\n\n'
                '## Paperwork\n\n'
                '- [x] Run-group id in the ledger key (agreed)\n'
                '- [ ] Remaining-tokens chip copy\n'
                '- [ ] Exhausted-budget danger tone\n\n'
                '## Notes\n\n'
                'Run-group id is the anchor for every remaining-token chip. '
                'A nightly sweep and an ad-hoc grade in the same hour must '
                'not share spend.\n\n'
                '> Eval-ops confirmed the nightly slot by Slack — keep the '
                'paper trail in the ticket, not in memory.',
            hoursAgo: 30,
          ),
          (
            id: 'demo-artifact-comps',
            title: 'Retrieval ablation — identifier queries',
            type: WorkProductType.report,
            ticketId: '$workspaceId:HX-129',
            agentId: agents[0].id,
            content:
                '# Retrieval ablation — identifier queries\n\n'
                'Five identifier queries against the 40k-chunk corpus:\n\n'
                '| Query | Dense@8 | Hybrid@8 | Hit |\n'
                '|---|---|---|---|\n'
                '| dataset:gsm8k | 0.12 | 0.88 | named chunk |\n'
                '| arxiv:2401.12345 | 0.08 | 0.91 | named chunk |\n'
                '| run-group nightly-04 | 0.21 | 0.76 | named chunk |\n'
                '| evalkit.budget.EvalBudget | 0.44 | 0.81 | named chunk |\n'
                '| "token ledger" | 0.67 | 0.73 | paraphrase |\n\n'
                'Hybrid (BM25 + dense, RRF) recovers identifier queries the '
                'dense-only path was ranking as paraphrases.',
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
            summary: 'Added eval-ops confirmation note',
            createdAt: now.subtract(const Duration(hours: 6)),
          ),
        );
      }
    }
  }

  /// An audit trail across the last two weeks.
  Future<void> _seedActivity(String workspaceId, List<Agent> agents) async {
    final dao = _dbs.of(workspaceId).activityLogDao;
    final entries =
        <({String action, String entityType, String entityId, int hoursAgo})>[
          (
            action: 'run.completed',
            entityType: 'agent_run',
            entityId: 'demo-run-0',
            hoursAgo: 6,
          ),
          (
            action: 'ticket.status_changed',
            entityType: 'ticket',
            entityId: 'HX-118',
            hoursAgo: 25,
          ),
          (
            action: 'review.submitted',
            entityType: 'pull_request',
            entityId: 'PR_412',
            hoursAgo: 6,
          ),
          (
            action: 'run.completed',
            entityType: 'agent_run',
            entityId: 'demo-run-1',
            hoursAgo: 25,
          ),
          (
            action: 'ticket.created',
            entityType: 'ticket',
            entityId: 'HX-129',
            hoursAgo: 72,
          ),
          (
            action: 'run.completed',
            entityType: 'agent_run',
            entityId: 'demo-run-2',
            hoursAgo: 48,
          ),
          (
            action: 'pr.merged',
            entityType: 'pull_request',
            entityId: 'PR_23',
            hoursAgo: 216,
          ),
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
          createdAt: drift.Value(
            _now().subtract(Duration(hours: entry.hoursAgo)),
          ),
        ),
      );
    }
  }

  /// A few unread notifications, so the inbox is not an empty state.
  Future<void> _seedNotifications(String workspaceId) async {
    final dao = _dbs.of(workspaceId).notificationFeedDao;
    final items =
        <({String method, Map<String, dynamic> params, int hoursAgo})>[
          (
            method: 'pr.review_requested',
            params: {
              'title': 'Diego requested your review on #412',
              'repo': kDemoRepoFullName,
              'pr_number': kDemoReviewPrNumber,
            },
            hoursAgo: 5,
          ),
          (
            method: 'pr.review_requested',
            params: {
              'title': 'helix/ml-eng was asked to review retriever #88',
              'repo': 'helix/retriever',
              'pr_number': 88,
            },
            hoursAgo: 8,
          ),
          (
            method: 'pr.opened',
            params: {
              'title': 'Draft: grader plugin load path (#409)',
              'repo': kDemoRepoFullName,
              'pr_number': 409,
            },
            hoursAgo: 9,
          ),
          (
            method: 'ticket.assigned',
            params: {
              'title': 'HX-129 assigned to Wren',
              'ticket_key': 'HX-129',
            },
            hoursAgo: 30,
          ),
          (
            method: 'pr.checks_failed',
            params: {
              'title': 'Checks failed on helix/retriever#81',
              'repo': 'helix/retriever',
              'pr_number': 81,
            },
            hoursAgo: 26,
          ),
          (
            method: 'meeting.summary_ready',
            params: {
              'title': 'Summary ready — Eval review',
              'meeting_id': 'demo-meeting-eval-review',
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
              'title': 'Two facts disagree about the Haiku token cap',
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
          createdAt: drift.Value(
            _now().subtract(Duration(hours: item.hoursAgo)),
          ),
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
        .where((s) => s.name == kDemoAgentSpaceName)
        .firstOrNull;
    final register = _registerConfirmation;
    if (register != null && reviewSpace != null) {
      register(
        ConfirmationRequest(
          spaceId: reviewSpace.id,
          workspaceId: workspaceId,
          title: 'Juno wants to pull the GSM8K eval split from Hugging Face',
          detail:
              'The sweep reads the public GSM8K dataset for the nightly '
              'grader on HX-124. It makes about 40 paginated requests to '
              'the Hub — approve to let it run once.',
          severity: ConfirmationSeverity.warning,
          command:
              'bin/eval_pull --dataset gsm8k --split test '
              '--revision 2026.04',
        ),
      );
    }

    await _syncLog.append(
      TicketSyncLogEntry(
        id: 'demo-synclog-0',
        workspaceId: workspaceId,
        ticketId: '$workspaceId:HX-124',
        vendor: 'linear',
        direction: SyncDirection.push,
        outcome: SyncOutcome.failed,
        message:
            'Push failed: Linear issue was closed on the vendor side '
            '(HX-124 mirrors as EVAL-418). Reopen there or relink before the '
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

    for (final spec in kDemoRepos) {
      await put(
        DemoPrCacheKind.assignableUsers,
        spec.fullName,
        resolved['assignable_users'],
      );
      await put(
        DemoPrCacheKind.requestableTeams,
        spec.fullName,
        resolved['requestable_teams'],
      );
    }

    final openByRepo = <String, List<Map<String, dynamic>>>{
      for (final spec in kDemoRepos) spec.fullName: <Map<String, dynamic>>[],
    };
    final closedByRepo = <String, List<Map<String, dynamic>>>{
      for (final spec in kDemoRepos) spec.fullName: <Map<String, dynamic>>[],
    };
    for (final raw in resolved['pull_requests'] as List) {
      final pr = Map<String, dynamic>.from(raw as Map);
      final detail = Map<String, dynamic>.from(pr['detail'] as Map);
      final number = detail['number'] as int;
      final repoFullName =
          detail['repo_full_name'] as String? ?? kDemoRepoFullName;
      final repoName = repoFullName.split('/').last;
      final key = demoPrCacheKey(repoFullName, number);

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

      final headSha = detail['head_sha'] as String? ?? '';
      final headRef = detail['head_ref'] as String? ?? '';
      for (final file in pr['files'] as List? ?? const []) {
        if (file is! Map) {
          continue;
        }
        final path = file['filename'] as String?;
        if (path == null || path.isEmpty) {
          continue;
        }
        final body = _fileBody(repoName, path);
        if (headSha.isNotEmpty) {
          await put(
            DemoPrCacheKind.fileContent,
            demoFileContentCacheKey(repoFullName, headSha, path),
            body,
          );
        }
        if (headRef.isNotEmpty && headRef != headSha) {
          await put(
            DemoPrCacheKind.fileContent,
            demoFileContentCacheKey(repoFullName, headRef, path),
            body,
          );
        }
      }

      if (detail['state'] == 'open') {
        (openByRepo[repoFullName] ??= []).add(detail);
      } else if (detail['state'] == 'merged') {
        (closedByRepo[repoFullName] ??= []).add(detail);
      }
    }

    Map<String, dynamic> listSnapshot(
      Map<String, List<Map<String, dynamic>>> byRepo,
    ) => {
      'authenticated': true,
      'repos': [
        for (final spec in kDemoRepos)
          {
            'repo_id': spec.id,
            'repo_full_name': spec.fullName,
            'github_owner': kDemoRepoOwner,
            'github_repo_name': spec.name,
            'has_more': false,
            'prs': byRepo[spec.fullName] ?? const <Map<String, dynamic>>[],
          },
      ],
    };

    // The snapshot `pr.watchOpenForWorkspace` follows. Without the demo's
    // no-op poller this row would never be read (a null poller short-circuits
    // to a signed-out empty list before touching the cache) and without the
    // row the poller would emit an authenticated-but-empty list.
    //
    // The wire key is `prs` (see OpenPrPollingService._repoWire and
    // RpcOpenPrListRepository._prsOf). Seeding `pull_requests` used to ship
    // an authenticated-looking snapshot whose groups decoded as empty, so
    // the PR list and the inbox both rendered as a zero state.
    await put(
      DemoPrCacheKind.openPrList,
      DemoPrCacheKind.openPrListKey,
      listSnapshot(openByRepo),
    );

    // Maya's merged history, the snapshot `pr.closedByAuthorForWorkspace`
    // reads. Same `prs` wire key; a demo answers from this row instead of
    // searching GitHub.
    await put(
      DemoPrCacheKind.closedPrList,
      DemoPrCacheKind.closedPrListKey,
      listSnapshot(closedByRepo),
    );
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
      unawaited(refresh(userId).catchError((Object _) {}));
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
  /// a missing shared run-group case) and `correctness` carries the one finding
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
        .where((s) => s.name == kDemoAgentSpaceName)
        .firstOrNull;
    if (reviewSpace != null) {
      await _reviewSpaces.create(
        spaceId: reviewSpace.id,
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        prNumber: kDemoReviewPrNumber,
        repoFullName: kDemoRepoFullName,
      );
    }

    await _reviewCohorts.replaceForPr(workspaceId, prExternalId, [
      ReviewCohort(
        id: '$workspaceId:$prExternalId:budget',
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        cohortKey: 'eval-budget',
        title: 'Token budget per model family',
        orderIndex: 0,
        impactScore: 82,
        summaryMarkdown:
            'Adds per-family caps to `EvalBudget` and renders remaining '
            'tokens on the run card.\n\n'
            'Spend is derived from the family alone, which means it moves '
            'whenever a sibling eval in the same run-group records a retry — '
            'worth confirming that is intended for a **shared sweep** and not '
            'only for a single job.',
        filePaths: const ['evalkit/budget.py'],
      ),
      ReviewCohort(
        id: '$workspaceId:$prExternalId:tests',
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        cohortKey: 'tests',
        title: 'Budget tests',
        orderIndex: 1,
        impactScore: 34,
        summaryMarkdown:
            '68 lines of new coverage over the cap arithmetic. The Haiku '
            'and Opus cases are covered; a cap that lands on a shared '
            'run-group is not.',
        filePaths: const ['tests/evalkit/test_budget.py'],
      ),
    ]);

    const axes = [
      (
        axis: ReviewAxis.correctness,
        verdict: ReviewAxisVerdict.warn,
        findings: 1,
        gated: true,
        confidence: 0.86,
        note: 'Budget moves when a sibling eval in the same run-group retries',
      ),
      (
        axis: ReviewAxis.testGap,
        verdict: ReviewAxisVerdict.warn,
        findings: 1,
        gated: false,
        confidence: 0.91,
        note: 'No case for two evals sharing one run-group id',
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
        note: 'Remaining tokens are computed once per run-card build',
      ),
      (
        axis: ReviewAxis.apiContract,
        verdict: ReviewAxisVerdict.pass,
        findings: 0,
        gated: true,
        confidence: 0.94,
        note: 'EvalBudget gains a ledger; nothing removed',
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

  /// Absolute snapshot tree for one Helix repo.
  String _snapshotPath(String workspaceId, String repoName) =>
      '$_dataDir/$workspaceId/repos/$repoName';

  /// Writes [kDemoSnapshotFiles] for [repoName] under [root].
  Future<void> _writeSnapshot(String root, String repoName) async {
    final files = kDemoSnapshotFiles[repoName];
    if (files == null) {
      return;
    }
    for (final entry in files.entries) {
      final file = File('$root/${entry.key}');
      await file.parent.create(recursive: true);
      if (!file.existsSync()) {
        await file.writeAsString(entry.value);
      }
    }
  }

  /// Body the PR file viewer opens at a given path.
  static String _fileBody(String repoName, String path) =>
      kDemoSnapshotFiles[repoName]?[path] ?? '# $path\n';

  /// The four-node HX-129 plan Wren authored in `eval-reports`.
  static OrchestrationProposal _hx129Proposal({
    required String builderId,
    required String reviewerId,
  }) => OrchestrationProposal(
    goal:
        'Save a schedule against the week\'s eval runs and deliver it to '
        'research, with a visible failure state when delivery does not land.',
    roles: [
      ProposedRole(
        roleKey: 'builder',
        title: 'Feature work',
        existingAgentId: builderId,
      ),
      ProposedRole(
        roleKey: 'reviewer',
        title: 'Code reviewer',
        existingAgentId: reviewerId,
      ),
    ],
    subTickets: const [
      ProposedSubTicket(
        key: 'persist-schedule',
        title: 'Persist an export schedule against a run group',
        roleKey: 'builder',
        description:
            'Store the schedule next to the run group so a later export '
            'job can load it without re-asking research for the window.',
        priority: 'high',
      ),
      ProposedSubTicket(
        key: 'csv-export',
        title: 'Wire CsvExporter through EvalExportJob',
        roleKey: 'builder',
        description:
            'CsvExporter and EvalExportJob already exist. Connect them so a '
            'scheduled run writes the week\'s scores to a file the delivery '
            'step can pick up.',
        priority: 'high',
      ),
      ProposedSubTicket(
        key: 'delivery-log',
        title: 'Deliver to research with a visible failure log',
        roleKey: 'builder',
        description:
            'An email that silently fails is worse than no feature. Log each '
            'attempt and surface a failure state on the schedule row.',
        dependsOn: ['csv-export', 'persist-schedule'],
        priority: 'high',
      ),
      ProposedSubTicket(
        key: 'cron-tz',
        title: 'Honor the schedule\'s timezone',
        roleKey: 'builder',
        description:
            'The pipeline-trigger cron parser already handles timezone '
            'cases. Reuse it so a Monday 09:00 Europe/London schedule does '
            'not fire at UTC.',
        dependsOn: ['persist-schedule'],
        priority: 'medium',
      ),
    ],
    synthesis: const SynthesisSpec(
      roleKey: 'builder',
      prompt:
          'Confirm the four pieces compose: a saved schedule exports the '
          'week\'s scores and delivers them, or names the failure.',
      outputSchema: {
        'type': 'object',
        'properties': {
          'gaps': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['gaps'],
      },
    ),
    budget: const BudgetSpec(estimatedCostCents: 42, maxCostCents: 200),
  );

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
