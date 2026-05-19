// Which tests actually cover the code this PR changed.
//
// "Are there tests?" is the wrong question — a repo with 4000 tests can still
// have none that execute the function being changed. This walks the code graph
// INBOUND from the changed symbols and keeps the callers that live in test
// files, which answers the question that matters: if this change is wrong,
// does anything fail?
//
// Pure: set arithmetic over edge rows the caller already read.

import 'package:cc_domain/features/pr_review/domain/value_objects/change_path_heuristics.dart';

/// An inbound code-graph edge, reduced to what coverage needs.
class InboundEdge {
  /// Creates an [InboundEdge].
  const InboundEdge({
    required this.sourceFilePath,
    required this.targetSymbolId,
  });

  /// File the reference comes FROM (a test file, when it counts as coverage).
  final String sourceFilePath;

  /// Symbol being referenced.
  final String targetSymbolId;
}

/// Test files covering a set of changed symbols.
class TestImpact {
  /// Creates a [TestImpact].
  const TestImpact({this.coveringTests = const [], this.known = false});

  /// Repository-relative test files that reach the changed symbols, sorted.
  final List<String> coveringTests;

  /// Whether coverage could be determined at all.
  ///
  /// False means the repo was not indexed, so the answer is "cannot tell" —
  /// which must never be rendered as "no tests". An unindexed repo with a
  /// thorough suite and one with none look identical from here, and saying so
  /// is the only honest option.
  final bool known;

  /// Number of covering test files, or null when unknown.
  int? get count => known ? coveringTests.length : null;

  /// Whether coverage is known AND genuinely absent — the only state that is
  /// a real risk signal.
  bool get isKnownUncovered => known && coveringTests.isEmpty;
}

/// Maps changed symbols to the test files that reference them.
class TestImpactMapper {
  /// Creates a [TestImpactMapper].
  const TestImpactMapper();

  /// Returns the test files among [edges] that reach [changedSymbolIds].
  ///
  /// Pass `indexed: false` when the repo has no code graph — the result is
  /// then explicitly unknown rather than empty.
  TestImpact map({
    required Set<String> changedSymbolIds,
    required Iterable<InboundEdge> edges,
    bool indexed = true,
  }) {
    if (!indexed) {
      return const TestImpact();
    }
    final tests = <String>{};
    for (final edge in edges) {
      if (!changedSymbolIds.contains(edge.targetSymbolId)) {
        continue;
      }
      if (isTestPath(edge.sourceFilePath)) {
        tests.add(edge.sourceFilePath);
      }
    }
    final sorted = tests.toList()..sort();
    return TestImpact(coveringTests: sorted, known: true);
  }
}
