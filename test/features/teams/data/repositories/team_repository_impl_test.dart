import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/team_dao.dart';
import 'package:cc_persistence/repositories/team_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TeamDao dao;
  late TeamRepositoryImpl repo;

  setUp(() async {
    db = createTestDatabase();
    dao = TeamDao(db);
    repo = TeamRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  Team makeTeam({
    String id = 'team-1',
    String workspaceId = 'ws-1',
    String name = 'Engineering',
    String? description = 'Core engineering team',
  }) =>
      Team(
        id: id,
        workspaceId: workspaceId,
        name: name,
        description: description,
        createdAt: DateTime(2025, 1, 1),
      );

  TeamMember makeMember({
    String teamId = 'team-1',
    String agentId = 'agent-42',
    TeamMemberRole role = TeamMemberRole.member,
  }) =>
      TeamMember(teamId: teamId, agentId: agentId, role: role);

  // ── Teams CRUD ──────────────────────────────────────────────────

  group('Teams CRUD', () {
    test('insertTeam persists a team', timeout: const Timeout.factor(2),
        () async {
      final team = makeTeam();
      await repo.insertTeam(team);

      final result = await repo.getTeam('team-1');
      expect(result, isNotNull);
      expect(result!.id, 'team-1');
      expect(result.workspaceId, 'ws-1');
      expect(result.name, 'Engineering');
      expect(result.description, 'Core engineering team');
      expect(result.createdAt, DateTime(2025, 1, 1));
    });

    test('insertTeam persists team with null description',
        timeout: const Timeout.factor(2), () async {
      final team = makeTeam(id: 't-null', description: null);
      await repo.insertTeam(team);

      final result = await repo.getTeam('t-null');
      expect(result, isNotNull);
      expect(result!.description, isNull);
    });

    test('getTeam retrieves by id', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam());
      final result = await repo.getTeam('team-1');
      expect(result, isNotNull);
      expect(result!.id, 'team-1');
    });

    test('getTeam returns null for missing id', timeout: const Timeout.factor(2),
        () async {
      final result = await repo.getTeam('nonexistent');
      expect(result, isNull);
    });

    test('getTeam returns null for empty database', timeout: const Timeout.factor(2),
        () async {
      final result = await repo.getTeam('any');
      expect(result, isNull);
    });

    test('teamsForWorkspace returns teams scoped to workspace',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-1', workspaceId: 'ws-1', name: 'A'));
      await repo.insertTeam(makeTeam(id: 't-2', workspaceId: 'ws-1', name: 'B'));
      await repo.insertTeam(makeTeam(id: 't-3', workspaceId: 'ws-2', name: 'C'));

      final ws1 = await repo.teamsForWorkspace('ws-1');
      expect(ws1.length, 2);
      expect(ws1.map((t) => t.id), containsAll(['t-1', 't-2']));

      final ws2 = await repo.teamsForWorkspace('ws-2');
      expect(ws2.length, 1);
      expect(ws2.single.id, 't-3');
    });

    test('teamsForWorkspace returns empty for workspace with no teams',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(workspaceId: 'ws-1'));
      final teams = await repo.teamsForWorkspace('ws-empty');
      expect(teams, isEmpty);
    });

    test('cross-workspace isolation: teams from different workspaces do not mix',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-ws1', workspaceId: 'ws-a', name: 'Alpha'));
      await repo.insertTeam(makeTeam(id: 't-ws2', workspaceId: 'ws-b', name: 'Beta'));

      final wsA = await repo.teamsForWorkspace('ws-a');
      expect(wsA.length, 1);
      expect(wsA.single.workspaceId, 'ws-a');
      expect(wsA.single.name, 'Alpha');

      final wsB = await repo.teamsForWorkspace('ws-b');
      expect(wsB.length, 1);
      expect(wsB.single.workspaceId, 'ws-b');
      expect(wsB.single.name, 'Beta');

      // Ensure they don't cross-contaminate
      expect(wsA.single.id, isNot(wsB.single.id));
    });

    test('deleteTeam removes a team', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam());
      await repo.deleteTeam('team-1');

      final result = await repo.getTeam('team-1');
      expect(result, isNull);
    });

    test('deleteTeam of nonexistent team does not throw',
        timeout: const Timeout.factor(2), () async {
      // should complete without error
      await repo.deleteTeam('nonexistent');
    });

    test('deleteTeam only removes the targeted team',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-keep', name: 'Keep'));
      await repo.insertTeam(makeTeam(id: 't-del', name: 'Delete'));
      await repo.deleteTeam('t-del');

      expect(await repo.getTeam('t-keep'), isNotNull);
      expect(await repo.getTeam('t-del'), isNull);
    });

    test('updateTeam modifies team fields', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam());
      final updated = Team(
        id: 'team-1',
        workspaceId: 'ws-1',
        name: 'Design',
        description: 'Updated description',
        createdAt: DateTime(2025, 1, 1),
      );
      await repo.updateTeam(updated);

      final result = await repo.getTeam('team-1');
      expect(result, isNotNull);
      expect(result!.name, 'Design');
      expect(result.description, 'Updated description');
    });

    test('updateTeam can clear description', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam(description: 'has desc'));
      final updated = Team(
        id: 'team-1',
        workspaceId: 'ws-1',
        name: 'Engineering',
        description: null,
        createdAt: DateTime(2025, 1, 1),
      );
      await repo.updateTeam(updated);

      final result = await repo.getTeam('team-1');
      expect(result!.description, isNull);
    });

    test('updateTeam replaces team by id', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam(id: 't-a', name: 'Old'));
      await repo.insertTeam(makeTeam(id: 't-b', name: 'Other'));

      await repo.updateTeam(makeTeam(id: 't-a', name: 'New'));
      // t-b should be unchanged
      final tA = await repo.getTeam('t-a');
      final tB = await repo.getTeam('t-b');
      expect(tA!.name, 'New');
      expect(tB!.name, 'Other');
    });

    test('insertTeam then updateTeam then teamsForWorkspace reflects changes',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-1', workspaceId: 'ws-1', name: 'Old'));
      await repo.updateTeam(makeTeam(id: 't-1', workspaceId: 'ws-1', name: 'New'));

      final teams = await repo.teamsForWorkspace('ws-1');
      expect(teams.length, 1);
      expect(teams.single.name, 'New');
    });
  });

  // ── Members CRUD ────────────────────────────────────────────────

  group('Members CRUD', () {
    setUp(() async {
      // Most member tests need a team to reference.
      await repo.insertTeam(makeTeam());
    });

    test('addMember adds a member to a team', timeout: const Timeout.factor(2),
        () async {
      await repo.addMember(makeMember());

      final members = await repo.membersOf('team-1');
      expect(members.length, 1);
      expect(members.first.teamId, 'team-1');
      expect(members.first.agentId, 'agent-42');
      expect(members.first.role, TeamMemberRole.member);
    });

    test('addMember with leader role', timeout: const Timeout.factor(2),
        () async {
      await repo.addMember(makeMember(role: TeamMemberRole.leader));

      final members = await repo.membersOf('team-1');
      expect(members.single.role, TeamMemberRole.leader);
    });

    test('addMember accepts multiple members', timeout: const Timeout.factor(2),
        () async {
      await repo.addMember(makeMember(agentId: 'a1'));
      await repo.addMember(makeMember(agentId: 'a2'));
      await repo.addMember(makeMember(agentId: 'a3'));

      final members = await repo.membersOf('team-1');
      expect(members.length, 3);
      expect(members.map((m) => m.agentId), containsAll(['a1', 'a2', 'a3']));
    });

    test('addMember ignores duplicate (same teamId + agentId)',
        timeout: const Timeout.factor(2), () async {
      await repo.addMember(makeMember());
      await repo.addMember(makeMember());

      final members = await repo.membersOf('team-1');
      expect(members.length, 1);
    });

    test('addMember allows same agent in different teams',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 'team-2'));
      await repo.addMember(makeMember(teamId: 'team-1', agentId: 'agent-1'));
      await repo.addMember(makeMember(teamId: 'team-2', agentId: 'agent-1'));

      expect((await repo.membersOf('team-1')).length, 1);
      expect((await repo.membersOf('team-2')).length, 1);
    });

    test('membersOf returns members of a team', timeout: const Timeout.factor(2),
        () async {
      await repo.addMember(makeMember(agentId: 'a1'));
      await repo.addMember(makeMember(agentId: 'a2'));
      await repo.addMember(makeMember(agentId: 'a3', teamId: 'team-1'));

      final members = await repo.membersOf('team-1');
      expect(members.length, 3);
    });

    test('membersOf returns empty for team with no members',
        timeout: const Timeout.factor(2), () async {
      // setUp inserted team-1 with no members
      final members = await repo.membersOf('team-1');
      expect(members, isEmpty);
    });

    test('membersOf returns empty for nonexistent team',
        timeout: const Timeout.factor(2), () async {
      final members = await repo.membersOf('nonexistent');
      expect(members, isEmpty);
    });

    test('removeMember removes a member', timeout: const Timeout.factor(2),
        () async {
      await repo.addMember(makeMember(agentId: 'a1'));
      await repo.addMember(makeMember(agentId: 'a2'));
      await repo.removeMember('team-1', 'a1');

      final members = await repo.membersOf('team-1');
      expect(members.length, 1);
      expect(members.single.agentId, 'a2');
    });

    test('removeMember targets only the specified member',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 'team-2'));
      await repo.addMember(makeMember(teamId: 'team-1', agentId: 'shared'));
      await repo.addMember(makeMember(teamId: 'team-2', agentId: 'shared'));

      await repo.removeMember('team-1', 'shared');

      expect(await repo.membersOf('team-1'), isEmpty);
      expect((await repo.membersOf('team-2')).length, 1);
    });

    test('removeMember of nonexistent member does not throw',
        timeout: const Timeout.factor(2), () async {
      // Should complete without error
      await repo.removeMember('team-1', 'nonexistent-agent');
    });

    test('removeMember does not affect other teams',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 'team-2'));
      await repo.addMember(makeMember(teamId: 'team-1', agentId: 'a1'));
      await repo.addMember(makeMember(teamId: 'team-2', agentId: 'a2'));

      await repo.removeMember('team-1', 'a1');

      expect(await repo.membersOf('team-1'), isEmpty);
      expect((await repo.membersOf('team-2')).length, 1);
      expect((await repo.membersOf('team-2')).single.agentId, 'a2');
    });
  });

  // ── Streams ─────────────────────────────────────────────────────

  group('Streams', () {
    test('watchTeamsForWorkspace emits current teams',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-1', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-2', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-3', workspaceId: 'ws-2'));

      final results = await repo.watchTeamsForWorkspace('ws-1').first;
      expect(results.length, 2);
      expect(results.map((t) => t.id), containsAll(['t-1', 't-2']));
    });

    test('watchTeamsForWorkspace emits empty list when no teams',
        timeout: const Timeout.factor(2), () async {
      final results = await repo.watchTeamsForWorkspace('empty-ws').first;
      expect(results, isEmpty);
    });

    test('watchTeamsForWorkspace streams updates on insert',
        timeout: const Timeout.factor(2), () async {
      final stream = repo.watchTeamsForWorkspace('ws-1');

      // First emission — empty
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert should trigger another emission
      await repo.insertTeam(makeTeam(workspaceId: 'ws-1'));
      final second = await stream.first;
      expect(second.length, 1);
    });

    test('watchTeamsForWorkspace streams updates on delete',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-1', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-2', workspaceId: 'ws-1'));

      final stream = repo.watchTeamsForWorkspace('ws-1');
      // Skip the initial emission with 2 teams
      await stream.first;

      await repo.deleteTeam('t-1');
      final afterDelete = await stream.first;
      expect(afterDelete.length, 1);
      expect(afterDelete.single.id, 't-2');
    });

    test('watchTeamsForWorkspace does not emit teams from other workspaces',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-1', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-2', workspaceId: 'ws-2'));

      final results = await repo.watchTeamsForWorkspace('ws-1').first;
      expect(results.length, 1);
      expect(results.single.workspaceId, 'ws-1');
    });

    test('watchMembersOf emits current members', timeout: const Timeout.factor(2),
        () async {
      await repo.insertTeam(makeTeam());
      await repo.addMember(makeMember(agentId: 'a1'));
      await repo.addMember(makeMember(agentId: 'a2'));

      final results = await repo.watchMembersOf('team-1').first;
      expect(results.length, 2);
      expect(results.map((m) => m.agentId), containsAll(['a1', 'a2']));
    });

    test('watchMembersOf emits empty for team with no members',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam());
      final results = await repo.watchMembersOf('team-1').first;
      expect(results, isEmpty);
    });

    test('watchMembersOf streams updates on addMember',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam());

      final stream = repo.watchMembersOf('team-1');
      final first = await stream.first;
      expect(first, isEmpty);

      await repo.addMember(makeMember(agentId: 'a1'));
      final second = await stream.first;
      expect(second.length, 1);
      expect(second.single.agentId, 'a1');
    });

    test('watchMembersOf streams updates on removeMember',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam());
      await repo.addMember(makeMember(agentId: 'a1'));
      await repo.addMember(makeMember(agentId: 'a2'));

      final stream = repo.watchMembersOf('team-1');
      // Drain initial emission
      await stream.first;

      await repo.removeMember('team-1', 'a1');
      final afterRemove = await stream.first;
      expect(afterRemove.length, 1);
      expect(afterRemove.single.agentId, 'a2');
    });

    test('watchMembersOf does not emit members from other teams',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 'team-1'));
      await repo.insertTeam(makeTeam(id: 'team-2'));
      await repo.addMember(makeMember(teamId: 'team-1', agentId: 'a1'));
      await repo.addMember(makeMember(teamId: 'team-2', agentId: 'a2'));

      final results = await repo.watchMembersOf('team-1').first;
      expect(results.length, 1);
      expect(results.single.agentId, 'a1');
    });
  });

  // ── Cross-workspace member isolation ────────────────────────────

  group('Cross-workspace member isolation', () {
    test('members of teams in different workspaces are independent',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-ws1', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-ws2', workspaceId: 'ws-2'));
      await repo.addMember(makeMember(teamId: 't-ws1', agentId: 'agent-a'));
      await repo.addMember(makeMember(teamId: 't-ws2', agentId: 'agent-b'));

      expect((await repo.membersOf('t-ws1')).single.agentId, 'agent-a');
      expect((await repo.membersOf('t-ws2')).single.agentId, 'agent-b');
    });

    test('removing member from one workspace does not affect another',
        timeout: const Timeout.factor(2), () async {
      await repo.insertTeam(makeTeam(id: 't-ws1', workspaceId: 'ws-1'));
      await repo.insertTeam(makeTeam(id: 't-ws2', workspaceId: 'ws-2'));
      await repo.addMember(makeMember(teamId: 't-ws1', agentId: 'shared'));
      await repo.addMember(makeMember(teamId: 't-ws2', agentId: 'shared'));

      await repo.removeMember('t-ws1', 'shared');

      expect(await repo.membersOf('t-ws1'), isEmpty);
      expect((await repo.membersOf('t-ws2')).length, 1);
    });
  });
}
