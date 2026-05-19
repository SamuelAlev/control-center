/// A Fenwick (binary-indexed) tree over a list of element *heights*, used by
/// the unified diff viewer to map between a file index and its vertical
/// offset in the single continuous scroll space — and back — in O(log n).
///
/// The unified renderer indexes per *file* (not per line): with up to 3000
/// files a per-line index would mean ~150k entries, whereas a per-file tree is
/// 3000 entries and every scroll query stays O(log files). When a file's
/// height changes (collapse/expand, a measured inline-comment block, a gap
/// expand), we point-update one leaf in O(log n) instead of rebuilding a
/// prefix-sum array.
///
/// All offsets are in logical pixels.
class DiffFenwickTree {
  /// Builds a tree from the initial per-element [heights].
  DiffFenwickTree(List<double> heights)
    : _n = heights.length,
      _tree = List<double>.filled(heights.length + 1, 0),
      _heights = List<double>.of(heights) {
    // Linear-time construction: add each height to its parent in the tree.
    for (var i = 1; i <= _n; i++) {
      _tree[i] += _heights[i - 1];
      final parent = i + (i & -i);
      if (parent <= _n) {
        _tree[parent] += _tree[i];
      }
    }
    _total = _heights.fold<double>(0, (a, b) => a + b);
  }

  int _n;
  List<double> _tree; // 1-based
  List<double> _heights; // 0-based mirror, authoritative per-element heights
  double _total = 0;

  /// Number of elements (files) in the tree.
  int get length => _n;

  /// Total height of all elements (the full scroll extent contribution).
  double get total => _total;

  /// Current height of element [index].
  double heightAt(int index) => _heights[index];

  /// Sum of heights for elements `[0, index)` — i.e. the top offset of
  /// element [index]. `offsetOf(0) == 0`, `offsetOf(length) == total`.
  double offsetOf(int index) {
    assert(index >= 0 && index <= _n);
    var sum = 0.0;
    var i = index; // prefix of first `index` elements → query tree index `i`
    while (i > 0) {
      sum += _tree[i];
      i -= i & -i;
    }
    return sum;
  }

  /// Sets element [index]'s height to [height], updating the tree in O(log n).
  void update(int index, double height) {
    assert(index >= 0 && index < _n);
    final delta = height - _heights[index];
    if (delta == 0) {
      return;
    }
    _heights[index] = height;
    _total += delta;
    var i = index + 1; // tree is 1-based
    while (i <= _n) {
      _tree[i] += delta;
      i += i & -i;
    }
  }

  /// Returns the element index whose vertical range contains [offset] —
  /// i.e. the largest `i` such that `offsetOf(i) <= offset`. Clamped to
  /// `[0, length - 1]`. Returns 0 for an empty tree.
  ///
  /// Uses Fenwick binary lifting: O(log n), no per-query allocation.
  int indexAtOffset(double offset) {
    if (_n == 0) {
      return 0;
    }
    if (offset <= 0) {
      return 0;
    }
    if (offset >= _total) {
      return _n - 1;
    }
    var pos = 0; // will become the count of elements fully above `offset`
    var remaining = offset;
    // Highest power of two <= _n.
    var bitMask = _highestBit(_n);
    while (bitMask > 0) {
      final next = pos + bitMask;
      if (next <= _n && _tree[next] <= remaining) {
        pos = next;
        remaining -= _tree[next];
      }
      bitMask >>= 1;
    }
    // `pos` = number of complete elements above `offset` = the index of the
    // element that contains it. Clamp defensively against float drift.
    return pos >= _n ? _n - 1 : pos;
  }

  static int _highestBit(int n) {
    var b = 1;
    while ((b << 1) <= n) {
      b <<= 1;
    }
    return b;
  }

  /// Replaces the whole height vector (e.g. after the file list changes or a
  /// mass collapse/expand). Cheaper than allocating a new tree object since it
  /// reuses the backing arrays when the length is unchanged.
  void rebuild(List<double> heights) {
    if (heights.length != _n) {
      _n = heights.length;
      _tree = List<double>.filled(_n + 1, 0);
      _heights = List<double>.of(heights);
    } else {
      _heights.setAll(0, heights);
      _tree.fillRange(0, _tree.length, 0);
    }
    for (var i = 1; i <= _n; i++) {
      _tree[i] += _heights[i - 1];
      final parent = i + (i & -i);
      if (parent <= _n) {
        _tree[parent] += _tree[i];
      }
    }
    _total = _heights.fold<double>(0, (a, b) => a + b);
  }
}
