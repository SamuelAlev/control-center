import 'package:control_center/features/meetings/data/services/meeting_diarization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assignSpeakerByOverlap', () {
    const spans = [
      DiarizedSpan(startMs: 0, endMs: 5000, speaker: 0),
      DiarizedSpan(startMs: 5000, endMs: 10000, speaker: 1),
    ];

    test('returns the speaker whose span the window overlaps most', () {
      // 0–800 is fully inside speaker 0's span.
      expect(assignSpeakerByOverlap(spans, 0, 800), 0);
      // 6000–7000 is fully inside speaker 1's span.
      expect(assignSpeakerByOverlap(spans, 6000, 7000), 1);
    });

    test('a window straddling two spans goes to the dominant one', () {
      // 4000–6000: 1000ms with speaker 0, 1000ms with speaker 1 → tie broken by
      // the first-seen maximum (speaker 0). Shift it so one clearly dominates:
      expect(assignSpeakerByOverlap(spans, 4500, 6000), 1); // 500 vs 1000
      expect(assignSpeakerByOverlap(spans, 4000, 5500), 0); // 1000 vs 500
    });

    test('returns null when nothing overlaps', () {
      expect(assignSpeakerByOverlap(spans, 20000, 21000), isNull);
    });

    test('returns null for empty spans', () {
      expect(assignSpeakerByOverlap(const [], 0, 1000), isNull);
    });

    test('touching-but-not-overlapping boundaries do not count', () {
      // Window [10000,11000) starts exactly where the last span ends.
      expect(assignSpeakerByOverlap(spans, 10000, 11000), isNull);
    });
  });
}
