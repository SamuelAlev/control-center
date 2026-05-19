import 'package:control_center/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ReviewDao - drafts', () {
    test('upsertDraft and getDraft', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'LGTM pending CI');

      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, 'LGTM pending CI');
    });

    test('getDraft returns null for nonexistent draft', () async {
      final draft = await db.reviewDao.getDraft('acme', 'repo', 99);
      expect(draft, isNull);
    });

    test('upsertDraft overwrites existing draft', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'first');
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'second');

      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, 'second');
    });

    test('different PRs have separate drafts', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 1, 'draft-1');
      await db.reviewDao.upsertDraft('acme', 'repo', 2, 'draft-2');

      expect(await db.reviewDao.getDraft('acme', 'repo', 1), 'draft-1');
      expect(await db.reviewDao.getDraft('acme', 'repo', 2), 'draft-2');
    });

    test('different owners/repos have separate drafts', () async {
      await db.reviewDao.upsertDraft('owner1', 'repo', 1, 'o1-r1');
      await db.reviewDao.upsertDraft('owner2', 'repo', 1, 'o2-r1');
      await db.reviewDao.upsertDraft('owner1', 'repo2', 1, 'o1-r2');

      expect(await db.reviewDao.getDraft('owner1', 'repo', 1), 'o1-r1');
      expect(await db.reviewDao.getDraft('owner2', 'repo', 1), 'o2-r1');
      expect(await db.reviewDao.getDraft('owner1', 'repo2', 1), 'o1-r2');
    });

    test('clearDraft removes a draft', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'will be cleared');
      await db.reviewDao.clearDraft('acme', 'repo', 42);

      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, isNull);
    });

    test('clearDraft is no-op for nonexistent draft', () async {
      await db.reviewDao.clearDraft('acme', 'repo', 999);
    });

    test('upsertDraft preserves updatedAt', () async {
      final before = DateTime.now();
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'test');

      final row = await (db.select(db.reviewDrafts)
            ..where((t) => t.id.equals('acme/repo/42')))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(
        row!.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
