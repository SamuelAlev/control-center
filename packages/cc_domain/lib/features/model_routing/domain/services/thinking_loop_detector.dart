/// Detects degenerate reasoning loops — an agent re-emitting the same intent
/// with cosmetic drift, burning tokens indefinitely.
/// Two independent signals; **either** firing flags a loop:
///   1. *Verbatim tail repeat* — a short unit repeated ≥4× over ≥180 chars at
///      the tail of the rolling 250-char window.
///   2. *Near-duplicate paragraphs* — ≥4 of the last 16 substantial segments
///      are ≥0.8 Jaccard-similar (trigram shingles), after an 8-segment warm-up.
///
/// Feed streamed thinking deltas to [push]; a non-null return is the loop
/// reason and the caller should abort the turn with a retryable empty error so
/// it is dropped and re-sampled.
class ThinkingLoopDetector {
  /// Creates a [ThinkingLoopDetector]. Pass `enabled: false` to no-op.
  ThinkingLoopDetector({this.enabled = true});

  /// Whether detection is active.
  final bool enabled;

  // --- verbatim tail-repeat tuning ---
  static const int _verbatimTailWindow = 250;
  static const int _verbatimMinRepeatedChars = 180;
  static const int _verbatimMaxUnit = 60;

  // --- segment Jaccard tuning ---
  static const int _segmentCharCap = 700;
  static const int _segmentMinNormChars = 60;
  static const int _segmentWindow = 16;
  static const double _segmentSimilarity = 0.8;
  static const int _segmentMinCount = 8;
  static const int _segmentMinCluster = 4;

  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _backtick = RegExp(r'`([^`]*)`');
  static final RegExp _nonAlnum = RegExp('[^a-z0-9]+');
  static final RegExp _wordHasLetter = RegExp('[a-z]');

  final StringBuffer _tail = StringBuffer();
  final StringBuffer _segment = StringBuffer();
  final List<Set<String>> _recent = [];
  int _segmentCount = 0;

  /// Feeds a streamed thinking [delta]. Returns a loop reason, or null.
  String? push(String delta) {
    if (!enabled || delta.isEmpty) {
      return null;
    }

    // Verbatim tail.
    _tail.write(delta);
    var tail = _tail.toString();
    if (tail.length > _verbatimTailWindow) {
      tail = tail.substring(tail.length - _verbatimTailWindow);
      _tail
        ..clear()
        ..write(tail);
    }
    if (_verbatimRepeat(tail)) {
      return 'verbatim tail repeated';
    }

    // Segment accumulation.
    _segment.write(delta);
    while (true) {
      final buf = _segment.toString();
      final breakAt = buf.indexOf('\n\n');
      String chunk;
      if (breakAt >= 0) {
        chunk = buf.substring(0, breakAt);
        final rest = buf.substring(breakAt + 2);
        _segment
          ..clear()
          ..write(rest);
      } else if (buf.length >= _segmentCharCap) {
        chunk = buf;
        _segment.clear();
      } else {
        break;
      }
      final reason = _ingestSegment(chunk);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }

  /// Flushes the trailing partial segment at stream end. Returns a reason if the
  /// final segment completes a loop, else null.
  String? flush() {
    if (!enabled) {
      return null;
    }
    final tail = _segment.toString();
    _segment.clear();
    if (tail.isEmpty) {
      return null;
    }
    return _ingestSegment(tail);
  }

  bool _verbatimRepeat(String tail) {
    for (var len = 2; len <= _verbatimMaxUnit && len <= tail.length; len++) {
      final unit = tail.substring(tail.length - len);
      if (!_hasLetter.hasMatch(unit)) {
        continue;
      }
      var count = 0;
      var pos = tail.length;
      while (pos >= len && tail.substring(pos - len, pos) == unit) {
        count++;
        pos -= len;
      }
      if (count >= 4 && len * count >= _verbatimMinRepeatedChars) {
        return true;
      }
    }
    return false;
  }

  /// Ingests a segment, first splitting any oversized chunk into ≤cap pieces so
  /// one huge unbroken segment fingerprints the same way the reference's
  /// incremental flushing would (it never lets a segment exceed the cap).
  String? _ingestSegment(String raw) {
    if (raw.length > _segmentCharCap) {
      for (var i = 0; i < raw.length; i += _segmentCharCap) {
        final end = (i + _segmentCharCap) < raw.length
            ? i + _segmentCharCap
            : raw.length;
        final reason = _ingestOne(raw.substring(i, end));
        if (reason != null) {
          return reason;
        }
      }
      return null;
    }
    return _ingestOne(raw);
  }

  String? _ingestOne(String raw) {
    final normalized = _normalize(raw);
    if (normalized.length < _segmentMinNormChars) {
      return null;
    }
    final fingerprint = _trigramShingles(normalized);
    var cluster = 1;
    for (final prev in _recent) {
      if (_jaccard(fingerprint, prev) >= _segmentSimilarity) {
        cluster++;
      }
    }
    _recent.add(fingerprint);
    if (_recent.length > _segmentWindow) {
      _recent.removeAt(0);
    }
    _segmentCount++;
    if (_segmentCount >= _segmentMinCount && cluster >= _segmentMinCluster) {
      return 'paragraph near-duplicate cluster';
    }
    return null;
  }

  static String _normalize(String seg) {
    final lower = seg.toLowerCase();
    final unticked = lower.replaceAllMapped(_backtick, (m) => ' ${m[1]} ');
    final spaced = unticked.replaceAll(_nonAlnum, ' ');
    return spaced
        .split(RegExp(r'\s+'))
        .where(_wordHasLetter.hasMatch)
        .join(' ');
  }

  static Set<String> _trigramShingles(String normalized) {
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 3) {
      return words.isEmpty ? <String>{} : {words.join(' ')};
    }
    final out = <String>{};
    for (var i = 0; i + 3 <= words.length; i++) {
      out.add('${words[i]} ${words[i + 1]} ${words[i + 2]}');
    }
    return out;
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }
    var intersection = 0;
    for (final x in a) {
      if (b.contains(x)) {
        intersection++;
      }
    }
    final union = a.length + b.length - intersection;
    return union == 0 ? 0 : intersection / union;
  }
}
