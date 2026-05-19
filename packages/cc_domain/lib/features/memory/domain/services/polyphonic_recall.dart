import 'package:cc_domain/features/memory/domain/services/memory_mmr.dart';
import 'package:cc_domain/features/memory/domain/services/query_intent.dart';
import 'package:cc_domain/features/memory/domain/services/weibull_decay.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';

/// The four independently-rankable recall voices, ported from oh-my-pi mnemopi
/// `core/polyphonic-recall.ts`.
enum RecallVoice {
  /// Dense semantic similarity (embedding/Hamming).
  vector,

  /// Episodic-graph connectivity (BFS over typed edges).
  graph,

  /// Lexical / full-text match.
  fact,

  /// Recency-weighted, activated by temporal queries.
  temporal,
}

/// Default per-voice fusion weight. Mirrors mnemopi's
/// `{vector:0.35, graph:0.25, fact:0.25, temporal:0.15}`.
const Map<RecallVoice, double> defaultVoiceWeights = <RecallVoice, double>{
  RecallVoice.vector: 0.35,
  RecallVoice.graph: 0.25,
  RecallVoice.fact: 0.25,
  RecallVoice.temporal: 0.15,
};

/// RRF constant. Higher = flatter contribution across ranks.
const int rrfK = 60;

/// A recall candidate with the metadata needed for decay + diversity scoring.
class RecallCandidate<T> {
  /// Creates a [RecallCandidate].
  const RecallCandidate({
    required this.id,
    required this.value,
    required this.content,
    required this.memoryType,
    required this.createdAt,
    this.importance = 1.0,
  });

  /// Stable id used to fuse the same memory across voices.
  final String id;

  /// The wrapped value returned in ranked order.
  final T value;

  /// Text used for MMR diversity.
  final String content;

  /// Type, driving Weibull decay.
  final MemoryType memoryType;

  /// Creation time, driving Weibull decay.
  final DateTime createdAt;

  /// Confidence/importance in `[0,1]`, a minor score multiplier.
  final double importance;
}

/// A scored, ranked recall result.
class RankedRecall<T> {
  /// Creates a [RankedRecall].
  const RankedRecall({required this.value, required this.score, required this.id});

  /// The wrapped value.
  final T value;

  /// Final fused+decayed score.
  final double score;

  /// The candidate id.
  final String id;
}

/// Fuses the per-voice ranked id lists into a single diverse, decay-aware
/// ordering.
///
/// For each enabled voice, an id at rank `r` (0-based) contributes
/// `voiceWeight * 1/(rrfK + r + 1)` (weighted Reciprocal Rank Fusion). Voice
/// weights are rebalanced by [intent] (vector←vecBias, fact←ftsBias,
/// temporal←importanceBias). The summed RRF score is then multiplied by the
/// fact's Weibull decay (so a stale `request` sinks below a fresh fact) and a
/// mild importance factor, and finally [mmrRerank]ed for topical diversity.
List<RankedRecall<T>> fusePolyphonicRecall<T>({
  required Map<RecallVoice, List<String>> rankedIdsByVoice,
  required Map<String, RecallCandidate<T>> candidates,
  QueryIntent? intent,
  DateTime? now,
  int topK = 10,
  double mmrLambda = 0.7,
  Map<RecallVoice, double> voiceWeights = defaultVoiceWeights,
  Set<RecallVoice>? enabledVoices,
}) {
  final enabled = enabledVoices ?? RecallVoice.values.toSet();
  final queryTime = now ?? DateTime.now();

  double voiceWeight(RecallVoice voice) {
    final base = voiceWeights[voice] ?? 0.0;
    if (intent == null) {
      return base;
    }
    switch (voice) {
      case RecallVoice.vector:
        return base * intent.vecBias;
      case RecallVoice.fact:
        return base * intent.ftsBias;
      case RecallVoice.temporal:
        return base * intent.importanceBias;
      case RecallVoice.graph:
        return base;
    }
  }

  // Weighted RRF accumulation.
  final rrf = <String, double>{};
  for (final entry in rankedIdsByVoice.entries) {
    if (!enabled.contains(entry.key)) {
      continue;
    }
    final weight = voiceWeight(entry.key);
    if (weight <= 0) {
      continue;
    }
    final ids = entry.value;
    for (var rank = 0; rank < ids.length; rank++) {
      final id = ids[rank];
      rrf[id] = (rrf[id] ?? 0) + weight * (1.0 / (rrfK + rank + 1));
    }
  }

  // Decay + importance shaping.
  final scored = <MmrItem<RankedRecall<T>>>[];
  for (final entry in rrf.entries) {
    final candidate = candidates[entry.key];
    if (candidate == null) {
      continue;
    }
    final decay = weibullBoost(
      candidate.createdAt,
      now: queryTime,
      memoryType: candidate.memoryType,
    );
    // Keep a small floor so a fully-decayed memory still surfaces (ranked last)
    // rather than vanishing entirely.
    final decayFactor = 0.02 + 0.98 * decay;
    final importanceFactor = 0.8 + 0.2 * candidate.importance.clamp(0.0, 1.0);
    final finalScore = entry.value * decayFactor * importanceFactor;
    scored.add(
      MmrItem<RankedRecall<T>>(
        value: RankedRecall<T>(value: candidate.value, score: finalScore, id: candidate.id),
        score: finalScore,
        content: candidate.content,
      ),
    );
  }

  final reranked = mmrRerank<RankedRecall<T>>(scored, lambda: mmrLambda, topK: topK);
  return reranked;
}