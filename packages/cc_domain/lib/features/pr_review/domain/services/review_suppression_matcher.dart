// Suppresses findings the workspace has already told us it does not want.
//
// A dismissal is the clearest feedback a reviewer ever gets, and until this
// existed nothing read it back: the reviewer brief merely ASKED agents to
// search a suppressions memory before flagging, which is exactly the kind of
// instruction that does not hold. The published evidence on this is blunt —
// teams that tried prompt wording to stop repeat nits saw no effect, and a
// model grading its own output scored near-randomly. What worked was a
// mechanical filter over the team's own past rejections, and that is what this
// is.
//
// Two deliberate differences from that prior art. It DEMOTES rather than
// blocks, because our nitpick group means a suppressed finding is one click
// away rather than gone — so a false suppression is cheap and the threshold
// can be less timid. And it never suppresses a critical or major finding: a
// team that dismissed something once has not licensed us to hide a breach.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// Decides which candidate findings echo a previously dismissed one.
class ReviewSuppressionMatcher {
  /// Creates a [ReviewSuppressionMatcher].
  ///
  /// [similarityThreshold] is cosine similarity on unit-norm embeddings.
  /// [minMatches] is how many distinct past dismissals a candidate must echo
  /// before it is set aside — more than one, so a single stubborn rejection
  /// cannot suppress a whole class of finding on its own.
  const ReviewSuppressionMatcher({
    required EmbeddingPort embedder,
    this.similarityThreshold = 0.86,
    this.minMatches = 2,
  }) : _embedder = embedder;

  final EmbeddingPort _embedder;

  /// How alike two findings must read before one counts as an echo of the
  /// other. High on purpose: "the same complaint" is a much stronger claim
  /// than "about the same area of code".
  final double similarityThreshold;

  /// How many distinct dismissals a candidate must echo to be set aside.
  final int minMatches;

  /// The subset of [candidates] that echo at least [minMatches] entries of
  /// [dismissedTitles], keyed by the candidate's index.
  ///
  /// Returns empty — suppressing nothing — whenever it cannot answer
  /// confidently: no embedder, no corpus, or a corpus too small for
  /// [minMatches] to mean anything. Degrading toward "report it" is the only
  /// safe direction; the opposite silently turns a missing model into a
  /// reviewer that finds nothing.
  Future<Set<int>> suppressed({
    required List<ReviewSuppressionCandidate> candidates,
    required List<String> dismissedTitles,
  }) async {
    if (candidates.isEmpty ||
        dismissedTitles.length < minMatches ||
        !_embedder.isReady) {
      return const {};
    }

    final eligible = <int>[];
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i].isSuppressible) {
        eligible.add(i);
      }
    }
    if (eligible.isEmpty) {
      return const {};
    }

    final List<Float32List> corpusVectors;
    final List<Float32List> candidateVectors;
    try {
      corpusVectors = await _embedder.embedAll(dismissedTitles);
      candidateVectors = await _embedder.embedAll([
        for (final i in eligible) candidates[i].title,
      ]);
    } on Object catch (_) {
      // The embedder is a best-effort enrichment here, never a gate on the
      // review completing.
      return const {};
    }

    final out = <int>{};
    for (var slot = 0; slot < eligible.length; slot++) {
      final vector = candidateVectors[slot];
      var matches = 0;
      for (final past in corpusVectors) {
        if (_cosine(vector, past) >= similarityThreshold) {
          matches++;
          if (matches >= minMatches) {
            out.add(eligible[slot]);
            break;
          }
        }
      }
    }
    return out;
  }

  /// Cosine similarity. The port promises unit-norm vectors, but the norms are
  /// divided out anyway — a silent change there would otherwise turn into
  /// scores above 1 and a threshold that quietly stops meaning anything.
  static double _cosine(Float32List a, Float32List b) {
    if (a.length != b.length || a.isEmpty) {
      return 0;
    }
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) {
      return 0;
    }
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}

/// One finding offered to the matcher.
class ReviewSuppressionCandidate {
  /// Creates a [ReviewSuppressionCandidate].
  const ReviewSuppressionCandidate({
    required this.title,
    required this.severity,
  });

  /// The finding's claim — its first line, not its whole body. The body is the
  /// argument for the claim and is the part that gets reworded between passes.
  final String title;

  /// Used only to protect the severities that are never suppressed.
  final ReviewFindingSeverity severity;

  /// Whether a past dismissal may set this finding aside.
  ///
  /// Critical and major never qualify. A team dismissing a nit once is a
  /// preference; it is not permission to stop reporting breaches.
  bool get isSuppressible =>
      title.trim().isNotEmpty &&
      severity != ReviewFindingSeverity.critical &&
      severity != ReviewFindingSeverity.major;
}
