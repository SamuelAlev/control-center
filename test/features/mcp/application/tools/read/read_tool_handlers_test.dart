import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_user.dart';
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
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../fakes/fake_agent_run_log_repository.dart';
import '../../../../../fakes/fake_filesystem_port.dart';
import '../../../../../fakes/fake_github_content_client.dart';
import '../../../../../fakes/fake_github_pr_client.dart';
import '../../../../../fakes/fake_memory_repositories.dart';

/// Fake filesystem that returns a real temp directory for local:// tests.
class _LocalTestFilesystem extends FakeFilesystemPort {

  _LocalTestFilesystem(this._workspaceRoot);
  final Directory _workspaceRoot;

  @override
  Future<Directory> workspaceDir(String workspaceId) async => _workspaceRoot;
}

/// A FakeGitHubPrClient variant whose files endpoint also throws — used to
/// verify the outer 406 error message path when no fallback succeeds.
class _FailingFilesClient extends FakeGitHubPrClient {
  _FailingFilesClient({required Object diffError}) {
    this.diffError = diffError;
  }

  @override
  Future<List<GitHubPullRequestFile>> listPullRequestFiles(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    throw diffError!;
  }
}

/// Simple fake McpTool for MCP handler tests.
class _FakeTool extends McpTool {
  _FakeTool({
    required this.toolName,
    String desc = 'test tool',
    Map<String, dynamic> schema = const {},
  })  : _desc = desc,
        _schema = schema;

  final String toolName;
  final String _desc;
  final Map<String, dynamic> _schema;

  @override
  String get name => toolName;
  @override
  String get description => _desc;
  @override
  Map<String, dynamic> get inputSchema => _schema;

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

/// Helper: make a PR with minimal fields.
GitHubPullRequest _makePr({
  int number = 42,
  String title = 'Test PR',
  String body = 'PR body',
  String state = 'open',
  String userLogin = 'testuser',
  String headSha = 'abc123',
  String baseRef = 'main',
  String headRef = 'feature/test',
}) =>
    GitHubPullRequest(
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: false,
      userLogin: userLogin,
      headSha: headSha,
      baseRef: baseRef,
      headRef: headRef,
      htmlUrl: 'https://github.com/owner/repo/pull/$number',
      nodeId: 'node_$number',
    );

GitHubCheckRun _makeCheckRun({
  int id = 1,
  String name = 'build',
  String appName = 'GitHub Actions',
}) =>
    GitHubCheckRun(
      id: id,
      name: name,
      status: GitHubCheckStatus.completed,
      conclusion: GitHubCheckConclusion.success,
      appName: appName,
      htmlUrl: 'https://github.com/owner/repo/runs/$id',
    );

GitHubPullRequestFile _makeFile({
  required String filename,
  String status = 'modified',
  int additions = 1,
  int deletions = 1,
  String patch = '@@ -1 +1 @@\n-old\n+new',
  String? previousFilename,
}) =>
    GitHubPullRequestFile(
      filename: filename,
      status: status,
      additions: additions,
      deletions: deletions,
      changes: additions + deletions,
      patch: patch,
      previousFilename: previousFilename,
    );

GitHubReview _makeReview({
  int id = 1,
  GitHubReviewState state = GitHubReviewState.approved,
  String body = 'LGTM',
  String login = 'reviewer1',
}) =>
    GitHubReview(
      id: id,
      state: state,
      body: body,
      submittedAt: DateTime(2025),
      user: GitHubUser(login: login, avatarUrl: ''),
    );

void main() {
  // ── PrProtocolHandler ──────────────────────────────────
  group('PrProtocolHandler', () {
    late FakeGitHubPrClient client;
    late PrProtocolHandler handler;

    setUp(() {
      client = FakeGitHubPrClient();
      handler = PrProtocolHandler(client: client);
    });

    test('none mode returns markdown with PR metadata', () async {
      client.pullRequests['owner/repo/42'] = _makePr();
      client.checkRuns['owner/repo/abc123'] = [
        _makeCheckRun(name: 'build'),
        _makeCheckRun(name: 'lint'),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: true,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('# 42: Test PR'));
      expect(result.content.first.text, contains('State: open'));
      expect(result.content.first.text, contains('build'));
      expect(result.content.first.text, contains('lint'));
    });

    test('none mode includes comments when enabled', () async {
      client.pullRequests['owner/repo/42'] = _makePr();
      client.reviews['owner/repo/42'] = [_makeReview()];
      client.issueComments['owner/repo/42'] = [
        GitHubIssueComment(
          id: 1,
          body: 'Nice work',
          user: const GitHubUser(login: 'commenter', avatarUrl: ''),
          createdAt: DateTime(2025),
        ),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: true,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Reviews (1)'));
      expect(result.content.first.text, contains('Comments (1)'));
    });

    test('none mode with ?comments=false skips comments', () async {
      client.pullRequests['owner/repo/42'] = _makePr();
      client.reviews['owner/repo/42'] = [_makeReview()];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, isNot(contains('Reviews')));
    });

    test('none mode PR not found returns error', () async {
      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 999,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: true,
        ),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('PR not found'));
    });

    test('none mode empty SHA returns no check runs', () async {
      client.pullRequests['owner/repo/42'] = _makePr(headSha: '');

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      // Should not crash
      expect(result.isError, isFalse);
    });

    test('none mode check run API failure falls back gracefully', () async {
      client.pullRequests['owner/repo/42'] = _makePr();
      client.checkRunError = Exception('API down');

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.none,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('# 42'));
      expect(result.content.first.text, isNot(contains('Check runs')));
    });

    test('fileList mode returns numbered file list from files endpoint',
        () async {
      client.files['owner/repo/42'] = [
        _makeFile(filename: 'src/main.dart'),
        _makeFile(filename: 'test/main_test.dart'),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.fileList,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('1. src/main.dart'));
      expect(result.content.first.text, contains('2. test/main_test.dart'));
    });

    test('fileList mode reports empty file list', () async {
      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.fileList,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('(no files)'));
    });

    test('full mode returns raw diff', () async {
      const diff = 'diff --git a/src/main.dart b/src/main.dart\n@@ -1 +1 @@\n-old\n+new\n';
      client.diffs['owner/repo/42'] = diff;

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.full,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('diff --git a/src/main.dart'));
    });

    test('singleFile mode returns nth file diff', () async {
      client.diffs['owner/repo/42'] =
          'diff --git a/file1.dart b/file1.dart\n@@ -1 +1 @@\n-a\n+b\n'
          'diff --git a/file2.dart b/file2.dart\n@@ -1 +1 @@\n-c\n+d\n';

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.singleFile,
          diffFileIndex: 2,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('file2.dart'));
      expect(result.content.first.text, isNot(contains('file1.dart')));
    });

    test('singleFile mode index out of range returns error', () async {
      client.diffs['owner/repo/42'] =
          'diff --git a/file1.dart b/file1.dart\n@@ -1 +1 @@\n-a\n+b\n';

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.singleFile,
          diffFileIndex: 99,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('out of range'));
    });

    test('full mode synthesises diff from files endpoint on HTTP 406',
        () async {
      client.diffError = const NetworkException(
        'too many files',
        statusCode: 406,
        responseBody:
            '{"message":"Sorry, the diff exceeded the maximum number of files (300)."}',
      );
      client.files['owner/repo/42'] = [
        _makeFile(filename: 'a.dart', patch: '@@ -1 +1 @@\n-a\n+A'),
        _makeFile(filename: 'b.dart', patch: '@@ -1 +1 @@\n-b\n+B'),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.full,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('diff --git a/a.dart b/a.dart'));
      expect(text, contains('diff --git a/b.dart b/b.dart'));
      expect(text, contains('-a'));
      expect(text, contains('+B'));
    });

    test('full mode synthesised diff marks files with empty patches',
        () async {
      client.diffError = const NetworkException(
        'too many files',
        statusCode: 406,
        responseBody: '{"message":"diff exceeded"}',
      );
      client.files['owner/repo/42'] = [
        _makeFile(
          filename: 'big.bin',
          status: 'modified',
          additions: 10,
          deletions: 5,
          patch: '',
        ),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.full,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('diff --git a/big.bin b/big.bin'));
      expect(text, contains('patch unavailable'));
      expect(text, contains('+10 -5'));
    });

    test('singleFile mode falls back to files endpoint on HTTP 406',
        () async {
      client.diffError = const NetworkException(
        'too many files',
        statusCode: 406,
        responseBody: '{"message":"diff exceeded"}',
      );
      client.files['owner/repo/42'] = [
        _makeFile(filename: 'first.dart', patch: '@@ -1 +1 @@\n-one\n+ONE'),
        _makeFile(filename: 'second.dart', patch: '@@ -1 +1 @@\n-two\n+TWO'),
      ];

      final result = await handler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.singleFile,
          diffFileIndex: 2,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('diff --git a/second.dart b/second.dart'));
      expect(text, contains('+TWO'));
      expect(text, isNot(contains('first.dart')));
    });

    test('406 surfaces github message when fallback also fails', () async {
      client.diffError = const NetworkException(
        'too many files',
        statusCode: 406,
        responseBody:
            '{"message":"Sorry, the diff exceeded the maximum number of files (300)."}',
      );
      // Force the files endpoint to also fail by giving the client a non-fake
      // path: don't populate `files` and instead throw via a separate
      // exception. The fake returns an empty list by default, so the diff
      // ends up as an empty string — that's still success. To verify the
      // "outer 406 message" path, simulate the files endpoint also throwing
      // 406 by reusing the same exception (the client.diffError doesn't apply
      // to files, so we override via a custom subclass below).
      final failingClient = _FailingFilesClient(diffError: client.diffError!);
      final failingHandler = PrProtocolHandler(client: failingClient);

      final result = await failingHandler.handle(
        const PrUrl(
          owner: 'owner',
          repo: 'repo',
          number: 42,
          diffMode: PrDiffMode.full,
          diffFileIndex: null,
          includeComments: false,
        ),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      final text = result.content.first.text;
      expect(text, contains('HTTP 406'));
      expect(text, contains('diff exceeded the maximum number of files'));
      expect(text, contains('pr://owner/repo/42/diff'));
    });
  });

  // ── IssueProtocolHandler ───────────────────────────────
  group('IssueProtocolHandler', () {
    late FakeGitHubPrClient client;
    late IssueProtocolHandler handler;

    setUp(() {
      client = FakeGitHubPrClient();
      handler = IssueProtocolHandler(client: client);
    });

    test('returns markdown with issue comments', () async {
      client.issueComments['octocat/hello/5'] = [
        GitHubIssueComment(
          id: 1,
          body: 'First comment',
          user: const GitHubUser(login: 'user1', avatarUrl: ''),
          createdAt: DateTime(2025, 1, 1),
        ),
        GitHubIssueComment(
          id: 2,
          body: 'Second comment',
          user: const GitHubUser(login: 'user2', avatarUrl: ''),
          createdAt: DateTime(2025, 1, 2),
        ),
      ];

      final result = await handler.handle(
        const IssueUrl(owner: 'octocat', repo: 'hello', number: 5),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('# octocat/hello issue #5'),
      );
      expect(result.content.first.text, contains('First comment'));
      expect(result.content.first.text, contains('Second comment'));
    });

    test('empty comments returns valid output', () async {
      final result = await handler.handle(
        const IssueUrl(owner: 'owner', repo: 'repo', number: 1),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Comments: 0'));
    });
  });

  // ── GhProtocolHandler ──────────────────────────────────
  group('GhProtocolHandler', () {
    late FakeGitHubContentClient client;
    late GhProtocolHandler handler;

    setUp(() {
      client = FakeGitHubContentClient();
      handler = GhProtocolHandler(client: client);
    });

    test('returns JSON with file content', () async {
      client.files['owner/repo/lib/main.dart@main'] = 'void main() {}';

      final result = await handler.handle(
        const GhBlobUrl(
          owner: 'owner',
          repo: 'repo',
          ref: 'main',
          path: 'lib/main.dart',
        ),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['owner'], 'owner');
      expect(data['repo'], 'repo');
      expect(data['ref'], 'main');
      expect(data['path'], 'lib/main.dart');
      expect(data['content'], 'void main() {}');
    });

    test('passes correct args to client', () async {
      client.files['owner/repo/src/foo.dart@abc123'] = 'content';

      await handler.handle(
        const GhBlobUrl(
          owner: 'owner',
          repo: 'repo',
          ref: 'abc123',
          path: 'src/foo.dart',
        ),
        const ReadContext(),
      );

      expect(client.lastCall, isNotNull);
      expect(client.lastCall!.owner, 'owner');
      expect(client.lastCall!.repo, 'repo');
      expect(client.lastCall!.ref, 'abc123');
      expect(client.lastCall!.path, 'src/foo.dart');
    });
  });

  // ── LocalProtocolHandler ───────────────────────────────
  group('LocalProtocolHandler', () {
    late Directory tempDir;
    late _LocalTestFilesystem filesystem;
    late LocalProtocolHandler handler;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cc_local_test_');
      filesystem = _LocalTestFilesystem(tempDir);
      handler = LocalProtocolHandler(filesystem: filesystem);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('reads file from workspace dir', () async {
      await File('${tempDir.path}/PLAN.md').writeAsString('# Plan');

      final result = await handler.handle(
        const LocalUrl(filename: 'PLAN.md'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['filename'], 'PLAN.md');
      expect(data['content'], '# Plan');
    });

    test('missing workspace_id returns error', () async {
      final result = await handler.handle(
        const LocalUrl(filename: 'PLAN.md'),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('requires a workspace_id'),
      );
    });

    test('path traversal returns error', () async {
      final result = await handler.handle(
        const LocalUrl(filename: '../secret.md'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('invalid path segments'),
      );
    });

    test('file not found returns error', () async {
      final result = await handler.handle(
        const LocalUrl(filename: 'nonexistent.md'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });
  });

  // ── SkillProtocolHandler ───────────────────────────────
  group('SkillProtocolHandler', () {
    late FakeFilesystemPort filesystem;
    late SkillProtocolHandler handler;

    setUp(() {
      filesystem = FakeFilesystemPort();
      handler = SkillProtocolHandler(filesystem: filesystem);
    });

    test('reads skill file content', () async {
      await filesystem.writeSkillFile('ws-1', 'code-review', '# Code Review');

      final result = await handler.handle(
        const SkillUrl(slug: 'code-review'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skill_slug'], 'code-review');
      expect(data['content'], '# Code Review');
    });

    test('missing workspace_id returns error', () async {
      final result = await handler.handle(
        const SkillUrl(slug: 'code-review'),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('requires a workspace_id'));
    });

    test('skill not found returns error', () async {
      final result = await handler.handle(
        const SkillUrl(slug: 'nonexistent'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });
  });

  // ── RuleProtocolHandler ────────────────────────────────
  group('RuleProtocolHandler', () {
    late FakeMemoryPolicyRepository policies;
    late RuleProtocolHandler handler;

    setUp(() {
      policies = FakeMemoryPolicyRepository();
      handler = RuleProtocolHandler(policies: policies);
    });

    test('returns matching policies', () async {
      policies.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws-1',
          domain: 'code-style',
          rule: 'Use trailing commas',
          active: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await handler.handle(
        const RuleUrl(name: 'code-style'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect((data['rules'] as List).first['domain'], 'code-style');
    });

    test('missing workspace_id returns error', () async {
      final result = await handler.handle(
        const RuleUrl(name: 'code-style'),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('requires a workspace_id'));
    });

    test('no matching policies returns error', () async {
      final result = await handler.handle(
        const RuleUrl(name: 'code-style'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });
  });

  // ── MemoryProtocolHandler ──────────────────────────────
  group('MemoryProtocolHandler', () {
    late FakeMemoryFactRepository facts;
    late FakeMemoryPolicyRepository policies;
    late FakeAgentWorkingMemoryRepository workingMemory;
    late FakeFilesystemPort filesystem;
    late MemoryProtocolHandler handler;

    setUp(() {
      facts = FakeMemoryFactRepository();
      policies = FakeMemoryPolicyRepository();
      workingMemory = FakeAgentWorkingMemoryRepository();
      filesystem = FakeFilesystemPort();
      handler = MemoryProtocolHandler(
        facts: facts,
        policies: policies,
        workingMemory: workingMemory,
        filesystem: filesystem,
      );
    });

    test('summary returns fact and policy counts', () async {
      facts.seed([
        MemoryFact(
          id: 'f1',
          workspaceId: 'ws-1',
          domain: 'decision',
          topic: 'architecture',
          content: 'Use Clean Architecture',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);
      policies.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws-1',
          domain: 'code-style',
          rule: 'Use trailing commas',
          active: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.summary),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['fact_count'], 1);
      expect(data['policy_count'], 1);
      expect(data['topics'], ['architecture']);
      expect(data['domains'], ['code-style']);
    });

    test('full returns markdown index', () async {
      facts.seed([
        MemoryFact(
          id: 'f1',
          workspaceId: 'ws-1',
          domain: 'decision',
          topic: 'architecture',
          content: 'Use Clean Architecture',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);
      policies.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws-1',
          domain: 'code-style',
          rule: 'Use trailing commas',
          active: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.full),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['content'], contains('# Memory Index'));
      expect(data['content'], contains('## Facts (1)'));
      expect(data['content'], contains('## Policies (1)'));
    });

    test('skill reads skill file from memory', () async {
      await filesystem.writeSkillFile('ws-1', 'code-review', '# Code Review');

      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.skill, slug: 'code-review'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['skill_slug'], 'code-review');
      expect(data['content'], '# Code Review');
    });

    test('policy returns matching policies', () async {
      policies.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws-1',
          domain: 'security',
          rule: 'Sanitize all inputs',
          active: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.policy, slug: 'security'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['domain'], 'security');
    });

    test('agent returns working memory', () async {
      workingMemory.seed([
        AgentWorkingMemory(
          id: 'wm1',
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          content: 'Remember: use null safety',
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.agent, agentId: 'agent-1'),
        const ReadContext(workspaceId: 'ws-1'),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['agent_id'], 'agent-1');
      expect(data['content'], 'Remember: use null safety');
    });

    test('missing workspace_id returns error', () async {
      final result = await handler.handle(
        const MemoryUrl(kind: MemoryUrlKind.summary),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('requires a workspace_id'));
    });
  });

  // ── AgentProtocolHandler ───────────────────────────────
  group('AgentProtocolHandler', () {
    late FakeAgentRunLogRepository runLogs;
    late Directory tempDir;
    late AgentProtocolHandler handler;

    setUp(() async {
      runLogs = FakeAgentRunLogRepository();
      tempDir = await Directory.systemTemp.createTemp('cc_agent_test_');
      handler = AgentProtocolHandler(runLogs: runLogs);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('found by run log ID returns content', () async {
      final logFile = File('${tempDir.path}/log.json');
      await logFile.writeAsString('{"result": "ok"}');

      runLogs.seed(AgentRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await handler.handle(
        const AgentUrl(id: 'log-1'),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['content'], '{"result": "ok"}');
    });

    test('found by agent ID returns latest completed run', () async {
      final logFile = File('${tempDir.path}/latest.json');
      await logFile.writeAsString('{"result": "latest"}');

      runLogs.seed(AgentRunLog(
        id: 'log-old',
        agentId: 'agent-1',
        startedAt: DateTime(2025, 1, 1),
        status: RunStatus.completed,
        logPath: '/nonexistent/old.json',
      ));
      runLogs.seed(AgentRunLog(
        id: 'log-new',
        agentId: 'agent-1',
        startedAt: DateTime(2025, 1, 10),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await handler.handle(
        const AgentUrl(id: 'agent-1'),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['content'], '{"result": "latest"}');
    });

    test('JSON path extraction returns extracted field', () async {
      final logFile = File('${tempDir.path}/log.json');
      await logFile.writeAsString(
        '{"findings": [{"path": "/a/b", "severity": "high"}]}',
      );

      runLogs.seed(AgentRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await handler.handle(
        const AgentUrl(id: 'log-1', jsonPath: 'findings/0/path'),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['content'], '/a/b');
    });

    test('not found returns error', () async {
      final result = await handler.handle(
        const AgentUrl(id: 'nonexistent'),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });
  });

  // ── ArtifactProtocolHandler ────────────────────────────
  group('ArtifactProtocolHandler', () {
    late FakeAgentRunLogRepository runLogs;
    late Directory tempDir;
    late ArtifactProtocolHandler handler;

    setUp(() async {
      runLogs = FakeAgentRunLogRepository();
      tempDir = await Directory.systemTemp.createTemp('cc_artifact_test_');
      handler = ArtifactProtocolHandler(runLogs: runLogs);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('found by ID with logPath returns content', () async {
      final logFile = File('${tempDir.path}/artifact.log');
      await logFile.writeAsString('raw artifact data');

      runLogs.seed(AgentRunLog(
        id: '42',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: logFile.path,
      ));

      final result = await handler.handle(
        const ArtifactUrl(id: 42),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['artifact_id'], '42');
      expect(data['content'], 'raw artifact data');
    });

    test('found by ID but logPath null returns error with available IDs', () async {
      runLogs.seed(AgentRunLog(
        id: '42',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: null,
      ));
      runLogs.seed(AgentRunLog(
        id: '43',
        agentId: 'agent-2',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: '/some/path',
      ));

      final result = await handler.handle(
        const ArtifactUrl(id: 42),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Available'));
      expect(result.content.first.text, contains('43'));
    });

    test('not found returns error', () async {
      final result = await handler.handle(
        const ArtifactUrl(id: 999),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });

    test('file deleted from disk returns error', () async {
      runLogs.seed(AgentRunLog(
        id: '42',
        agentId: 'agent-1',
        startedAt: DateTime(2025),
        status: RunStatus.completed,
        logPath: '/nonexistent/path.log',
      ));

      final result = await handler.handle(
        const ArtifactUrl(id: 42),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found on disk'));
    });
  });

  // ── McpProtocolHandler ─────────────────────────────────
  group('McpProtocolHandler', () {
    late McpToolRegistry registry;
    late McpProtocolHandler handler;

    setUp(() {
      registry = McpToolRegistry([
        _FakeTool(toolName: 'read', desc: 'Read resources'),
        _FakeTool(toolName: 'write', desc: 'Write files'),
        _FakeTool(toolName: 'bash', desc: 'Execute commands'),
      ]);
      handler = McpProtocolHandler(registry: registry);
    });

    test('matching tools returned', () async {
      final result = await handler.handle(
        const McpUrl(uri: 'read'),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(data['uri'], 'read');
    });

    test('no match returns error with available tools', () async {
      final result = await handler.handle(
        const McpUrl(uri: 'nonexistent'),
        const ReadContext(),
      );

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('No MCP tools match'));
      expect(result.content.first.text, contains('read'));
      expect(result.content.first.text, contains('write'));
      expect(result.content.first.text, contains('bash'));
    });

    test('empty URI returns all tools', () async {
      final result = await handler.handle(
        const McpUrl(uri: ''),
        const ReadContext(),
      );

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
