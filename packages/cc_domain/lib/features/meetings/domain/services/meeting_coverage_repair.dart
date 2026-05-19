/// Pure coverage-analysis math for post-meeting transcript repair.
///
/// After a recording stops, offline VAD over the retained audio yields the
/// regions where someone actually spoke. Comparing that to what the live
/// transcript already covers reveals speech the rolling-window transcriber
/// missed (a stalled decode, a dropped window, a model that warmed up late).
/// These helpers decide whether the gap is bad enough to re-decode and which
/// regions to re-transcribe. Pure (no I/O) so the policy is unit-testable; the
/// VAD run + re-decode live in the data/orchestration layers.
library;

/// A half-open time interval `[startMs, endMs)` in milliseconds from audio start.
typedef Span = ({int startMs, int endMs});

int _len(Span s) {
  final d = s.endMs - s.startMs;
  return d > 0 ? d : 0;
}

/// Sorts and merges overlapping/adjacent [spans] into a minimal disjoint set.
List<Span> mergeSpans(List<Span> spans) {
  final valid = spans.where((s) => _len(s) > 0).toList()
    ..sort((a, b) => a.startMs.compareTo(b.startMs));
  final out = <Span>[];
  for (final s in valid) {
    if (out.isNotEmpty && s.startMs <= out.last.endMs) {
      final last = out.removeLast();
      out.add((
        startMs: last.startMs,
        endMs: s.endMs > last.endMs ? s.endMs : last.endMs,
      ));
    } else {
      out.add(s);
    }
  }
  return out;
}

/// Total speech milliseconds in [speech] that overlap a [covered] interval,
/// divided by total speech milliseconds. `1.0` when there is no speech (nothing
/// to repair). Covered spans are merged first so overlapping segments never
/// double-count.
double speechCoverageRatio(List<Span> speech, List<Span> covered) {
  final totalSpeech = speech.fold<int>(0, (a, s) => a + _len(s));
  if (totalSpeech <= 0) {
    return 1;
  }
  final merged = mergeSpans(covered);
  var coveredMs = 0;
  for (final s in speech) {
    for (final c in merged) {
      final lo = s.startMs > c.startMs ? s.startMs : c.startMs;
      final hi = s.endMs < c.endMs ? s.endMs : c.endMs;
      if (hi > lo) {
        coveredMs += hi - lo;
      }
    }
  }
  return coveredMs / totalSpeech;
}

/// The speech regions NOT overlapped by any [covered] interval, keeping only
/// gaps of at least [minRegionMs] (shorter gaps aren't worth a re-decode).
/// Returned in time order.
List<Span> uncoveredSpeechRegions(
  List<Span> speech,
  List<Span> covered, {
  int minRegionMs = 800,
}) {
  final merged = mergeSpans(covered);
  final out = <Span>[];
  for (final s in speech) {
    if (_len(s) <= 0) {
      continue;
    }
    var cursor = s.startMs;
    for (final c in merged) {
      if (c.endMs <= s.startMs || c.startMs >= s.endMs) {
        continue; // no overlap with this speech span
      }
      if (c.startMs > cursor && c.startMs - cursor >= minRegionMs) {
        out.add((startMs: cursor, endMs: c.startMs));
      }
      if (c.endMs > cursor) {
        cursor = c.endMs;
      }
      if (cursor >= s.endMs) {
        break;
      }
    }
    if (cursor < s.endMs && s.endMs - cursor >= minRegionMs) {
      out.add((startMs: cursor, endMs: s.endMs));
    }
  }
  return out;
}

/// Whether the transcript is missing enough speech to warrant a re-decode:
/// coverage below [threshold] AND at least one re-decodable [uncovered] region (default 55% coverage floor).
bool shouldRepairCoverage({
  required double ratio,
  required List<Span> uncovered,
  double threshold = 0.55,
}) => ratio < threshold && uncovered.isNotEmpty;
