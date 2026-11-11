import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/comment_on_pull_request_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakePort port;
  late CommentOnPullRequestTool tool;

  setUp(() {
    port = _FakePort();
    tool = CommentOnPullRequestTool(comments: port);
  });

  test('only a run can call it, and the run names its own conversation', () {
    expect(tool.name, kAgentCommentOnPullRequestTool);
    expect(tool.requiresRunGrant, isTrue);
    expect(tool.actionClasses, {ActionClass.prPublish});
    expect(tool.forcedScopeKeys, contains('conversation_id'));
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

  test('forwards the comment and answers where it went', () async {
    final result = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'repo': 'acme/widgets',
      'number': 7,
      'body': 'Fixed in the latest push.',
    });
    expect(result.isError, isFalse);
    expect(jsonDecode(result.content.first.text), {
      'repo': 'acme/widgets',
      'number': 7,
      'url': 'https://github.com/acme/widgets/pull/7',
      'author': 'bot',
    });
    final sent = port.comments.single;
    expect((sent.workspaceId, sent.conversationId), ('w1', 'c1'));
    expect((sent.repo, sent.number), ('acme/widgets', 7));
    expect(sent.body, 'Fixed in the latest push.');
  });

  test('a missing argument or a refusal is an error result', () async {
    final missing = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'body': 'x',
    });
    expect(missing.isError, isTrue);
    expect(missing.content.first.text, contains('number'));
    expect(port.comments, isEmpty);

    port.refusal = const ValidationException('not this run\'s pull request');
    final refused = await tool.run({
      'workspace_id': 'w1',
      'conversation_id': 'c1',
      'number': 7,
      'body': 'x',
    });
    expect(refused.isError, isTrue);
    expect(refused.content.first.text, contains('not this run'));
  });
}

class _FakePort implements AgentPullRequestCommentPort {
  final comments = <AgentPullRequestComment>[];
  Exception? refusal;

  @override
  Future<AgentPullRequestCommentResult> comment(
    AgentPullRequestComment comment,
  ) async {
    if (refusal case final refusal?) {
      throw refusal;
    }
    comments.add(comment);
    return AgentPullRequestCommentResult(
      repoFullName: comment.repo ?? 'acme/widgets',
      number: comment.number,
      url: 'https://github.com/acme/widgets/pull/${comment.number}',
    );
  }
}
