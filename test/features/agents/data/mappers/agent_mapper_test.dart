import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/agent_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

AgentsTableData _makeRow({
  String id = 'agent-1',
  String name = 'TestAgent',
  String title = 'Test Agent',
  String agentMdPath = '/agents/test.md',
  String workspaceId = 'ws-1',
  String? reportsTo,
  String skills = 'coding, review',
  String? persona,
  String? systemPrompt,
  String? adapterId = 'adapter-a',
  String? modelId,
  bool strictMode = false,
  String? effort,
  int? contextSize,
  String sandboxCapabilitiesJson = '',
  String commandPolicyJson = '',
  String? role,
  int monthlyBudgetCents = 0,
  DateTime? createdAt,
}) =>
    AgentsTableData(
      id: id,
      name: name,
      title: title,
      agentMdPath: agentMdPath,
      workspaceId: workspaceId,
      reportsTo: reportsTo,
      skills: skills,
      persona: persona,
      systemPrompt: systemPrompt,
      adapterId: adapterId,
      modelId: modelId,
      strictMode: strictMode,
      effort: effort,
      contextSize: contextSize,
      sandboxCapabilitiesJson: sandboxCapabilitiesJson,
      commandPolicyJson: commandPolicyJson,
      role: role,
      monthlyBudgetCents: monthlyBudgetCents,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
    );

void main() {
  group('AgentMapper', () {
    const mapper = AgentMapper();

    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final row = _makeRow(
        id: 'a1',
        name: 'Coder',
        title: 'Code Agent',
        agentMdPath: '/p.md',
        workspaceId: 'ws-2',
        reportsTo: 'ceo-id',
        skills: 'coding, review',
        persona: 'friendly',
        systemPrompt: 'be helpful',
        adapterId: 'ada',
        modelId: 'gpt-4',
        strictMode: true,
        effort: 'high',
        contextSize: 128000,
        role: 'coder',
        monthlyBudgetCents: 5000,
      );

      final agent = mapper.toDomain(row);

      expect(agent.id, 'a1');
      expect(agent.name, 'Coder');
      expect(agent.title, 'Code Agent');
      expect(agent.agentMdPath, '/p.md');
      expect(agent.workspaceId, 'ws-2');
      expect(agent.reportsTo, 'ceo-id');
      expect(agent.persona, 'friendly');
      expect(agent.systemPrompt, 'be helpful');
      expect(agent.adapterId, 'ada');
      expect(agent.modelId, 'gpt-4');
      expect(agent.strictMode, isTrue);
      expect(agent.effort, 'high');
      expect(agent.contextSize, 128000);
      expect(agent.role, AgentRole.coder);
      expect(agent.monthlyBudgetCents, 5000);
    });

    test('splits skills from comma-separated string', timeout: const Timeout.factor(2), () {
      final row = _makeRow(skills: 'coding, review, testing');
      final agent = mapper.toDomain(row);
      expect(agent.skills.toList(), ['coding', 'review', 'testing']);
    });

    test('trims whitespace from skills', timeout: const Timeout.factor(2), () {
      final row = _makeRow(skills: '  coding ,  review  , testing ');
      final agent = mapper.toDomain(row);
      expect(agent.skills.toList(), ['coding', 'review', 'testing']);
    });

    test('filters empty skills from trailing comma', timeout: const Timeout.factor(2), () {
      final row = _makeRow(skills: 'coding,,review,');
      final agent = mapper.toDomain(row);
      expect(agent.skills.toList(), ['coding', 'review']);
    });

    test('handles empty skills string', timeout: const Timeout.factor(2), () {
      final row = _makeRow(skills: '');
      final agent = mapper.toDomain(row);
      expect(agent.skills.toList(), isEmpty);
    });

    test('capabilities is null when sandboxCapabilitiesJson is empty',
        timeout: const Timeout.factor(2), () {
      final row = _makeRow(sandboxCapabilitiesJson: '');
      final agent = mapper.toDomain(row);
      expect(agent.capabilities, isNull);
    });

    test('parses capabilities from JSON string', timeout: const Timeout.factor(2), () {
      const json = '{"canPushToRepo":true,"canCallGitHubApi":false,"canCallTicketing":true,"canAccessNetwork":true}';
      final row = _makeRow(sandboxCapabilitiesJson: json);
      final agent = mapper.toDomain(row);
      expect(agent.capabilities, isNotNull);
      expect(agent.capabilities!.canPushToRepo, isTrue);
      expect(agent.capabilities!.canCallGitHubApi, isFalse);
      expect(agent.capabilities!.canCallTicketing, isTrue);
    });

    test('role is null for unrecognized string', timeout: const Timeout.factor(2), () {
      final row = _makeRow(role: 'nonexistent');
      final agent = mapper.toDomain(row);
      expect(agent.role, isNull);
    });

    test('role is null when null', timeout: const Timeout.factor(2), () {
      final row = _makeRow(role: null);
      final agent = mapper.toDomain(row);
      expect(agent.role, isNull);
    });

    test('effort passes the raw level id through (model-driven)', timeout: const Timeout.factor(2), () {
      final row = _makeRow(effort: 'extreme');
      final agent = mapper.toDomain(row);
      // effort is now a model-driven level id (any string), not a validated
      // enum, so the raw value round-trips.
      expect(agent.effort, 'extreme');
    });

    test('effort is null when null', timeout: const Timeout.factor(2), () {
      final row = _makeRow(effort: null);
      final agent = mapper.toDomain(row);
      expect(agent.effort, isNull);
    });

    test('toDomainList maps multiple rows', timeout: const Timeout.factor(2), () {
      final rows = [
        _makeRow(id: 'a1', name: 'Alpha'),
        _makeRow(id: 'a2', name: 'Beta'),
      ];
      final agents = mapper.toDomainList(rows);
      expect(agents, hasLength(2));
      expect(agents[0].name, 'Alpha');
      expect(agents[1].name, 'Beta');
    });

    test('toDomainList returns non-growable list', timeout: const Timeout.factor(2), () {
      final rows = [_makeRow()];
      final agents = mapper.toDomainList(rows);
      expect(() => agents.add(mapper.toDomain(_makeRow(id: 'x'))),
          throwsUnsupportedError);
    });
  });
}
