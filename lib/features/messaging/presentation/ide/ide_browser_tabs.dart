import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/messaging/providers/space_browser_tabs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';

/// The open HOST browser tabs (the in-app webview kind) of the messaging IDE,
/// addressed by stable per-session ids so the sidebar's BROWSERS rows can
/// focus and close them.
///
/// Minting the id here (rather than in the tab's args) keeps restored layouts
/// — which never carried one — addressable too. Ids are keyed by tab identity
/// and pruned on every [sync].
class IdeBrowserTabs {
  /// Creates the tab ids over the IDE's current `layout`.
  IdeBrowserTabs({required this._layout});

  final EditorLayoutController Function() _layout;
  final Map<EditorTab, String> _ids = {};
  int _seq = 0;

  /// Prunes ids of tabs that left the tree, mints ids for new browser tabs
  /// and returns the BROWSERS mirror, in tree order.
  List<BrowserTabMirror> sync(AppLocalizations l10n) {
    final all = _layout().allTabs();
    final live = Set<EditorTab>.identity()..addAll(all);
    _ids.removeWhere((tab, _) => !live.contains(tab));
    final tabs = [
      for (final tab in all)
        if (tab.kind == MessagingTabKinds.browser) tab,
    ];
    for (final tab in tabs) {
      _ids.putIfAbsent(tab, () => 'ide-browser-${_seq++}');
    }
    return [
      for (var i = 0; i < tabs.length; i++)
        BrowserTabMirror(
          tabId: _ids[tabs[i]]!,
          // A second host webview reads the same words as the first; the
          // number is the only thing telling the rows — and their × — apart.
          label: i == 0
              ? tabs[i].label
              : l10n.rigLabelNumbered(tabs[i].label, '${i + 1}'),
        ),
    ];
  }

  /// Focuses the browser tab with mirror id [tabId] — a BROWSERS row's tap.
  /// A stale row (its tab already gone) opens a fresh browser, the closest
  /// thing to what the tap asked for.
  void focus(String tabId, AppLocalizations l10n) {
    final layout = _layout();
    final found = layout.focusTab(
      (t) => t.kind == MessagingTabKinds.browser && _ids[t] == tabId,
    );
    if (!found) {
      layout.openInActiveLeaf(MessagingIdeTabs.newBrowser(l10n));
    }
  }

  /// Closes the browser tab with mirror id [tabId] — a BROWSERS row's ×. A
  /// host webview holds no machine and no unsaved work, so the close is
  /// immediate.
  void close(String tabId) {
    for (final entry in _ids.entries) {
      if (entry.value == tabId) {
        _layout().closeTabByIdentity(entry.key);
        return;
      }
    }
  }
}
