import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
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
          conversationId: 'c-1',
          content: 'do it',
          status: TodoStatus.inProgress,
          position: 2,
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['id'], 't-1');
      expect(w['workspace_id'], 'ws-1');
      expect(w['conversation_id'], 'c-1');
      expect(w['content'], 'do it');
      expect(w['status'], 'in_progress');
      expect(w['position'], 2);
      expect(w['created_at'], '2026-07-01T09:00:00.000');
      expect(w['updated_at'], '2026-07-01T10:00:00.000');
    });

    test('goalToWire maps every field', () {
      final w = goalToWire(
        ConversationGoal(
          conversationId: 'c-1',
          workspaceId: 'ws-1',
          title: 'Ship it',
          createdAt: DateTime(2026, 7, 1, 9),
          updatedAt: DateTime(2026, 7, 1, 10),
        ),
      );
      expect(w['conversation_id'], 'c-1');
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
          channelId: 'ch-1',
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
      expect(w['channel_id'], 'ch-1');
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
          channelId: 'ch-1',
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
          githubOwner: 'SamuelAlev',
          githubRepoName: 'control-center',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        ),
      );
      expect(w['id'], 'r-1');
      expect(w['name'], 'control-center');
      expect(w['path'], '/repo');
      expect(w['github_owner'], 'SamuelAlev');
      expect(w['github_repo_name'], 'control-center');
      expect(w['created_at'], '2026-01-01T00:00:00.000');
    });

    test('channelReadToWire includes last_read_at only when set', () {
      expect(channelReadToWire('c-1', null), {'channel_id': 'c-1'});
      final withRead = channelReadToWire('c-1', DateTime(2026, 7, 1, 9));
      expect(withRead['channel_id'], 'c-1');
      expect(withRead['last_read_at'], '2026-07-01T09:00:00.000');
    });

    test('channelReadFromWire round-trips', () {
      expect(channelReadFromWire({'channel_id': 'c-1'}), isNull);
      expect(
        channelReadFromWire({'last_read_at': '2026-07-01T09:00:00.000'}),
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

    test('githubCliStatusToWire omits the token', () {
      final w = githubCliStatusToWire(
        const GitHubCliStatus(
          isInstalled: true,
          isAuthenticated: true,
          username: 'sam',
          token: 'ghp_secret',
        ),
      );
      expect(w['is_installed'], isTrue);
      expect(w['is_authenticated'], isTrue);
      expect(w['username'], 'sam');
      // SECURITY: the token never crosses the wire.
      expect(w.containsKey('token'), isFalse);
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
