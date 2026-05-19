import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/webview_lru.dart';
import 'package:flutter/widgets.dart';

/// Keep-alive / lazy-build machinery shared by every editor host (the messaging
/// IDE and the PR workbench).
///
/// The editor engine renders leaf bodies inside an [IndexedStack], which builds
/// *every* child — offscreen tabs included. Left unmanaged that spawns terminals
/// and heavyweight webviews the moment a layout mounts. This host fixes that
/// without the engine knowing about tab kinds:
///
/// - **Keep-alive**: each tab body lives under a stable [GlobalKey] (tabs are
///   compared by identity, [EditorTab] has no `==`), so moving a tab between
///   panes reparents the live element instead of rebuilding it.
/// - **Lazy build**: a body is only built once its tab has been *visible* at
///   least once; never-seen tabs render nothing until first revealed.
/// - **TickerMode**: hidden tabs stop burning frames (spinners, cursors,
///   implicit animations) while their element is kept alive.
/// - **Webview LRU**: only the [WebviewLru.maxHidden] most-recently-visible
///   hidden webview tabs (code-server / browser) keep their heavyweight platform
///   view mounted; the rest are suspended and rebuilt fresh on reveal.
///
/// Feature-specific per-tab resources (terminal sessions, etc.) stay in the
/// host state; call [reconcile] with the layout's live tabs each time the tree
/// changes so this host prunes its own bookkeeping, then prune yours against
/// the same set.
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

  /// A stable [GlobalKey] for [tab]'s body (created on first use).
  GlobalKey keyFor(EditorTab tab) => _bodyKeys.putIfAbsent(tab, GlobalKey.new);

  /// Whether [tab] has ever been visible (and thus its body built).
  bool hasVisited(EditorTab tab) => _visitedTabs.contains(tab);

  /// Wraps a tab body with keep-alive, lazy-build, TickerMode and webview
  /// suspension. [buildContent] is invoked only when the tab has been visible
  /// and is not suspended; [buildSuspended] renders the lightweight placeholder
  /// for an evicted hidden webview (falls back to an empty box when omitted).
  ///
  /// Side effect: marks [tab] visited and notes webview recency when
  /// [isVisible] — mirrors the engine's build-time visibility signal.
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
    // TickerMode sits INSIDE the KeyedSubtree so GlobalKey reparenting across
    // pane moves keeps the element, while a hidden tab's animations/tickers stop
    // burning frames.
    return KeyedSubtree(
      key: keyFor(tab),
      child: TickerMode(
        enabled: isVisible,
        child: ColoredBox(
          color: background,
          child: suspended
              ? (buildSuspended?.call() ?? const SizedBox.shrink())
              : visited
              ? buildContent()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Drops keep-alive entries for tabs no longer in [liveTabs] (from
  /// `EditorLayoutController.allTabs()`). The caller is responsible for tearing
  /// down feature-specific per-tab resources for the same removed set.
  void reconcile(Iterable<EditorTab> liveTabs) {
    final live = Set<EditorTab>.identity()..addAll(liveTabs);
    _bodyKeys.removeWhere((tab, _) => !live.contains(tab));
    _visitedTabs.removeWhere((tab) => !live.contains(tab));
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
