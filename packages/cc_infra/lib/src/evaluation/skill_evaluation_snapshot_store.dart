import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/controlled_skill_evaluation.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifact_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A captured revision, admitted independently from its evaluation outcome.
class AdmittedSkillEvaluationSnapshot {
  /// Associates exact package bytes with their scoped identity and scan result.
  const AdmittedSkillEvaluationSnapshot({
    required this.skillKey,
    required this.package,
    required this.scan,
    this.skillPath,
  });

  /// Workspace/repository catalog identity, independent of a package revision.
  final String skillKey;

  /// Immutable bytes and content digest admitted for execution.
  final SkillPackageSnapshot package;

  /// Security verdict for these exact bytes, not a runtime utility score.
  final SkillScanResult scan;

  /// Repository-relative `SKILL.md` path, absent for workspace installations.
  final String? skillPath;

  /// Public provenance metadata; excludes source bytes and host paths.
  Map<String, dynamic> get identity => {
    'skillKey': skillKey,
    'slug': package.slug,
    'packageHash': package.packageHash,
    'origin': package.origin,
    'repoId': package.repoId,
    'sourceCommit': package.sourceCommit,
    'skillPath': skillPath,
    'scanVerdict': scan.verdict.wire,
    'scanRulesVersion': scan.rulesVersion,
    'scanLlmReviewed': scan.llmReviewed,
    'fileCount': package.files.length,
  };
}

/// Server-only content-addressed history. Never edits the live installation.
///
/// Callers must authorize the workspace and repository before invoking this
/// adapter. Repository membership is also checked here before reading a path.
class SkillEvaluationSnapshotStore {
  /// Binds authorized storage and scanning ports to the server data directory.
  SkillEvaluationSnapshotStore({
    required this.filesystem,
    required this.repositories,
    required this.workspaces,
    required this.bundles,
    required this.scanner,
    required this.dataDir,
  });

  /// Resolves workspace-owned skill installation paths.
  final WorkspaceFilesystemPort filesystem;

  /// Resolves linked repositories before reading repository skill packages.
  final RepoRepository repositories;

  /// Validates workspace-to-repository linkage.
  final WorkspaceRepository workspaces;

  /// Reads installed lock metadata and its existing quarantine decision.
  final SkillBundlePort bundles;

  /// Re-scans the frozen bytes before publishing or reusing a revision.
  final SkillScanPort scanner;

  /// Server-private root for content-addressed package history.
  final String dataDir;

  /// Maximum aggregate source bytes admitted for one skill package.
  static const maxPackageBytes = 16 * 1024 * 1024;

  /// Maximum number of regular resource files in one package.
  static const maxFiles = 1024;
  static final _slug = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$');
  static final _hash = RegExp(r'^[a-f0-9]{64}$');

  /// Rejects unsafe installation names before any filesystem lookup.
  static void validateSlug(String value) {
    if (!_slug.hasMatch(value) || value == '.' || value == '..') {
      throw ArgumentError.value(value, 'skill_slug', 'Invalid skill slug');
    }
  }

  /// Captures at most [maxFiles] regular files and [maxPackageBytes] bytes,
  /// scans the frozen bytes, then atomically publishes immutable history.
  Future<AdmittedSkillEvaluationSnapshot> capture({
    required String workspaceId,
    required String slug,
    String? repoId,
    String? skillPath,
  }) async {
    validateSlug(slug);
    String directory;
    String key;
    String origin;
    String? sourceCommit;
    var trust = SkillTrustTier.workspace;
    SkillScanVerdict? pinnedVerdict;
    String? pinnedHash;
    if (repoId == null) {
      if (skillPath != null) {
        throw ArgumentError('skill_path requires repo_id');
      }
      final root = await Directory(
        await filesystem.skillsDir(workspaceId),
      ).resolveSymbolicLinks();
      directory = await Directory(
        await filesystem.skillDir(workspaceId, slug),
      ).resolveSymbolicLinks();
      if (!p.isWithin(root, directory)) {
        throw StateError('Skill directory is outside its workspace');
      }
      key = 'workspace:$slug';
      final pin = (await bundles.readLock(workspaceId)).skills[slug];
      origin = pin?.sourceType.wire ?? 'workspace';
      sourceCommit = pin?.ref;
      trust = pin?.trustTier ?? trust;
      pinnedVerdict = pin?.scanVerdict;
      pinnedHash = pin?.computedHash;
    } else {
      if (!await workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
        throw StateError('Repository is not linked to this workspace');
      }
      final repo = await repositories.getById(workspaceId, repoId);
      if (repo == null) {
        throw StateError('Unknown workspace repository');
      }
      if (skillPath == null ||
          !_safeRelative(skillPath) ||
          !skillPath.endsWith('/SKILL.md')) {
        throw ArgumentError('skill_path must name a catalog SKILL.md');
      }
      final root = await Directory(repo.path).resolveSymbolicLinks();
      final entries = await const HarnessSkillScanner().scan(
        [root],
        permittedLinkRoots: [root],
      );
      String? selected;
      for (final entry in entries) {
        final relative = p
            .relative(entry.path, from: root)
            .replaceAll('\\', '/');
        if (relative == skillPath &&
            p.basename(p.dirname(entry.path)) == slug) {
          selected = await Directory(
            p.dirname(entry.path),
          ).resolveSymbolicLinks();
          break;
        }
      }
      if (selected == null || !p.isWithin(root, selected)) {
        throw StateError('Skill is not in the registered repository catalog');
      }
      directory = selected;
      key = 'repo:$repoId:$skillPath';
      origin = 'repository';
      // No git probe of the source checkout. The immutable byte hash is the
      // revision identity when no pinned source commit exists.
    }
    final files = await _captureFiles(directory);
    final hash = packageHash(files);
    if (hash == pinnedHash && pinnedVerdict == SkillScanVerdict.quarantine) {
      throw StateError('The pinned revision is quarantined');
    }
    final scan = await _scan(workspaceId, slug, files, trust);
    final captured = AdmittedSkillEvaluationSnapshot(
      skillKey: key,
      skillPath: skillPath,
      package: SkillPackageSnapshot(
        slug: slug,
        packageHash: hash,
        files: files,
        origin: origin,
        repoId: repoId,
        sourceCommit: sourceCommit,
        scanRulesVersion: scan.rulesVersion.toString(),
      ),
      scan: scan,
    );
    await _save(workspaceId, captured);
    return captured;
  }

  /// Loads only a previously captured revision of this exact workspace/scope.
  /// It is rescanned under current rules; past admission never bypasses a gate.
  Future<AdmittedSkillEvaluationSnapshot?> previous({
    required String workspaceId,
    required String skillKey,
    required String hash,
  }) async {
    if (!_hash.hasMatch(hash)) {
      throw ArgumentError('Invalid baseline hash');
    }
    final file = _file(workspaceId, skillKey, hash);
    if (!file.existsSync()) {
      return null;
    }
    final data =
        (jsonDecode(
                  utf8.decode(
                    await readEvaluationArtifact(file, maxPackageBytes * 2),
                  ),
                )
                as Map)
            .cast<String, dynamic>();
    if (data['workspaceId'] != workspaceId ||
        data['skillKey'] != skillKey ||
        data['packageHash'] != hash) {
      throw StateError('Stored skill snapshot ownership mismatch');
    }
    final slug = data['slug'] as String;
    validateSlug(slug);
    final files = (data['files'] as Map).map<String, List<int>>(
      (key, value) => MapEntry(key as String, base64Decode(value as String)),
    );
    _validateFiles(files);
    if (packageHash(files) != hash) {
      throw StateError('Stored revision changed');
    }
    final scan = await _scan(
      workspaceId,
      slug,
      files,
      SkillTrustTier.community,
    );
    return AdmittedSkillEvaluationSnapshot(
      skillKey: skillKey,
      skillPath: data['skillPath'] as String?,
      package: SkillPackageSnapshot(
        slug: slug,
        packageHash: hash,
        files: files,
        origin: data['origin'] as String,
        repoId: data['repoId'] as String?,
        sourceCommit: data['sourceCommit'] as String?,
        scanRulesVersion: scan.rulesVersion.toString(),
      ),
      scan: scan,
    );
  }

  Future<SkillScanResult> _scan(
    String workspaceId,
    String slug,
    Map<String, List<int>> files,
    SkillTrustTier trust,
  ) async {
    // Existing scanner is textual. Binary assets remain byte-exact in the
    // snapshot; Latin-1 exposes their ASCII instruction/secret sequences rather
    // than silently dropping them from the supply-chain scan.
    final text = <String, String>{};
    for (final entry in files.entries) {
      try {
        text[entry.key] = utf8.decode(entry.value);
      } on FormatException {
        text[entry.key] = latin1.decode(entry.value);
      }
    }
    final result = await scanner.scan(
      SkillBundle(slug: slug, files: text),
      workspaceId: workspaceId,
      trustTier: trust,
      // Static admission is deterministic and does not spend outside the
      // explicitly approved campaign budget. It never relaxes a quarantine.
      runLlmReview: false,
    );
    if (!result.verdict.installable) {
      throw StateError(
        'Revision rejected by skill scan rules ${result.rulesVersion}',
      );
    }
    return result;
  }

  Future<Map<String, List<int>>> _captureFiles(String directory) async {
    final files = <String, List<int>>{};
    var size = 0;
    await for (final entry in Directory(
      directory,
    ).list(recursive: true, followLinks: false)) {
      if (entry is Link) {
        throw StateError('Skill snapshots cannot contain symbolic links');
      }
      if (entry is! File) {
        continue;
      }
      final name = p
          .relative(entry.path, from: directory)
          .replaceAll('\\', '/');
      if (name == 'skills-lock.json') {
        continue;
      }
      if (!_safeRelative(name)) {
        throw StateError('Invalid package path');
      }
      final resolved = await entry.resolveSymbolicLinks();
      if (!p.isWithin(directory, resolved) ||
          FileSystemEntity.typeSync(entry.path, followLinks: false) !=
              FileSystemEntityType.file) {
        throw StateError('Skill file escaped its package');
      }
      if (size + await entry.length() > maxPackageBytes ||
          files.length >= maxFiles) {
        throw StateError('Skill package exceeds the snapshot limit');
      }
      final bytes = await readEvaluationArtifact(entry, maxPackageBytes - size);
      if (resolved != await entry.resolveSymbolicLinks()) {
        throw StateError('Skill file changed during capture');
      }
      size += bytes.length;
      files[name] = bytes;
    }
    _validateFiles(files);
    return files;
  }

  static bool _safeRelative(String path) =>
      path.isNotEmpty &&
      !p.posix.isAbsolute(path) &&
      !path.contains('\\') &&
      !path.contains(':') &&
      !path.contains('\u0000') &&
      path
          .split('/')
          .every((part) => part.isNotEmpty && part != '.' && part != '..');

  static void _validateFiles(Map<String, List<int>> files) {
    if (!files.containsKey('SKILL.md') ||
        files.length > maxFiles ||
        files.keys.any((key) => !_safeRelative(key)) ||
        files.values.fold<int>(0, (size, bytes) => size + bytes.length) >
            maxPackageBytes) {
      throw StateError('Invalid or oversized skill package');
    }
  }

  /// Matches the installed skill lock's full-package content address.
  static String packageHash(Map<String, List<int>> files) {
    final names = files.keys.where((key) => key != 'skills-lock.json').toList()
      ..sort();
    return sha256
        .convert(
          utf8.encode(
            names
                .map((name) => '$name:${sha256.convert(files[name]!)}')
                .join('\n'),
          ),
        )
        .toString();
  }

  File _file(String workspaceId, String skillKey, String hash) {
    // Workspace IDs never become path components; both namespace segments are
    // digests so even a malformed authenticated id cannot escape the store.
    final workspace = sha256.convert(utf8.encode(workspaceId)).toString();
    final scope = sha256.convert(utf8.encode(skillKey)).toString();
    return File(
      p.join(
        dataDir,
        'skill-evaluations',
        workspace,
        'snapshots',
        scope,
        '$hash.json',
      ),
    );
  }

  /// In-flight saves per snapshot path. POSIX record locks never exclude a
  /// second handle in the same process, while Windows locks fail immediately
  /// on one, so same-process writers queue here before taking the file lock.
  static final Map<String, Future<void>> _pendingSaves = {};

  Future<void> _save(
    String workspaceId,
    AdmittedSkillEvaluationSnapshot snapshot,
  ) async {
    final file = _file(
      workspaceId,
      snapshot.skillKey,
      snapshot.package.packageHash,
    );
    final key = p.normalize(p.absolute(file.path));
    final previous = _pendingSaves[key];
    final done = Completer<void>();
    _pendingSaves[key] = done.future;
    try {
      if (previous != null) {
        await previous;
      }
      await _saveLocked(file, workspaceId, snapshot);
    } finally {
      done.complete();
      if (identical(_pendingSaves[key], done.future)) {
        unawaited(_pendingSaves.remove(key));
      }
    }
  }

  Future<void> _saveLocked(
    File file,
    String workspaceId,
    AdmittedSkillEvaluationSnapshot snapshot,
  ) async {
    await file.parent.create(recursive: true);
    if (file.existsSync()) {
      return;
    }
    final lock = await File('${file.path}.lock').open(mode: FileMode.append);
    try {
      // Blocking: another process saving the same address is waited for, not
      // reported as a failed capture.
      await lock.lock(FileLock.blockingExclusive);
      // Another capture may have installed the same content address while
      // this writer waited. Never overwrite its admitted history.
      if (file.existsSync()) {
        return;
      }
      final encoded = jsonEncode({
        ...snapshot.identity,
        'workspaceId': workspaceId,
        'files': snapshot.package.files.map(
          (key, bytes) => MapEntry(key, base64Encode(bytes)),
        ),
      });
      // Readers see only a fully flushed revision after same-directory rename.
      final temporary = File(
        '${file.path}.$pid.${Random.secure().nextInt(1 << 32)}.tmp',
      );
      await temporary.create(exclusive: true);
      try {
        await temporary.writeAsString(encoded, flush: true);
        await temporary.rename(file.path);
      } finally {
        if (temporary.existsSync()) {
          await temporary.delete();
        }
      }
    } finally {
      await lock.close();
    }
  }
}
