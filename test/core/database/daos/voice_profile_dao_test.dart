import 'package:cc_persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Scope this test to DAO query logic, not FK enforcement.
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await db.close();
  });

  VoiceProfilesTableCompanion profile(String id, String ws, String name) =>
      VoiceProfilesTableCompanion.insert(
        id: id,
        workspaceId: ws,
        displayName: name,
        embedding: '[1.0,0.0]',
      );

  group('VoiceProfileDao workspace isolation', () {
    test('watch/getByWorkspace return only the workspace rows', () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));
      await db.voiceProfileDao.upsertProfile(profile('b', 'w2', 'Bea'));

      final w1 = await db.voiceProfileDao.getByWorkspace('w1');
      expect(w1.map((p) => p.displayName), ['Alex']);

      final w1Stream = await db.voiceProfileDao.watchByWorkspace('w1').first;
      expect(w1Stream.map((p) => p.id), ['a']);
    });

    test('getByName is workspace-scoped (a foreign workspace cannot read it)',
        () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));

      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNotNull);
      expect(await db.voiceProfileDao.getByName('w2', 'Alex'), isNull);
    });

    test('the same name can coexist across two workspaces', () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));
      await db.voiceProfileDao.upsertProfile(profile('b', 'w2', 'Alex'));

      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNotNull);
      expect(await db.voiceProfileDao.getByName('w2', 'Alex'), isNotNull);
    });

    test('the same name cannot exist twice within one workspace', () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));
      // A second row with the same (workspaceId, displayName) but a fresh id
      // violates the unique index.
      await expectLater(
        db.voiceProfileDao.upsertProfile(profile('b', 'w1', 'Alex')),
        throwsA(anything),
      );
    });

    test('rename with the wrong workspace is a no-op', () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));

      await db.voiceProfileDao.rename('w2', 'a', 'Hacked'); // wrong ws — no-op
      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNotNull);

      await db.voiceProfileDao.rename('w1', 'a', 'Alexandra');
      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNull);
      expect(await db.voiceProfileDao.getByName('w1', 'Alexandra'), isNotNull);
    });

    test('deleteProfile only deletes within the workspace', () async {
      await db.voiceProfileDao.upsertProfile(profile('a', 'w1', 'Alex'));

      await db.voiceProfileDao.deleteProfile('w2', 'a'); // wrong ws — no-op
      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNotNull);

      await db.voiceProfileDao.deleteProfile('w1', 'a');
      expect(await db.voiceProfileDao.getByName('w1', 'Alex'), isNull);
    });
  });
}
