import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [SkillScanDao] against an in-memory database. Every read filters
/// by `workspaceId` (the isolation invariant); the cache key is
/// `(workspaceId, contentHash, rulesVersion)`.
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Seed workspaces the scans FK-reference.
  });

  tearDown(() async => db.close());

  Future<void> insertScan(
    String id,
    String ws,
    String hash, {
    int rulesVersion = 1,
    String verdict = 'pass',
    DateTime? scannedAt,
  }) => db.skillScanDao.upsertScan(
    SkillScanResultsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      contentHash: hash,
      rulesVersion: Value(rulesVersion),
      verdict: Value(verdict),
      scannedAt: scannedAt == null ? const Value.absent() : Value(scannedAt),
    ),
  );

  group('SkillScanDao workspace isolation', () {
    test('scanByHash is scoped by workspace', () async {
      await insertScan('s-1', 'w-1', 'hash-a');
      expect(await db.skillScanDao.scanByHash('w-1', 'hash-a', 1), isNotNull);
      // w-2 must not see w-1's scan.
      expect(await db.skillScanDao.scanByHash('w-2', 'hash-a', 1), isNull);
    });

    test('scanByHash matches the rules version', () async {
      await insertScan('s-1', 'w-1', 'hash-a', rulesVersion: 1);
      expect(await db.skillScanDao.scanByHash('w-1', 'hash-a', 1), isNotNull);
      expect(await db.skillScanDao.scanByHash('w-1', 'hash-a', 2), isNull);
    });

    test('scans is scoped by workspace and ordered newest-first', () async {
      await insertScan('s-1', 'w-1', 'h1', scannedAt: DateTime(2026, 1, 1));
      await insertScan('s-2', 'w-1', 'h2', scannedAt: DateTime(2026, 2, 1));
      await insertScan('s-3', 'w-2', 'h3', scannedAt: DateTime(2026, 3, 1));
      final scans = await db.skillScanDao.scans('w-1');
      expect(scans.map((s) => s.id), ['s-2', 's-1']);
    });

    test('watchScans is scoped by workspace', () async {
      await insertScan('s-1', 'w-1', 'h1');
      await insertScan('s-2', 'w-2', 'h2');
      final scans = await db.skillScanDao.watchScans('w-1').first;
      expect(scans.map((s) => s.id), ['s-1']);
    });
  });

  group('SkillScanDao staleness', () {
    test(
      'latestScanForHash returns the most recent under any rules version',
      () async {
        await insertScan(
          's-1',
          'w-1',
          'h',
          rulesVersion: 1,
          scannedAt: DateTime(2026, 1, 1),
        );
        await insertScan(
          's-2',
          'w-1',
          'h',
          rulesVersion: 2,
          scannedAt: DateTime(2026, 2, 1),
        );
        final latest = await db.skillScanDao.latestScanForHash('w-1', 'h');
        expect(latest?.id, 's-2');
        expect(latest?.rulesVersion, 2);
      },
    );

    test('staleScans returns rows under the current rules version', () async {
      await insertScan('s-1', 'w-1', 'h', rulesVersion: 1);
      await insertScan('s-2', 'w-1', 'h2', rulesVersion: 2);
      final stale = await db.skillScanDao.staleScans('w-1', 3);
      expect(stale.map((s) => s.id).toSet(), {'s-1', 's-2'});
      // rulesVersion 3 is current — a row at 3 is not stale.
      await insertScan('s-3', 'w-1', 'h3', rulesVersion: 3);
      final staleAfter = await db.skillScanDao.staleScans('w-1', 3);
      expect(staleAfter.map((s) => s.id).toSet(), {'s-1', 's-2'});
    });

    test('staleScans is scoped by workspace', () async {
      await insertScan('s-1', 'w-1', 'h', rulesVersion: 1);
      await insertScan('s-2', 'w-2', 'h', rulesVersion: 1);
      final stale = await db.skillScanDao.staleScans('w-1', 3);
      expect(stale.map((s) => s.id), ['s-1']);
    });
  });

  group('SkillScanDao upsert', () {
    test('upsert replaces on conflict (same id)', () async {
      await insertScan('s-1', 'w-1', 'hash-a', verdict: 'pass');
      await insertScan('s-1', 'w-1', 'hash-a', verdict: 'quarantine');
      final scan = await db.skillScanDao.scanByHash('w-1', 'hash-a', 1);
      expect(scan?.verdict, 'quarantine');
    });
  });
}
