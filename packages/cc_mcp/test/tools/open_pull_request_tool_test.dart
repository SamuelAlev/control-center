import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NeedsSignInException;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/open_pull_request_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakePort port;
  late OpenPullRequestTool tool;

  setUp(() {
    port = _FakePort();
    tool = OpenPullRequestTool(pullRequests: port);
  });

  test('only a run can call it, and the run names its own conversation', () {
    expect(tool.name, kAgentOpenPullRequestTool);
    expect(tool.requiresRunGrant, isTrue);
    expect(tool.actionClasses, {ActionClass.prCreate});
    expect(tool.forcedScopeKeys, contains('conversation_id'));
    expect(
      tool.requiredScopeKeys,
      containsAll(['workspace_id', 'conversation_id']),
    );

    // The model cannot point the call at another workspace or conversation.
    const scope = McpCallScope(
      workspaceId: 'w1',
      conversationId: 'c1',
      attested: true,
    );
    final scoped = scope.apply(
      {'workspace_id': 'w2', 'conversation_id': 'c-other', 'head': 'x'},
      tool.inputSchema,
      force: tool.forcedScopeKeys,
    );
    expect(scoped['workspace_id'], 'w1');
    expect(scoped['conversation_id'], 'c1');
  });

  test('forwards the draft and answers the pull request', () async {
    final result = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'repo': 'acme/widgets',
      'head': 'feature/x',
      'base': 'main',
      'title': 'Add the widget',
      'body': 'Details',
      'draft': true,
    });
    expect(result.isError, isFalse);
    final wire = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(wire, {
      'repo': 'acme/widgets',
      'number': 7,
      'url': 'https://github.com/acme/widgets/pull/7',
      'author': 'requester',
    });
    final sent = port.drafts.single;
    expect(sent.workspaceId, 'w1');
    expect(sent.conversationId, 'c1');
    expect(sent.repo, 'acme/widgets');
    expect((sent.head, sent.base), ('feature/x', 'main'));
    expect(sent.draft, isTrue);
  });

  test('a missing argument or a refusal is an error result', () async {
    final missing = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'head': 'feature/x',
      'title': 'x',
    });
    expect(missing.isError, isTrue);
    expect(missing.content.first.text, contains('base'));

    port.refusal = const NeedsSignInException('github', 'Sign in to GitHub.');
    final refused = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'head': 'feature/x',
      'base': 'main',
      'title': 'x',
    });
    expect(refused.isError, isTrue);
    expect(refused.content.first.text, contains('Sign in to GitHub'));
  });
}

class _FakePort implements AgentPullRequestPort {
  final drafts = <AgentPullRequestDraft>[];
  Exception? refusal;

  @override
  Future<String?> requesterOf({
    required String workspaceId,
    required String conversationId,
  }) async => 'alice';

  @override
  Future<Set<String>> approvalOwnersOf({
    required String workspaceId,
    required String conversationId,
  }) async => {'alice'};

  @override
  Future<List<AgentCommitIdentity>> commitIdentitiesOf({
    required String workspaceId,
    required String conversationId,
  }) async => const [];

  @override
  Future<AgentPullRequestResult> open(AgentPullRequestDraft draft) async {
    if (refusal case final refusal?) {
      throw refusal;
    }
    drafts.add(draft);
    return AgentPullRequestResult(
      repoFullName: draft.repo ?? 'acme/widgets',
      number: 7,
      url: 'https://github.com/acme/widgets/pull/7',
      author: AgentPullRequestAuthor.requester,
    );
  }

  @override
  Future<AgentPullRequestEditResult> update(AgentPullRequestEdit edit) =>
      throw UnimplementedError();
}
