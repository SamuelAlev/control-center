import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width tolerance, in logical pixels, inside which a stored extent still
/// answers a lookup. Sub-pixel column jitter (a scrollbar fading, fractional
/// device pixel ratios) must not throw away every measurement in the feed.
const double kFeedHeightWidthTolerance = 0.5;

/// Bounded LRU of feed row heights, keyed by a globally unique row key.
///
/// A row key carries the message id it renders (for example
/// `seg:<messageId>:3`), so an entry survives the row moving to another list
/// index — the reason this exists beside `SuperListView`'s own extent list,
/// which is keyed by index and forgets everything when rows shift.
///
/// Each entry holds up to two values: a `measured` extent taken from real
/// layout and an `estimated` extent from text measurement. Both are tagged
/// with the width they were taken at; the entry carries one content
/// `revision`. A lookup hits only when the revision matches exactly and the
/// width is within [kFeedHeightWidthTolerance]. Recording a value at a new
/// revision drops the other value (it describes stale content); recording at
/// the same revision leaves it alone.
///
/// The LRU touch is O(1): one insertion-ordered [Map], with a hit removed and
/// reinserted so the least recently used key is always first.
class FeedHeightCache {
  /// Creates a cache holding at most [maxEntries] row keys.
  ///
  /// Throws an [ArgumentError] when [maxEntries] is not positive.
  FeedHeightCache({this.maxEntries = 20000}) {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'must be positive');
    }
  }

  /// Maximum number of row keys held before the least recently used is
  /// evicted.
  final int maxEntries;

  final Map<String, _HeightEntry> _entries = <String, _HeightEntry>{};

  /// Number of row keys currently cached.
  int get length => _entries.length;

  /// The measured extent of [key] at [width] and [revision], or null.
  ///
  /// A hit refreshes the key's recency.
  double? measured(String key, {required double width, required int revision}) {
    final entry = _touch(key);
    if (entry == null || entry.revision != revision) {
      return null;
    }
    return entry.measured?.at(width);
  }

  /// The last measured extent of [key] at [width], whatever revision it was
  /// measured at, or null. For a stand-in that only needs a good guess (a
  /// message scrolled past before and unloaded since).
  double? lastMeasured(String key, {required double width}) =>
      _touch(key)?.measured?.at(width);

  /// The estimated extent of [key] at [width] and [revision], or null.
  ///
  /// A hit refreshes the key's recency.
  double? estimated(
    String key, {
    required double width,
    required int revision,
  }) {
    final entry = _touch(key);
    if (entry == null || entry.revision != revision) {
      return null;
    }
    return entry.estimated?.at(width);
  }

  /// Stores [extent] as the measured height of [key] at [width] and
  /// [revision].
  ///
  /// Keeps an existing estimate of the same revision; a different revision
  /// replaces the whole entry.
  void recordMeasured(
    String key,
    double extent, {
    required double width,
    required int revision,
  }) {
    _entryFor(key, revision).measured = _SizedExtent(extent, width);
  }

  /// Stores [extent] as the estimated height of [key] at [width] and
  /// [revision].
  ///
  /// Keeps an existing measurement of the same revision; a different revision
  /// replaces the whole entry.
  void recordEstimated(
    String key,
    double extent, {
    required double width,
    required int revision,
  }) {
    _entryFor(key, revision).estimated = _SizedExtent(extent, width);
  }

  /// Drops both values stored for [key].
  void invalidate(String key) => _entries.remove(key);

  /// Drops every entry.
  void clear() => _entries.clear();

  _HeightEntry? _touch(String key) {
    final entry = _entries.remove(key);
    if (entry != null) {
      _entries[key] = entry;
    }
    return entry;
  }

  _HeightEntry _entryFor(String key, int revision) {
    var entry = _entries.remove(key);
    if (entry == null || entry.revision != revision) {
      entry = _HeightEntry(revision);
    }
    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return entry;
  }
}

/// One cached row: the content revision and up to two extents.
class _HeightEntry {
  _HeightEntry(this.revision);

  final int revision;
  _SizedExtent? measured;
  _SizedExtent? estimated;
}

/// An extent and the width it was taken at.
class _SizedExtent {
  const _SizedExtent(this.extent, this.width);

  final double extent;
  final double width;

  double? at(double width) =>
      (width - this.width).abs() <= kFeedHeightWidthTolerance ? extent : null;
}

/// The process-wide feed height cache.
///
/// Global rather than per-space so heights survive leaving and re-entering a
/// conversation; row keys embed message ids, so spaces cannot collide.
final feedHeightCacheProvider = Provider<FeedHeightCache>(
  (ref) => FeedHeightCache(),
);
