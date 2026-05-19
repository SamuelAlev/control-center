import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/cohort_grouper.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Computes a PR's semantic cohorts (PRD 18 §1) server-side and persists them.
///
/// Maps the PR's changed files → code-graph symbols → connected components
/// (via the pure [CohortGrouper]), ranks cohorts by blast radius, and stores
/// them keyed by push-stable cohort key so summaries and review progress
/// survive a rebase. Falls back to honest path grouping (`derivation: path`)
/// when the repo isn't indexed — never fakes semantic confidence.
///
/// Depends on [CodeGraphDao] directly (not the domain `CodeGraphRepository`)
/// because it needs the file-scoped symbol/edge queries and cohort computation
/// is always server-side; the client never computes cohorts. The DAO is
/// resolved per call from the workspace's own database file.
class ReviewCohortService {
  /// Creates a [ReviewCohortService] over the per-workspace databases.
  ReviewCohortService({
    required WorkspaceDatabaseManager workspaceDbs,
    required ReviewCohortRepository cohorts,
    required String Function() idFactory,
    this.impactDepth = 2,
  }) : _dbs = workspaceDbs,
       _cohorts = cohorts,
       _newId = idFactory;

  final WorkspaceDatabaseManager _dbs;
  final ReviewCohortRepository _cohorts;
  final String Function() _newId;

  CodeGraphDao _codeGraph(String workspaceId) =>
      _dbs.of(workspaceId).codeGraphDao;

  /// Impact-radius depth used for cohort ranking.
  final int impactDepth;

  static const _grouper = CohortGrouper();

  /// Computes and persists cohorts for [prNodeId] against [headSha]. Returns
  /// the persisted cohorts (reading order). [changedFiles] are the PR's
  /// repository-relative changed paths.
  Future<List<ReviewCohort>> compute({
    required String workspaceId,
    required String repoId,
    required String prNodeId,
    required String headSha,
    required List<String> changedFiles,
  }) async {
    final files = changedFiles.where((f) => f.isNotEmpty).toSet().toList()
      ..sort();
    if (files.isEmpty) {
      await _cohorts.replaceForPr(workspaceId, prNodeId, const []);
      return const [];
    }

    final symbols = await _codeGraph(
      workspaceId,
    ).getSymbolsByFiles(workspaceId, repoId, files);
    final indexed = symbols.isNotEmpty;

    // dominant symbol per file (largest line span) + symbol id → file map.
    final dominantByFile = <String, String>{};
    final spanByFile = <String, int>{};
    final fileBySymbolId = <String, String>{};
    for (final s in symbols) {
      fileBySymbolId[s.id] = s.filePath;
      final span = s.endLine - s.startLine;
      if (span >= (spanByFile[s.filePath] ?? -1)) {
        spanByFile[s.filePath] = span;
        dominantByFile[s.filePath] = s.qualifiedName;
      }
    }

    // Blast-radius weight per file (dominant symbol's impact-radius node count).
    final impactByFile = <String, int>{};
    if (indexed) {
      for (final entry in dominantByFile.entries) {
        final domId = symbols.firstWhere((s) => s.filePath == entry.key).id;
        try {
          final impact = await _codeGraph(
            workspaceId,
          ).getImpactRadius(workspaceId, domId, depth: impactDepth);
          impactByFile[entry.key] = impact.nodes.length;
        } catch (_) {
          impactByFile[entry.key] = 1;
        }
      }
    }

    final links = <({String a, String b})>[];
    if (indexed) {
      // Graph links: a resolved edge whose source and target files are both
      // changed files (and differ).
      final edges = await _codeGraph(
        workspaceId,
      ).getResolvedEdgesBySourceFiles(workspaceId, repoId, files);
      for (final e in edges) {
        final targetFile = fileBySymbolId[e.targetSymbolId];
        if (targetFile != null && targetFile != e.sourceFilePath) {
          links.add((a: e.sourceFilePath, b: targetFile));
        }
      }
    }
    // Locality links (same directory) reinforce cohesion in both modes.
    links.addAll(_sameDirectoryLinks(files));

    final inputs = [
      for (final f in files)
        CohortFileInput(
          path: f,
          dominantSymbol: dominantByFile[f],
          impactWeight: impactByFile[f] ?? 1,
        ),
    ];

    final drafts = _grouper.group(
      files: inputs,
      links: links,
      derivation: indexed ? CohortDerivation.graph : CohortDerivation.path,
    );

    final cohorts = [
      for (final d in drafts)
        ReviewCohort(
          id: _newId(),
          workspaceId: workspaceId,
          prNodeId: prNodeId,
          cohortKey: d.cohortKey,
          title: d.title,
          orderIndex: d.orderIndex,
          impactScore: d.impactScore,
          derivation: d.derivation,
          filePaths: d.filePaths,
          layers: [
            for (final p in d.filePaths)
              CohortLayer(title: _basename(p), filePath: p),
          ],
          headSha: headSha,
        ),
    ];

    await _cohorts.replaceForPr(workspaceId, prNodeId, cohorts);
    return cohorts;
  }

  List<({String a, String b})> _sameDirectoryLinks(List<String> files) {
    final byDir = <String, List<String>>{};
    for (final f in files) {
      byDir.putIfAbsent(_dir(f), () => []).add(f);
    }
    final links = <({String a, String b})>[];
    for (final group in byDir.values) {
      for (var i = 1; i < group.length; i++) {
        links.add((a: group.first, b: group[i]));
      }
    }
    return links;
  }

  String _dir(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  String _basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }
}
