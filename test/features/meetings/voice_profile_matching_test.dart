import 'dart:math' as math;

import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/meetings/domain/services/voice_profile_matching.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceProfile _profile(String name, List<double> embedding, {int count = 1}) {
  final now = DateTime(2026);
  return VoiceProfile(
    id: 'vp_$name',
    workspaceId: 'w1',
    displayName: name,
    embedding: embedding,
    sampleCount: count,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('bestVoiceMatch', () {
    test('picks the highest-cosine profile', () {
      final match = bestVoiceMatch(const [1, 0, 0], [
        _profile('A', const [1, 0, 0]),
        _profile('B', const [0, 1, 0]),
      ]);
      expect(match, isNotNull);
      expect(match!.profile.displayName, 'A');
      expect(match.similarity, closeTo(1.0, 1e-9));
    });

    test('returns null when nothing clears the suggest threshold', () {
      final match = bestVoiceMatch(const [0, 0, 1], [
        _profile('A', const [1, 0, 0]),
        _profile('B', const [0, 1, 0]),
      ]);
      expect(match, isNull);
    });

    test('returns null for an empty embedding or no profiles', () {
      expect(bestVoiceMatch(const [], [_profile('A', const [1, 0])]), isNull);
      expect(bestVoiceMatch(const [1, 0], const []), isNull);
    });
  });

  group('isAutoApply', () {
    test('true at/above the auto-apply threshold, false below', () {
      final p = _profile('A', const [1, 0]);
      expect(
        isAutoApply(VoiceMatch(profile: p, similarity: kVoiceAutoApplyThreshold)),
        isTrue,
      );
      expect(isAutoApply(VoiceMatch(profile: p, similarity: 0.85)), isTrue);
      expect(
        isAutoApply(
          VoiceMatch(profile: p, similarity: kVoiceAutoApplyThreshold - 0.01),
        ),
        isFalse,
      );
      // A merely-plausible (suggest-range) match is not auto-applied.
      expect(
        isAutoApply(VoiceMatch(profile: p, similarity: kVoiceSuggestThreshold)),
        isFalse,
      );
    });
  });

  group('suggestedNames', () {
    test('returns plausible names ordered by similarity, capped', () {
      // cos([1,0], [1,0])=1.0, [0.6,0.8]=0.6 (both >= 0.5), [0,1]=0 (excluded).
      final names = suggestedNames(const [1, 0], [
        _profile('Mid', const [0.6, 0.8]),
        _profile('Best', const [1, 0]),
        _profile('None', const [0, 1]),
      ]);
      expect(names, ['Best', 'Mid']);
    });

    test('honors the max cap', () {
      final names = suggestedNames(
        const [1, 0],
        [
          _profile('Best', const [1, 0]),
          _profile('Mid', const [0.6, 0.8]),
        ],
        max: 1,
      );
      expect(names, ['Best']);
    });

    test('is empty when no profile is plausible', () {
      final names = suggestedNames(const [0, 1], [
        _profile('A', const [1, 0]),
      ]);
      expect(names, isEmpty);
    });
  });

  group('blendCentroid', () {
    test('re-normalizes the weighted mean to unit length', () {
      final blended = blendCentroid(const [1, 0], 1, const [0, 1]);
      // mean = [0.5, 0.5] → normalized = [0.7071, 0.7071]
      expect(blended[0], closeTo(math.sqrt1_2, 1e-9));
      expect(blended[1], closeTo(math.sqrt1_2, 1e-9));
      final norm = math.sqrt(blended[0] * blended[0] + blended[1] * blended[1]);
      expect(norm, closeTo(1.0, 1e-9));
    });

    test('weights the existing centroid by its sample count', () {
      // old has 3 samples → the new sample moves it only a little.
      final blended = blendCentroid(const [1, 0], 3, const [0, 1]);
      expect(blended[0], greaterThan(blended[1])); // still dominated by "old"
    });

    test('falls back to the normalized sample on a length mismatch', () {
      // old has 2 dims, sample has 3 → can't blend; normalize the sample.
      final blended = blendCentroid(const [1, 0], 1, const [3, 4, 0]);
      // normalize([3,4,0]) = [0.6, 0.8, 0]
      expect(blended, hasLength(3));
      expect(blended[0], closeTo(0.6, 1e-9));
      expect(blended[1], closeTo(0.8, 1e-9));
      expect(blended[2], closeTo(0, 1e-9));
    });
  });

  group('unblendCentroid', () {
    test('backing a sample out pulls the centroid toward the kept sample', () {
      // Blend [1,0] and [0,1] (count 1→2): centroid = normalize([0.5,0.5]).
      final centroid = blendCentroid(const [1, 0], 1, const [0, 1]);
      // Remove the [0,1] sample → the centroid leans back toward [1,0]. (An
      // approximate inverse: each blend re-normalized, so it isn't exact, but it
      // must move in the right direction and stay unit length.)
      final back = unblendCentroid(centroid, 2, const [0, 1]);
      expect(back, isNotNull);
      expect(back![0], greaterThan(centroid[0])); // moved toward [1,0]
      expect(back[0], greaterThan(back[1])); // now dominated by the kept sample
      final norm = math.sqrt(back[0] * back[0] + back[1] * back[1]);
      expect(norm, closeTo(1.0, 1e-9));
    });

    test('returns null when removing the only sample (count <= 1)', () {
      expect(unblendCentroid(const [1, 0], 1, const [1, 0]), isNull);
      expect(unblendCentroid(const [1, 0], 0, const [1, 0]), isNull);
    });

    test('returns null on a length mismatch (cannot un-blend a foreign dim)',
        () {
      expect(unblendCentroid(const [1, 0], 3, const [1, 0, 0]), isNull);
    });

    test('result stays unit length for the remaining samples', () {
      // Three unit samples blended in, then back one out.
      var c = blendCentroid(const [1, 0, 0], 1, const [0, 1, 0]);
      c = blendCentroid(c, 2, const [0, 0, 1]);
      final back = unblendCentroid(c, 3, const [0, 0, 1])!;
      final norm = math.sqrt(
        back[0] * back[0] + back[1] * back[1] + back[2] * back[2],
      );
      expect(norm, closeTo(1.0, 1e-9));
    });
  });
}
