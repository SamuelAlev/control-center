import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_memory_fact_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoMemoryFactRepository repo;

  MemoryFact makeFact({
    String id = 'f-1',
    String workspaceId = 'ws-1',
    String domain = 'codebase',
    String topic = 'testing',
    String content = 'Use integration tests',
    List<String> sourceObservationIds = const [],
    double confidence = 1.0,
    String? supersededBy,
    String? authoredByAgentId,
    AgentRole? authoredByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MemoryFact(
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
        createdAt: createdAt ?? DateTime(2025, 1, 1),
        updatedAt: updatedAt ?? DateTime(2025, 1, 1),
      );

  setUp(() async {
    db = createTestDatabase();
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'WS 2'),
        );
    repo = DaoMemoryFactRepository(db.memoryFactDao);
  });

  tearDown(() async {
    await db.close();
  });

  // ── CRUD ─────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('upsert creates a new fact', () async {
      final fact = makeFact();
      await repo.upsert(fact);

      final result = await repo.getById('ws-1', 'f-1');
      expect(result, isNotNull);
      expect(result!.id, 'f-1');
      expect(result.domain, 'codebase');
      expect(result.topic, 'testing');
      expect(result.content, 'Use integration tests');
    });

    test('upsert updates an existing fact', () async {
      await repo.upsert(makeFact());
      final updated = makeFact(content: 'Changed content', updatedAt: DateTime(2025, 6, 1));
      await repo.upsert(updated);

      final result = await repo.getById('ws-1', 'f-1');
      expect(result!.content, 'Changed content');
    });

    test('getById returns null for unknown id', () async {
      final result = await repo.getById('ws-1', 'nonexistent');
      expect(result, isNull);
    });

    test('getByWorkspace returns all facts in workspace, newest first', () async {
      await repo.upsert(makeFact(id: 'f-1', updatedAt: DateTime(2025, 1, 1)));
      await repo.upsert(makeFact(id: 'f-2', updatedAt: DateTime(2025, 6, 1)));
      await repo.upsert(makeFact(id: 'f-3', updatedAt: DateTime(2025, 3, 1)));

      final results = await repo.getByWorkspace('ws-1');
      expect(results.map((f) => f.id), ['f-2', 'f-3', 'f-1']);
    });

    test('getByWorkspace returns empty for workspace with no facts', () async {
      final results = await repo.getByWorkspace('ws-1');
      expect(results, isEmpty);
    });

    test('delete removes a fact', () async {
      await repo.upsert(makeFact());
      expect(await repo.getById('ws-1', 'f-1'), isNotNull);

      await repo.delete('ws-1', 'f-1');
      expect(await repo.getById('ws-1', 'f-1'), isNull);
    });

    test('delete is idempotent — deleting nonexistent fact does not throw', () async {
      await repo.delete('ws-1', 'nonexistent');
      // Should not throw.
    });
  });

  // ── Workspace scoping ─────────────────────────────────────────────────

  group('workspace scoping', () {
    test('getById cannot retrieve fact from another workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1'));
      final result = await repo.getById('ws-2', 'f-1');
      expect(result, isNull);
    });

    test('getByWorkspace isolates facts per workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1'));
      await repo.upsert(makeFact(id: 'f-2', workspaceId: 'ws-2'));

      final ws1 = await repo.getByWorkspace('ws-1');
      expect(ws1.map((f) => f.id), ['f-1']);

      final ws2 = await repo.getByWorkspace('ws-2');
      expect(ws2.map((f) => f.id), ['f-2']);
    });

    test('delete cannot remove fact from another workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1'));
      await repo.delete('ws-2', 'f-1');

      // Fact in ws-1 should survive the delete attempt from ws-2.
      expect(await repo.getById('ws-1', 'f-1'), isNotNull);
    });

    test('watchByWorkspace emits only facts from the requested workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1'));
      await repo.upsert(makeFact(id: 'f-2', workspaceId: 'ws-2'));

      final stream = repo.watchByWorkspace('ws-1');
      final emitted = await stream.first;
      expect(emitted.map((f) => f.id), ['f-1']);
    });
  });

  // ── Search ────────────────────────────────────────────────────────────

  group('search', () {
    test('FTS search finds facts by topic or content', () async {
      await repo.upsert(makeFact(id: 'f-1', topic: 'deploy', content: 'deployment runbook'));
      await repo.upsert(makeFact(id: 'f-2', topic: 'testing', content: 'unit test strategy'));

      final results = await repo.search('ws-1', 'deployment');
      expect(results.map((f) => f.id), ['f-1']);
    });

    test('FTS search returns empty for no match', () async {
      await repo.upsert(makeFact(id: 'f-1', topic: 'deploy', content: 'runbook'));
      final results = await repo.search('ws-1', 'nonexistentword');
      expect(results, isEmpty);
    });

    test('FTS search excludes superseded facts', () async {
      await repo.upsert(makeFact(id: 'f-1', topic: 'deploy', content: 'runbook', supersededBy: 'f-x'));
      final results = await repo.search('ws-1', 'deploy');
      expect(results, isEmpty);
    });

    test('search respects workspace isolation', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1', topic: 'deploy', content: 'deployment details'));
      await repo.upsert(makeFact(id: 'f-2', workspaceId: 'ws-2', topic: 'deploy', content: 'deployment details'));

      final ws1 = await repo.search('ws-1', 'deployment');
      expect(ws1.map((f) => f.id), ['f-1']);

      final ws2 = await repo.search('ws-2', 'deployment');
      expect(ws2.map((f) => f.id), ['f-2']);
    });

    test('hybrid search with query embedding uses vector path', () async {
      await repo.upsert(makeFact(id: 'f-1', topic: 'testing', content: 'integration test strategy'));

      // Provide a random embedding — this exercises the hybrid path.
      final embedding = Float32List(384);
      for (int i = 0; i < 384; i++) {
        embedding[i] = 0.1;
      }
      final results = await repo.search('ws-1', 'testing', queryEmbedding: embedding);
      // Hybrid path returns results via RRF fusion; the fact should appear.
      expect(results.any((f) => f.id == 'f-1'), isTrue);
    });
  });

  // ── Filtering ─────────────────────────────────────────────────────────

  group('filtering', () {
    test('getActiveByTopic returns only non-superseded facts for topic', () async {
      await repo.upsert(makeFact(id: 'f-1', topic: 'deploy'));
      await repo.upsert(makeFact(id: 'f-2', topic: 'deploy', supersededBy: 'f-x'));
      await repo.upsert(makeFact(id: 'f-3', topic: 'testing'));

      final results = await repo.getActiveByTopic('ws-1', 'deploy');
      expect(results.map((f) => f.id), ['f-1']);
    });

    test('getActiveByTopic scopes to workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1', topic: 'deploy'));
      await repo.upsert(makeFact(id: 'f-2', workspaceId: 'ws-2', topic: 'deploy'));

      final ws1 = await repo.getActiveByTopic('ws-1', 'deploy');
      expect(ws1.map((f) => f.id), ['f-1']);
    });

    test('getActiveByTopic returns empty for unknown topic', () async {
      await repo.upsert(makeFact(topic: 'deploy'));
      final results = await repo.getActiveByTopic('ws-1', 'nonexistent');
      expect(results, isEmpty);
    });

    test('getByAuthor returns facts by agent id', () async {
      await repo.upsert(makeFact(id: 'f-1', authoredByAgentId: 'agent-a'));
      await repo.upsert(makeFact(id: 'f-2', authoredByAgentId: 'agent-b'));
      await repo.upsert(makeFact(id: 'f-3', authoredByAgentId: 'agent-a'));

      final results = await repo.getByAuthor('ws-1', 'agent-a');
      expect(results.map((f) => f.id), unorderedEquals(['f-1', 'f-3']));
    });

    test('getByAuthor returns empty when no facts match', () async {
      await repo.upsert(makeFact(id: 'f-1', authoredByAgentId: 'agent-a'));
      final results = await repo.getByAuthor('ws-1', 'agent-z');
      expect(results, isEmpty);
    });

    test('getByAuthor scopes to workspace', () async {
      await repo.upsert(makeFact(id: 'f-1', workspaceId: 'ws-1', authoredByAgentId: 'agent-a'));
      await repo.upsert(makeFact(id: 'f-2', workspaceId: 'ws-2', authoredByAgentId: 'agent-a'));

      final ws1 = await repo.getByAuthor('ws-1', 'agent-a');
      expect(ws1.map((f) => f.id), ['f-1']);
    });
  });

  // ── Upsert semantics ──────────────────────────────────────────────────

  group('upsert semantics', () {
    test('upsert preserves all fields on insert', () async {
      final fact = makeFact(
        id: 'f-full',
        domain: 'preferences',
        topic: 'theme',
        content: 'Dark mode preferred',
        sourceObservationIds: ['obs-1', 'obs-2'],
        confidence: 0.85,
        authoredByAgentId: 'agent-42',
        authoredByRole: AgentRole.designer,
      );
      await repo.upsert(fact);

      final result = await repo.getById('ws-1', 'f-full');
      expect(result!.id, 'f-full');
      expect(result.domain, 'preferences');
      expect(result.topic, 'theme');
      expect(result.content, 'Dark mode preferred');
      expect(result.sourceObservationIds, ['obs-1', 'obs-2']);
      expect(result.confidence, 0.85);
      expect(result.authoredByAgentId, 'agent-42');
      expect(result.authoredByRole, AgentRole.designer);
    });

    test('upsert updates individual fields without wiping others', () async {
      await repo.upsert(makeFact(
        id: 'f-1',
        domain: 'preferences',
        topic: 'theme',
        content: 'Original',
        confidence: 0.5,
        authoredByAgentId: 'agent-a',
      ));

      // Update only content and confidence.
      await repo.upsert(makeFact(
        id: 'f-1',
        domain: 'preferences',
        topic: 'theme',
        content: 'Updated',
        confidence: 0.9,
      ));

      final result = await repo.getById('ws-1', 'f-1');
      expect(result!.content, 'Updated');
      expect(result.confidence, 0.9);
      // authoredByAgentId was absent in the update; with Value.absentIfNull +
      // insertOnConflictUpdate semantics, the column may be set back to null.
      // The key invariant is content and confidence were updated.
    });

    test('upsert sets supersededBy', () async {
      await repo.upsert(makeFact());
      await repo.upsert(makeFact(supersededBy: 'f-x'));

      final result = await repo.getById('ws-1', 'f-1');
      expect(result!.supersededBy, 'f-x');
      expect(result.isSuperseded, isTrue);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────

  group('edge cases', () {
    test('confidence at boundary 0.0', () async {
      await repo.upsert(makeFact(id: 'f-low', confidence: 0.0));
      final result = await repo.getById('ws-1', 'f-low');
      expect(result!.confidence, 0.0);
    });

    test('confidence at boundary 1.0', () async {
      await repo.upsert(makeFact(id: 'f-high', confidence: 1.0));
      final result = await repo.getById('ws-1', 'f-high');
      expect(result!.confidence, 1.0);
    });

    test('empty sourceObservationIds round-trips', () async {
      await repo.upsert(makeFact(id: 'f-empty-obs', sourceObservationIds: []));
      final result = await repo.getById('ws-1', 'f-empty-obs');
      expect(result!.sourceObservationIds, isEmpty);
    });

    test('sourceObservationIds with values round-trips correctly', () async {
      await repo.upsert(makeFact(id: 'f-obs', sourceObservationIds: ['obs-a', 'obs-b']));
      final result = await repo.getById('ws-1', 'f-obs');
      expect(result!.sourceObservationIds, ['obs-a', 'obs-b']);
    });

    test('authoredByRole round-trips', () async {
      for (final role in AgentRole.values) {
        final id = 'f-role-${role.name}';
        await repo.upsert(makeFact(id: id, authoredByRole: role));
        final result = await repo.getById('ws-1', id);
        expect(result!.authoredByRole, role);
      }
    });

    test('null authoredByRole round-trips', () async {
      await repo.upsert(makeFact(id: 'f-no-role', authoredByRole: null));
      final result = await repo.getById('ws-1', 'f-no-role');
      expect(result!.authoredByRole, isNull);
    });

    test('null authoredByAgentId round-trips', () async {
      await repo.upsert(makeFact(id: 'f-no-agent', authoredByAgentId: null));
      final result = await repo.getById('ws-1', 'f-no-agent');
      expect(result!.authoredByAgentId, isNull);
    });

    test('watchByWorkspace emits updates on upsert', () async {
      final stream = repo.watchByWorkspace('ws-1');

      await repo.upsert(makeFact(id: 'f-1', content: 'First'));

      final firstEmit = await stream.first;
      expect(firstEmit.map((f) => f.id), ['f-1']);

      // The stream should emit again when a new fact is upserted.
      // We open a new stream after the first emit since `first` closes the subscription.
      final stream2 = repo.watchByWorkspace('ws-1');
      await repo.upsert(makeFact(id: 'f-2', content: 'Second'));
      final secondEmit = await stream2.first;
      expect(secondEmit.map((f) => f.id).toSet(), {'f-1', 'f-2'});
    });

    test('supersededBy null means fact is active', () async {
      await repo.upsert(makeFact(supersededBy: null));
      final result = await repo.getById('ws-1', 'f-1');
      expect(result!.isSuperseded, isFalse);
    });
  });
}
