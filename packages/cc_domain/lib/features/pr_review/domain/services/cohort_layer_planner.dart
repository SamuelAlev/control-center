// The guided reading order inside one cohort (PRD 18 §2).
//
// A diff is served to a reviewer alphabetically, which is the one order that
// carries no information. This planner replaces it with the order a person
// would actually explain the change in: the things nothing else in the cohort
// depends on come FIRST (the new type, the new column, the changed signature),
// then their consumers, then the tests that pin them.
//
// Pure and deterministic: same files + links in, same layer order out.

import 'package:cc_domain/features/pr_review/domain/value_objects/change_path_heuristics.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';

/// Plans the ordered reading path of a cohort's files.
class CohortLayerPlanner {
  /// Creates a [CohortLayerPlanner].
  const CohortLayerPlanner();

  /// Orders [filePaths] into reading layers.
  ///
  /// [links] are intra-cohort dependency edges where `a` depends on `b` (an
  /// edge from a call site to its callee). Foundations — files nothing else
  /// depends on *pointing at them* — read first, so the ordering runs over the
  /// reversed graph: depth 0 = depended-upon by others but depending on
  /// nothing inside the cohort.
  ///
  /// [dominantSymbolByFile] / [dominantSpanByFile] name and anchor each layer
  /// when the repo is indexed; without them a layer falls back to the file's
  /// basename and a whole-file range (honest: no fake precision).
  ///
  /// Tests always read last regardless of graph depth — a reviewer who reads
  /// the test first learns the assertion before the behavior.
  List<CohortLayer> plan({
    required List<String> filePaths,
    List<({String a, String b})> links = const [],
    Map<String, String> dominantSymbolByFile = const {},
    Map<String, ({int start, int end})> dominantSpanByFile = const {},
    Map<String, String> summaryByFile = const {},
  }) {
    final files = filePaths.where((f) => f.isNotEmpty).toSet().toList()..sort();
    if (files.isEmpty) {
      return const [];
    }
    final inCohort = files.toSet();

    // Dependency depth over the cohort-internal graph. `a depends on b` means
    // b is more foundational, so b must come before a.
    final dependsOn = <String, Set<String>>{for (final f in files) f: {}};
    for (final link in links) {
      if (link.a == link.b) {
        continue;
      }
      if (!inCohort.contains(link.a) || !inCohort.contains(link.b)) {
        continue;
      }
      dependsOn[link.a]!.add(link.b);
    }

    final depth = _depths(files, dependsOn);

    files.sort((a, b) {
      // 1. Tests last.
      final testA = isTestPath(a);
      final testB = isTestPath(b);
      if (testA != testB) {
        return testA ? 1 : -1;
      }
      // 2. Foundations first (lower dependency depth).
      final byDepth = depth[a]!.compareTo(depth[b]!);
      if (byDepth != 0) {
        return byDepth;
      }
      // 3. Deterministic tie-break — a cycle must not reorder between runs.
      return a.compareTo(b);
    });

    return [
      for (final path in files)
        CohortLayer(
          title: dominantSymbolByFile[path] ?? _basename(path),
          filePath: path,
          startLine: dominantSpanByFile[path]?.start,
          endLine: dominantSpanByFile[path]?.end,
          summaryMarkdown: summaryByFile[path] ?? '',
        ),
    ];
  }

  /// Longest-path depth of each file over the `dependsOn` graph, iteratively
  /// (no recursion: a cycle in a real code graph must not blow the stack).
  ///
  /// A file that depends on nothing inside the cohort is depth 0. Cycles
  /// stabilize at the iteration cap and fall through to the path tie-break.
  Map<String, int> _depths(
    List<String> files,
    Map<String, Set<String>> dependsOn,
  ) {
    final depth = <String, int>{for (final f in files) f: 0};
    // At most |V| relaxation rounds are needed for an acyclic graph; a cycle
    // simply stops changing once every member shares the maximum.
    for (var round = 0; round < files.length; round++) {
      var changed = false;
      for (final file in files) {
        var best = 0;
        for (final dep in dependsOn[file]!) {
          final candidate = depth[dep]! + 1;
          if (candidate > best) {
            best = candidate;
          }
        }
        // Clamp so a cycle cannot run the depth up unboundedly.
        if (best > files.length) {
          best = files.length;
        }
        if (best != depth[file]) {
          depth[file] = best;
          changed = true;
        }
      }
      if (!changed) {
        break;
      }
    }
    return depth;
  }

  String _basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }
}
