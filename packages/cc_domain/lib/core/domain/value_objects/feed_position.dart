/// A row's place in an append-only, time-stamped stream: when it was
/// created and its insertion sequence (the SQLite `rowid`).
///
/// Read cursors compare positions, never bare times. `created_at` is stored
/// in whole seconds, so several rows share one: a cursor holding only a time
/// would treat a row recorded later in the same second as already seen. The
/// sequence breaks that tie in insertion order.
class FeedPosition {
  /// Creates a [FeedPosition]. [seq] is never negative; 0 marks a cursor
  /// taken over an empty stream (every row of that second still follows it).
  FeedPosition({required this.at, required this.seq}) {
    if (seq < 0) {
      throw ArgumentError.value(seq, 'seq', 'must not be negative');
    }
  }

  /// When the row was created (second resolution).
  final DateTime at;

  /// The row's insertion sequence.
  final int seq;

  /// Whether this position comes strictly after [other].
  bool isAfter(FeedPosition other) =>
      at.isAfter(other.at) || (at.isAtSameMomentAs(other.at) && seq > other.seq);

  /// Wire shape: `{at: ISO-8601, seq: int}`.
  Map<String, Object> toJson() => {'at': at.toUtc().toIso8601String(), 'seq': seq};

  /// Decodes [toJson]'s shape; null when [json] is not one.
  static FeedPosition? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    final seq = json['seq'];
    if (at == null || seq is! num || seq < 0) {
      return null;
    }
    return FeedPosition(at: at, seq: seq.toInt());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedPosition && at.isAtSameMomentAs(other.at) && seq == other.seq;

  @override
  int get hashCode => Object.hash(at.millisecondsSinceEpoch, seq);

  @override
  String toString() => 'FeedPosition(${at.toIso8601String()}, $seq)';
}
