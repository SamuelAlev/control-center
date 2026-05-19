import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_mcp/src/tools/record_observation_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  final Map<String, AgentWorkingMemory> _store = {};

  String _key(String wsId, String agentId) => '$wsId:$agentId';

  @override
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId) async =>
      _store[_key(workspaceId, agentId)];

  @override
  Future<void> upsert(AgentWorkingMemory memory) async {
    _store[_key(memory.workspaceId, memory.agentId)] = memory;
  }

  @override
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(_store[_key(workspaceId, agentId)]);

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      Stream.value(_store.values.where((m) => m.workspaceId == workspaceId).toList());
}

void main() {
  group('RecordObservationTool', () {
    late FakeAgentWorkingMemoryRepository fakeRepo;
    late RecordObservationTool tool;

    setUp(() {
      fakeRepo = FakeAgentWorkingMemoryRepository();
      tool = RecordObservationTool(repository: fakeRepo);
    });

    // -- existing tests --------------------------------------------------

    test('name is record_observation', () {
      expect(tool.name, 'record_observation');
    });

    test('records an observation', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'Test observation',
      });

      expect(result.isError, isFalse);
      final memory = fakeRepo._store['ws-1:a-1'];
      expect(memory, isNotNull);
      expect(memory!.content, contains('Test observation'));
    });

    test('appends to existing notes', () async {
      fakeRepo._store['ws-1:a-1'] = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: '- Existing note', updatedAt: DateTime.now(),
      );

      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'New observation',
      });

      final content = fakeRepo._store['ws-1:a-1']!.content;
      expect(content, contains('Existing note'));
      expect(content, contains('New observation'));
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({'agent_id': 'a-1', 'observation': 'test'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing agent_id', () async {
      final result = await tool.run({'workspace_id': 'ws-1', 'observation': 'test'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing observation', () async {
      final result = await tool.run({'workspace_id': 'ws-1', 'agent_id': 'a-1'});
      expect(result.isError, isTrue);
    });

    // -- new tests -------------------------------------------------------

    test('inputSchema has type=object and required includes all fields', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], containsAll(['workspace_id', 'agent_id', 'observation']));
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
      expect(tool.description, isA<String>());
    });

    test('workspace_id as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 42,
        'agent_id': 'a-1',
        'observation': 'test',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('agent_id as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 99,
        'observation': 'test',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('agent_id'));
    });

    test('observation as int returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 123,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('observation'));
    });

    test('workspace_id as null returns error', () async {
      final result = await tool.run({
        'workspace_id': null,
        'agent_id': 'a-1',
        'observation': 'test',
      });
      expect(result.isError, isTrue);
    });

    test('agent_id as null returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': null,
        'observation': 'test',
      });
      expect(result.isError, isTrue);
    });

    test('observation as null returns error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': null,
      });
      expect(result.isError, isTrue);
    });

    test('first observation creates bullet-point format', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'First observation',
      });

      final content = fakeRepo._store['ws-1:a-1']!.content;
      expect(content, startsWith('- '));
      expect(content, endsWith('First observation'));
    });

    test('empty observation string records empty bullet', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': '',
      });

      expect(result.isError, isFalse);
      final content = fakeRepo._store['ws-1:a-1']!.content;
      expect(content, '- ');
    });

    test('very long observation (500+ chars) records successfully', () async {
      final longText = 'A' * 600;

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': longText,
      });

      expect(result.isError, isFalse);
      final content = fakeRepo._store['ws-1:a-1']!.content;
      expect(content, contains(longText));
      expect(content.length, greaterThan(600));
    });

    test('multiple successive observations accumulate properly', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'first',
      });
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'second',
      });
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'third',
      });

      final content = fakeRepo._store['ws-1:a-1']!.content;
      expect(content, '- first\n- second\n- third');
    });

    test('different agent_ids create separate memory entries', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-alpha',
        'observation': 'Alpha observation',
      });
      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-beta',
        'observation': 'Beta observation',
      });

      final alphaContent = fakeRepo._store['ws-1:agent-alpha']!.content;
      final betaContent = fakeRepo._store['ws-1:agent-beta']!.content;
      expect(alphaContent, contains('Alpha observation'));
      expect(alphaContent, isNot(contains('Beta observation')));
      expect(betaContent, contains('Beta observation'));
      expect(betaContent, isNot(contains('Alpha observation')));
    });

    test('response JSON has status recorded, agent_id, observation_length', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'Hello world',
      });

      expect(result.isError, isFalse);
      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['status'], 'recorded');
      expect(json['agent_id'], 'a-1');
      expect(json.containsKey('observation_length'), isTrue);
    });

    test('observation_length matches actual input length', () async {
      const observation = 'This string is exactly 37 chars long!';
      expect(observation.length, 37);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': observation,
      });

      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['observation_length'], 37);
    });
  });
}
