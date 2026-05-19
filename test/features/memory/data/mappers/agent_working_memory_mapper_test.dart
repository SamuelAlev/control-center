import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/features/memory/data/mappers/agent_working_memory_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentWorkingMemoryMapper', () {
    const mapper = AgentWorkingMemoryMapper();

    db.AgentWorkingMemoryTableData createRow({
      String id = 'wm1',
      String workspaceId = 'ws1',
      String agentId = 'agent1',
      String content = '{"key": "value"}',
      DateTime? updatedAt,
    }) {
      return db.AgentWorkingMemoryTableData(
        id: id,
        workspaceId: workspaceId,
        agentId: agentId,
        content: content,
        updatedAt: updatedAt ?? DateTime(2025, 6, 10),
      );
    }

    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 6, 10);
      final row = createRow(
        id: 'wm-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        content: '{"task": "coding"}',
        updatedAt: now,
      );

      final memory = mapper.toDomain(row);

      expect(memory.id, 'wm-1');
      expect(memory.workspaceId, 'ws-1');
      expect(memory.agentId, 'agent-1');
      expect(memory.content, '{"task": "coding"}');
      expect(memory.updatedAt, now);
    });

    test('maps empty content', timeout: const Timeout.factor(2), () {
      final row = createRow(content: '');

      final memory = mapper.toDomain(row);

      expect(memory.content, isEmpty);
    });

    test('maps large content', timeout: const Timeout.factor(2), () {
      final largeContent = 'x' * 10000;
      final row = createRow(content: largeContent);

      final memory = mapper.toDomain(row);

      expect(memory.content.length, 10000);
    });
  });
}
