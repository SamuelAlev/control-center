import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/exceptions/skill_scan_blocked_exception.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/skills/skill_bundle_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A scanner that always passes, stamping a fixed [rulesVersion] — lets a test
/// install a skill as "verdict-stale" (older rules) to exercise re-verify.
class _FakeScanPort implements SkillScanPort {
  _FakeScanPort({this.rulesVersion = 1});
  int rulesVersion;
  int scans = 0;
  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    scans++;
    return SkillScanResult(
      verdict: SkillScanVerdict.pass,
      findings: const [],
      manifest: const SkillCapabilityManifest(),
      rulesVersion: rulesVersion,
    );
  }
}

/// In-memory policy store returning a fixed rule list.
class _FakePolicyRepo implements ActionPolicyRepository {
  _FakePolicyRepo(this._rules);
  final List<ActionPolicyRule> _rules;
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => _rules;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [ConfirmationPort] that always answers [answer], counting prompts.
class _RecordingPort implements ConfirmationPort {
  _RecordingPort({required this.answer});
  final bool answer;
  int prompts = 0;
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    prompts++;
    return answer;
  }
}

/// Minimal [WorkspaceFilesystemPort] over a real temp directory — enough for
/// the skill-bundle service (skillsDir / skillDir / read+write SKILL.md).
class _TmpFs implements WorkspaceFilesystemPort {
  _TmpFs(this.root);
  final String root;

  @override
  Future<String> skillsDir(String workspaceId) async =>
      p.join(root, workspaceId, 'skills');

  @override
  Future<String> skillDir(String workspaceId, String slug) async =>
      p.join(root, workspaceId, 'skills', slug);

  @override
  Future<String> skillFilePath(String workspaceId, String slug) async =>
      p.join(root, workspaceId, 'skills', slug, 'SKILL.md');

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String slug,
    String content,
  ) async {
    final file = File(await skillFilePath(workspaceId, slug));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<String?> readSkillFile(String workspaceId, String slug) async {
    final file = File(await skillFilePath(workspaceId, slug));
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SkillLock JSON round-trip', () {
    test('serializes and parses entries with a pinned ref', () {
      final lock = SkillLock.empty.withEntry(
        const SkillLockEntry(
          slug: 'code-review',
          source: 'octo/skills',
          sourceType: SkillOrigin.github,
          skillPath: 'skills/code-review/SKILL.md',
          computedHash: 'abc123',
          ref: 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
        ),
      );
      final parsed = SkillLock.fromJson(lock.toJson());
      expect(parsed.skills.containsKey('code-review'), isTrue);
      final entry = parsed.skills['code-review']!;
      expect(entry.sourceType, SkillOrigin.github);
      expect(entry.ref, 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef');
      expect(entry.isPinnedToCommit, isTrue);
    });

    test('isPinnedToCommit is false for a branch ref', () {
      const entry = SkillLockEntry(
        slug: 's',
        source: 'o/r',
        sourceType: SkillOrigin.github,
        skillPath: 'p',
        computedHash: 'h',
        ref: 'main',
      );
      expect(entry.isPinnedToCommit, isFalse);
    });
  });

  group('SkillBundleService', () {
    late Directory tmp;
    late SkillBundleService service;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('skills_test');
      service = SkillBundleService(
        filesystem: _TmpFs(tmp.path),
        fetchGitHubFile:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async => '# Skill\nFetched from $owner/$repo@$ref',
      );
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test(
      'installs a GitHub skill pinned to a commit SHA and records the pin',
      () async {
        const sha = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
        final entry = await service.installFromGitHub(
          workspaceId: 'ws1',
          slug: 'code-review',
          owner: 'octo',
          repo: 'skills',
          path: 'skills/code-review/SKILL.md',
          ref: sha,
        );
        expect(entry.sourceType, SkillOrigin.github);
        expect(entry.ref, sha);
        expect(entry.isPinnedToCommit, isTrue);
        expect(entry.computedHash, isNotEmpty);

        // skills-lock.json records the pin.
        final lock = await service.readLock('ws1');
        expect(lock.skills['code-review']!.ref, sha);
        expect(lock.skills['code-review']!.computedHash, entry.computedHash);

        // The SKILL.md was written on disk.
        final lockFile = File(
          p.join(tmp.path, 'ws1', 'skills', 'skills-lock.json'),
        );
        expect(lockFile.existsSync(), isTrue);
      },
    );

    test(
      'verify reports matched, then drift after the content changes',
      () async {
        await service.installFromGitHub(
          workspaceId: 'ws1',
          slug: 'code-review',
          owner: 'octo',
          repo: 'skills',
          path: 'skills/code-review/SKILL.md',
          ref: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        );
        final clean = await service.verify('ws1');
        expect(clean.isClean, isTrue);
        expect(clean.matched, ['code-review']);

        // Mutate the installed file → drift.
        File(
          p.join(tmp.path, 'ws1', 'skills', 'code-review', 'SKILL.md'),
        ).writeAsStringSync('# tampered');
        final dirty = await service.verify('ws1');
        expect(dirty.isClean, isFalse);
        expect(dirty.drifted, ['code-review']);
      },
    );

    test('content hash is stable for identical content', () async {
      final fs = _TmpFs(tmp.path);
      await fs.writeSkillFile('ws1', 's', '# same');
      final h1 = await service.computeSkillHash('ws1', 's');
      final h2 = await service.computeSkillHash('ws1', 's');
      expect(h1, isNotNull);
      expect(h1, h2);
    });
  });

  group(
    'SkillBundleService — capability→policy gate at install (PRD 23/24)',
    () {
      late Directory tmp;

      setUp(() => tmp = Directory.systemTemp.createTempSync('skills_pol_test'));
      tearDown(() => tmp.deleteSync(recursive: true));

      // A skill whose SKILL.md declares a network-egress capability (curl) → the
      // extractor maps it to ActionClass.networkEgress.
      SkillBundleService svc({
        required List<ActionPolicyRule> rules,
        ConfirmationPort? port,
      }) => SkillBundleService(
        filesystem: _TmpFs(tmp.path),
        actionGuard: ActionGuardService(
          repository: _FakePolicyRepo(rules),
          confirmationPort: port,
        ),
        fetchGitHubFile:
            ({
              required owner,
              required repo,
              required path,
              required ref,
            }) async =>
                '# Skill\n\n```bash\ncurl https://api.example.com\n```\n',
      );

      ActionPolicyRule wsRule(ActionClass cls, ActionDecision decision) =>
          ActionPolicyRule(
            id: 'ws::${cls.wire}',
            workspaceId: 'ws1',
            scopeType: ActionScopeType.workspace,
            scopeId: '',
            actionClass: cls,
            decision: decision,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          );

      Future<SkillLockEntry> install(SkillBundleService s) =>
          s.installFromGitHub(
            workspaceId: 'ws1',
            slug: 'net-skill',
            owner: 'octo',
            repo: 'skills',
            path: 'skills/net-skill/SKILL.md',
            ref: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
          );

      test(
        'a policy deny on a required capability blocks the install (no write)',
        () async {
          final s = svc(
            rules: [wsRule(ActionClass.networkEgress, ActionDecision.deny)],
          );
          await expectLater(
            install(s),
            throwsA(isA<SkillScanBlockedException>()),
          );
          // Nothing was written on disk.
          expect(
            File(
              p.join(tmp.path, 'ws1', 'skills', 'net-skill', 'SKILL.md'),
            ).existsSync(),
            isFalse,
          );
          expect((await s.readLock('ws1')).skills, isEmpty);
        },
      );

      test('a policy allow lets the install proceed', () async {
        final s = svc(
          rules: [wsRule(ActionClass.networkEgress, ActionDecision.allow)],
        );
        final entry = await install(s);
        expect(entry.slug, 'net-skill');
      });

      test('a prompt decision approved by the operator installs', () async {
        final port = _RecordingPort(answer: true);
        final s = svc(
          rules: [wsRule(ActionClass.networkEgress, ActionDecision.prompt)],
          port: port,
        );
        final entry = await install(s);
        expect(entry.slug, 'net-skill');
        expect(port.prompts, 1);
      });

      test(
        'a prompt decision denied by the operator blocks the install',
        () async {
          final s = svc(
            rules: [wsRule(ActionClass.networkEgress, ActionDecision.prompt)],
            port: _RecordingPort(answer: false),
          );
          await expectLater(
            install(s),
            throwsA(isA<SkillScanBlockedException>()),
          );
        },
      );

      test('prompt + no approver fails closed (blocked)', () async {
        final s = svc(
          rules: [wsRule(ActionClass.networkEgress, ActionDecision.prompt)],
        );
        await expectLater(
          install(s),
          throwsA(isA<SkillScanBlockedException>()),
        );
      });
    },
  );

  group('SkillBundleService — update / re-scan flow (PRD 23 §4/§6)', () {
    late Directory tmp;
    const sha1 = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
    const sha2 = 'ffffffffffffffffffffffffffffffffffffffff';

    setUp(() => tmp = Directory.systemTemp.createTempSync('skills_upd_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    SkillBundleService svc({String? latestSha, int rulesVersion = 1}) =>
        SkillBundleService(
          filesystem: _TmpFs(tmp.path),
          scanner: _FakeScanPort(rulesVersion: rulesVersion),
          fetchGitHubFile:
              ({
                required owner,
                required repo,
                required path,
                required ref,
              }) async => '# Skill @ $ref',
          latestCommit:
              ({required owner, required repo, required path, branch}) async =>
                  latestSha,
          defaultBranch: ({required owner, required repo}) async => 'main',
        );

    Future<void> install(SkillBundleService s, {String ref = sha1}) =>
        s.installFromGitHub(
          workspaceId: 'ws1',
          slug: 'code-review',
          owner: 'octo',
          repo: 'skills',
          path: 'skills/code-review/SKILL.md',
          ref: ref,
        );

    test('checkUpdates reports a skill whose upstream moved', () async {
      final s = svc(latestSha: sha2);
      await install(s);
      final updates = await s.checkUpdates('ws1');
      expect(updates, hasLength(1));
      expect(updates.single.slug, 'code-review');
      expect(updates.single.currentRef, sha1);
      expect(updates.single.latestRef, sha2);
      expect(updates.single.hasUpdate, isTrue);
    });

    test(
      'checkUpdates reports nothing when upstream matches the pin',
      () async {
        final s = svc(latestSha: sha1);
        await install(s);
        expect(await s.checkUpdates('ws1'), isEmpty);
      },
    );

    test(
      'applyUpdate re-pins and records the previous hash for rollback',
      () async {
        final s = svc(latestSha: sha2);
        await install(s);
        final before = (await s.readLock('ws1')).skills['code-review']!;
        final entry = await s.applyUpdate(
          workspaceId: 'ws1',
          slug: 'code-review',
          ref: sha2,
        );
        expect(entry.ref, sha2);
        expect(entry.previousHash, before.computedHash);
        expect(entry.computedHash, isNot(before.computedHash));
        // The lock now points at the new version, keeping the rollback hash.
        final after = (await s.readLock('ws1')).skills['code-review']!;
        expect(after.ref, sha2);
        expect(after.previousHash, before.computedHash);
      },
    );

    test(
      'a rules-version bump surfaces the skill as stale; reVerify clears it',
      () async {
        // Install under an OLD rules version (0) → verify() flags it stale.
        final s = svc(rulesVersion: 0);
        await install(s);
        final stale = await s.verify('ws1');
        expect(stale.stale, ['code-review']);

        // A service whose scanner reports the CURRENT rules version (1) re-scans
        // the on-disk bytes and clears the staleness.
        final current = SkillBundleService(
          filesystem: _TmpFs(tmp.path),
          scanner: _FakeScanPort(),
          fetchGitHubFile:
              ({
                required owner,
                required repo,
                required path,
                required ref,
              }) async => '# unused',
        );
        final reScanned = await current.reVerify('ws1');
        expect(reScanned, ['code-review']);
        expect((await current.verify('ws1')).stale, isEmpty);
      },
    );
  });
}
