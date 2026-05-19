import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/features/mcp/application/tools/record_observation_tool.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  AgentWorkingMemory? _memory;

  @override
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId) async => _memory;

  @override
  Future<void> upsert(AgentWorkingMemory memory) async {
    _memory = memory;
  }

  @override
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId) => Stream.value(_memory);

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) => Stream.value([]);
}

void main() {
  group('RecordObservationTool', () {
    late FakeAgentWorkingMemoryRepository fakeRepo;
    late RecordObservationTool tool;

    setUp(() {
      fakeRepo = FakeAgentWorkingMemoryRepository();
      tool = RecordObservationTool(repository: fakeRepo);
    });

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
      expect(fakeRepo._memory, isNotNull);
      expect(fakeRepo._memory!.content, contains('Test observation'));
    });

    test('appends to existing notes', () async {
      fakeRepo._memory = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: '- Existing note', updatedAt: DateTime.now(),
      );

      await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
        'observation': 'New observation',
      });

      expect(fakeRepo._memory!.content, contains('Existing note'));
      expect(fakeRepo._memory!.content, contains('New observation'));
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
  });
}
