import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_infra/src/pr_review/api_contract_diff_service.dart';

/// Detects changed dependency lockfiles in a PR and computes what actually
/// moved.
///
/// A lockfile shows up in a diff as thousands of unreadable lines, so in
/// practice nobody reads it and a swapped transitive dependency ships
/// unnoticed. This reduces it to the only three questions worth asking: what
/// was added, what was removed, what changed version.
///
/// Entirely offline — the lockfile bodies are the whole input. No registry
/// call, no CVE database, no network. (`LockfileDiffer` marks where an OSV
/// enrichment would later hook in.)
class ReviewDependencyService {
  /// Creates a [ReviewDependencyService].
  ReviewDependencyService({
    required ReviewDependencyDiffRepository repository,
    required String Function() idFactory,
    LockfileDiffer differ = const LockfileDiffer(),
  }) : _repository = repository,
       _newId = idFactory,
       _differ = differ;

  final ReviewDependencyDiffRepository _repository;
  final String Function() _newId;
  final LockfileDiffer _differ;

  /// The changed files that are lockfiles we can read.
  List<String> matchingLockfiles(List<String> changedFiles) => [
    for (final f in changedFiles)
      if (LockfileEcosystem.detect(f) != null) f,
  ];

  /// Computes and persists the dependency diffs for a PR.
  ///
  /// Replaces the PR's whole diff set, so a lockfile dropped from the PR stops
  /// being reported. Returns the persisted diffs (empty when no lockfile
  /// changed, or when none of them actually moved a dependency — a lockfile
  /// churned only by a checksum rewrite is noise, not a review signal).
  Future<List<PrDependencyDiff>> compute({
    required String workspaceId,
    required String prExternalId,
    required String baseSha,
    required String headSha,
    required List<String> changedFiles,
    required ContentReader readContent,
  }) async {
    final lockfiles = matchingLockfiles(changedFiles);
    if (lockfiles.isEmpty) {
      await _repository.replaceForPr(workspaceId, prExternalId, const []);
      return const [];
    }

    final diffs = <PrDependencyDiff>[];
    for (final path in lockfiles) {
      // A lockfile added in this PR has no base content, and one deleted has
      // no head content; both are legitimate and read as an empty side.
      final base = baseSha.isEmpty
          ? ''
          : (await _safeRead(readContent, path, baseSha)) ?? '';
      final head = headSha.isEmpty
          ? ''
          : (await _safeRead(readContent, path, headSha)) ?? '';
      if (base.isEmpty && head.isEmpty) {
        continue;
      }
      final diff = _differ.diff(
        filePath: path,
        baseContent: base,
        headContent: head,
      );
      if (diff == null || diff.isEmpty) {
        continue;
      }
      diffs.add(
        PrDependencyDiff(
          id: _newId(),
          workspaceId: workspaceId,
          prExternalId: prExternalId,
          filePath: path,
          diff: diff,
          baseSha: baseSha.isEmpty ? null : baseSha,
          headSha: headSha.isEmpty ? null : headSha,
        ),
      );
    }

    await _repository.replaceForPr(workspaceId, prExternalId, diffs);
    return diffs;
  }

  /// One unreadable lockfile must not abort the other lockfiles' diffs.
  Future<String?> _safeRead(ContentReader read, String path, String ref) async {
    try {
      return await read(path: path, ref: ref);
    } catch (_) {
      return null;
    }
  }
}
