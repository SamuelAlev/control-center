import 'package:cc_persistence/database/global/global_database.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase db;

  setUp(() async {
    db = createTestGlobalDatabase();
    // user_preferences.userId FK-references users.id.
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: 'u-1',
            handle: 'u1',
            displayName: 'U1',
          ),
        );
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: 'u-2',
            handle: 'u2',
            displayName: 'U2',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('UserPreferenceDao', () {
    test('setValue upserts and getValue reads it back', () async {
      await db.userPreferenceDao.setValue('u-1', 'theme', 'dark');
      expect(await db.userPreferenceDao.getValue('u-1', 'theme'), 'dark');

      // upsert replaces
      await db.userPreferenceDao.setValue('u-1', 'theme', 'light');
      expect(await db.userPreferenceDao.getValue('u-1', 'theme'), 'light');
    });

    test('getValue is user-scoped and returns null for missing keys', () async {
      await db.userPreferenceDao.setValue('u-1', 'lang', 'en');
      expect(await db.userPreferenceDao.getValue('u-2', 'lang'), isNull);
      expect(await db.userPreferenceDao.getValue('u-1', 'missing'), isNull);
    });

    test('getForUser + watchForUser are user-scoped', () async {
      await db.userPreferenceDao.setValue('u-1', 'a', '1');
      await db.userPreferenceDao.setValue('u-1', 'b', '2');
      await db.userPreferenceDao.setValue('u-2', 'a', '9');

      expect(await db.userPreferenceDao.getForUser('u-1'), hasLength(2));
      expect(
        await db.userPreferenceDao.watchForUser('u-2').first,
        hasLength(1),
      );
    });

    test('deleteValue removes only the (user, key) pair', () async {
      await db.userPreferenceDao.setValue('u-1', 'a', '1');
      await db.userPreferenceDao.setValue('u-1', 'b', '2');
      await db.userPreferenceDao.setValue('u-2', 'a', '9');

      expect(await db.userPreferenceDao.deleteValue('u-1', 'a'), 1);
      expect(await db.userPreferenceDao.getValue('u-1', 'a'), isNull);
      expect(await db.userPreferenceDao.getValue('u-1', 'b'), '2');
      // other user untouched
      expect(await db.userPreferenceDao.getValue('u-2', 'a'), '9');
    });
  });
}
