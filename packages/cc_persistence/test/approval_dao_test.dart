import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedApproval({
    required String id,
    required String ws,
    String title = 'merge',
    String status = 'pending',
  }) => db.approvalDao.upsert(
    ApprovalsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      title: title,
      status: Value(status),
    ),
  );

  group('ApprovalDao workspace isolation', () {
    test('watchByWorkspace emits only the workspace rows', () async {
      await seedApproval(id: 'a-1', ws: 'w-1');
      await seedApproval(id: 'a-2', ws: 'w-2');
      final rows = await db.approvalDao.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'a-1');
    });

    test('watchByStatus filters by status within the workspace', () async {
      await seedApproval(id: 'a-1', ws: 'w-1', status: 'pending');
      await seedApproval(id: 'a-2', ws: 'w-1', status: 'approved');
      await seedApproval(id: 'a-3', ws: 'w-2', status: 'pending');
      final rows = await db.approvalDao.watchByStatus('w-1', 'pending').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'a-1');
    });

    test('getById is workspace-scoped', () async {
      await seedApproval(id: 'a-1', ws: 'w-1');
      expect((await db.approvalDao.getById('w-1', 'a-1'))?.id, 'a-1');
      expect(await db.approvalDao.getById('w-2', 'a-1'), isNull);
      expect(await db.approvalDao.getById('w-1', 'missing'), isNull);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await seedApproval(id: 'a-1', ws: 'w-1', title: 'first');
      await seedApproval(id: 'a-1', ws: 'w-1', title: 'second');
      expect((await db.approvalDao.getById('w-1', 'a-1'))?.title, 'second');
    });

    test(
      'deleteById is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seedApproval(id: 'a-1', ws: 'w-1');
        expect(await db.approvalDao.deleteById('w-2', 'a-1'), 0);
        expect(await db.approvalDao.getById('w-1', 'a-1'), isNotNull);
        expect(await db.approvalDao.deleteById('w-1', 'a-1'), 1);
        expect(await db.approvalDao.getById('w-1', 'a-1'), isNull);
      },
    );
  });

  group('ApprovalDao comments', () {
    test('insertComment + getComments is workspace-scoped', () async {
      await seedApproval(id: 'a-1', ws: 'w-1');
      await db.approvalDao.insertComment(
        ApprovalCommentsTableCompanion.insert(
          id: 'cm-1',
          approvalId: 'a-1',
          workspaceId: 'w-1',
          body: 'LGTM',
        ),
      );
      await db.approvalDao.insertComment(
        ApprovalCommentsTableCompanion.insert(
          id: 'cm-2',
          approvalId: 'a-1',
          workspaceId: 'w-1',
          body: 'ship it',
        ),
      );

      final comments = await db.approvalDao.getComments('w-1', 'a-1');
      expect(comments, hasLength(2));
      // oldest-first ordering.
      expect(comments.first.body, 'LGTM');

      // Foreign workspace cannot see the thread.
      expect(await db.approvalDao.getComments('w-2', 'a-1'), isEmpty);
    });

    test('watchComments emits only the workspace thread', () async {
      await seedApproval(id: 'a-1', ws: 'w-1');
      await db.approvalDao.insertComment(
        ApprovalCommentsTableCompanion.insert(
          id: 'cm-1',
          approvalId: 'a-1',
          workspaceId: 'w-1',
          body: 'hi',
        ),
      );
      final comments = await db.approvalDao.watchComments('w-1', 'a-1').first;
      expect(comments, hasLength(1));
    });

    test('comments cascade with the parent approval', () async {
      await seedApproval(id: 'a-1', ws: 'w-1');
      await db.approvalDao.insertComment(
        ApprovalCommentsTableCompanion.insert(
          id: 'cm-1',
          approvalId: 'a-1',
          workspaceId: 'w-1',
          body: 'hi',
        ),
      );
      await db.approvalDao.deleteById('w-1', 'a-1');
      expect(await db.approvalDao.getComments('w-1', 'a-1'), isEmpty);
    });
  });
}
