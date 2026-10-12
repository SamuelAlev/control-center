import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_infra/src/evaluation/skill_evaluation_snapshot_store.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Filesystem implements WorkspaceFilesystemPort {
  _Filesystem(this.root);
  final String root;

  @override
  Future<String> skillsDir(String workspaceId) async => p.join(root, 'skills');

  @override
  Future<String> skillDir(String workspaceId, String slug) async =>
      p.join(root, 'skills', slug);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bundles implements SkillBundlePort {
  @override
  Future<SkillLock> readLock(String workspaceId) async => SkillLock.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Scanner implements SkillScanPort {
  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async => const SkillScanResult(
    verdict: SkillScanVerdict.pass,
    findings: [],
    manifest: SkillCapabilityManifest(),
    rulesVersion: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repos implements RepoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _grow(File file, int length) async {
  final handle = await file.open(mode: FileMode.write);
  try {
    await handle.truncate(length);
  } finally {
    await handle.close();
  }
}

void main() {
  test(
    'capture bounds package bytes and concurrent history remains readable',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'cc-snapshot-boundary-',
      );
      try {
        final directory = await Directory(
          p.join(root.path, 'skills', 'demo'),
        ).create(recursive: true);
        final source = File(p.join(directory.path, 'SKILL.md'));
        await source.writeAsString('---\nname: demo\n---\n');
        final store = SkillEvaluationSnapshotStore(
          filesystem: _Filesystem(root.path),
          repositories: _Repos(),
          workspaces: _Workspaces(),
          bundles: _Bundles(),
          scanner: _Scanner(),
          dataDir: root.path,
        );
        final captures = await Future.wait(
          List.generate(
            4,
            (_) => store.capture(workspaceId: 'workspace', slug: 'demo'),
          ),
        );
        final hash = captures.first.package.packageHash;
        expect(
          captures.map((snapshot) => snapshot.package.packageHash).toSet(),
          {hash},
        );
        final previous = await store.previous(
          workspaceId: 'workspace',
          skillKey: 'workspace:demo',
          hash: hash,
        );
        expect(
          utf8.decode(previous!.package.files['SKILL.md']!),
          '---\nname: demo\n---\n',
        );
        final history = Directory(
          p.join(
            root.path,
            'skill-evaluations',
            sha256.convert(utf8.encode('workspace')).toString(),
            'snapshots',
            sha256.convert(utf8.encode('workspace:demo')).toString(),
          ),
        );
        expect(
          await history
              .list()
              .where((entry) => entry.path.endsWith('.tmp'))
              .toList(),
          isEmpty,
        );

        await _grow(source, SkillEvaluationSnapshotStore.maxPackageBytes + 1);
        await expectLater(
          store.capture(workspaceId: 'workspace', slug: 'demo'),
          throwsStateError,
        );

        // Oversized stored revisions are rejected before decoding. History
        // cannot be redirected through a symlink to an outside file either.
        final saved = File(p.join(history.path, '$hash.json'));
        await _grow(
          saved,
          SkillEvaluationSnapshotStore.maxPackageBytes * 2 + 1,
        );
        await expectLater(
          store.previous(
            workspaceId: 'workspace',
            skillKey: 'workspace:demo',
            hash: hash,
          ),
          throwsStateError,
        );
        await saved.delete();
        await Link(saved.path).create(source.path);
        await expectLater(
          store.previous(
            workspaceId: 'workspace',
            skillKey: 'workspace:demo',
            hash: hash,
          ),
          throwsStateError,
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
