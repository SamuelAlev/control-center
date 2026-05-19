import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_waveform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mixTracksToMono', () {
    test('returns empty for no/empty tracks', () {
      expect(mixTracksToMono(const []), isEmpty);
      expect(mixTracksToMono([Float32List(0), Float32List(0)]), isEmpty);
    });

    test('passes a single track through unchanged', () {
      final t = Float32List.fromList([0.1, -0.2, 0.3]);
      expect(mixTracksToMono([t]), same(t));
    });

    test('sums overlapping samples', () {
      final a = Float32List.fromList([0.2, 0.2, 0.2]);
      final b = Float32List.fromList([0.1, 0.1, 0.1]);
      final mixed = mixTracksToMono([a, b]);
      expect(mixed.length, 3);
      for (final s in mixed) {
        expect(s, closeTo(0.3, 1e-6));
      }
    });

    test('output length is the longest track; shorter contributes silence', () {
      final a = Float32List.fromList([0.5, 0.5]);
      final b = Float32List.fromList([0.1, 0.1, 0.1, 0.1]);
      final mixed = mixTracksToMono([a, b]);
      expect(mixed.length, 4);
      expect(mixed[0], closeTo(0.6, 1e-6));
      expect(mixed[1], closeTo(0.6, 1e-6));
      expect(mixed[2], closeTo(0.1, 1e-6));
      expect(mixed[3], closeTo(0.1, 1e-6));
    });

    test('clips the sum to [-1, 1]', () {
      final a = Float32List.fromList([0.8, -0.8]);
      final b = Float32List.fromList([0.8, -0.8]);
      final mixed = mixTracksToMono([a, b]);
      expect(mixed[0], 1.0);
      expect(mixed[1], -1.0);
    });
  });

  group('peakBuckets', () {
    test('returns empty for empty input or non-positive bucket count', () {
      expect(peakBuckets(Float32List(0), 10), isEmpty);
      expect(peakBuckets(Float32List.fromList([0.5]), 0), isEmpty);
      expect(peakBuckets(Float32List.fromList([0.5]), -1), isEmpty);
    });

    test('produces exactly bucketCount entries even when oversampled', () {
      final samples = Float32List.fromList([0.1, 0.2]);
      expect(peakBuckets(samples, 8).length, 8);
    });

    test('normalizes so the loudest bucket is 1.0', () {
      // Two halves: quiet then loud.
      final samples = Float32List.fromList([0.1, 0.1, 0.5, 0.5]);
      final b = peakBuckets(samples, 2);
      expect(b.length, 2);
      expect(b[0], closeTo(0.2, 1e-6)); // 0.1 / 0.5
      expect(b[1], closeTo(1.0, 1e-6)); // 0.5 / 0.5
    });

    test('takes the peak (max abs) within each bucket', () {
      final samples = Float32List.fromList([0.1, -0.9, 0.2, 0.2]);
      final b = peakBuckets(samples, 2);
      // First bucket peak 0.9, second 0.2 → normalized to 1.0 and ~0.222.
      expect(b[0], closeTo(1.0, 1e-6));
      expect(b[1], closeTo(0.2 / 0.9, 1e-6));
    });

    test('all-silence input yields all zeros (no divide-by-zero)', () {
      final b = peakBuckets(Float32List.fromList([0, 0, 0, 0]), 4);
      expect(b, everyElement(0.0));
    });
  });
}
