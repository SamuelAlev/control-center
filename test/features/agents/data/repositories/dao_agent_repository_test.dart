
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/repositories/dao_agent_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

Agent _createAgent({
  String id = 'agent-1',
  String name = 'Test Agent',
  String title = 'Tester',
  String agentMdPath = '/agents/test.md',
  String? reportsTo,
  List<String> skills = const ['dart', 'flutter'],
  String? persona,
  String? systemPrompt,
  String? adapterId,
  String? modelId,
  bool strictMode = false,
  String? effort,
  int? contextSize,
  DateTime? createdAt,
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: agentMdPath,
    workspaceId: 'ws-1',
    reportsTo: reportsTo,
    skills: AgentSkills(skills),
    persona: persona,
    systemPrompt: systemPrompt,
    adapterId: adapterId,
    modelId: modelId,
    strictMode: strictMode,
    effort: effort,
    contextSize: contextSize,
    createdAt: createdAt ?? DateTime(2025),
  );
}

void main() {
  late AppDatabase db;
  late AgentDao dao;
  late DaoAgentRepository repo;

  setUp(() async {
    db = createTestDatabase();
    dao = AgentDao(db);
    repo = DaoAgentRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('emits agents from the database', () async {
      final agent = _createAgent();
      await repo.upsert(agent);

      final agents = await repo.watchAll().first;

      expect(agents.length, 1);
      expect(agents.first.id, 'agent-1');
      expect(agents.first.name, 'Test Agent');
    });

    test('emits empty list when no agents exist', () async {
      final agents = await repo.watchAll().first;

      expect(agents, isEmpty);
    });

    test('emits updated list after insertion', () async {
      final stream = repo.watchAll();

      await repo.upsert(_createAgent(id: 'a1', name: 'Alpha'));
      await repo.upsert(_createAgent(id: 'a2', name: 'Beta'));

      final agents = await stream.first;

      expect(agents.length, 2);
    });
  });

  group('getById', () {
    test('returns agent when found', () async {
      final agent = _createAgent(id: 'found', name: 'Found Agent');
      await repo.upsert(agent);

      final result = await repo.getById('found');

      expect(result, isNotNull);
      expect(result!.id, 'found');
      expect(result.name, 'Found Agent');
    });

    test('returns null when not found', () async {
      final result = await repo.getById('nonexistent');

      expect(result, isNull);
    });
  });

  group('upsert', () {
    test('inserts new agent', () async {
      final agent = _createAgent(
        name: 'New Agent',
        persona: 'Helpful assistant',
        adapterId: 'opencode',
        modelId: 'gpt-4',
        strictMode: true,
        effort: 'medium',
        contextSize: 128000,
      );

      await repo.upsert(agent);

      final row = await dao.getById('agent-1');
      expect(row, isNotNull);
      expect(row!.name, 'New Agent');
      expect(row.persona, 'Helpful assistant');
      expect(row.adapterId, 'opencode');
      expect(row.modelId, 'gpt-4');
      expect(row.strictMode, isTrue);
      expect(row.effort, 'medium');
      expect(row.contextSize, 128000);
    });

    test('updates existing agent', () async {
      await repo.upsert(_createAgent(id: 'agent-x', name: 'Original'));

      await repo.upsert(_createAgent(id: 'agent-x', name: 'Updated'));

      final row = await dao.getById('agent-x');
      expect(row!.name, 'Updated');
    });

    test('stores skills as comma-joined string', () async {
      final agent = _createAgent(skills: ['dart', 'flutter', 'drift']);

      await repo.upsert(agent);

      final row = await dao.getById('agent-1');
      expect(row!.skills, 'dart,flutter,drift');
    });

    test('handles null optional fields', () async {
      final agent = _createAgent(
        reportsTo: null,
        persona: null,
        systemPrompt: null,
        adapterId: null,
        modelId: null,
        effort: null,
        contextSize: null,
      );

      await repo.upsert(agent);

      final row = await dao.getById('agent-1');
      expect(row!.reportsTo, isNull);
      expect(row.persona, isNull);
      expect(row.systemPrompt, isNull);
      expect(row.adapterId, isNull);
      expect(row.modelId, isNull);
      expect(row.effort, isNull);
      expect(row.contextSize, isNull);
    });
  });

  group('delete', () {
    test('deletes agent by id', () async {
      await repo.upsert(_createAgent(id: 'to-delete'));

      await repo.delete('to-delete');

      final row = await dao.getById('to-delete');
      expect(row, isNull);
    });

    test('does not throw when deleting nonexistent agent', () async {
      await repo.delete('nonexistent');
    });
  });
}
