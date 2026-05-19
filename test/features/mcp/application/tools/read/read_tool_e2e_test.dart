import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/agent_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/artifact_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/gh_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/issue_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/local_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/mcp_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/memory_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/pr_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/rule_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/handlers/skill_protocol_handler.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/application/tools/read/read_tool.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../fakes/fake_agent_run_log_repository.dart';
import '../../../../../fakes/fake_filesystem_port.dart';
import '../../../../../fakes/fake_github_content_client.dart';
import '../../../../../fakes/fake_github_pr_client.dart';
import '../../../../../fakes/fake_memory_repositories.dart';

class _FakeTool extends McpTool {
  _FakeTool({required String toolName}) : _name = toolName;
  final String _name;
  @override
  String get name => _name;
  @override
  String get description => 'test';
  @override
  Map<String, dynamic> get inputSchema => const {};
  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

GitHubPullRequest _makePr({int number = 1}) => GitHubPullRequest(
      number: number,
      title: 'Test PR',
      body: 'body',
      state: 'open',
      isDraft: false,
      userLogin: 'user',
      headSha: 'sha1',
      baseRef: 'main',
      headRef: 'feat',
      htmlUrl: 'https://github.com/owner/repo/pull/$number',
      nodeId: 'n$number',
    );

void main() {
  late FakeGitHubPrClient prClient;
  late FakeGitHubContentClient contentClient;
  late FakeAgentRunLogRepository runLogs;
  late FakeMemoryFactRepository facts;
  late FakeMemoryPolicyRepository policies;
  late FakeAgentWorkingMemoryRepository workingMemory;
  late FakeFilesystemPort filesystem;
  late InternalUrlRouter router;
  late ReadTool readTool;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cc_e2e_');
    prClient = FakeGitHubPrClient();
    contentClient = FakeGitHubContentClient();
    runLogs = FakeAgentRunLogRepository();
    facts = FakeMemoryFactRepository();
    policies = FakeMemoryPolicyRepository();
    workingMemory = FakeAgentWorkingMemoryRepository();
    filesystem = FakeFilesystemPort();

    router = InternalUrlRouter(
      pr: PrProtocolHandler(client: prClient),
      issue: IssueProtocolHandler(client: prClient),
      gh: GhProtocolHandler(client: contentClient),
      agent: AgentProtocolHandler(runLogs: runLogs),
      artifact: ArtifactProtocolHandler(runLogs: runLogs),
      skill: SkillProtocolHandler(filesystem: filesystem),
      rule: RuleProtocolHandler(policies: policies),
      local: LocalProtocolHandler(filesystem: filesystem),
      memory: MemoryProtocolHandler(
        facts: facts,
        policies: policies,
        workingMemory: workingMemory,
        filesystem: filesystem,
      ),
      mcp: McpProtocolHandler(
        registry: McpToolRegistry([_FakeTool(toolName: 'read')]),
      ),
    );
    readTool = ReadTool(router: router);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ── Error cases ───────────────────────────────────────
  group('error cases', () {
    test('missing path argument returns error', () async {
      final result = await readTool.run({});
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument'),
      );
    });

    test('invalid URL returns error', () async {
      final result = await readTool.run({'path': 'not-a-url'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Invalid URL'));
    });

    test('unknown scheme returns error', () async {
      final result = await readTool.run({'path': 'ftp://file'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('unknown scheme'));
    });
  });

  // ── pr:// ──────────────────────────────────────────────
  group('pr://', () {
    test('pr://owner/repo/1 returns PR view', () async {
      prClient.pullRequests['owner/repo/1'] = _makePr();

      final result = await readTool.run({'path': 'pr://owner/repo/1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('# 1: Test PR'));
    });

    test('pr://owner/repo/1/diff returns file list', () async {
      prClient.files['owner/repo/1'] = const [
        GitHubPullRequestFile(
          filename: 'a.dart',
          status: 'modified',
          additions: 1,
          deletions: 1,
          changes: 2,
          patch: '@@ -1 +1 @@\n-old\n+new',
        ),
      ];

      final result = await readTool.run({'path': 'pr://owner/repo/1/diff'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('1. a.dart'));
    });

    test('pr://owner/repo/1/diff/all returns full diff', () async {
      prClient.diffs['owner/repo/1'] =
          'diff --git a/a.dart b/a.dart\n@@ -1 +1 @@\n-old\n+new\n';

      final result =
          await readTool.run({'path': 'pr://owner/repo/1/diff/all'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('diff --git'));
    });
  });

  // ── issue:// ───────────────────────────────────────────
  group('issue://', () {
    test('issue://owner/repo/5 returns issue view', () async {
      final result = await readTool.run({'path': 'issue://owner/repo/5'});
      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('# owner/repo issue #5'),
      );
    });
  });

  // ── gh:// ──────────────────────────────────────────────
  group('gh://', () {
    test('gh://owner/repo/blob/main/lib/main.dart returns file', () async {
      contentClient.files['owner/repo/lib/main.dart@main'] = 'void main() {}';

      final result = await readTool.run(
        {'path': 'gh://owner/repo/blob/main/lib/main.dart'},
      );
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['content'], 'void main() {}');
    });
  });

  // ── memory:// ──────────────────────────────────────────
  group('memory://', () {
    test('memory://root with workspace_id returns summary', () async {
      final result = await readTool.run({
        'path': 'memory://root',
        'workspace_id': 'ws-1',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['fact_count'], 0);
    });

    test('memory://root without workspace_id returns error', () async {
      final result = await readTool.run({'path': 'memory://root'});
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('requires a workspace_id'),
      );
    });
  });

  // ── skill:// ───────────────────────────────────────────
  group('skill://', () {
    test('skill://code-review with workspace_id succeeds', () async {
      await filesystem.writeSkillFile('ws-1', 'code-review', '# Code Review');

      final result = await readTool.run({
        'path': 'skill://code-review',
        'workspace_id': 'ws-1',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skill_slug'], 'code-review');
    });

    test('skill://code-review without workspace_id returns error', () async {
      final result = await readTool.run({'path': 'skill://code-review'});
      expect(result.isError, isTrue);
    });
  });

  // ── agent:// ───────────────────────────────────────────
  group('agent://', () {
    test('agent://abc returns content', () async {
      final logFile = File('${tempDir.path}/agent.log');
      await logFile.writeAsString('agent output');
      runLogs.seed(AgentRunLog(
        id: 'abc',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await readTool.run({'path': 'agent://abc'});
      expect(result.isError, isFalse);
    });
  });

  // ── artifact:// ────────────────────────────────────────
  group('artifact://', () {
    test('artifact://42 returns content', () async {
      final logFile = File('${tempDir.path}/artifact.log');
      await logFile.writeAsString('raw output');
      runLogs.seed(AgentRunLog(
        id: '42',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await readTool.run({'path': 'artifact://42'});
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['artifact_id'], '42');
    });
  });

  // ── rule:// ────────────────────────────────────────────
  group('rule://', () {
    test('rule://domain with workspace_id returns policies', () async {
      policies.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws-1',
          domain: 'domain',
          rule: 'The rule',
          active: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await readTool.run({
        'path': 'rule://domain',
        'workspace_id': 'ws-1',
      });
      expect(result.isError, isFalse);
    });

    test('rule://domain without workspace_id returns error', () async {
      final result = await readTool.run({'path': 'rule://domain'});
      expect(result.isError, isTrue);
    });
  });

  // ── local:// ───────────────────────────────────────────
  group('local://', () {
    test('local://PLAN.md with workspace_id succeeds', () async {
      final dir = await Directory.systemTemp.createTemp('cc_local_e2e_');
      try {
        await File('${dir.path}/PLAN.md').writeAsString('# Plan');

        // Re-bind local handler with temp dir
        final fs = FakeFilesystemPort()..workspaceDirOverride = dir;
        final customRouter = InternalUrlRouter(
          pr: PrProtocolHandler(client: prClient),
          issue: IssueProtocolHandler(client: prClient),
          gh: GhProtocolHandler(client: contentClient),
          agent: AgentProtocolHandler(runLogs: runLogs),
          artifact: ArtifactProtocolHandler(runLogs: runLogs),
          skill: SkillProtocolHandler(filesystem: filesystem),
          rule: RuleProtocolHandler(policies: policies),
          local: LocalProtocolHandler(filesystem: fs),
          memory: MemoryProtocolHandler(
            facts: facts,
            policies: policies,
            workingMemory: workingMemory,
            filesystem: filesystem,
          ),
          mcp: McpProtocolHandler(
            registry: McpToolRegistry([_FakeTool(toolName: 'read')]),
          ),
        );
        final tool = ReadTool(router: customRouter);

        final result = await tool.run({
          'path': 'local://PLAN.md',
          'workspace_id': 'ws-1',
        });
        expect(result.isError, isFalse);
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['filename'], 'PLAN.md');
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  // ── mcp:// ─────────────────────────────────────────────
  group('mcp://', () {
    test('mcp://read returns matching tools', () async {
      final result = await readTool.run({'path': 'mcp://read'});
      expect(result.isError, isFalse);
    });
  });
}
