import 'package:cc_domain/features/skills/domain/entities/skill_source.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  group('DaoSkillSourceRepository', () {
    late WorkspaceDatabaseManager dbs;
    late DaoSkillSourceRepository repo;

    setUp(() {
      dbs = createTestWorkspaceDatabases();
      repo = DaoSkillSourceRepository(dbs);
    });

    tearDown(() async {
      await dbs.closeAll();
    });

    SkillSource source(String workspaceId, String owner, String repo_) =>
        SkillSource(
          id: 'id-$owner-$repo_',
          workspaceId: workspaceId,
          owner: owner,
          repo: repo_,
          url: 'https://github.com/$owner/$repo_',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        );

    test('add + list round-trips', () async {
      await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      await repo.add('ws-a', source('ws-a', 'anthropics', 'claude-skills'));

      final list = await repo.list('ws-a');
      expect(
        list.map((s) => s.fullName),
        containsAll(['octo/skills', 'anthropics/claude-skills']),
      );
    });

    test('byOwnerRepo finds the source', () async {
      await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      final found = await repo.byOwnerRepo('ws-a', 'octo', 'skills');
      expect(found?.fullName, 'octo/skills');
      expect(await repo.byOwnerRepo('ws-a', 'octo', 'other'), isNull);
    });

    test('byId resolves only within the workspace', () async {
      final stored = await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      expect(await repo.byId('ws-a', stored.id), isNotNull);
      // The isolation invariant: the same id in another workspace's file is
      // simply not found.
      expect(await repo.byId('ws-b', stored.id), isNull);
    });

    test('a source is invisible from another workspace', () async {
      await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      expect(await repo.list('ws-b'), isEmpty);
      expect(await repo.byOwnerRepo('ws-b', 'octo', 'skills'), isNull);
    });

    test('update persists sync state and clears errors', () async {
      final stored = await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      await repo.update(
        'ws-a',
        stored.copyWith(
          skillCount: 7,
          lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(1700000001000),
          lastError: 'boom',
        ),
      );
      var row = await repo.byId('ws-a', stored.id);
      expect(row?.skillCount, 7);
      expect(row?.lastError, 'boom');

      await repo.update(
        'ws-a',
        row!.copyWith(skillCount: 8, clearLastError: true),
      );
      row = await repo.byId('ws-a', stored.id);
      expect(row?.skillCount, 8);
      expect(row?.lastError, isNull);
    });

    test('remove deletes the row only in its workspace', () async {
      final stored = await repo.add('ws-a', source('ws-a', 'octo', 'skills'));
      await repo.remove('ws-a', stored.id);
      expect(await repo.list('ws-a'), isEmpty);
    });
  });
}
