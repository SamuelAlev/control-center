import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_mcp/src/tools/update_my_notes_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('UpdateMyNotesTool', () {
    late FakeAgentWorkingMemoryRepository fakeRepo;
    late UpdateMyNotesTool tool;

    setUp(() {
      fakeRepo = FakeAgentWorkingMemoryRepository();
      tool = UpdateMyNotesTool(repository: fakeRepo);
    });

    test('name is update_my_notes', () {
      expect(tool.name, 'update_my_notes');
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({
        'agent_id': 'a-1',
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('returns error for missing agent_id', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('returns error for missing content', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(result.isError, isTrue);
    });

    test('creates new memory when none exists', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': '# Fresh notes',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"status":"updated"'));
      expect(result.content.first.text, contains('"agent_id":"a-1"'));

      final saved = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(saved, isNotNull);
      expect(saved!.content, '# Fresh notes');
      expect(saved.workspaceId, 'ws-1');
    });

    test('updates existing memory preserving its id', () async {
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-existing',
          workspaceId: 'ws-1',
          agentId: 'a-1',
          content: 'old notes',
          updatedAt: DateTime(2025),
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'updated notes',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"status":"updated"'));

      final saved = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(saved, isNotNull);
      expect(saved!.id, 'mem-existing');
      expect(saved.content, 'updated notes');
    });

    test('does not overwrite memory for different agent', () async {
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-a2',
          workspaceId: 'ws-1',
          agentId: 'a-2',
          content: 'a-2 notes',
          updatedAt: DateTime(2025),
        ),
      ]);

      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'a-1 notes',
      });

      final a2Mem = await fakeRepo.getByAgent('ws-1', 'a-2');
      expect(a2Mem!.content, 'a-2 notes');

      final a1Mem = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(a1Mem!.content, 'a-1 notes');
    });

    test('inputSchema has correct structure', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], containsAll(['workspace_id', 'agent_id', 'content']));
      expect((schema['required'] as List).length, 3);
      final props = schema['properties'] as Map<String, dynamic>;
      expect(props['workspace_id'], {'type': 'string', 'description': 'The workspace ID.'});
      expect(props['agent_id'], {'type': 'string', 'description': 'The agent ID.'});
      expect(props['content'], {'type': 'string', 'description': 'New content for the notes (markdown).'});
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('workspace_id as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 42,
        'agent_id': 'a-1',
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('agent_id as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 99,
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('content as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 123,
      });
      expect(result.isError, isTrue);
    });

    test('workspace_id as null returns error', () async {
      final result = await tool.run({
        'workspace_id': null,
        'agent_id': 'a-1',
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('agent_id as null returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': null,
        'content': 'notes',
      });
      expect(result.isError, isTrue);
    });

    test('content as null returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': null,
      });
      expect(result.isError, isTrue);
    });

    test('empty string content is accepted', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': '',
      });
      expect(result.isError, isFalse);
      final saved = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(saved, isNotNull);
      expect(saved!.content, '');
    });

    test('very long content (1000+ chars) works', () async {
      final longContent = List.filled(50, '# Section\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit.\n').join();
      expect(longContent.length, greaterThan(1000));

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': longContent,
      });
      expect(result.isError, isFalse);
      final saved = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(saved, isNotNull);
      expect(saved!.content, longContent);
    });

    test('update twice in succession replaces first', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'first update',
      });
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'second update',
      });
      final saved = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(saved, isNotNull);
      expect(saved!.content, 'second update');
    });

    test('response JSON has status=updated and agent_id', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-x',
        'content': 'some notes',
      });
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('"status":"updated"'));
      expect(text, contains('"agent_id":"agent-x"'));
    });

    test('different workspace_id with same agent_id creates separate memory', () async {
      await tool.run({
        'workspace_id': 'ws-alpha',
        'agent_id': 'a-1',
        'content': 'alpha notes',
      });
      await tool.run({
        'workspace_id': 'ws-beta',
        'agent_id': 'a-1',
        'content': 'beta notes',
      });

      final alphaMem = await fakeRepo.getByAgent('ws-alpha', 'a-1');
      expect(alphaMem, isNotNull);
      expect(alphaMem!.content, 'alpha notes');
      expect(alphaMem.workspaceId, 'ws-alpha');

      final betaMem = await fakeRepo.getByAgent('ws-beta', 'a-1');
      expect(betaMem, isNotNull);
      expect(betaMem!.content, 'beta notes');
      expect(betaMem.workspaceId, 'ws-beta');

      expect(alphaMem.id, isNot(betaMem.id));
    });

    test('idempotent — same content twice preserves content', () async {
      final result1 = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'repeat me',
      });
      expect(result1.isError, isFalse);

      final afterFirst = await fakeRepo.getByAgent('ws-1', 'a-1');
      final firstId = afterFirst!.id;
      final firstContent = afterFirst.content;

      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'repeat me',
      });

      final afterSecond = await fakeRepo.getByAgent('ws-1', 'a-1');
      expect(afterSecond, isNotNull);
      expect(afterSecond!.content, firstContent);
      expect(afterSecond.id, firstId);
    });

    test('updated_at timestamp changes on each update', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'v1',
      });
      final afterFirst = await fakeRepo.getByAgent('ws-1', 'a-1');
      final ts1 = afterFirst!.updatedAt;

      // Small delay to ensure timestamp would differ
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'content': 'v2',
      });
      final afterSecond = await fakeRepo.getByAgent('ws-1', 'a-1');
      final ts2 = afterSecond!.updatedAt;

      expect(ts2, isNot(ts1));
      // Verify the ordering: second update should have a later timestamp
      expect(ts2.microsecondsSinceEpoch, greaterThan(ts1.microsecondsSinceEpoch));
    });
  });
}
