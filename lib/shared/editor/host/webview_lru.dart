/// Recency tracker deciding which hidden webview panes stay alive.
///
/// Webview tabs (code-server / browser) each hold a heavyweight platform
/// view, so an editor host keeps only the [maxHidden] most-recently-visible
/// ones mounted while hidden and suspends the rest (their pane is torn down
/// and rebuilt fresh on the next reveal). Pure and identity-agnostic so the
/// eviction decision is unit-testable without mounting the layout.
class WebviewLru<T extends Object> {
  /// Creates a tracker keeping at most [maxHidden] hidden entries alive.
  WebviewLru({required this.maxHidden})
    : assert(maxHidden >= 0, 'negative cap');

  /// How many hidden entries survive eviction (most-recently-visible first).
  final int maxHidden;

  /// Recency order, least-recently-visible first.
  final List<T> _recency = [];

  /// The tracked entries, least-recently-visible first (unmodifiable view).
  List<T> get order => List.unmodifiable(_recency);

  /// Records that [entry] is currently visible, moving it to the
  /// most-recently-visible position.
  void noteVisible(T entry) {
    _recency
      ..remove(entry)
      ..add(entry);
  }

  /// Drops every tracked entry for which [isLive] returns false (closed tabs).
  void prune(bool Function(T entry) isLive) {
    _recency.removeWhere((entry) => !isLive(entry));
  }

  /// Whether [entry] should be suspended: it is hidden and not among the
  /// [maxHidden] most-recently-visible tracked entries. An untracked (never
  /// yet visible) hidden entry is suspended — it holds no live pane to keep.
  bool shouldSuspend(T entry, {required bool isVisible}) {
    if (isVisible) {
      return false;
    }
    final index = _recency.indexOf(entry);
    if (index < 0) {
      return true;
    }
    return index < _recency.length - maxHidden;
  }
}
