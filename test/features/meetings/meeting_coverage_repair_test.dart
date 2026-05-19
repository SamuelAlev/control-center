import 'package:cc_domain/features/meetings/domain/services/meeting_coverage_repair.dart';
import 'package:flutter_test/flutter_test.dart';

Span _s(int a, int b) => (startMs: a, endMs: b);

void main() {
  group('mergeSpans', () {
    test('sorts and merges overlapping/adjacent spans, drops empties', () {
      final merged = mergeSpans([_s(100, 200), _s(0, 0), _s(190, 300), _s(500, 600)]);
      expect(merged, [_s(100, 300), _s(500, 600)]);
    });
  });

  group('speechCoverageRatio', () {
    test('no speech → fully covered (nothing to repair)', () {
      expect(speechCoverageRatio(const [], const []), 1.0);
    });

    test('full coverage → 1.0', () {
      expect(speechCoverageRatio([_s(0, 1000)], [_s(0, 1000)]), 1.0);
    });

    test('half covered → 0.5', () {
      expect(speechCoverageRatio([_s(0, 1000)], [_s(0, 500)]), 0.5);
    });

    test('overlapping covered spans never double-count past the speech span', () {
      // Two covered spans both overlap the same speech region; ratio stays ≤ 1.
      expect(
        speechCoverageRatio([_s(0, 1000)], [_s(0, 600), _s(400, 1000)]),
        1.0,
      );
    });

    test('coverage outside the speech span does not inflate the ratio', () {
      expect(speechCoverageRatio([_s(0, 1000)], [_s(2000, 5000)]), 0.0);
    });
  });

  group('uncoveredSpeechRegions', () {
    test('returns the gap between covered segments when long enough', () {
      final gaps = uncoveredSpeechRegions(
        [_s(0, 5000)],
        [_s(0, 1000), _s(3000, 5000)],
      );
      expect(gaps, [_s(1000, 3000)]);
    });

    test('drops gaps shorter than minRegionMs', () {
      final gaps = uncoveredSpeechRegions(
        [_s(0, 5000)],
        [_s(0, 2500), _s(2800, 5000)], // 300ms gap < 800ms default
      );
      expect(gaps, isEmpty);
    });

    test('a fully-uncovered speech span is one region', () {
      expect(uncoveredSpeechRegions([_s(1000, 4000)], const []), [_s(1000, 4000)]);
    });

    test('leading and trailing uncovered tails are both surfaced', () {
      final gaps = uncoveredSpeechRegions([_s(0, 5000)], [_s(2000, 3000)]);
      expect(gaps, [_s(0, 2000), _s(3000, 5000)]);
    });
  });

  group('shouldRepairCoverage', () {
    test('repairs when coverage is below the floor AND there is a gap', () {
      expect(
        shouldRepairCoverage(ratio: 0.4, uncovered: [_s(0, 1000)]),
        isTrue,
      );
    });

    test('skips when coverage is healthy', () {
      expect(
        shouldRepairCoverage(ratio: 0.9, uncovered: [_s(0, 1000)]),
        isFalse,
      );
    });

    test('skips when there is no re-decodable gap even if coverage is low', () {
      expect(shouldRepairCoverage(ratio: 0.1, uncovered: const []), isFalse);
    });
  });
}
