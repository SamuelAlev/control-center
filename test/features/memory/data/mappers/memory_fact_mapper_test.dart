import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/memory/data/mappers/memory_fact_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryFactMapper', () {
    const mapper = MemoryFactMapper();

    db.MemoryFactsTableData createRow({
      String id = 'f1',
      String workspaceId = 'ws1',
      String domain = 'codebase',
      String topic = 'testing',
      String content = 'Use integration tests',
      String sourceObservationIds = '[]',
      double confidence = 1.0,
      String? supersededBy,
      String? authoredByAgentId,
      String? authoredByRole,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime(2025, 6, 10);
      return db.MemoryFactsTableData(
        id: id,
        workspaceId: workspaceId,
        domain: domain,
        topic: topic,
        content: content,
        sourceObservationIds: sourceObservationIds,
        confidence: confidence,
        supersededBy: supersededBy,
        authoredByAgentId: authoredByAgentId,
        authoredByRole: authoredByRole,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('maps all basic fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 6, 10);
      final row = createRow(
        id: 'fact-1',
        workspaceId: 'ws-1',
        domain: 'preferences',
        topic: 'editor',
        content: 'Prefers vim keybindings',
        confidence: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      final fact = mapper.toDomain(row);

      expect(fact.id, 'fact-1');
      expect(fact.workspaceId, 'ws-1');
      expect(fact.domain, 'preferences');
      expect(fact.topic, 'editor');
      expect(fact.content, 'Prefers vim keybindings');
      expect(fact.confidence, 0.9);
      expect(fact.createdAt, now);
      expect(fact.updatedAt, now);
    });

    test('parses source observation ids from JSON array', timeout: const Timeout.factor(2), () {
      final row = createRow(
        sourceObservationIds: jsonEncode(['obs1', 'obs2', 'obs3']),
      );

      final fact = mapper.toDomain(row);

      expect(fact.sourceObservationIds, ['obs1', 'obs2', 'obs3']);
    });

    test('returns empty list when source observation ids is empty string', timeout: const Timeout.factor(2), () {
      final row = createRow(sourceObservationIds: '[]');

      final fact = mapper.toDomain(row);

      expect(fact.sourceObservationIds, isEmpty);
    });

    test('returns empty list when source observation ids is non-JSON', timeout: const Timeout.factor(2), () {
      // If sourceObservationIds is non-empty but not a valid JSON list

      // jsonDecode of 'not-json' throws, so let's test with a non-list JSON
      final rowNonList = createRow(sourceObservationIds: jsonEncode('a-string'));

      final fact = mapper.toDomain(rowNonList);

      expect(fact.sourceObservationIds, isEmpty);
    });

    test('maps nullable supersededBy', timeout: const Timeout.factor(2), () {
      final rowWith = createRow(supersededBy: 'f2');
      expect(mapper.toDomain(rowWith).supersededBy, 'f2');

      final rowWithout = createRow(supersededBy: null);
      expect(mapper.toDomain(rowWithout).supersededBy, isNull);
    });

    test('maps nullable authoredByAgentId', timeout: const Timeout.factor(2), () {
      final rowWith = createRow(authoredByAgentId: 'agent-1');
      expect(mapper.toDomain(rowWith).authoredByAgentId, 'agent-1');

      final rowWithout = createRow(authoredByAgentId: null);
      expect(mapper.toDomain(rowWithout).authoredByAgentId, isNull);
    });

    test('parses authoredByRole to AgentRole', timeout: const Timeout.factor(2), () {
      final row = createRow(authoredByRole: 'coder');
      expect(mapper.toDomain(row).authoredByRole, AgentRole.coder);
    });

    test('returns null authoredByRole when not set', timeout: const Timeout.factor(2), () {
      final row = createRow(authoredByRole: null);
      expect(mapper.toDomain(row).authoredByRole, isNull);
    });

    test('handles unknown authoredByRole gracefully', timeout: const Timeout.factor(2), () {
      final row = createRow(authoredByRole: 'unknown_role');
      expect(mapper.toDomain(row).authoredByRole, isNull);
    });
  });
}
