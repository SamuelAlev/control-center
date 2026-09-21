import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/webview_lru.dart';
import 'package:flutter/widgets.dart';

/// Shared editor-host keep-alive / lazy-build over [IndexedStack] leaves.
///
/// Stable [GlobalKey] per tab (identity; [EditorTab] has no `==`). Build only
/// after first visible; reuse hidden bodies; [TickerMode] off when hidden;
/// webview LRU ([WebviewLru.maxHidden]). Call [reconcile] on layout changes.
class EditorBodyHost {
  /// Creates a body host. [_isWebviewKind] identifies the heavyweight webview
  /// kinds subject to LRU suspension; [maxHiddenWebviews] is how many hidden
  /// ones stay mounted.
  EditorBodyHost({required this._isWebviewKind, int maxHiddenWebviews = 2})
    : _webviewLru = WebviewLru<EditorTab>(maxHidden: maxHiddenWebviews);

  final bool Function(String kind) _isWebviewKind;
  final WebviewLru<EditorTab> _webviewLru;

  // Keyed by tab identity (EditorTab has no `==`). Pruned in [reconcile].
  final Map<EditorTab, GlobalKey> _bodyKeys = {};
  final Set<EditorTab> _visitedTabs = Set<EditorTab>.identity();
  final Map<EditorTab, Widget> _contentWidgets =
      Map<EditorTab, Widget>.identity();
  final Map<EditorTab, bool> _contentVisibility =
      Map<EditorTab, bool>.identity();

  /// A stable [GlobalKey] for [tab]'s body (created on first use).
  GlobalKey keyFor(EditorTab tab) => _bodyKeys.putIfAbsent(tab, GlobalKey.new);

  /// Whether [tab] has ever been visible (and thus its body built).
  bool hasVisited(EditorTab tab) => _visitedTabs.contains(tab);

  /// Wraps a tab body with keep-alive, lazy-build, offscreen reuse, TickerMode
  /// and webview suspension.
  ///
  /// [buildContent] runs when the tab is visible or its visibility just
  /// changed. Stable hidden tabs reuse the same widget instance, preventing an
  /// [IndexedStack] rebuild from walking every previously visited body. Visible
  /// tabs still rebuild normally, so provider and host configuration updates
  /// reach the on-screen surface.
  ///
  /// [buildSuspended] renders the lightweight placeholder for an evicted hidden
  /// webview (and falls back to an empty box when omitted).
  Widget wrap(
    EditorTab tab, {
    required bool isVisible,
    required Color background,
    required Widget Function() buildContent,
    Widget Function()? buildSuspended,
  }) {
    if (isVisible) {
      _visitedTabs.add(tab);
      if (_isWebviewKind(tab.kind)) {
        _webviewLru.noteVisible(tab);
      }
    }
    final visited = _visitedTabs.contains(tab);
    // Hidden webviews beyond the LRU cap are suspended: the heavyweight platform
    // view is torn down and replaced by a lightweight placeholder, then rebuilt
    // fresh when the tab is next focused.
    final suspended =
        _isWebviewKind(tab.kind) &&
        _webviewLru.shouldSuspend(tab, isVisible: isVisible);
    final content = switch ((suspended, visited)) {
      (true, _) => buildSuspended?.call() ?? const SizedBox.shrink(),
      (false, true) => _contentFor(
        tab,
        isVisible: isVisible,
        buildContent: buildContent,
      ),
      _ => const SizedBox.shrink(),
    };
    // TickerMode sits inside the KeyedSubtree so GlobalKey reparenting across
    // pane moves keeps the element, while a hidden tab's animations and tickers
    // stop burning frames.
    return KeyedSubtree(
      key: keyFor(tab),
      child: TickerMode(
        enabled: isVisible,
        child: ColoredBox(color: background, child: content),
      ),
    );
  }

  Widget _contentFor(
    EditorTab tab, {
    required bool isVisible,
    required Widget Function() buildContent,
  }) {
    final previousVisibility = _contentVisibility[tab];
    final cached = _contentWidgets[tab];
    if (cached != null && !isVisible && previousVisibility == isVisible) {
      return cached;
    }

    final content = buildContent();
    _contentWidgets[tab] = content;
    _contentVisibility[tab] = isVisible;
    return content;
  }

  /// Drops keep-alive entries for tabs no longer in [liveTabs] (from
  /// `EditorLayoutController.allTabs()`). The caller is responsible for tearing
  /// down feature-specific per-tab resources for the same removed set.
  void reconcile(Iterable<EditorTab> liveTabs) {
    final live = Set<EditorTab>.identity()..addAll(liveTabs);
    _bodyKeys.removeWhere((tab, _) => !live.contains(tab));
    _visitedTabs.removeWhere((tab) => !live.contains(tab));
    _contentWidgets.removeWhere((tab, _) => !live.contains(tab));
    _contentVisibility.removeWhere((tab, _) => !live.contains(tab));
    _webviewLru.prune(live.contains);
  }
}

/// Lightweight placeholder shown for a suspended (LRU-evicted) hidden webview
/// tab. The heavyweight platform view is torn down while suspended; selecting
/// the tab rebuilds the pane fresh — server-side sessions (code-server) survive,
/// so the editor reattaches rather than losing work.
class EditorSuspendedPane extends StatelessWidget {
  /// Creates a suspended-pane placeholder showing [icon].
  const EditorSuspendedPane({super.key, required this.icon});

  /// The placeholder icon (kind-specific, chosen by the host).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: t.fgQuaternary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.paneSuspendedCaption,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: t.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
