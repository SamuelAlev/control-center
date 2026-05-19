import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/services/memory_mmr.dart';

/// The decision produced when a candidate fact is checked against an existing
/// active fact on the same `(domain, topic)`.
class ConflictDecision {
  /// Creates a [ConflictDecision].
  const ConflictDecision({
    required this.candidate,
    required this.existing,
    required this.winner,
    required this.loser,
  });

  /// The newly-arriving fact.
  final MemoryFact candidate;

  /// The pre-existing active fact that contradicts it.
  final MemoryFact existing;

  /// The fact that should remain active.
  final MemoryFact winner;

  /// The fact that should be superseded.
  final MemoryFact loser;
}

/// Veracity-weighted confidence: a tool-sourced 0.9 ranks below a user-stated
/// 0.9 because tool veracity carries less weight. This is the comparison key
/// used to pick a conflict winner.
double weightedConfidence(MemoryFact fact) => fact.confidence * fact.veracity.weight;

/// Token-Jaccard similarity at/above which two same-topic, non-identical
/// contents are treated as a contradiction.
///
/// mnemopi keys conflicts on an exact `(subject, predicate)` match with a
/// different `object`. Two such facts share their subject+predicate text, so
/// they overlap heavily *and* differ only in the value — high lexical overlap,
/// not low. CC maps topic≈subject+predicate, so a contradiction shows up as two
/// same-topic facts with HIGH content overlap (e.g. "deploy target is prod" vs
/// "…staging") differing in a key term. Genuinely distinct facts filed under one
/// topic (a harvest list) overlap little and are left alone.
const double conflictSimilarityThreshold = 0.5;

/// Detects contradictions for [candidate] against [existingActive] facts (which
/// the caller must already have scoped to the same workspace + domain + topic,
/// excluding [candidate] itself and any superseded rows).
///
/// A contradiction is a near-variant: identical content is a re-mention (dedup,
/// handled elsewhere), low-overlap content is an unrelated fact, and content
/// with token-Jaccard ≥ [conflictSimilarityThreshold] that is *not* identical is
/// a same-statement-different-value clash. The winner is the higher
/// [weightedConfidence] fact; ties break toward the newer `createdAt`. Mirrors
/// the supersession half of mnemopi `core/veracity-consolidation.ts`.
List<ConflictDecision> detectConflicts(
  MemoryFact candidate,
  List<MemoryFact> existingActive,
) {
  final decisions = <ConflictDecision>[];
  final candidateContent = candidate.content.trim();
  for (final existing in existingActive) {
    if (existing.id == candidate.id) {
      continue;
    }
    final existingContent = existing.content.trim();
    if (existingContent.toLowerCase() == candidateContent.toLowerCase()) {
      continue; // identical → dedup, not conflict
    }
    final similarity = jaccardSimilarity(candidateContent, existingContent);
    if (similarity < conflictSimilarityThreshold) {
      continue; // unrelated facts under the same topic, not a contradiction
    }
    final candidateScore = weightedConfidence(candidate);
    final existingScore = weightedConfidence(existing);
    final MemoryFact winner;
    final MemoryFact loser;
    if (candidateScore > existingScore) {
      winner = candidate;
      loser = existing;
    } else if (existingScore > candidateScore) {
      winner = existing;
      loser = candidate;
    } else {
      // Tie on weighted confidence → newer fact wins.
      if (candidate.createdAt.isAfter(existing.createdAt)) {
        winner = candidate;
        loser = existing;
      } else {
        winner = existing;
        loser = candidate;
      }
    }
    decisions.add(
      ConflictDecision(
        candidate: candidate,
        existing: existing,
        winner: winner,
        loser: loser,
      ),
    );
  }
  return decisions;
}