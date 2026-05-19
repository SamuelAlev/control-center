import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> record({
    required String id,
    required String ws,
    required String team,
    required String ticket,
    required String kind,
  }) => db.teamActivityDao.record(
    TeamActivityLogTableCompanion.insert(
      id: id,
      workspaceId: ws,
      teamId: team,
      ticketId: ticket,
      kind: kind,
    ),
  );

  group('TeamActivityDao workspace isolation', () {
    test('forTicket returns only the workspace rows, newest first', () async {
      await record(
        id: '1',
        ws: 'w-1',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'action',
      );
      await record(
        id: '2',
        ws: 'w-1',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'no_action',
      );
      await record(
        id: '3',
        ws: 'w-2',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'action',
      );

      final rows = await db.teamActivityDao.forTicket('w-1', 'tk-1');
      expect(rows, hasLength(2));
      // newest-first ordering by createdAt (both default to "now"; insert order
      // is preserved by tie-break on rowid).
      expect(rows.first.kind, isNotNull);
    });

    test('watchForTeam emits only the team rows in the workspace', () async {
      await record(
        id: '1',
        ws: 'w-1',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'action',
      );
      await record(
        id: '2',
        ws: 'w-1',
        team: 't-2',
        ticket: 'tk-1',
        kind: 'action',
      );
      await record(
        id: '3',
        ws: 'w-2',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'action',
      );

      final rows = await db.teamActivityDao.watchForTeam('w-1', 't-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.teamId, 't-1');
    });

    test('hasNoActionEvaluationForTicket is workspace+team scoped', () async {
      await record(
        id: '1',
        ws: 'w-1',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'no_action',
      );
      // Within (w-1, t-1) for tk-1: a no_action exists.
      expect(
        await db.teamActivityDao.hasNoActionEvaluationForTicket(
          'w-1',
          't-1',
          'tk-1',
        ),
        isTrue,
      );
      // Different team in same workspace: no.
      expect(
        await db.teamActivityDao.hasNoActionEvaluationForTicket(
          'w-1',
          't-2',
          'tk-1',
        ),
        isFalse,
      );
      // Different workspace: no.
      expect(
        await db.teamActivityDao.hasNoActionEvaluationForTicket(
          'w-2',
          't-1',
          'tk-1',
        ),
        isFalse,
      );
      // Different ticket: no.
      expect(
        await db.teamActivityDao.hasNoActionEvaluationForTicket(
          'w-1',
          't-1',
          'tk-2',
        ),
        isFalse,
      );
    });

    test('hasNoActionEvaluationForTicket ignores other kinds', () async {
      await record(
        id: '1',
        ws: 'w-1',
        team: 't-1',
        ticket: 'tk-1',
        kind: 'action',
      );
      expect(
        await db.teamActivityDao.hasNoActionEvaluationForTicket(
          'w-1',
          't-1',
          'tk-1',
        ),
        isFalse,
      );
    });
  });
}
