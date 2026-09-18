import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Space ids whose conversation pane is currently mounted.
///
/// A permission prompt renders inside those panes, so the global approval
/// overlay must not also float the same request. Refcounted: split view can
/// mount the same space twice.
class VisibleConversationSpaces extends Notifier<Set<String>> {
  final Map<String, int> _counts = {};
  bool _publishQueued = false;

  @override
  Set<String> build() => const {};

  /// The conversation for [spaceId] is on screen.
  void acquire(String spaceId) {
    if (spaceId.isEmpty) {
      return;
    }
    _counts[spaceId] = (_counts[spaceId] ?? 0) + 1;
    _schedulePublish();
  }

  /// The conversation for [spaceId] left the tree.
  void release(String spaceId) {
    final remaining = (_counts[spaceId] ?? 0) - 1;
    if (remaining <= 0) {
      _counts.remove(spaceId);
    } else {
      _counts[spaceId] = remaining;
    }
    _schedulePublish();
  }

  /// Panes acquire/release from initState/dispose, which run while the parent
  /// (ConversationPane) is still building. Notifying listeners in that window
  /// throws ("Tried to modify a provider while the widget tree was building")
  /// because the approval overlay is already watching this set. Counts stay
  /// synchronous; the published snapshot is a microtask so ProviderScope can
  /// setState again.
  void _schedulePublish() {
    if (_publishQueued) {
      return;
    }
    _publishQueued = true;
    Future.microtask(() {
      _publishQueued = false;
      if (!ref.mounted) {
        return;
      }
      state = {..._counts.keys};
    });
  }
}

/// See [VisibleConversationSpaces].
final visibleConversationSpacesProvider =
    NotifierProvider<VisibleConversationSpaces, Set<String>>(
      VisibleConversationSpaces.new,
    );
