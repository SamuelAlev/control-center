import 'package:cc_mcp_client/src/semantic/worktree_overlay.dart';

/// Embeds a natural-language query into a vector. The host wires this to CC's
/// `EmbeddingPort` (ONNX bge-small).
typedef QueryEmbedder = Future<List<double>> Function(String query);

/// Runs a vector similarity search against an index, returning up to [limit]
/// hits. Two are injected: one over the shared baseline index, one over the
/// worktree-local delta index.
typedef VectorSearch =
    Future<List<SemanticHit>> Function(List<double> vector, int limit);

/// Worktree-aware semantic code search (PRD 01 phase 1.6).
///
/// Searches the shared baseline index AND the worktree-local delta index, then
/// validates every baseline hit through the [WorktreeOverlay] (rejecting
/// diverged/in-flight files) before merging. Because most files are unchanged,
/// the baseline index is reused across worktrees instead of re-embedding the
/// whole repo per worktree.
class WorktreeSemanticSearch {
  /// Creates a [WorktreeSemanticSearch].
  WorktreeSemanticSearch({
    required this.overlay,
    required QueryEmbedder embed,
    required VectorSearch baselineSearch,
    required VectorSearch deltaSearch,
  }) : _embed = embed,
       _baselineSearch = baselineSearch,
       _deltaSearch = deltaSearch;

  /// The overlay validating baseline hits for this worktree.
  final WorktreeOverlay overlay;

  final QueryEmbedder _embed;
  final VectorSearch _baselineSearch;
  final VectorSearch _deltaSearch;

  /// Searches for [query], returning up to [limit] ranked, validated hits.
  ///
  /// The internal search ceiling over-fetches (`max(limit, min(limit*16, 1000))`)
  /// so post-filtering still yields enough valid baseline hits.
  Future<List<SemanticHit>> search(String query, {int limit = 10}) async {
    final vector = await _embed(query);
    final ceiling = _ceiling(limit);

    final deltaRaw = await _deltaSearch(vector, ceiling);
    final delta = deltaRaw.where(overlay.acceptsDeltaHit).toList();

    final baselineRaw = await _baselineSearch(vector, ceiling);
    final checks = <String, String?>{};
    final baseline = <SemanticHit>[];
    for (final hit in baselineRaw) {
      if (await overlay.acceptsBaselineHit(hit, checks: checks)) {
        baseline.add(hit);
      }
    }

    return WorktreeOverlay.mergeRanked(baseline, delta, limit: limit);
  }

  static int _ceiling(int limit) {
    final expanded = limit * 16;
    final capped = expanded < 1000 ? expanded : 1000;
    return capped > limit ? capped : limit;
  }
}
