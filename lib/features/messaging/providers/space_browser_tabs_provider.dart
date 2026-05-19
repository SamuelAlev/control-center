import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A read-mirror entry for one open HOST web-browser tab in a conversation:
/// the stable id the IDE layout minted for the tab, plus its display label
/// (already localized, numbered when the conversation holds more than one).
///
/// Lets the General pane's BROWSERS section list the in-app webview tabs
/// beside the VM browser rigs without reaching into the layout's private
/// state — the same discipline as `TerminalMirror` for terminals.
class BrowserTabMirror {
  /// Creates a [BrowserTabMirror].
  const BrowserTabMirror({required this.tabId, required this.label});

  /// The tab's stable id, minted by the IDE layout (host browser tabs carry
  /// no arg of their own, so the id lives beside the tab, keyed by identity).
  final String tabId;

  /// The tab's display label.
  final String label;
}

/// A read mirror of the open host web-browser tabs for one conversation.
///
/// Tab lifecycle stays owned by the IDE layout; the layout writes through to
/// this provider whenever the live tab set changes, so the General pane's
/// BROWSERS section can list them. Rows focus the tab on tap and close it
/// with the hover ×.
class SpaceBrowserTabsNotifier extends Notifier<List<BrowserTabMirror>> {
  /// Creates a [SpaceBrowserTabsNotifier] for [spaceId].
  SpaceBrowserTabsNotifier(this.spaceId);

  /// The conversation whose browser tabs this tracks.
  final String spaceId;

  @override
  List<BrowserTabMirror> build() => const [];

  /// Replaces the tracked tabs for this conversation.
  void set(List<BrowserTabMirror> tabs) => state = tabs;
}

/// Open host web-browser tabs for a conversation (space id), maintained by
/// the IDE layout.
final spaceBrowserTabsProvider =
    NotifierProvider.family<
      SpaceBrowserTabsNotifier,
      List<BrowserTabMirror>,
      String
    >(SpaceBrowserTabsNotifier.new);
