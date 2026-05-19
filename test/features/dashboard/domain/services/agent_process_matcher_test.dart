import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:control_center/features/dashboard/domain/services/agent_process_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent({
  required String id,
  required String name,
  String agentMdPath = '/ws/agents/test/AGENTS.md',
}) {
  return Agent(
    id: id,
    name: name,
    title: 'Title for $name',
    agentMdPath: agentMdPath,
    workspaceId: 'ws-1',
    skills: AgentSkills([]),
    createdAt: DateTime.now(),
  );
}

ActiveProcessInfo _process({
  required int pid,
  required String command,
  String workspaceName = 'My Workspace',
}) {
  return ActiveProcessInfo(
    agentName: '',
    workspaceName: workspaceName,
    pid: pid,
    command: command,
    startTime: DateTime.now(),
  );
}

void main() {
  group('AgentProcessMatcher', () {
    late AgentProcessMatcher matcher;

    setUp(() {
      matcher = AgentProcessMatcher();
    });

    test('returns processes unchanged when agents list is empty', () {
      final processes = [
        _process(pid: 1, command: 'ceo --workspace My Workspace'),
      ];

      final matched = matcher.match(processes: processes, agents: []);

      expect(matched.length, 1);
      expect(matched[0].pid, 1);
      expect(matched[0].agentName, '');
    });

    test('returns processes unchanged when processes list is empty', () {
      final agents = [_agent(id: 'a1', name: 'ceo')];

      final matched = matcher.match(processes: [], agents: agents);

      expect(matched, isEmpty);
    });

    test('matches process by agent name in command', () {
      final processes = [
        _process(pid: 100, command: '/usr/bin/ceo --workspace ws-1'),
      ];
      final agents = [_agent(id: 'a1', name: 'ceo')];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched[0].agentName, 'ceo');
      expect(matched[0].pid, 100);
      expect(matched[0].workspaceName, 'My Workspace');
    });

    test('matches case-insensitively', () {
      final processes = [
        _process(pid: 100, command: '/usr/bin/CEO --workspace ws-1'),
      ];
      final agents = [_agent(id: 'a1', name: 'ceo')];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched[0].agentName, 'ceo');
    });

    test('matches by agentMdPath slug when name not found', () {
      final processes = [
        _process(pid: 200, command: 'runner --workspace ws1'),
      ];
      final agents = [
        _agent(
          id: 'a1',
          name: 'very_different_name',
          agentMdPath: '/some/path/runner',
        ),
      ];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched[0].agentName, 'very_different_name');
    });

    test('matches multiple processes', () {
      final processes = [
        _process(pid: 1, command: 'ceo'),
        _process(pid: 2, command: 'architect'),
      ];
      final agents = [
        _agent(id: 'a1', name: 'ceo'),
        _agent(id: 'a2', name: 'architect'),
      ];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched.length, 2);
      expect(matched[0].agentName, 'ceo');
      expect(matched[1].agentName, 'architect');
    });

    test('preserves process properties for matched processes', () {
      final now = DateTime(2026, 1, 1);
      final processes = [
        ActiveProcessInfo(
          agentName: '',
          workspaceName: 'WS Alpha',
          pid: 42,
          command: 'ceo -w ws1',
          startTime: now,
        ),
      ];
      final agents = [_agent(id: 'a1', name: 'ceo')];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched[0].workspaceName, 'WS Alpha');
      expect(matched[0].pid, 42);
      expect(matched[0].startTime, now);
    });

    test('name match takes precedence over slug match', () {
      final processes = [
        _process(pid: 1, command: 'reviews'),
      ];
      final agents = [
        _agent(id: 'a1', name: 'reviews', agentMdPath: '/agents/reviews.py/AGENTS.md'),
      ];

      final matched = matcher.match(processes: processes, agents: agents);

      expect(matched[0].agentName, 'reviews');
    });
  });
}
