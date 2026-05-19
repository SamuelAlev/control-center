import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/services/team_operating_protocol.dart';
import 'package:cc_domain/features/teams/domain/services/team_roster.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(
  String id,
  String name, {
  List<String> skills = const [],
  AgentRole? role,
}) => Agent(
  id: id,
  name: name,
  title: '$name title',
  agentMdPath: '/agents/$id.md',
  workspaceId: 'ws1',
  skills: AgentSkills(skills),
  role: role,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  final team = Team(
    id: 'team1',
    workspaceId: 'ws1',
    name: 'Frontend',
    leaderId: 'lead',
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final members = [
    TeamMember(teamId: 'team1', agentId: 'lead', role: TeamMemberRole.leader),
    TeamMember(teamId: 'team1', agentId: 'alice'),
    TeamMember(teamId: 'team1', agentId: 'bob'),
  ];
  final agentsById = {
    'lead': _agent('lead', 'Lina', role: AgentRole.pm),
    'alice': _agent('alice', 'Alice', skills: ['flutter', 'a11y']),
    'bob': _agent('bob', 'Bob', skills: ['testing']),
  };

  group('buildTeamRoster', () {
    test('emits mention links for non-leader members with their skills', () {
      final roster = buildTeamRoster(
        team: team,
        members: members,
        agentsById: agentsById,
      );
      expect(roster, contains('[@Alice](mention://agent/alice)'));
      expect(roster, contains('[@Bob](mention://agent/bob)'));
      expect(roster, contains('skills: flutter, a11y'));
      expect(roster, contains('skills: testing'));
    });

    test('excludes the leader from the delegatable roster', () {
      final roster = buildTeamRoster(
        team: team,
        members: members,
        agentsById: agentsById,
      );
      expect(roster, isNot(contains('mention://agent/lead')));
    });

    test('handles a member with no assigned skills', () {
      final roster = buildTeamRoster(
        team: team,
        members: [TeamMember(teamId: 'team1', agentId: 'alice')],
        agentsById: {'alice': _agent('alice', 'Alice')},
      );
      expect(roster, contains('(no skills assigned)'));
    });
  });

  group('TeamOperatingProtocol.build', () {
    test(
      'includes the stop-after-dispatch contract, the eval verb and roster',
      () {
        final briefing = TeamOperatingProtocol.build(
          team: team,
          members: members,
          agentsById: agentsById,
          ticketId: 'TIX-1',
        );
        expect(briefing, contains('coordinator'));
        expect(briefing, contains('Stop after dispatch'));
        expect(briefing, contains('record_team_activity'));
        expect(briefing, contains('TIX-1'));
        expect(briefing, contains('[@Alice](mention://agent/alice)'));
      },
    );

    test('appends team instructions when present', () {
      final withInstructions = team.copyWith(
        instructions: 'Always ship behind a feature flag.',
      );
      final briefing = TeamOperatingProtocol.build(
        team: withInstructions,
        members: members,
        agentsById: agentsById,
      );
      expect(briefing, contains('Always ship behind a feature flag.'));
    });
  });
}
