import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/governance/domain/services/org_chart_service.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(
  String id, {
  String workspaceId = 'ws1',
  String? reportsTo,
  AgentRole? role,
}) => Agent(
  id: id,
  name: id,
  title: 'Agent $id',
  agentMdPath: '/tmp/$id.md',
  workspaceId: workspaceId,
  reportsTo: reportsTo,
  skills: AgentSkills(const []),
  role: role,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// Replayable fake — `watchByWorkspace` returns a fresh single-value stream so
/// the service's `.first` resolves deterministically.
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo(this.agents);
  final List<Agent> agents;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      agents.where((a) => a.id == id).firstOrNull;

  @override
  Stream<List<Agent>> watchAll() => Stream.value(agents);

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => agents
      .where((a) => a.workspaceId == workspaceId && a.name == name)
      .firstOrNull;

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

void main() {
  group('buildTreeFrom', () {
    test('CEO is the root; specialists report up', () {
      final agents = [
        _agent('ceo', role: AgentRole.ceo),
        _agent('coder', reportsTo: 'ceo', role: AgentRole.coder),
        _agent('reviewer', reportsTo: 'ceo', role: AgentRole.reviewer),
        _agent('qa', reportsTo: 'coder', role: AgentRole.qa),
      ];
      final roots = OrgChartService.buildTreeFrom(agents);
      expect(roots.length, 1);
      expect(roots.single.agent.id, 'ceo');
      expect(roots.single.reports.map((r) => r.agent.id).toSet(), {
        'coder',
        'reviewer',
      });
      expect(roots.single.subtreeSize, 4);
      expect(roots.single.depth, 2);
    });

    test('a stored self-cycle is broken into a root, not an infinite loop', () {
      final agents = [_agent('a', reportsTo: 'a')];
      final roots = OrgChartService.buildTreeFrom(agents);
      expect(roots.length, 1);
      expect(roots.single.agent.id, 'a');
    });

    test('an agent with a missing manager becomes a root', () {
      final agents = [_agent('orphan', reportsTo: 'ghost')];
      final roots = OrgChartService.buildTreeFrom(agents);
      expect(roots.single.agent.id, 'orphan');
    });
  });

  group('validateReportsTo', () {
    test('valid reporting line passes', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([_agent('ceo'), _agent('coder')]),
      );
      await svc.validateReportsTo(
        workspaceId: 'ws1',
        agentId: 'coder',
        reportsTo: 'ceo',
      );
    });

    test('reporting to self is rejected', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([_agent('a')]),
      );
      expect(
        () => svc.validateReportsTo(
          workspaceId: 'ws1',
          agentId: 'a',
          reportsTo: 'a',
        ),
        throwsA(isA<OrgChartException>()),
      );
    });

    test('a manager in another workspace is rejected', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([
          _agent('a', workspaceId: 'ws1'),
          _agent('foreign', workspaceId: 'ws2'),
        ]),
      );
      expect(
        () => svc.validateReportsTo(
          workspaceId: 'ws1',
          agentId: 'a',
          reportsTo: 'foreign',
        ),
        throwsA(isA<OrgChartException>()),
      );
    });

    test('a cycle is rejected', () async {
      // coder → ceo already; making ceo → coder closes a cycle.
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([
          _agent('ceo'),
          _agent('coder', reportsTo: 'ceo'),
        ]),
      );
      expect(
        () => svc.validateReportsTo(
          workspaceId: 'ws1',
          agentId: 'ceo',
          reportsTo: 'coder',
        ),
        throwsA(isA<OrgChartException>()),
      );
    });

    test('null manager (top-level) is always valid', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([_agent('a')]),
      );
      await svc.validateReportsTo(
        workspaceId: 'ws1',
        agentId: 'a',
        reportsTo: null,
      );
    });
  });

  group('assertDeletable', () {
    test('a manager with reports cannot be deleted', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([
          _agent('ceo'),
          _agent('coder', reportsTo: 'ceo'),
        ]),
      );
      expect(
        () => svc.assertDeletable(workspaceId: 'ws1', agentId: 'ceo'),
        throwsA(isA<OrgChartException>()),
      );
    });

    test('a leaf agent can be deleted', () async {
      final svc = OrgChartService(
        agentRepository: _FakeAgentRepo([
          _agent('ceo'),
          _agent('coder', reportsTo: 'ceo'),
        ]),
      );
      await svc.assertDeletable(workspaceId: 'ws1', agentId: 'coder');
    });
  });
}
