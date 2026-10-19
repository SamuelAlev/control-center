import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A refcounted set of ids published on a microtask. Backs both
/// [VisibleConversationSpaces] and [VisibleConversations].
abstract class RefcountedIdSet extends Notifier<Set<String>> {
  final Map<String, int> _counts = {};
  bool _publishQueued = false;

  @override
  Set<String> build() => const {};

  /// One more holder shows [id].
  void acquire(String id) {
    if (id.isEmpty) {
      return;
    }
    _counts[id] = (_counts[id] ?? 0) + 1;
    _schedulePublish();
  }

  /// One holder of [id] stopped showing it.
  void release(String id) {
    final remaining = (_counts[id] ?? 0) - 1;
    if (remaining <= 0) {
      _counts.remove(id);
    } else {
      _counts[id] = remaining;
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

/// Space ids whose conversation pane is currently on screen.
///
/// A permission prompt renders inside those panes, so the global approval
/// overlay must not also float the same request. Refcounted: split view can
/// show the same space twice. Only consulted for requests that name no
/// conversation; see [VisibleConversations].
class VisibleConversationSpaces extends RefcountedIdSet {}

/// See [VisibleConversationSpaces].
final visibleConversationSpacesProvider =
    NotifierProvider<VisibleConversationSpaces, Set<String>>(
      VisibleConversationSpaces.new,
    );

/// Conversation ids whose pane is currently on screen.
///
/// A space hosts several conversations, each its own editor tab, and a
/// request that names its conversation is answered inline only in that
/// conversation's pane. A sibling tab of the same space showing does not
/// count: the overlay keeps floating the request until its own pane is up.
class VisibleConversations extends RefcountedIdSet {}

/// See [VisibleConversations].
final visibleConversationsProvider =
    NotifierProvider<VisibleConversations, Set<String>>(
      VisibleConversations.new,
    );

/// Whether [request] is answerable inline in a pane that is on screen, given
/// the visible [spaces] and [conversations].
bool isConfirmationShownInline(
  ConfirmationRequestDto request, {
  required Set<String> spaces,
  required Set<String> conversations,
}) {
  final conversationId = request.conversationId;
  if (conversationId != null && conversationId.isNotEmpty) {
    return conversations.contains(conversationId);
  }
  return request.spaceId.isNotEmpty && spaces.contains(request.spaceId);
}
