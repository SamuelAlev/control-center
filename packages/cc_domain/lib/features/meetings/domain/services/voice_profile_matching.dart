import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/services/cosine_similarity.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';

/// Cosine-similarity threshold at/above which a diarized speaker is confidently
/// the same person as a saved profile, so the profile's name is auto-applied.
///
/// Set stricter than the clustering boundary: a silent mislabel ("that wasn't
/// me") is worse than leaving a speaker as "Person N", so auto-apply must be
/// confident. WeSpeaker cosine scores for same-speaker pairs typically sit well
/// above this.
const double kVoiceAutoApplyThreshold = 0.70;

/// Cosine-similarity floor at/above which a saved profile is a *plausible*
/// match worth surfacing as a rename suggestion (but not confident enough to
/// auto-apply). Sits around the WeSpeaker clustering boundary.
const double kVoiceSuggestThreshold = 0.50;

/// A candidate match between a diarized speaker's embedding and a saved
/// [VoiceProfile], with its cosine [similarity] (`-1`..`1`).
class VoiceMatch {
  /// Creates a [VoiceMatch].
  const VoiceMatch({required this.profile, required this.similarity});

  /// The matched profile.
  final VoiceProfile profile;

  /// Cosine similarity between the speaker embedding and the profile centroid.
  final double similarity;
}

/// The best profile match for [embedding] among [profiles] whose similarity is
/// at least [kVoiceSuggestThreshold], or null when nothing is plausible.
///
/// Pure + top-level so it is directly unit-testable.
VoiceMatch? bestVoiceMatch(
  List<double> embedding,
  List<VoiceProfile> profiles,
) {
  if (embedding.isEmpty || profiles.isEmpty) {
    return null;
  }
  final query = Float32List.fromList(embedding);
  VoiceProfile? best;
  var bestSim = kVoiceSuggestThreshold;
  for (final profile in profiles) {
    final sim = cosineSimilarity(query, Float32List.fromList(profile.embedding));
    if (sim >= bestSim) {
      bestSim = sim;
      best = profile;
    }
  }
  return best == null ? null : VoiceMatch(profile: best, similarity: bestSim);
}

/// Whether [match] is confident enough to auto-apply its profile's name.
bool isAutoApply(VoiceMatch match) =>
    match.similarity >= kVoiceAutoApplyThreshold;

/// Ordered candidate names to suggest in the rename UI for a still-unnamed
/// speaker: every profile whose similarity to [embedding] clears
/// [kVoiceSuggestThreshold], most-similar first, de-duplicated by name and
/// capped at [max]. Empty when nothing is plausible.
///
/// Pure + top-level so it is directly unit-testable.
List<String> suggestedNames(
  List<double> embedding,
  List<VoiceProfile> profiles, {
  int max = 3,
}) {
  if (embedding.isEmpty || profiles.isEmpty || max <= 0) {
    return const [];
  }
  final query = Float32List.fromList(embedding);
  final scored = <({String name, double sim})>[];
  for (final profile in profiles) {
    final sim = cosineSimilarity(query, Float32List.fromList(profile.embedding));
    if (sim >= kVoiceSuggestThreshold) {
      scored.add((name: profile.displayName, sim: sim));
    }
  }
  scored.sort((a, b) => b.sim.compareTo(a.sim));
  final out = <String>[];
  for (final s in scored) {
    if (!out.contains(s.name)) {
      out.add(s.name);
    }
    if (out.length >= max) {
      break;
    }
  }
  return out;
}

/// Blends a new [sample] embedding into a profile's running centroid via a
/// sample-count-weighted mean, re-normalized to unit length so it stays a valid
/// cosine reference: `new = normalize((old * oldCount + sample) / (oldCount+1))`.
///
/// Falls back to the normalized [sample] when the lengths disagree (e.g. the
/// embedding model changed) — a fresh start rather than a corrupt blend. Pure +
/// top-level so it is directly unit-testable.
List<double> blendCentroid(
  List<double> old,
  int oldCount,
  List<double> sample,
) {
  if (old.length != sample.length || oldCount <= 0) {
    return _l2normalize(sample);
  }
  final n = oldCount.toDouble();
  final blended = <double>[
    for (var i = 0; i < old.length; i++) (old[i] * n + sample[i]) / (n + 1),
  ];
  return _l2normalize(blended);
}

/// Removes a previously-blended [sample] from a profile's running [centroid],
/// the inverse of [blendCentroid]: backs the sample out of the count-weighted
/// mean — `old = normalize((centroid * count - sample) / (count - 1))` — for the
/// remaining `count - 1` samples. Used when a speaker is renamed away from a
/// profile their voiceprint was enrolled into, so the corrected name doesn't
/// leave a stale sample behind.
///
/// Returns null when nothing meaningful remains — the [sample] was the profile's
/// only one (`count <= 1`) — signalling the caller to delete the profile rather
/// than keep an empty husk. Re-normalization is lossy (each blend dropped the
/// pre-normalization magnitude), so this is an approximate inverse; for the
/// common one-sample profile it is exact (it deletes). Falls back to deletion
/// (null) when the lengths disagree, mirroring [blendCentroid]'s fresh-start
/// guard. Pure + top-level so it is directly unit-testable.
List<double>? unblendCentroid(
  List<double> centroid,
  int count,
  List<double> sample,
) {
  if (count <= 1 || centroid.length != sample.length) {
    return null;
  }
  final n = count.toDouble();
  final remaining = <double>[
    for (var i = 0; i < centroid.length; i++)
      (centroid[i] * n - sample[i]) / (n - 1),
  ];
  return _l2normalize(remaining);
}

/// L2-normalizes [v] to unit length. Returns it unchanged when its norm is 0.
List<double> _l2normalize(List<double> v) {
  var sumSq = 0.0;
  for (final x in v) {
    sumSq += x * x;
  }
  final norm = math.sqrt(sumSq);
  if (norm == 0) {
    return List<double>.from(v);
  }
  return [for (final x in v) x / norm];
}
