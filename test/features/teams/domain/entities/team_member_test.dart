import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TeamMember createMember({
    String teamId = 'team-1',
    String agentId = 'agent-1',
    TeamMemberRole role = TeamMemberRole.member,
  }) {
    return TeamMember(
      teamId: teamId,
      agentId: agentId,
      role: role,
    );
  }

  group('TeamMemberRole', () {
    group('fromString', () {
      test('returns leader for leader', timeout: const Timeout.factor(2), () {
        expect(TeamMemberRole.fromString('leader'), TeamMemberRole.leader);
      });

      test('returns member for member', timeout: const Timeout.factor(2), () {
        expect(TeamMemberRole.fromString('member'), TeamMemberRole.member);
      });

      test('returns member for unknown values', timeout: const Timeout.factor(2), () {
        expect(TeamMemberRole.fromString('unknown'), TeamMemberRole.member);
        expect(TeamMemberRole.fromString(''), TeamMemberRole.member);
        expect(TeamMemberRole.fromString('LEADER'), TeamMemberRole.member);
      });
    });

    group('toStorageString', () {
      test('returns correct string for leader', timeout: const Timeout.factor(2), () {
        expect(TeamMemberRole.leader.toStorageString(), 'leader');
      });

      test('returns correct string for member', timeout: const Timeout.factor(2), () {
        expect(TeamMemberRole.member.toStorageString(), 'member');
      });

      test('round-trips through fromString', timeout: const Timeout.factor(2), () {
        for (final role in TeamMemberRole.values) {
          expect(TeamMemberRole.fromString(role.toStorageString()), role);
        }
      });
    });
  });

  group('TeamMember', () {
    group('constructor', () {
      test('creates member with required fields', timeout: const Timeout.factor(2), () {
        final m = createMember();
        expect(m.teamId, 'team-1');
        expect(m.agentId, 'agent-1');
        expect(m.role, TeamMemberRole.member);
      });

      test('creates member with leader role', timeout: const Timeout.factor(2), () {
        final m = createMember(role: TeamMemberRole.leader);
        expect(m.role, TeamMemberRole.leader);
      });

      test('defaults to member role', timeout: const Timeout.factor(2), () {
        final m = TeamMember(teamId: 't', agentId: 'a');
        expect(m.role, TeamMemberRole.member);
      });
    });

    group('== and hashCode', () {
      test('== returns true for same teamId and agentId', timeout: const Timeout.factor(2), () {
        final m1 = createMember(role: TeamMemberRole.leader);
        final m2 = createMember(role: TeamMemberRole.member);
        expect(m1, equals(m2));
      });

      test('== returns false for different teamId', timeout: const Timeout.factor(2), () {
        final m1 = createMember(teamId: 'team-1');
        final m2 = createMember(teamId: 'team-2');
        expect(m1, isNot(equals(m2)));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final m1 = createMember(agentId: 'agent-1');
        final m2 = createMember(agentId: 'agent-2');
        expect(m1, isNot(equals(m2)));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final m = createMember();
        expect(m, equals(m));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final m = createMember();
        expect(m, isNot(equals('not a member')));
      });

      test('hashCode matches for equal members', timeout: const Timeout.factor(2), () {
        final m1 = createMember();
        final m2 = createMember();
        expect(m1.hashCode, equals(m2.hashCode));
      });

      test('hashCode differs for different members', timeout: const Timeout.factor(2), () {
        final m1 = createMember(agentId: 'a1');
        final m2 = createMember(agentId: 'a2');
        expect(m1.hashCode, isNot(equals(m2.hashCode)));
      });
    });
  });
}
