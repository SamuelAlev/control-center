/// The live navigation state of a browser rig: what the address bar shows and
/// whether there is anywhere to go back or forward to.
///
/// Read on demand from the browser itself (the session history is the
/// authority), not persisted: back/forward reachability is a property of the
/// live page session and is meaningless once the rig is gone. The URL alone
/// is ALSO carried on the rig row (`Rig.currentUrl`) so watchers see
/// navigations as they happen without polling this.
class RigBrowserState {
  /// Creates a [RigBrowserState].
  const RigBrowserState({
    required this.url,
    required this.canGoBack,
    required this.canGoForward,
    this.loading = false,
  });

  /// The current page URL, empty when unknown.
  final String url;

  /// Whether the session history has an entry before this one.
  final bool canGoBack;

  /// Whether the session history has an entry after this one.
  final bool canGoForward;

  /// Whether the main frame is mid-load — the toolbar's reload button
  /// becomes a stop button for as long as this holds.
  final bool loading;

  /// The wire form for the `rig.browserState` op.
  Map<String, dynamic> toJson() => {
    'url': url,
    'can_go_back': canGoBack,
    'can_go_forward': canGoForward,
    'loading': loading,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigBrowserState &&
          other.url == url &&
          other.canGoBack == canGoBack &&
          other.canGoForward == canGoForward &&
          other.loading == loading;

  @override
  int get hashCode => Object.hash(url, canGoBack, canGoForward, loading);

  @override
  String toString() =>
      'RigBrowserState($url, back: $canGoBack, forward: $canGoForward, '
      'loading: $loading)';
}
