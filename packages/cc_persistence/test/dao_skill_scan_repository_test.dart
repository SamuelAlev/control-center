import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoSkillScanRepository] end-to-end against an in-memory database.
/// Covers upsert / byHash / latestForHash / staleScans / watchScans, asserting
/// the JSON serialization round-trips findings + manifest, and workspace
/// isolation holds.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoSkillScanRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoSkillScanRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  SkillScanResult result({
    SkillScanVerdict verdict = SkillScanVerdict.pass,
    List<SkillScanFinding> findings = const [],
    SkillCapabilityManifest manifest = const SkillCapabilityManifest(),
    int rulesVersion = 1,
    bool llmReviewed = false,
  }) => SkillScanResult(
    verdict: verdict,
    findings: findings,
    manifest: manifest,
    rulesVersion: rulesVersion,
    llmReviewed: llmReviewed,
  );

  group('DaoSkillScanRepository upsert + byHash', () {
    test('byHash returns null when absent', () async {
      expect(await repo.byHash('w-1', 'hash-a', 1), isNull);
    });

    test('upsert then byHash round-trips the verdict + manifest', () async {
      await repo.upsert(
        'w-1',
        'hash-a',
        result(
          verdict: SkillScanVerdict.warn,
          manifest: const SkillCapabilityManifest(
            needsBash: true,
            networkEgress: true,
          ),
          rulesVersion: 1,
        ),
      );
      final loaded = await repo.byHash('w-1', 'hash-a', 1);
      expect(loaded, isNotNull);
      expect(loaded!.verdict, SkillScanVerdict.warn);
      expect(loaded.manifest.needsBash, isTrue);
      expect(loaded.manifest.networkEgress, isTrue);
      expect(loaded.rulesVersion, 1);
    });

    test('findings round-trip through JSON', () async {
      await repo.upsert(
        'w-1',
        'hash-b',
        result(
          verdict: SkillScanVerdict.quarantine,
          findings: [
            const SkillScanFinding(
              ruleId: 'curl_pipe_bash',
              verdict: SkillScanVerdict.quarantine,
              message: 'shell injection',
              file: 'scripts/run.sh',
              line: 4,
              snippet: 'curl ... | bash',
            ),
          ],
          rulesVersion: 2,
          llmReviewed: true,
        ),
      );
      final loaded = await repo.byHash('w-1', 'hash-b', 2);
      expect(loaded, isNotNull);
      expect(loaded!.verdict, SkillScanVerdict.quarantine);
      expect(loaded.findings, hasLength(1));
      expect(loaded.findings.first.ruleId, 'curl_pipe_bash');
      expect(loaded.findings.first.file, 'scripts/run.sh');
      expect(loaded.llmReviewed, isTrue);
    });

    test('byHash is workspace-scoped', () async {
      await repo.upsert('w-1', 'hash-a', result());
      expect(await repo.byHash('w-2', 'hash-a', 1), isNull);
    });

    test('byHash matches the rules version', () async {
      await repo.upsert('w-1', 'hash-a', result(rulesVersion: 1));
      expect(await repo.byHash('w-1', 'hash-a', 2), isNull);
    });
  });

  group('DaoSkillScanRepository latestForHash + staleness', () {
    test('latestForHash returns a row regardless of rules version', () async {
      await repo.upsert('w-1', 'hash-a', result(rulesVersion: 1));
      // A second scan of the same hash under a newer rules version produces a
      // distinct row (the deterministic id embeds rulesVersion).
      await repo.upsert('w-1', 'hash-a', result(rulesVersion: 2));
      final latest = await repo.latestForHash('w-1', 'hash-a');
      expect(latest, isNotNull);
      expect(latest!.rulesVersion, anyOf(1, 2));
      // The exact-hash lookup still resolves each version individually.
      expect(await repo.byHash('w-1', 'hash-a', 1), isNotNull);
      expect(await repo.byHash('w-1', 'hash-a', 2), isNotNull);
    });

    test('latestForHash is workspace-scoped', () async {
      await repo.upsert('w-1', 'hash-a', result());
      expect(await repo.latestForHash('w-2', 'hash-a'), isNull);
    });

    test('staleScans lists hashes under the current rules version', () async {
      await repo.upsert('w-1', 'hash-a', result(rulesVersion: 1));
      await repo.upsert('w-1', 'hash-b', result(rulesVersion: 2));
      final stale = await repo.staleScans('w-1', 3);
      expect(stale.map((s) => s.contentHash).toSet(), {'hash-a', 'hash-b'});
    });

    test('staleScans is workspace-scoped', () async {
      await repo.upsert('w-1', 'hash-a', result(rulesVersion: 1));
      await repo.upsert('w-2', 'hash-a', result(rulesVersion: 1));
      final stale = await repo.staleScans('w-1', 3);
      expect(stale.map((s) => s.contentHash), ['hash-a']);
    });
  });

  group('DaoSkillScanRepository watchScans', () {
    test('emits only the workspace rows', () async {
      await repo.upsert('w-1', 'hash-a', result());
      await repo.upsert('w-2', 'hash-b', result());
      final scans = await repo.watchScans('w-1').first;
      expect(scans, hasLength(1));
      // The reconstructed manifest fields survive the round-trip.
      expect(scans.first.manifest.needsBash, isFalse);
      expect(scans.first.verdict, SkillScanVerdict.pass);
    });
  });
}
