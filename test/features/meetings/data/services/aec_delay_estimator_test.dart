import 'dart:math' as math;
import 'dart:typed_data';

import 'package:control_center/features/meetings/data/services/aec_delay_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a PCM16 block whose samples are all [amplitude] (a cheap way to make a
/// block with a known RMS for the [AecDelayEstimator.rms] check).
Uint8List _flatBlock(int amplitude, {int frames = 160}) {
  final b = Uint8List(frames * 2);
  final bd = ByteData.sublistView(b);
  for (var i = 0; i < frames; i++) {
    bd.setInt16(i * 2, amplitude, Endian.little);
  }
  return b;
}

void main() {
  group('AecDelayEstimator.rms', () {
    test('RMS of a constant block equals |amplitude|', () {
      expect(AecDelayEstimator.rms(_flatBlock(1000)), closeTo(1000, 0.001));
      expect(AecDelayEstimator.rms(_flatBlock(-2000)), closeTo(2000, 0.001));
      expect(AecDelayEstimator.rms(_flatBlock(0)), 0);
    });
  });

  group('AecDelayEstimator.estimate', () {
    // A white per-bin energy envelope correlates sharply with a shifted copy of
    // itself, so the recovered lag is unambiguous — ideal for testing the
    // cross-correlation mechanics independently of any acoustic modelling.
    List<double> whiteEnvelope(int bins, int seed) {
      final rnd = math.Random(seed);
      return List<double>.generate(bins, (_) => 200 + rnd.nextDouble() * 4000);
    }

    test('recovers a POSITIVE far-lead (mic lags the loopback)', () {
      final est = AecDelayEstimator(minNearStd: 0.5);
      final far = whiteEnvelope(700, 1);
      final rnd = math.Random(2);
      const delayBins = 8; // far leads near by 80 ms → near[i] = far[i-8]
      for (var bin = 0; bin < far.length; bin++) {
        final t = bin * 10;
        est.addFar(t, far[bin]);
        final src = bin - delayBins;
        final near =
            src >= 0 ? far[src] * 0.5 + rnd.nextDouble() * 50 : rnd.nextDouble() * 50;
        est.addNear(t, near);
      }
      final e = est.estimate();
      expect(e, isNotNull);
      expect(e!.lagMs, closeTo(80, 10)); // +1 bin tolerance
      expect(e.confidence, greaterThan(0.7));
    });

    test('recovers a NEGATIVE far-lead (laggy tap: mic leads the loopback)', () {
      final est = AecDelayEstimator(minNearStd: 0.5);
      final far = whiteEnvelope(700, 3);
      final rnd = math.Random(4);
      const advanceBins = 12; // near[i] = far[i+12] → mic leads far by 120 ms
      for (var bin = 0; bin < far.length; bin++) {
        final t = bin * 10;
        est.addFar(t, far[bin]);
        final src = bin + advanceBins;
        final near = src < far.length
            ? far[src] * 0.5 + rnd.nextDouble() * 50
            : rnd.nextDouble() * 50;
        est.addNear(t, near);
      }
      final e = est.estimate();
      expect(e, isNotNull);
      expect(e!.lagMs, closeTo(-120, 10));
      expect(e.confidence, greaterThan(0.7));
    });

    test('returns null while still warming up (not enough history)', () {
      final est = AecDelayEstimator();
      for (var bin = 0; bin < 20; bin++) {
        est.addFar(bin * 10, 1000);
        est.addNear(bin * 10, 500);
      }
      expect(est.estimate(), isNull);
    });

    test('returns null when the mic is silent (nothing to align)', () {
      final est = AecDelayEstimator(minNearStd: 1.0);
      final far = whiteEnvelope(700, 5);
      for (var bin = 0; bin < far.length; bin++) {
        est.addFar(bin * 10, far[bin]);
        est.addNear(bin * 10, 0); // mic dead silent
      }
      expect(est.estimate(), isNull);
    });

    test('uncorrelated channels yield low confidence', () {
      final est = AecDelayEstimator(minNearStd: 0.5);
      final far = whiteEnvelope(700, 6);
      final near = whiteEnvelope(700, 9999); // independent noise
      for (var bin = 0; bin < far.length; bin++) {
        est.addFar(bin * 10, far[bin]);
        est.addNear(bin * 10, near[bin]);
      }
      final e = est.estimate();
      expect(e, isNotNull);
      expect(e!.confidence, lessThan(0.5));
    });

    test('recovers a large far-lead beyond the old ±400 ms range', () {
      // 600 ms lead — outside the previous ±400 ms search, inside the new
      // ±800 ms default. Proves the widened range catches high-latency calls.
      final est = AecDelayEstimator(minNearStd: 0.5);
      final far = whiteEnvelope(800, 11);
      final rnd = math.Random(12);
      const delayBins = 60; // near[i] = far[i-60] → far leads by 600 ms
      for (var bin = 0; bin < far.length; bin++) {
        final t = bin * 10;
        est.addFar(t, far[bin]);
        final src = bin - delayBins;
        final near = src >= 0
            ? far[src] * 0.5 + rnd.nextDouble() * 50
            : rnd.nextDouble() * 50;
        est.addNear(t, near);
      }
      final e = est.estimate();
      expect(e, isNotNull);
      expect(e!.lagMs, closeTo(600, 20));
    });
  });

  group('AecDelayEstimator.recencyWeightedMedianLagMs', () {
    AecDelayEstimate at(int lag) =>
        AecDelayEstimate(lagMs: lag, confidence: 1);

    test('empty list is zero', () {
      expect(AecDelayEstimator.recencyWeightedMedianLagMs([]), 0);
    });

    test('a single stale outlier cannot swing the result', () {
      // Three agreeing 100 ms estimates outweigh one newer 500 ms outlier.
      final lag = AecDelayEstimator.recencyWeightedMedianLagMs(
        [at(100), at(100), at(100), at(500)],
      );
      expect(lag, 100);
    });

    test('tracks a genuinely drifting delay toward recent values', () {
      // Older 100s, newer 200s — the recency weighting follows the drift.
      final lag = AecDelayEstimator.recencyWeightedMedianLagMs(
        [at(100), at(100), at(200), at(200), at(200)],
      );
      expect(lag, 200);
    });
  });

  group('AecDelayEstimator.estimateSmoothed / hasRepeatedSupport', () {
    List<double> whiteEnvelope(int bins, int seed) {
      final rnd = math.Random(seed);
      return List<double>.generate(bins, (_) => 200 + rnd.nextDouble() * 4000);
    }

    test('builds repeated support after several agreeing measurements', () {
      final est = AecDelayEstimator(minNearStd: 0.5);
      final far = whiteEnvelope(700, 21);
      final rnd = math.Random(22);
      const delayBins = 8;
      for (var bin = 0; bin < far.length; bin++) {
        final t = bin * 10;
        est.addFar(t, far[bin]);
        final src = bin - delayBins;
        est.addNear(
          t,
          src >= 0 ? far[src] * 0.5 + rnd.nextDouble() * 50 : rnd.nextDouble() * 50,
        );
      }
      expect(est.hasRepeatedSupport, isFalse, reason: 'no measurements yet');
      AecDelayEstimate? last;
      for (var i = 0; i < 3; i++) {
        last = est.estimateSmoothed();
        expect(last, isNotNull);
      }
      expect(last!.lagMs, closeTo(80, 10));
      expect(est.hasRepeatedSupport, isTrue);
    });
  });
}
