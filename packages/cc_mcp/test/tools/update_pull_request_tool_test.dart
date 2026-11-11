import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, ValidationException;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/update_pull_request_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakePort port;
  late UpdatePullRequestTool tool;

  setUp(() {
    port = _FakePort();
    tool = UpdatePullRequestTool(pullRequests: port);
  });

  test('only a run can call it, asks like any other publish, and the run '
      'names its own conversation', () {
    expect(tool.name, kAgentUpdatePullRequestTool);
    expect(tool.requiresRunGrant, isTrue);
    expect(tool.actionClasses, {ActionClass.prPublish});
    expect(tool.forcedScopeKeys, {'conversation_id'});
    expect(tool.requiredScopeKeys, {'workspace_id', 'conversation_id'});
    const scope = McpCallScope(
      workspaceId: 'w1',
      conversationId: 'c1',
      attested: true,
    );
    final scoped = scope.apply(
      {'workspace_id': 'w2', 'conversation_id': 'c-other', 'number': 3},
      tool.inputSchema,
      force: tool.forcedScopeKeys,
    );
    expect(scoped['workspace_id'], 'w1');
    expect(scoped['conversation_id'], 'c1');
  });

  test('forwards the edit and answers where it went', () async {
    final result = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'repo': 'acme/widgets',
      'number': '7',
      'title': 'Add the widget',
      'body': 'Adds it.',
    });
    expect(result.isError, isFalse);
    expect(jsonDecode(result.content.first.text), {
      'repo': 'acme/widgets',
      'number': 7,
      'url': 'https://github.com/acme/widgets/pull/7',
    });
    final sent = port.edits.single;
    expect((sent.workspaceId, sent.conversationId), ('w1', 'c1'));
    expect((sent.repo, sent.number), ('acme/widgets', 7));
    expect((sent.title, sent.body), ('Add the widget', 'Adds it.'));
  });

  test('a title alone or a body alone leaves the other out', () async {
    await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'number': 7,
      'title': 'Add the widget',
    });
    await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'number': 7,
      'body': '',
    });
    expect(port.edits.map((e) => (e.repo, e.title, e.body)), [
      (null, 'Add the widget', null),
      (null, null, ''),
    ]);
  });

  test('missing or malformed arguments are errors and reach nothing', () async {
    for (final arguments in <Map<String, dynamic>>[
      {'workspace_id': 'w1', 'conversation_id': 'c1', 'title': 'x'},
      {
        'workspace_id': 'w1',
        'conversation_id': 'c1',
        'number': 0,
        'title': 'x',
      },
      {'workspace_id': 'w1', 'conversation_id': 'c1', 'number': 'seven'},
      {'workspace_id': 'w1', 'conversation_id': 'c1', 'number': 7},
      {'workspace_id': 'w1', 'conversation_id': 'c1', 'number': 7, 'title': 3},
      {'workspace_id': 'w1', 'conversation_id': 'c1', 'number': 7, 'body': []},
      {'conversation_id': 'c1', 'number': 7, 'title': 'x'},
    ]) {
      final result = await tool.run(arguments);
      expect(result.isError, isTrue, reason: '$arguments');
    }
    expect(port.edits, isEmpty);
  });

  test('a refusal is an error result naming the reason', () async {
    port.refusal = const ValidationException(
      'acme/widgets#7 is merged: only an open pull request can be edited.',
    );
    final refused = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'number': 7,
      'title': 'x',
    });
    expect(refused.isError, isTrue);
    expect(refused.content.first.text, contains('is merged'));

    port.refusal = const NeedsSignInException('github', 'Sign in to GitHub.');
    final signIn = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'number': 7,
      'title': 'x',
    });
    expect(signIn.isError, isTrue);
    expect(signIn.content.first.text, contains('Sign in to GitHub'));
  });
}

class _FakePort implements AgentPullRequestPort {
  final edits = <AgentPullRequestEdit>[];
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
  Future<AgentPullRequestResult> open(AgentPullRequestDraft draft) =>
      throw UnimplementedError();

  @override
  Future<AgentPullRequestEditResult> update(AgentPullRequestEdit edit) async {
    if (refusal case final refusal?) {
      throw refusal;
    }
    edits.add(edit);
    return AgentPullRequestEditResult(
      repoFullName: edit.repo ?? 'acme/widgets',
      number: edit.number,
      url: 'https://github.com/acme/widgets/pull/${edit.number}',
    );
  }
}
