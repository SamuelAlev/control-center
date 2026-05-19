import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/teams/data/mappers/team_mappers.dart';
import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  final now = DateTime(2025, 6, 11, 14, 30);
  final teamEntity = Team(
    id: 'team-1',
    workspaceId: 'ws-1',
    name: 'Engineering',
    description: 'Core engineering team',
    createdAt: now,
  );
  final teamEntityNoDesc = Team(
    id: 'team-2',
    workspaceId: 'ws-2',
    name: 'Design',
    createdAt: now,
  );
  final memberEntity = TeamMember(
    teamId: 'team-1',
    agentId: 'agent-42',
    role: TeamMemberRole.leader,
  );
  final memberEntityDefault = TeamMember(
    teamId: 'team-1',
    agentId: 'agent-99',
  );

  group('teamToCompanion', () {
    test('converts all fields with Value wrappers', timeout: const Timeout.factor(2), () {
      final companion = teamToCompanion(teamEntity);

      expect(companion.id, isA<Value<String>>());
      expect(companion.id.value, 'team-1');
      expect(companion.workspaceId, isA<Value<String>>());
      expect(companion.workspaceId.value, 'ws-1');
      expect(companion.name, isA<Value<String>>());
      expect(companion.name.value, 'Engineering');
      expect(companion.description, isA<Value<String?>>());
      expect(companion.description.value, 'Core engineering team');
      expect(companion.createdAt, isA<Value<DateTime>>());
      expect(companion.createdAt.value, now);
    });

    test('wraps null description in Value', timeout: const Timeout.factor(2), () {
      final companion = teamToCompanion(teamEntityNoDesc);

      expect(companion.description, isA<Value<String?>>());
      expect(companion.description.value, isNull);
    });
  });

  group('teamFromRow', () {
    test('reconstructs Team from table row', timeout: const Timeout.factor(2), () {
      final row = TeamsTableData(
        id: 'team-1',
        workspaceId: 'ws-1',
        name: 'Engineering',
        description: 'Core engineering team',
        createdAt: now,
      );
      final team = teamFromRow(row);

      expect(team.id, 'team-1');
      expect(team.workspaceId, 'ws-1');
      expect(team.name, 'Engineering');
      expect(team.description, 'Core engineering team');
      expect(team.createdAt, now);
    });

    test('handles null description', timeout: const Timeout.factor(2), () {
      final row = TeamsTableData(
        id: 'team-2',
        workspaceId: 'ws-2',
        name: 'Design',
        createdAt: now,
      );
      final team = teamFromRow(row);

      expect(team.description, isNull);
    });
  });

  group('teamMemberToCompanion', () {
    test('converts TeamMember with role serialization', timeout: const Timeout.factor(2), () {
      final companion = teamMemberToCompanion(memberEntity);

      expect(companion.teamId, isA<Value<String>>());
      expect(companion.teamId.value, 'team-1');
      expect(companion.agentId, isA<Value<String>>());
      expect(companion.agentId.value, 'agent-42');
      expect(companion.role, isA<Value<String>>());
      expect(companion.role.value, 'leader');
    });

    test('serializes default member role as "member"', timeout: const Timeout.factor(2), () {
      final companion = teamMemberToCompanion(memberEntityDefault);

      expect(companion.role.value, 'member');
    });
  });

  group('teamMemberFromRow', () {
    test('reconstructs TeamMember with role deserialization', timeout: const Timeout.factor(2), () {
      const row = TeamMembersTableData(
        teamId: 'team-1',
        agentId: 'agent-42',
        role: 'leader',
      );
      final member = teamMemberFromRow(row);

      expect(member.teamId, 'team-1');
      expect(member.agentId, 'agent-42');
      expect(member.role, TeamMemberRole.leader);
    });

    test('deserializes "member" role', timeout: const Timeout.factor(2), () {
      const row = TeamMembersTableData(
        teamId: 'team-1',
        agentId: 'agent-99',
        role: 'member',
      );
      final member = teamMemberFromRow(row);

      expect(member.role, TeamMemberRole.member);
    });

    test('falls back to member for unknown role strings', timeout: const Timeout.factor(2), () {
      const row = TeamMembersTableData(
        teamId: 'team-1',
        agentId: 'agent-77',
        role: 'garbage',
      );
      final member = teamMemberFromRow(row);

      expect(member.role, TeamMemberRole.member);
    });
  });

  group('round-trip', () {
    test(
      'Team: entity → companion → insert → read → fromRow → equality',
      timeout: const Timeout.factor(2),
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final original = Team(
          id: 'rt-team',
          workspaceId: 'ws-rt',
          name: 'Roundtrip',
          description: 'Roundtrip test team',
          createdAt: now,
        );

        final companion = teamToCompanion(original);
        await db.into(db.teamsTable).insert(companion);

        final row = await db.select(db.teamsTable).getSingle();
        final restored = teamFromRow(row);

        expect(restored.id, original.id);
        expect(restored.workspaceId, original.workspaceId);
        expect(restored.name, original.name);
        expect(restored.description, original.description);
        expect(restored.createdAt, original.createdAt);
      },
    );

    test(
      'Team round-trip with null description',
      timeout: const Timeout.factor(2),
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final original = Team(
          id: 'rt-team-nodesc',
          workspaceId: 'ws-rt',
          name: 'NoDesc',
          createdAt: now,
        );

        final companion = teamToCompanion(original);
        await db.into(db.teamsTable).insert(companion);

        final row = await db.select(db.teamsTable).getSingle();
        final restored = teamFromRow(row);

        expect(restored.description, isNull);
      },
    );

    test(
      'TeamMember: entity → companion → insert → read → fromRow → equality',
      timeout: const Timeout.factor(2),
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final original = TeamMember(
          teamId: 'rt-team',
          agentId: 'rt-agent',
          role: TeamMemberRole.leader,
        );

        final companion = teamMemberToCompanion(original);
        await db.into(db.teamMembersTable).insert(companion);

        final row = await db.select(db.teamMembersTable).getSingle();
        final restored = teamMemberFromRow(row);

        expect(restored.teamId, original.teamId);
        expect(restored.agentId, original.agentId);
        expect(restored.role, original.role);
      },
    );

    test(
      'TeamMember round-trip with default role',
      timeout: const Timeout.factor(2),
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final original = TeamMember(
          teamId: 'rt-team',
          agentId: 'rt-agent-2',
        );

        final companion = teamMemberToCompanion(original);
        await db.into(db.teamMembersTable).insert(companion);

        final row = await db.select(db.teamMembersTable).getSingle();
        final restored = teamMemberFromRow(row);

        expect(restored.role, TeamMemberRole.member);
      },
    );
  });
}
