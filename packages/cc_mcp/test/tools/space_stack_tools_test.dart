import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_harness/tools.dart';
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
    expect((wire['entries'] as List).first['branch'], 'main');
    expect((wire['entries'] as List).first['current'], isTrue);
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

  test('stack_publish pushes and opens pull requests', () async {
    final tool = StackPublishTool(stack: stack);
    expect(tool.actionClasses, {ActionClass.gitPush, ActionClass.prCreate});

    final result = await tool.run({
      'workspace_id': 'ws',
      'space_id': 's1',
      'repo_id': 'repo-1',
      'draft': false,
    });
    expect(result.isError, isFalse);
    final wire = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(wire['opened'], 1);
    expect(stack.lastPublish, ('ws', 's1', 'repo-1', false));
  });
}

class _FakeStack implements SpaceStackPort {
  bool dirty = false;
  (String, String, String, String?, String?)? lastCut;
  (String, String, String?, bool)? lastPublish;

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
    bool draft = true,
  }) async {
    lastPublish = (workspaceId, spaceId, repoId, draft);
    return _view;
  }
}
