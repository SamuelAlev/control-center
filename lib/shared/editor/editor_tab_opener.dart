import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';

/// A stable handle a host editor layout publishes so anything rendered *inside*
/// a tab body can ask for another tab to be opened.
///
/// Deliberately a small mutable-free wrapper around one callback (the same shape
/// as `MessagingIdeActions`): the host builds it ONCE in its state and the
/// closure reads the live layout controller at call time, so the instance stays
/// identity-stable across rebuilds and conversation switches. That is what lets
/// [EditorTabOpenerScope.updateShouldNotify] be a cheap identity check instead of
/// re-notifying every descendant on every frame.
@immutable
class EditorTabOpener {
  /// Creates an opener that forwards to [_open].
  const EditorTabOpener(this._open);

  final void Function(EditorTab tab) _open;

  /// Asks the host to open (or refocus, when the tab carries a
  /// [EditorTab.dedupKey] already present in the tree) [tab].
  void open(EditorTab tab) => _open(tab);
}

/// Publishes an [EditorTabOpener] to a subtree.
///
/// The alternative — threading an `onOpenX` callback from the layout through
/// every intermediate widget down to a chat bubble seven levels deep — couples
/// each of those widgets to a feature they don't otherwise know about. A scope
/// also degrades gracefully: a surface hosted *outside* an editor layout (the
/// dashboard, a dialog, the phone client) simply finds none and falls back to
/// route navigation.
class EditorTabOpenerScope extends InheritedWidget {
  /// Creates an [EditorTabOpenerScope].
  const EditorTabOpenerScope({
    super.key,
    required this.opener,
    required super.child,
  });

  /// The host's opener.
  final EditorTabOpener opener;

  /// The nearest opener, or null when not hosted inside an editor layout.
  static EditorTabOpener? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EditorTabOpenerScope>()
      ?.opener;

  @override
  bool updateShouldNotify(EditorTabOpenerScope oldWidget) =>
      oldWidget.opener != opener;
}
