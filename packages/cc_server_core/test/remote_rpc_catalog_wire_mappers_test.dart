import 'package:cc_domain/cc_domain.dart' show RepoDto;
import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:test/test.dart';

/// Unit tests for the top-level `*ToWire` mapper functions in
/// `remote_rpc_catalog.dart`. Each is a pure entity→Map transform; these tests
/// pin the snake_case wire keys and the enum/timestamp encoding so a renamed
/// key is caught before it reaches a client.
void main() {
  group('remote_rpc_catalog wire mappers', () {
    test('todoItemToWire maps every field', () {
      final w = todoItemToWire(
        TodoItem(
          id: 't-1',
          workspaceId: 'ws-1',
          spaceId: 's-1',
          content: 'do it',
          status: TodoStatus.inProgress,
          position: 2,
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['id'], 't-1');
      expect(w['workspace_id'], 'ws-1');
      expect(w['space_id'], 's-1');
      expect(w['content'], 'do it');
      expect(w['status'], 'in_progress');
      expect(w['position'], 2);
      expect(w['created_at'], '2026-07-01T09:00:00.000');
      expect(w['updated_at'], '2026-07-01T10:00:00.000');
    });

    test('goalToWire maps every field', () {
      final w = goalToWire(
        ConversationGoal(
          spaceId: 's-1',
          workspaceId: 'ws-1',
          title: 'Ship it',
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['space_id'], 's-1');
      expect(w['workspace_id'], 'ws-1');
      expect(w['title'], 'Ship it');
      expect(w['created_at'], '2026-07-01T09:00:00.000');
      expect(w['updated_at'], '2026-07-01T10:00:00.000');
    });

    test('agentGoalRunToWire maps every field', () {
      final w = agentGoalRunToWire(
        AgentGoalRun(
          id: 'g-1',
          workspaceId: 'ws-1',
          spaceId: 'ch-1',
          conversationId: 'c-1',
          agentId: 'a-1',
          userText: 'keep polishing until done',
          kind: AgentGoalKind.loop,
          status: AgentGoalStatus.budgetExhausted,
          deadlineAt: DateTime(2026, 8, 1, 12),
          costCapCents: 5000,
          costCents: 125,
          maxRuns: 100,
          runCount: 3,
          consecutiveFailures: 1,
          activeRunId: 'run-9',
          requestedByUserId: 'user-1',
          summary: 'all done',
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['id'], 'g-1');
      expect(w['workspace_id'], 'ws-1');
      expect(w['space_id'], 'ch-1');
      expect(w['conversation_id'], 'c-1');
      expect(w['agent_id'], 'a-1');
      expect(w['user_text'], 'keep polishing until done');
      expect(w['kind'], 'loop');
      expect(w['status'], 'budget_exhausted');
      expect(w['deadline_at'], '2026-08-01T12:00:00.000');
      expect(w['cost_cap_cents'], 5000);
      expect(w['cost_cents'], 125);
      expect(w['max_runs'], 100);
      expect(w['run_count'], 3);
      expect(w['consecutive_failures'], 1);
      expect(w['active_run_id'], 'run-9');
      expect(w['requested_by_user_id'], 'user-1');
      expect(w['summary'], 'all done');
      expect(w['created_at'], '2026-07-01T09:00:00.000');
      expect(w['updated_at'], '2026-07-01T10:00:00.000');
    });

    test('agentGoalRunToWire omits null optional fields', () {
      final w = agentGoalRunToWire(
        AgentGoalRun(
          id: 'g-2',
          workspaceId: 'ws-1',
          spaceId: 'ch-1',
          conversationId: 'c-1',
          agentId: 'a-1',
          userText: 'finish the migration',
          kind: AgentGoalKind.goal,
          deadlineAt: DateTime(2026, 8, 1),
          costCapCents: 5000,
          maxRuns: 100,
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['kind'], 'goal');
      expect(w['status'], 'active');
      expect(w['cost_cents'], 0);
      expect(w['run_count'], 0);
      expect(w.containsKey('active_run_id'), isFalse);
      expect(w.containsKey('requested_by_user_id'), isFalse);
      expect(w.containsKey('summary'), isFalse);
    });

    test('repoToWire maps every field', () {
      final w = repoToWire(
        Repo(
          id: 'r-1',
          name: 'control-center',
          path: '/repo',
          remoteOwner: 'SamuelAlev',
          remoteName: 'control-center',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        ),
      );
      expect(w['id'], 'r-1');
      expect(w['name'], 'control-center');
      expect(w['path'], '/repo');
      expect(w['forge'], 'github');
      expect(w['remote_owner'], 'SamuelAlev');
      expect(w['remote_name'], 'control-center');
      expect(w['created_at'], '2026-01-01T00:00:00.000');
    });

    test('repoToWire and repoFromWire agree on their keys', () {
      // A mismatch here is silent and catastrophic: every repo arrives with an
      // empty owner/name, `hasForgeRemote` reads false, and the PR surfaces
      // report "no repositories configured" for a workspace full of repos.
      final original = Repo(
        id: 'r-1',
        name: 'group/sub/api',
        path: '/repo',
        forge: ForgeHost.gitlab,
        remoteOwner: 'group/sub',
        remoteName: 'api',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final restored = repoFromWire(repoToWire(original));

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.path, original.path);
      expect(restored.forge, ForgeHost.gitlab);
      expect(restored.remoteOwner, 'group/sub');
      expect(restored.remoteName, 'api');
      expect(restored.hasForgeRemote, isTrue);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('repoToWire feeds RepoDto.fromJson, which is what clients parse', () {
      // The seam that actually broke: the server mapper and the client DTO are
      // different code, and nothing else compares them. When they drifted apart
      // every repo reached the client with an empty owner/name, so the inbox
      // and the PR queue reported "no repositories configured" for a workspace
      // with five repos, the repo rows lost their avatars, and the owner/name
      // filter facets came up empty.
      final dto = RepoDto.fromJson(
        repoToWire(
          Repo(
            id: 'r-1',
            name: 'acme/web',
            path: '/repo',
            remoteOwner: 'acme',
            remoteName: 'web',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 2),
          ),
        ),
      );

      expect(dto.remoteOwner, 'acme');
      expect(dto.remoteName, 'web');
      expect(dto.forge, 'github');
    });

    test('a wire payload with no forge reads as GitHub, not as unconfigured',
        () {
      final restored = repoFromWire({
        'id': 'r-1',
        'name': 'acme/web',
        'path': '/repo',
        'remote_owner': 'acme',
        'remote_name': 'web',
      });
      expect(restored.forge, ForgeHost.github);
      expect(restored.hasForgeRemote, isTrue);
    });

    test('spaceReadToWire includes last_read_at only when set', () {
      expect(spaceReadToWire('c-1', null), {'space_id': 'c-1'});
      final withRead = spaceReadToWire('c-1', DateTime(2026, 7, 1, 9));
      expect(withRead['space_id'], 'c-1');
      expect(withRead['last_read_at'], '2026-07-01T09:00:00.000');
    });

    test('spaceReadFromWire round-trips', () {
      expect(spaceReadFromWire({'space_id': 'c-1'}), isNull);
      expect(
        spaceReadFromWire({'last_read_at': '2026-07-01T09:00:00.000'}),
        DateTime(2026, 7, 1, 9),
      );
    });

    test('agentRunLogToWire flattens cost into token columns', () {
      final w = agentRunLogToWire(
        AgentRunLog(
          id: 'run-1',
          agentId: 'a-1',
          workspaceId: 'ws-1',
          conversationId: 'c-1',
          startedAt: DateTime(2026, 7, 1, 9),
          status: RunStatus.completed,
          summary: 'done',
          adapter: 'harness',
          modelId: 'claude-opus-4-5',
          cost: const RunCost(
            inputTokens: 100,
            outputTokens: 50,
            estimatedCostCents: 7,
          ),
        ),
      );
      expect(w['id'], 'run-1');
      expect(w['agent_id'], 'a-1');
      expect(w['status'], 'completed');
      expect(w['input_tokens'], 100);
      expect(w['output_tokens'], 50);
      expect(w['estimated_cost_cents'], 7);
      expect(w['agent_role'], 'main');
      expect(w['output_contract_mode'], 'strict');
    });

    test('commitStatusToWire maps every field and encodes the state name', () {
      final wire = commitStatusToWire(
        CommitStatus(
          context: 'netlify/test-web-app/deploy-preview',
          state: CommitStatusState.success,
          targetUrl:
              'https://deploy-preview-2803.usectrl.dev',
          description: 'Deploy preview ready!',
          updatedAt: DateTime.utc(2026, 7, 20, 12, 30),
        ),
      );
      expect(wire['context'], 'netlify/test-web-app/deploy-preview');
      expect(wire['state'], 'success');
      expect(
        wire['target_url'],
        'https://deploy-preview-2803.usectrl.dev',
      );
      expect(wire['description'], 'Deploy preview ready!');
      expect(wire['updated_at'], '2026-07-20T12:30:00.000Z');
    });

    test('commitStatusToWire omits updated_at when null', () {
      final wire = commitStatusToWire(
        const CommitStatus(
          context: 'netlify/site/deploy-preview',
          state: CommitStatusState.pending,
          targetUrl: 'https://x--site.netlify.app',
        ),
      );
      expect(wire.containsKey('updated_at'), isFalse);
      expect(wire['state'], 'pending');
    });

    test('activeProcessInfoToWire maps every field', () {
      final w = activeProcessInfoToWire(
        ActiveProcessInfo(
          agentName: 'architect',
          workspaceName: 'ws',
          pid: 1234,
          command: 'pi --mode json',
          startTime: DateTime(2026, 7, 1, 9),
        ),
      );
      expect(w['agent_name'], 'architect');
      expect(w['workspace_name'], 'ws');
      expect(w['pid'], 1234);
      expect(w['command'], 'pi --mode json');
      expect(w['start_time'], '2026-07-01T09:00:00.000');
    });

    test('detectedAdapterToWire includes optional fields only when set', () {
      // Minimal — no version/path/capabilities.
      final minimal = detectedAdapterToWire(
        const DetectedAdapter(
          adapter: Adapter(
            id: 'pi',
            name: 'Pi',
            description: 'd',
            cliName: 'pi',
          ),
          status: DetectionStatus.notFound,
        ),
      );
      expect(minimal['adapter_id'], 'pi');
      expect(minimal['status'], 'notFound');
      expect(minimal.containsKey('version'), isFalse);
      expect(minimal.containsKey('capabilities'), isFalse);

      // Full — every optional field set.
      final full = detectedAdapterToWire(
        const DetectedAdapter(
          adapter: Adapter(
            id: 'pi',
            name: 'Pi',
            description: 'd',
            cliName: 'pi',
          ),
          status: DetectionStatus.found,
          version: '1.2.3',
          path: '/usr/local/bin/pi',
          capabilities: AdapterCapabilities(
            supportsJsonMode: true,
            supportsModelSelection: false,
          ),
        ),
      );
      expect(full['version'], '1.2.3');
      expect(full['path'], '/usr/local/bin/pi');
      final capabilities = full['capabilities'] as Map<String, dynamic>;
      expect(capabilities['supports_json_mode'], isTrue);
      expect(capabilities['supports_model_selection'], isFalse);
    });

    test('acpModelToWire includes optional fields only when set', () {
      final minimal = acpModelToWire(const AcpModel(id: 'm-1', name: 'Model'));
      expect(minimal['id'], 'm-1');
      expect(minimal['name'], 'Model');
      expect(minimal.containsKey('description'), isFalse);

      final full = acpModelToWire(
        const AcpModel(
          id: 'm-1',
          name: 'Model',
          description: 'desc',
          contextWindow: 200000,
          thinkingLevels: [
            ThinkingLevel(id: 'low', label: 'Low'),
            ThinkingLevel(id: 'high', label: 'High'),
          ],
          defaultThinkingLevel: 'low',
        ),
      );
      expect(full['description'], 'desc');
      expect(full['context_window'], 200000);
      expect((full['thinking_levels'] as List).length, 2);
      expect(full['default_thinking_level'], 'low');
    });

    test('backupSnapshotToWire carries the paths a restore needs', () {
      final wire = backupSnapshotToWire(
        BackupSnapshot(
          path: '/data/backups/2026-08-31T09-00-00-000Z',
          name: '2026-08-31T09-00-00-000Z',
          createdAt: DateTime.utc(2026, 8, 31, 9),
          bytes: 4096,
          workspaces: const [
            BackupSnapshotWorkspace(
              workspaceId: 'ws-1',
              path: '/data/backups/2026-08-31T09-00-00-000Z/ws-1/workspace.db',
              bytes: 2048,
            ),
          ],
          skippedWorkspaceIds: const ['ws-2'],
        ),
      );

      expect(wire['name'], '2026-08-31T09-00-00-000Z');
      expect(wire['created_at'], '2026-08-31T09:00:00.000Z');
      expect(wire['bytes'], 4096);
      expect(wire['complete'], isTrue);
      expect(wire['skipped_workspace_ids'], <String>['ws-2']);
      // The per-workspace path is what the client hands back to
      // `workspace.import`, so dropping it would leave the snapshot listable
      // and un-restorable.
      final workspace = (wire['workspaces'] as List).single as Map;
      expect(workspace['workspace_id'], 'ws-1');
      expect(
        workspace['path'],
        '/data/backups/2026-08-31T09-00-00-000Z/ws-1/workspace.db',
      );
      expect(workspace['bytes'], 2048);
    });

    test('backupSnapshotToWire omits a timestamp it could not read', () {
      final wire = backupSnapshotToWire(
        const BackupSnapshot(
          path: '/data/backups/half-written',
          name: 'half-written',
          bytes: 0,
          workspaces: [],
          complete: false,
        ),
      );

      expect(wire.containsKey('created_at'), isFalse);
      expect(wire['complete'], isFalse);
      expect(wire['workspaces'], isEmpty);
    });

    test('agentToWire maps every field and omits null optionals', () {
      final w = agentToWire(
        Agent(
          id: 'a-1',
          name: 'Architect',
          title: 'Arch',
          agentMdPath: '/a.md',
          workspaceId: 'ws-1',
          skills: AgentSkills(['architecture']),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      expect(w['id'], 'a-1');
      expect(w['name'], 'Architect');
      expect(w['skills'], ['architecture']);
      expect(w['strict_mode'], isFalse);
      expect(w['visibility'], isNotNull);
      expect(w['lifecycle_status'], isNotNull);
      expect(w['created_at'], '2026-01-01T00:00:00.000');
      // Optional fields absent.
      expect(w.containsKey('model_id'), isFalse);
      expect(w.containsKey('reports_to'), isFalse);
    });

    CalendarEvent calendarEvent({
      required DateTime start,
      required DateTime end,
      bool isAllDay = false,
    }) => CalendarEvent(
      id: 'ev-1',
      workspaceId: 'ws-1',
      accountId: 'acc-1',
      externalEventId: 'ext-1',
      calendarId: 'primary',
      title: 'Sync',
      startTime: start,
      endTime: end,
      updatedAt: DateTime.utc(2026, 8, 20, 12),
      isAllDay: isAllDay,
    );

    test('calendarEventToWire emits ISO instants for a timed event', () {
      final w = calendarEventToWire(
        calendarEvent(
          start: DateTime.utc(2026, 8, 26, 9),
          end: DateTime.utc(2026, 8, 26, 9, 30),
        ),
      );
      expect(w['start_time'], '2026-08-26T09:00:00.000Z');
      expect(w['end_time'], '2026-08-26T09:30:00.000Z');
      expect(w['is_all_day'], isFalse);
    });

    test(
      'calendarEventToWire emits a bare civil date for an all-day event',
      () {
        // All-day rows are stored as HOST-local midnights; a timestamp on the
        // wire would let a client in another timezone shift the event onto
        // the wrong day when it renders with `toLocal()`. The bare date pins
        // the civil day: every reader parses it as its OWN local midnight.
        final w = calendarEventToWire(
          calendarEvent(
            start: DateTime(2026, 8, 26),
            end: DateTime(2026, 8, 27), // Google's exclusive end date
            isAllDay: true,
          ),
        );
        expect(w['start_time'], '2026-08-26');
        expect(w['end_time'], '2026-08-27');
        expect(w['is_all_day'], isTrue);

        final parsed = DateTime.parse(w['start_time'] as String);
        expect(parsed.isUtc, isFalse);
        expect((parsed.year, parsed.month, parsed.day), (2026, 8, 26));
        expect((parsed.hour, parsed.minute), (0, 0));
      },
    );
  });

  group('prCountsTowardNeedsMyReview', () {
    Map<String, dynamic> pr({
      bool isDraft = false,
      String authorLogin = 'someone-else',
      List<String> reviewers = const ['octocat'],
      List<String> teamSlugs = const [],
      String repoFullName = 'acme/app',
    }) => {
      'is_draft': isDraft,
      'author': {'login': authorLogin},
      'repo_full_name': repoFullName,
      'requested_reviewers': [for (final r in reviewers) {'login': r}],
      'requested_team_slugs': teamSlugs,
    };

    test('counts a non-draft PR by another author requesting the operator', () {
      expect(prCountsTowardNeedsMyReview(pr(), 'octocat'), isTrue);
    });

    test('reviewer login matching is case-insensitive', () {
      expect(
        prCountsTowardNeedsMyReview(pr(reviewers: ['OctoCat']), 'octocat'),
        isTrue,
      );
    });

    test('excludes drafts even when the operator is requested', () {
      // The inbox classifier files drafts by others in NO section ("drafts
      // are not reviewable yet") — the badge must not count rows the page
      // can never show.
      expect(prCountsTowardNeedsMyReview(pr(isDraft: true), 'octocat'), isFalse);
    });

    test("excludes the operator's own PRs", () {
      // Own PRs land in author-centric sections (returnedToYou, approved, …),
      // never needsYourReview.
      expect(
        prCountsTowardNeedsMyReview(pr(authorLogin: 'OctoCat'), 'octocat'),
        isFalse,
      );
    });

    test('excludes PRs not requesting the operator', () {
      expect(
        prCountsTowardNeedsMyReview(pr(reviewers: ['hubot']), 'octocat'),
        isFalse,
      );
    });

    test('tolerates a missing author and empty reviewer list', () {
      expect(
        prCountsTowardNeedsMyReview(
          {'is_draft': false, 'requested_reviewers': const []},
          'octocat',
        ),
        isFalse,
      );
    });

    test('counts a PR that still requests a team the operator belongs to', () {
      expect(
        prCountsTowardNeedsMyReview(
          pr(reviewers: const [], teamSlugs: const ['frontend-platform']),
          'octocat',
          viewerTeamsByOrg: {
            'acme': {'frontend-platform'},
          },
        ),
        isTrue,
      );
    });

    test('excludes a team request when the operator is not on that team', () {
      expect(
        prCountsTowardNeedsMyReview(
          pr(reviewers: const [], teamSlugs: const ['frontend-platform']),
          'octocat',
          viewerTeamsByOrg: {
            'acme': {'other-team'},
          },
        ),
        isFalse,
      );
    });
  });
}
