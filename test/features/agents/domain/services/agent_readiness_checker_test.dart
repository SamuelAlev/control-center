import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/services/agent_readiness_checker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';

Agent _makeAgent({
  String id = 'agent-1',
  String workspaceId = 'ws-1',
  String? adapterId = 'adapter-a',
}) =>
    Agent(
      id: id,
      name: 'TestAgent',
      title: 'Test Agent',
      agentMdPath: '/path/to/agent.md',
      workspaceId: workspaceId,
      skills: AgentSkills(['coding']),
      adapterId: adapterId,
      createdAt: DateTime(2025, 1, 1),
    );

void main() {
  group('AgentReadinessChecker', () {
    late FakeAgentRepository agentRepo;
    late AgentReadinessChecker checker;

    setUp(() {
      agentRepo = FakeAgentRepository();
      checker = AgentReadinessChecker(agentRepository: agentRepo);
    });

    test('returns ready when workspace matches and adapter is set',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent();
      final result = await checker.check(agent, workspaceId: 'ws-1');

      expect(result.isReady, isTrue);
      expect(result.readiness, AgentReadiness.ready);
      expect(result.reason, isNull);
    });

    test('returns ready when workspaceId is null (no workspace filter)',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent();
      final result = await checker.check(agent, workspaceId: null);

      expect(result.isReady, isTrue);
    });

    test('returns wrongWorkspace when workspace does not match',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent(workspaceId: 'ws-1');
      final result = await checker.check(agent, workspaceId: 'ws-other');

      expect(result.readiness, AgentReadiness.wrongWorkspace);
      expect(result.isReady, isFalse);
      expect(result.reason, isNotNull);
    });

    test('returns noAdapter when adapterId is null',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent(adapterId: null);
      final result = await checker.check(agent, workspaceId: 'ws-1');

      expect(result.readiness, AgentReadiness.noAdapter);
      expect(result.isReady, isFalse);
    });

    test('returns noAdapter when adapterId is empty string',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent(adapterId: '');
      final result = await checker.check(agent, workspaceId: 'ws-1');

      expect(result.readiness, AgentReadiness.noAdapter);
    });

    test('checkFromId returns noAdapter when agent not found',
        timeout: const Timeout.factor(2), () async {
      final result =
          await checker.checkFromId('missing', workspaceId: 'ws-1');

      expect(result.readiness, AgentReadiness.noAdapter);
      expect(result.reason, 'Agent not found');
    });

    test('checkFromId delegates to check when agent exists',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent();
      await agentRepo.upsert(agent);

      final result =
          await checker.checkFromId('agent-1', workspaceId: 'ws-1');

      expect(result.isReady, isTrue);
    });

    test('checkFromId propagates wrongWorkspace from check',
        timeout: const Timeout.factor(2), () async {
      final agent = _makeAgent(workspaceId: 'ws-1');
      await agentRepo.upsert(agent);

      final result =
          await checker.checkFromId('agent-1', workspaceId: 'ws-other');

      expect(result.readiness, AgentReadiness.wrongWorkspace);
    });
  });

  group('AgentReadinessResult', () {
    test('isReady is true only for ready state', timeout: const Timeout.factor(2), () {
      expect(
          const AgentReadinessResult(AgentReadiness.ready).isReady, isTrue);
      expect(
          const AgentReadinessResult(AgentReadiness.noAdapter).isReady, isFalse);
      expect(
          const AgentReadinessResult(AgentReadiness.wrongWorkspace).isReady,
          isFalse);
    });

    test('carries reason', timeout: const Timeout.factor(2), () {
      const result =
          AgentReadinessResult(AgentReadiness.noAdapter, reason: 'no adapter');
      expect(result.reason, 'no adapter');
    });
  });
}
