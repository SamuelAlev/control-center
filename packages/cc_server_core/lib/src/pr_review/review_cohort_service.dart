import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/changed_symbol_mapper.dart';
import 'package:cc_domain/features/pr_review/domain/services/cohort_grouper.dart';
import 'package:cc_domain/features/pr_review/domain/services/cohort_layer_planner.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/services/test_impact_mapper.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Computes a PR's semantic cohorts (PRD 18 §1) server-side and persists them.
///
/// Maps the PR's changed files → code-graph symbols → connected components
/// (via the pure [CohortGrouper]), ranks cohorts by blast radius and stores
/// them keyed by push-stable cohort key so summaries and review progress
/// survive a rebase. Falls back to honest path grouping (`derivation: path`)
/// when the repo isn't indexed — never fakes semantic confidence.
///
/// Alongside the grouping it computes each cohort's deterministic
/// [CohortInsights]: the ordered reading path ([CohortLayerPlanner]), the
/// symbols the diff actually touched ([ChangedSymbolMapper]) and the test files
/// that cover them ([TestImpactMapper]). All three are cheap joins over data
/// this method already has in hand, and doing them here means one pass over the
/// code graph instead of three.
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
  static const _layerPlanner = CohortLayerPlanner();
  static const _symbolMapper = ChangedSymbolMapper();
  static const _testMapper = TestImpactMapper();

  /// Computes and persists cohorts for [prExternalId] against [headSha]. Returns
  /// the persisted cohorts (reading order). [changedFiles] are the PR's
  /// repository-relative changed paths.
  ///
  /// [patchByFile] carries each changed file's unified diff, when available;
  /// without it the cohorts still compute but carry no changed-symbol detail
  /// (the insight degrades, the grouping does not).
  ///
  /// [checkoutId] selects the code-graph partition. Pass the PR worktree's
  /// `isolated_repos` row id to read head-accurate spans; when that partition
  /// holds nothing yet (a worktree indexes asynchronously) the base partition
  /// is used instead and the result is stamped [SymbolSource.base] rather than
  /// presented as current.
  Future<List<ReviewCohort>> compute({
    required String workspaceId,
    required String repoId,
    required String prExternalId,
    required String headSha,
    required List<String> changedFiles,
    Map<String, String> patchByFile = const {},
    String? checkoutId,
  }) async {
    final files = changedFiles.where((f) => f.isNotEmpty).toSet().toList()
      ..sort();
    if (files.isEmpty) {
      await _cohorts.replaceForPr(workspaceId, prExternalId, const []);
      return const [];
    }

    final dao = _codeGraph(workspaceId);

    // Head partition first; fall back to the base one rather than reporting no
    // symbols at all for a worktree that has not finished indexing.
    var symbolSource = SymbolSource.head;
    var symbols = checkoutId == null
        ? const <CodeSymbolsTableData>[]
        : await dao.getSymbolsByFiles(
            workspaceId,
            repoId,
            files,
            checkoutId: checkoutId,
          );
    if (symbols.isEmpty) {
      symbols = await dao.getSymbolsByFiles(workspaceId, repoId, files);
      symbolSource = symbols.isEmpty
          ? SymbolSource.none
          : (checkoutId == null ? SymbolSource.head : SymbolSource.base);
    }
    final indexed = symbols.isNotEmpty;

    // dominant symbol per file (largest line span) + symbol id → file map.
    final dominantByFile = <String, String>{};
    final dominantIdByFile = <String, String>{};
    final dominantSpanByFile = <String, ({int start, int end})>{};
    final spanByFile = <String, int>{};
    final fileBySymbolId = <String, String>{};
    final spansByFile = <String, List<SymbolSpan>>{};
    for (final s in symbols) {
      fileBySymbolId[s.id] = s.filePath;
      spansByFile
          .putIfAbsent(s.filePath, () => [])
          .add(
            SymbolSpan(
              name: s.name,
              qualifiedName: s.qualifiedName,
              kind: s.kind,
              filePath: s.filePath,
              startLine: s.startLine,
              endLine: s.endLine,
              symbolId: s.id,
            ),
          );
      final span = s.endLine - s.startLine;
      if (span >= (spanByFile[s.filePath] ?? -1)) {
        spanByFile[s.filePath] = span;
        dominantByFile[s.filePath] = s.qualifiedName;
        dominantIdByFile[s.filePath] = s.id;
        dominantSpanByFile[s.filePath] = (start: s.startLine, end: s.endLine);
      }
    }

    // Blast-radius weight per file (dominant symbol's impact-radius node count).
    final impactByFile = <String, int>{};
    if (indexed) {
      for (final entry in dominantIdByFile.entries) {
        try {
          final impact = await dao.getImpactRadius(
            workspaceId,
            entry.value,
            depth: impactDepth,
          );
          impactByFile[entry.key] = impact.nodes.length;
        } catch (_) {
          impactByFile[entry.key] = 1;
        }
      }
    }

    final links = <({String a, String b})>[];
    // Dependency links kept separately from the locality links below: the
    // layer planner needs REAL edges to order foundations before consumers,
    // and "these two files share a directory" is not a dependency.
    final dependencyLinks = <({String a, String b})>[];
    if (indexed) {
      // Graph links: a resolved edge whose source and target files are both
      // changed files (and differ).
      final edges = await dao.getResolvedEdgesBySourceFiles(
        workspaceId,
        repoId,
        files,
        checkoutId: symbolSource == SymbolSource.head ? checkoutId : null,
      );
      for (final e in edges) {
        final targetFile = fileBySymbolId[e.targetSymbolId];
        if (targetFile != null && targetFile != e.sourceFilePath) {
          links.add((a: e.sourceFilePath, b: targetFile));
          dependencyLinks.add((a: e.sourceFilePath, b: targetFile));
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

    // Which symbols the diff actually touched, per file.
    final changedByFile = _changedSymbolsByFile(patchByFile, spansByFile);

    // Test coverage, resolved once for every changed symbol in the PR and then
    // split per cohort — one inbound-edge query instead of one per cohort.
    final testsBySymbolId = await _coveringTests(
      dao: dao,
      workspaceId: workspaceId,
      repoId: repoId,
      changedByFile: changedByFile,
      indexed: indexed,
      checkoutId: symbolSource == SymbolSource.head ? checkoutId : null,
    );

    final cohorts = [
      for (final d in drafts)
        ReviewCohort(
          id: _newId(),
          workspaceId: workspaceId,
          prExternalId: prExternalId,
          cohortKey: d.cohortKey,
          title: d.title,
          orderIndex: d.orderIndex,
          impactScore: d.impactScore,
          derivation: d.derivation,
          filePaths: d.filePaths,
          layers: _layerPlanner.plan(
            filePaths: d.filePaths,
            links: dependencyLinks,
            dominantSymbolByFile: dominantByFile,
            dominantSpanByFile: dominantSpanByFile,
          ),
          insights: _insightsFor(
            filePaths: d.filePaths,
            changedByFile: changedByFile,
            testsBySymbolId: testsBySymbolId,
            symbolSource: symbolSource,
            indexed: indexed,
          ),
          headSha: headSha,
        ),
    ];

    await _cohorts.replaceForPr(workspaceId, prExternalId, cohorts);
    return cohorts;
  }

  /// The touched symbols of every changed file, keyed by path.
  Map<String, List<ChangedSymbol>> _changedSymbolsByFile(
    Map<String, String> patchByFile,
    Map<String, List<SymbolSpan>> spansByFile,
  ) {
    if (patchByFile.isEmpty || spansByFile.isEmpty) {
      return const {};
    }
    final parsed = <String, List<DiffLine>>{};
    for (final entry in patchByFile.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      parsed[entry.key] = parseUnifiedDiff(entry.value);
    }
    final changed = _symbolMapper.map(
      parsedPatchByFile: parsed,
      symbolsByFile: spansByFile,
    );
    final byFile = <String, List<ChangedSymbol>>{};
    for (final c in changed) {
      byFile.putIfAbsent(c.symbol.filePath, () => []).add(c);
    }
    return byFile;
  }

  /// Test files covering each changed symbol id.
  Future<Map<String, List<String>>> _coveringTests({
    required CodeGraphDao dao,
    required String workspaceId,
    required String repoId,
    required Map<String, List<ChangedSymbol>> changedByFile,
    required bool indexed,
    String? checkoutId,
  }) async {
    if (!indexed || changedByFile.isEmpty) {
      return const {};
    }
    final symbolIds = <String>{
      for (final list in changedByFile.values)
        for (final c in list)
          if (c.symbol.symbolId.isNotEmpty) c.symbol.symbolId,
    };
    if (symbolIds.isEmpty) {
      return const {};
    }
    final edges = await dao.getEdgesIntoSymbols(
      workspaceId,
      repoId,
      symbolIds.toList(),
      checkoutId: checkoutId,
    );
    final bySymbol = <String, List<String>>{};
    for (final symbolId in symbolIds) {
      final impact = _testMapper.map(
        changedSymbolIds: {symbolId},
        edges: [
          for (final e in edges)
            if (e.targetSymbolId != null)
              InboundEdge(
                sourceFilePath: e.sourceFilePath,
                targetSymbolId: e.targetSymbolId!,
              ),
        ],
      );
      bySymbol[symbolId] = impact.coveringTests;
    }
    return bySymbol;
  }

  /// Folds the per-file computations into one cohort's insight bundle.
  CohortInsights _insightsFor({
    required List<String> filePaths,
    required Map<String, List<ChangedSymbol>> changedByFile,
    required Map<String, List<String>> testsBySymbolId,
    required SymbolSource symbolSource,
    required bool indexed,
  }) {
    final changed = <ChangedSymbol>[];
    for (final path in filePaths) {
      final list = changedByFile[path];
      if (list != null) {
        changed.addAll(list);
      }
    }
    changed.sort((a, b) => b.changedLines.compareTo(a.changedLines));

    final tests = <String>{};
    for (final c in changed) {
      final covering = testsBySymbolId[c.symbol.symbolId];
      if (covering != null) {
        tests.addAll(covering);
      }
    }

    // Coverage is only KNOWN when the graph could answer: an unindexed repo,
    // or one where the diff touched no resolvable symbol, leaves it unknown so
    // the risk score and the UI both say "cannot tell" instead of "no tests".
    final coverageKnown = indexed && changed.isNotEmpty;

    return CohortInsights(
      changedSymbols: changed,
      coveringTests: tests.toList()..sort(),
      symbolSource: symbolSource,
      testCoverageKnown: coverageKnown,
    );
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
}
