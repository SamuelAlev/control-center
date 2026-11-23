import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show RepoGrantRequiredException, ValidationException;
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/space_stack_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeStack stack;

  setUp(() => stack = _FakeStack());

  test('stack_status refuses a missing workspace', () async {
    final result = await StackStatusTool(stack: stack).run({'space_id': 's1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('stack_status returns the recorded layers', () async {
    final result = await StackStatusTool(
      stack: stack,
    ).run({'workspace_id': 'ws', 'space_id': 's1'});
    expect(result.isError, isFalse);
    final wire = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(wire['ok'], isTrue);
    expect(wire['entries'], hasLength(1));
    final entry = (wire['entries'] as List).first as Map<String, dynamic>;
    expect(entry['branch'], 'main');
    expect(entry['current'], isTrue);
  });

  test('stack_cut forwards the part name and surfaces a refusal', () async {
    final tool = StackCutTool(stack: stack);
    final missing = await tool.run({'workspace_id': 'ws', 'space_id': 's1'});
    expect(missing.isError, isTrue);
    expect(missing.content.first.text, contains('name'));

    stack.dirty = true;
    final refused = await tool.run({
      'workspace_id': 'ws',
      'space_id': 's1',
      'name': 'ui',
      'at': 'abc',
    });
    expect(refused.isError, isTrue);
    expect(refused.content.first.text, contains('dirty'));
    expect(stack.lastCut, ('ws', 's1', 'ui', null, 'abc'));
  });

  test('stack_checkout refuses a missing branch argument', () async {
    final result = await StackCheckoutTool(
      stack: stack,
    ).run({'workspace_id': 'ws', 'space_id': 's1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('branch'));
  });

  test(
    'stack_publish pushes and opens pull requests as the requester',
    () async {
      final tool = StackPublishTool(stack: stack, agentRuns: _Runs('alice'));
      expect(tool.actionClasses, {ActionClass.gitPush, ActionClass.prCreate});
      expect(tool.requiresRunGrant, isTrue);
      expect(
        tool.forcedScopeKeys,
        containsAll(['space_id', 'conversation_id']),
      );

      final result = await tool.run({
        'workspace_id': 'ws',
        'space_id': 's1',
        'conversation_id': 'c1',
        'repo_id': 'repo-1',
        'draft': false,
      });
      expect(result.isError, isFalse);
      final wire =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(wire['opened'], 1);
      expect(stack.lastPublish, (
        'ws',
        's1',
        'repo-1',
        false,
        'alice',
        'alice',
      ));
      // Every pushed commit is held to the run's own identity, never to
      // anything the model sent.
      expect(stack.lastIdentities, [_Runs.identity]);
    },
  );

  test('stack_publish shows each step on the call\'s row', () async {
    final steps = <String>[];
    final tool = StackPublishTool(stack: stack, agentRuns: _Runs('alice'));

    final result = await tool.callScoped({
      'workspace_id': 'ws',
      'space_id': 's1',
      'conversation_id': 'c1',
    }, McpCallContext(reportProgress: steps.add));

    expect(result.isError, isFalse);
    expect(steps, ['Pushing feature (1 of 1)']);
  });

  test('an unrequested run publishes as the bot, owned by whoever armed its '
      'trigger', () async {
    final tool = StackPublishTool(
      stack: stack,
      agentRuns: _Runs('', armedBy: {'admin', 'other-admin'}),
    );
    final result = await tool.run({
      'workspace_id': 'ws',
      'space_id': 's1',
      'conversation_id': 'c1',
    });
    expect(result.isError, isFalse);
    expect(stack.lastPublish, (
      'ws',
      's1',
      null,
      true,
      null,
      'admin,other-admin',
    ));
  });

  test(
    'a run for a person without the write grant publishes nothing',
    () async {
      stack.writers = const {'alice'};
      final tool = StackPublishTool(stack: stack, agentRuns: _Runs('bob'));
      final result = await tool.run({
        'workspace_id': 'ws',
        'space_id': 's1',
        'conversation_id': 'c1',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('No write access'));
      expect(stack.lastPublish, isNull);
    },
  );

  test('stack_publish without an open run publishes nothing', () async {
    final tool = StackPublishTool(stack: stack, agentRuns: _Runs(null));
    final result = await tool.run({
      'workspace_id': 'ws',
      'space_id': 's1',
      'conversation_id': 'c1',
    });
    expect(result.isError, isTrue);
    expect(stack.lastPublish, isNull);
  });
}

/// Answers [requester] for the open run ('' for a run nobody requested),
/// or refuses as if none were open.
class _Runs implements AgentPullRequestPort {
  _Runs(this.requester, {this.armedBy = const {}});

  final String? requester;
  final Set<String> armedBy;

  @override
  Future<String?> requesterOf({
    required String workspaceId,
    required String conversationId,
  }) async {
    final requester = this.requester;
    if (requester == null) {
      throw const ValidationException('No run is open here.');
    }
    return requester.isEmpty ? null : requester;
  }

  @override
  Future<Set<String>> approvalOwnersOf({
    required String workspaceId,
    required String conversationId,
  }) async {
    final requester = await requesterOf(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    return requester != null ? {requester} : armedBy;
  }

  static final identity = AgentCommitIdentity.person((
    name: 'Alice',
    email: '7+alice@users.noreply.github.com',
  ));

  @override
  Future<List<AgentCommitIdentity>> commitIdentitiesOf({
    required String workspaceId,
    required String conversationId,
  }) async {
    await requesterOf(workspaceId: workspaceId, conversationId: conversationId);
    return [identity];
  }

  @override
  Future<AgentPullRequestResult> open(AgentPullRequestDraft draft) =>
      throw UnimplementedError();

  @override
  Future<AgentPullRequestEditResult> update(AgentPullRequestEdit edit) =>
      throw UnimplementedError();
}

class _FakeStack implements SpaceStackPort {
  bool dirty = false;
  Set<String> writers = const {};
  (String, String, String, String?, String?)? lastCut;
  (String, String, String?, bool, String?, String?)? lastPublish;
  List<AgentCommitIdentity>? lastIdentities;

  SpaceStackView get _view => SpaceStackView(
    ok: !dirty,
    dirty: dirty,
    error: dirty ? 'worktree is dirty' : null,
    opened: dirty ? 0 : 1,
    entries: [
      SpaceStackEntry(
        id: 'layer-1',
        workspaceId: 'ws',
        spaceId: 's1',
        repoId: 'repo-1',
        position: 0,
        branch: 'main',
        baseBranch: 'main',
        createdAt: DateTime.utc(2026),
      ),
    ],
    checkedOut: const {'repo-1': 'main'},
  );

  @override
  Future<SpaceStackView> list({
    required String workspaceId,
    required String spaceId,
  }) async => _view;

  @override
  Future<SpaceStackView> cut({
    required String workspaceId,
    required String spaceId,
    required String name,
    String? repoId,
    String? at,
  }) async {
    lastCut = (workspaceId, spaceId, name, repoId, at);
    return _view;
  }

  @override
  Future<SpaceStackView> checkout({
    required String workspaceId,
    required String spaceId,
    required String branch,
    String? repoId,
  }) async => _view;

  @override
  Future<SpaceStackView> publish({
    required String workspaceId,
    required String spaceId,
    String? repoId,
    String? actingUserId,
    Set<String> approvalOwnerUserIds = const {},
    List<AgentCommitIdentity>? agentRunIdentities,
    bool draft = true,
    required void Function(String step) onProgress,
  }) async {
    onProgress('Pushing feature (1 of 1)');
    if (actingUserId != null &&
        actingUserId.isNotEmpty &&
        writers.isNotEmpty &&
        !writers.contains(actingUserId)) {
      throw const RepoGrantRequiredException(
        RepoGrantLevel.write,
        'No write access to acme/widgets',
      );
    }
    lastIdentities = agentRunIdentities;
    lastPublish = (
      workspaceId,
      spaceId,
      repoId,
      draft,
      actingUserId,
      (approvalOwnerUserIds.toList()..sort()).join(','),
    );
    return _view;
  }
}
