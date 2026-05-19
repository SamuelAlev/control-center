import 'dart:io';

import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/exceptions/skill_scan_blocked_exception.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_registry_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';
import 'package:cc_infra/src/skills/skill_bundle_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A scanner that returns a configured verdict for any bundle.
class _FakeScanner implements SkillScanPort {
  _FakeScanner({this.verdict = SkillScanVerdict.pass, this.throwObject})
    : manifest = const SkillCapabilityManifest();

  final SkillScanVerdict verdict;
  final SkillCapabilityManifest manifest;
  final Object? throwObject;
  final int rulesVersion = kSkillRulesVersion;
  int calls = 0;
  final List<SkillBundle> scanned = [];

  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    calls++;
    scanned.add(bundle);
    if (throwObject != null) {
      throw throwObject!;
    }
    return SkillScanResult(
      verdict: verdict,
      findings: const [],
      manifest: manifest,
      rulesVersion: rulesVersion,
    );
  }
}

class _FakeRegistry implements SkillRegistryPort {
  _FakeRegistry({this.resolved});
  ResolvedSkill? resolved;
  final List<(String, String?)> resolves = [];

  @override
  Future<List<SkillListing>> search(String query, {int limit = 25}) async {
    return const [];
  }

  @override
  Future<ResolvedSkill> resolve(String slug, {String? version}) async {
    resolves.add((slug, version));
    return resolved ??
        ResolvedSkill(
          slug: slug,
          files: const {'SKILL.md': '# skill'},
          version: '1.0.0',
          publisher: 'pub',
        );
  }
}

String _workspaceRoot(Directory temp) => temp.path;

WorkspaceFilesystemService _fs(Directory temp) =>
    WorkspaceFilesystemService(CcPaths(_workspaceRoot(temp)));

Future<Directory> _tempWorkspace() async {
  final temp = await Directory.systemTemp.createTemp('skill_bundle_test_');
  return temp;
}

SkillBundleService _service(
  Directory temp, {
  required Future<String> Function({
    required String owner,
    required String repo,
    required String path,
    required String ref,
  })
  fetch,
  SkillScanPort? scanner,
  Future<String?> Function({
    required String owner,
    required String repo,
    required String path,
    String? branch,
  })?
  latestCommit,
  Future<String?> Function({required String owner, required String repo})?
  defaultBranch,
  _FakeRegistry? registry,
}) => SkillBundleService(
  filesystem: _fs(temp),
  fetchGitHubFile: fetch,
  scanner: scanner,
  latestCommit: latestCommit,
  defaultBranch: defaultBranch,
  registry: registry,
);

String _sha(String s) => sha256.convert(s.codeUnits).toString();

void main() {
  late Directory temp;

  setUp(() async {
    temp = await _tempWorkspace();
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  group('SkillBundleService.computeSkillHash', () {
    test('null when skill is absent on disk', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      expect(await svc.computeSkillHash('ws', 'nope'), isNull);
    });

    test('falls back to single SKILL.md hash when no directory', () async {
      // Write a SKILL.md directly to the skill dir.
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'mine'),
      );
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'SKILL.md'));
      await file.writeAsString('# hello');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      // The directory DOES exist here, so we hit the listing path with one file.
      final hash = await svc.computeSkillHash('ws', 'mine');
      expect(hash, isNotNull);
      // Rolled-up hash of the single SKILL.md.
      expect(hash, _sha('SKILL.md:${_sha('# hello')}'));
    });

    test('empty directory returns null', () async {
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'empty'),
      );
      await dir.create(recursive: true);
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      expect(await svc.computeSkillHash('ws', 'empty'), isNull);
    });

    test('rolled-up hash excludes skills-lock.json', () async {
      final dir = Directory(p.join(_workspaceRoot(temp), 'ws', 'skills', 'sk'));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString('A');
      await File(p.join(dir.path, 'skills-lock.json')).writeAsString('LOCK');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final hash = await svc.computeSkillHash('ws', 'sk');
      expect(hash, isNotNull);
      // Only SKILL.md hashed.
      expect(hash, _sha('SKILL.md:${_sha('A')}'));
    });

    test('multi-file rollup sorts by relative path', () async {
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'multi'),
      );
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString('A');
      await Directory(p.join(dir.path, 'sub')).create(recursive: true);
      await File(p.join(dir.path, 'sub', 'helper.md')).writeAsString('B');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final hash = await svc.computeSkillHash('ws', 'multi');
      expect(hash, isNotNull);
      final rollup = 'SKILL.md:${_sha('A')}\nsub/helper.md:${_sha('B')}';
      expect(hash, _sha(rollup));
    });
  });

  group('SkillBundleService.readLock/writeLock', () {
    test('absent lock returns empty', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final lock = await svc.readLock('ws');
      expect(lock.skills, isEmpty);
    });

    test('malformed lock returns empty', () async {
      final dir = Directory(p.join(_workspaceRoot(temp), 'ws', 'skills'));
      await dir.create(recursive: true);
      await File(
        p.join(dir.path, 'skills-lock.json'),
      ).writeAsString('not json');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final lock = await svc.readLock('ws');
      expect(lock.skills, isEmpty);
    });

    test('non-map lock returns empty', () async {
      final dir = Directory(p.join(_workspaceRoot(temp), 'ws', 'skills'));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'skills-lock.json')).writeAsString('[1,2,3]');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final lock = await svc.readLock('ws');
      expect(lock.skills, isEmpty);
    });

    test('round-trips a written lock', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      const entry = SkillLockEntry(
        slug: 's',
        source: 'o/r',
        sourceType: SkillOrigin.github,
        skillPath: 'skills/s/SKILL.md',
        computedHash: 'abc',
        ref: 'deadbeef',
      );
      await svc.writeLock('ws', const SkillLock(skills: {'s': entry}));
      final read = await svc.readLock('ws');
      expect(read.skills['s']!.computedHash, 'abc');
      expect(read.skills['s']!.ref, 'deadbeef');
    });
  });

  group('SkillBundleService.installFromGitHub', () {
    test('writes content and records a pin', () async {
      final scanner = _FakeScanner();
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# fetched skill',
      );
      final entry = await svc.installFromGitHub(
        workspaceId: 'ws',
        slug: 'gh-skill',
        owner: 'o',
        repo: 'r',
        path: 'skills/gh-skill/SKILL.md',
        ref: 'deadbeef',
      );
      expect(entry.slug, 'gh-skill');
      expect(entry.source, 'o/r');
      expect(entry.sourceType, SkillOrigin.github);
      expect(entry.ref, 'deadbeef');
      expect(scanner.calls, 1);
      // File persisted on disk.
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'gh-skill', 'SKILL.md'),
      );
      expect(await file.readAsString(), '# fetched skill');
      // Lock recorded.
      final lock = await svc.readLock('ws');
      expect(lock.skills['gh-skill'], isNotNull);
    });

    test('quarantine verdict throws and writes nothing', () async {
      final scanner = _FakeScanner(verdict: SkillScanVerdict.quarantine);
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# bad',
      );
      await expectLater(
        svc.installFromGitHub(
          workspaceId: 'ws',
          slug: 'bad',
          owner: 'o',
          repo: 'r',
          path: 'x/SKILL.md',
          ref: 'deadbeef',
        ),
        throwsA(isA<SkillScanBlockedException>()),
      );
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'bad', 'SKILL.md'),
      );
      expect(file.existsSync(), isFalse);
      final lock = await svc.readLock('ws');
      expect(lock.skills, isEmpty);
    });

    test('quarantine with override installs', () async {
      final scanner = _FakeScanner(verdict: SkillScanVerdict.quarantine);
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# bad',
      );
      final entry = await svc.installFromGitHub(
        workspaceId: 'ws',
        slug: 'bad',
        owner: 'o',
        repo: 'r',
        path: 'x/SKILL.md',
        ref: 'deadbeef',
        allowQuarantineOverride: true,
      );
      expect(entry.scanVerdict, SkillScanVerdict.quarantine);
    });

    test('scanner error throws and writes nothing', () async {
      final scanner = _FakeScanner(throwObject: StateError('scanner down'));
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# bad',
      );
      await expectLater(
        svc.installFromGitHub(
          workspaceId: 'ws',
          slug: 'boom',
          owner: 'o',
          repo: 'r',
          path: 'x/SKILL.md',
          ref: 'deadbeef',
        ),
        throwsA(isA<SkillScanBlockedException>()),
      );
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'boom', 'SKILL.md'),
      );
      expect(file.existsSync(), isFalse);
    });

    test(
      'install without scanner writes content with null scan fields',
      () async {
        final svc = _service(
          temp,
          fetch:
              ({
                required owner,
                required repo,
                required path,
                required ref,
              }) async => '# plain',
        );
        final entry = await svc.installFromGitHub(
          workspaceId: 'ws',
          slug: 'plain',
          owner: 'o',
          repo: 'r',
          path: 'x/SKILL.md',
          ref: 'aaa',
        );
        expect(entry.scanVerdict, isNull);
        expect(entry.rulesVersion, isNull);
      },
    );
  });

  group('SkillBundleService.pinLocal', () {
    test('records an on-disk skill', () async {
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'local'),
      );
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString('# local');
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final entry = await svc.pinLocal(workspaceId: 'ws', slug: 'local');
      expect(entry.slug, 'local');
      expect(entry.sourceType, SkillOrigin.manual);
      expect(entry.computedHash, isNotEmpty);
    });

    test('missing on disk throws StateError', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.pinLocal(workspaceId: 'ws', slug: 'missing'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SkillBundleService.verify', () {
    test('empty lock is clean', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final result = await svc.verify('ws');
      expect(result.matched, isEmpty);
      expect(result.drifted, isEmpty);
      expect(result.missing, isEmpty);
      expect(result.isClean, isTrue);
    });

    test('matched, drifted, missing, and stale are detected', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );

      // matched: skill on disk with correct hash
      final mDir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'matched'),
      );
      await mDir.create(recursive: true);
      await File(p.join(mDir.path, 'SKILL.md')).writeAsString('A');
      final mHash = _sha('SKILL.md:${_sha('A')}');

      // drifted: on disk but different content
      final dDir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'drifted'),
      );
      await dDir.create(recursive: true);
      await File(p.join(dDir.path, 'SKILL.md')).writeAsString('B');

      // stale: low rulesVersion, content still matches
      final sDir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'stale'),
      );
      await sDir.create(recursive: true);
      await File(p.join(sDir.path, 'SKILL.md')).writeAsString('S');
      final sHash = _sha('SKILL.md:${_sha('S')}');

      final lock = SkillLock(
        skills: {
          'matched': SkillLockEntry(
            slug: 'matched',
            source: 'ws',
            sourceType: SkillOrigin.manual,
            skillPath: 'skills/matched/SKILL.md',
            computedHash: mHash,
          ),
          'drifted': const SkillLockEntry(
            slug: 'drifted',
            source: 'ws',
            sourceType: SkillOrigin.manual,
            skillPath: 'skills/drifted/SKILL.md',
            computedHash: 'wrong',
          ),
          'missing': const SkillLockEntry(
            slug: 'missing',
            source: 'ws',
            sourceType: SkillOrigin.manual,
            skillPath: 'skills/missing/SKILL.md',
            computedHash: 'whatever',
          ),
          'stale': SkillLockEntry(
            slug: 'stale',
            source: 'ws',
            sourceType: SkillOrigin.manual,
            skillPath: 'skills/stale/SKILL.md',
            computedHash: sHash,
            rulesVersion: 0,
          ),
        },
      );
      await svc.writeLock('ws', lock);
      final result = await svc.verify('ws');
      expect(result.matched, containsAll(['matched', 'stale']));
      expect(result.drifted, ['drifted']);
      expect(result.missing, ['missing']);
      expect(result.stale, ['stale']);
      expect(result.isClean, isFalse);
    });
  });

  group('SkillBundleService.checkUpdates', () {
    test('no latestCommit resolver returns empty', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      expect(await svc.checkUpdates('ws'), isEmpty);
    });

    test('returns candidates whose latestRef differs from current', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
        latestCommit:
            ({required owner, required repo, required path, branch}) async =>
                'newsha',
        defaultBranch: ({required owner, required repo}) async => 'main',
      );
      // Pin a github skill.
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'g': SkillLockEntry(
              slug: 'g',
              source: 'o/r',
              sourceType: SkillOrigin.github,
              skillPath: 'p/SKILL.md',
              computedHash: 'h',
              ref: 'oldsha',
            ),
          },
        ),
      );
      final updates = await svc.checkUpdates('ws');
      expect(updates, hasLength(1));
      expect(updates.first.slug, 'g');
      expect(updates.first.currentRef, 'oldsha');
      expect(updates.first.latestRef, 'newsha');
    });

    test('skips non-github entries', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
        latestCommit:
            ({required owner, required repo, required path, branch}) async =>
                'x',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'm': SkillLockEntry(
              slug: 'm',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/m/SKILL.md',
              computedHash: 'h',
            ),
          },
        ),
      );
      expect(await svc.checkUpdates('ws'), isEmpty);
    });

    test('skips entries with malformed source', () async {
      var calls = 0;
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
        latestCommit:
            ({required owner, required repo, required path, branch}) async {
              calls++;
              return 'new';
            },
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'bad': SkillLockEntry(
              slug: 'bad',
              source: 'no-slash',
              sourceType: SkillOrigin.github,
              skillPath: 'p',
              computedHash: 'h',
              ref: 'old',
            ),
          },
        ),
      );
      expect(await svc.checkUpdates('ws'), isEmpty);
      expect(calls, 0);
    });

    test('skips entries where latest is null or equal', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
        latestCommit:
            ({required owner, required repo, required path, branch}) async =>
                'same',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'g': SkillLockEntry(
              slug: 'g',
              source: 'o/r',
              sourceType: SkillOrigin.github,
              skillPath: 'p/SKILL.md',
              computedHash: 'h',
              ref: 'same',
            ),
          },
        ),
      );
      expect(await svc.checkUpdates('ws'), isEmpty);
    });

    test('latestCommit throwing is swallowed per-skill', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
        latestCommit:
            ({required owner, required repo, required path, branch}) async =>
                throw StateError('net'),
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'g': SkillLockEntry(
              slug: 'g',
              source: 'o/r',
              sourceType: SkillOrigin.github,
              skillPath: 'p/SKILL.md',
              computedHash: 'h',
              ref: 'old',
            ),
          },
        ),
      );
      expect(await svc.checkUpdates('ws'), isEmpty);
    });
  });

  group('SkillBundleService.applyUpdate', () {
    test('throws when skill not installed', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.applyUpdate(workspaceId: 'ws', slug: 'nope', ref: 'r'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when skill is not github', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'm': SkillLockEntry(
              slug: 'm',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/m/SKILL.md',
              computedHash: 'h',
            ),
          },
        ),
      );
      await expectLater(
        svc.applyUpdate(workspaceId: 'ws', slug: 'm', ref: 'r'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when source is unparseable', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'g': SkillLockEntry(
              slug: 'g',
              source: 'bad',
              sourceType: SkillOrigin.github,
              skillPath: 'p',
              computedHash: 'h',
              ref: 'old',
            ),
          },
        ),
      );
      await expectLater(
        svc.applyUpdate(workspaceId: 'ws', slug: 'g', ref: 'r'),
        throwsA(isA<StateError>()),
      );
    });

    test('re-fetches and re-pins, recording previousHash', () async {
      final scanner = _FakeScanner();
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# updated $ref',
      );
      // Install first.
      final installed = await svc.installFromGitHub(
        workspaceId: 'ws',
        slug: 'g',
        owner: 'o',
        repo: 'r',
        path: 'skills/g/SKILL.md',
        ref: 'aaa',
      );
      // Apply an update.
      final updated = await svc.applyUpdate(
        workspaceId: 'ws',
        slug: 'g',
        ref: 'bbb',
      );
      expect(updated.ref, 'bbb');
      expect(updated.previousHash, installed.computedHash);
      expect(updated.computedHash, isNot(installed.computedHash));
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'g', 'SKILL.md'),
      );
      expect(await file.readAsString(), '# updated bbb');
    });
  });

  group('SkillBundleService.installFromRegistry', () {
    test('throws when no registry is wired', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.installFromRegistry(workspaceId: 'ws', slug: 's'),
        throwsA(isA<StateError>()),
      );
    });

    test('writes content and records registry origin', () async {
      final scanner = _FakeScanner();
      final registry = _FakeRegistry(
        resolved: const ResolvedSkill(
          slug: 'rs',
          files: {'SKILL.md': '# from registry'},
          version: '2.0.0',
          publisher: 'pub-co',
          verifiedPublisher: true,
        ),
      );
      final svc = _service(
        temp,
        scanner: scanner,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final entry = await svc.installFromRegistry(
        workspaceId: 'ws',
        slug: 'rs',
      );
      expect(entry.source, 'pub-co');
      expect(entry.sourceType, SkillOrigin.registry);
      expect(entry.trustTier, SkillTrustTier.verified);
      expect(entry.ref, '2.0.0');
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'rs', 'SKILL.md'),
      );
      expect(await file.readAsString(), '# from registry');
    });

    test('community tier when not verified', () async {
      final scanner = _FakeScanner();
      final registry = _FakeRegistry(
        resolved: const ResolvedSkill(
          slug: 'cs',
          files: {'SKILL.md': '# c'},
          version: '',
          publisher: '',
        ),
      );
      final svc = _service(
        temp,
        scanner: scanner,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final entry = await svc.installFromRegistry(
        workspaceId: 'ws',
        slug: 'cs',
      );
      expect(entry.trustTier, SkillTrustTier.community);
      expect(entry.source, 'skills.sh');
      expect(entry.ref, isNull);
    });

    test('scanner quarantine blocks install', () async {
      final scanner = _FakeScanner(verdict: SkillScanVerdict.quarantine);
      final registry = _FakeRegistry(
        resolved: const ResolvedSkill(slug: 'qs', files: {'SKILL.md': '# bad'}),
      );
      final svc = _service(
        temp,
        scanner: scanner,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.installFromRegistry(workspaceId: 'ws', slug: 'qs'),
        throwsA(isA<SkillScanBlockedException>()),
      );
    });
  });

  group('SkillBundleService.previewInstall', () {
    test('throws when no registry', () async {
      final scanner = _FakeScanner();
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.previewInstall(workspaceId: 'ws', slug: 'x'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when no scanner', () async {
      final registry = _FakeRegistry();
      final svc = _service(
        temp,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await expectLater(
        svc.previewInstall(workspaceId: 'ws', slug: 'x'),
        throwsA(isA<StateError>()),
      );
    });

    test('returns scan result without writing', () async {
      final scanner = _FakeScanner(verdict: SkillScanVerdict.warn);
      final registry = _FakeRegistry(
        resolved: const ResolvedSkill(
          slug: 'ps',
          files: {'SKILL.md': '# preview'},
          verifiedPublisher: true,
        ),
      );
      final svc = _service(
        temp,
        scanner: scanner,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final result = await svc.previewInstall(workspaceId: 'ws', slug: 'ps');
      expect(result.verdict, SkillScanVerdict.warn);
      // Nothing written.
      final file = File(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'ps', 'SKILL.md'),
      );
      expect(file.existsSync(), isFalse);
    });

    test('returns a quarantine verdict without throwing', () async {
      final scanner = _FakeScanner(verdict: SkillScanVerdict.quarantine);
      final registry = _FakeRegistry();
      final svc = _service(
        temp,
        scanner: scanner,
        registry: registry,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      final result = await svc.previewInstall(workspaceId: 'ws', slug: 'ps');
      expect(result.verdict, SkillScanVerdict.quarantine);
    });
  });

  group('SkillBundleService.reVerify', () {
    test('no scanner returns empty', () async {
      final svc = _service(
        temp,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      expect(await svc.reVerify('ws'), isEmpty);
    });

    test('skips current-version entries', () async {
      final scanner = _FakeScanner();
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'cur'),
      );
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString('# c');
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'cur': SkillLockEntry(
              slug: 'cur',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/cur/SKILL.md',
              computedHash: 'h',
              rulesVersion: kSkillRulesVersion,
            ),
          },
        ),
      );
      expect(await svc.reVerify('ws'), isEmpty);
    });

    test('re-scans stale entries and updates lock', () async {
      final scanner = _FakeScanner();
      final dir = Directory(
        p.join(_workspaceRoot(temp), 'ws', 'skills', 'old'),
      );
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString('# old');
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'old': SkillLockEntry(
              slug: 'old',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/old/SKILL.md',
              computedHash: 'h',
              rulesVersion: 0,
            ),
          },
        ),
      );
      final reScanned = await svc.reVerify('ws');
      expect(reScanned, ['old']);
      final lock = await svc.readLock('ws');
      expect(lock.skills['old']!.rulesVersion, kSkillRulesVersion);
    });

    test('skips stale entries missing on disk', () async {
      final scanner = _FakeScanner();
      final svc = _service(
        temp,
        scanner: scanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'missing': SkillLockEntry(
              slug: 'missing',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/missing/SKILL.md',
              computedHash: 'h',
              rulesVersion: 0,
            ),
          },
        ),
      );
      expect(await svc.reVerify('ws'), isEmpty);
    });

    test('scanner error on one skill does not abort others', () async {
      var throwOnce = true;
      final scanner = _FakeScanner();
      // Custom scanner that throws the first time, succeeds after.
      final failingScanner = _ThrowOnceScanner(
        fail: () {
          if (throwOnce) {
            throwOnce = false;
            throw StateError('boom');
          }
        },
        inner: scanner,
      );
      final dir1 = Directory(p.join(_workspaceRoot(temp), 'ws', 'skills', 'a'));
      final dir2 = Directory(p.join(_workspaceRoot(temp), 'ws', 'skills', 'b'));
      await dir1.create(recursive: true);
      await dir2.create(recursive: true);
      await File(p.join(dir1.path, 'SKILL.md')).writeAsString('A');
      await File(p.join(dir2.path, 'SKILL.md')).writeAsString('B');
      final svc = _service(
        temp,
        scanner: failingScanner,
        fetch:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '',
      );
      await svc.writeLock(
        'ws',
        const SkillLock(
          skills: {
            'a': SkillLockEntry(
              slug: 'a',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/a/SKILL.md',
              computedHash: 'h',
              rulesVersion: 0,
            ),
            'b': SkillLockEntry(
              slug: 'b',
              source: 'ws',
              sourceType: SkillOrigin.manual,
              skillPath: 'skills/b/SKILL.md',
              computedHash: 'h',
              rulesVersion: 0,
            ),
          },
        ),
      );
      final reScanned = await svc.reVerify('ws');
      // At least one succeeded despite the other throwing.
      expect(reScanned, isNotEmpty);
      expect(reScanned.length, lessThanOrEqualTo(2));
    });
  });
}

class _ThrowOnceScanner implements SkillScanPort {
  _ThrowOnceScanner({required this.fail, required this.inner});
  final void Function() fail;
  final SkillScanPort inner;

  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    fail();
    return inner.scan(
      bundle,
      workspaceId: workspaceId,
      trustTier: trustTier,
      runLlmReview: runLlmReview,
    );
  }
}
