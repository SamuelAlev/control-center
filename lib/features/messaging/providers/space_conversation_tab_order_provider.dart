import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The order of one space's conversation tabs in the IDE's tab strip, as
/// conversation ids, so the sidebar can list the conversations the same way.
///
/// The IDE layout owns the tabs and writes through here whenever they change
/// (a drag, an open, a close). Empty until the space's IDE has published one.
class SpaceConversationTabOrderNotifier extends Notifier<List<String>> {
  /// Creates a notifier for [spaceId].
  SpaceConversationTabOrderNotifier(this.spaceId);

  /// The space whose tab order this holds.
  final String spaceId;

  @override
  List<String> build() => const [];

  /// Replaces the order. An unchanged order keeps the old state, so the
  /// sidebar does not rebuild on tab changes that move no conversation.
  void set(List<String> conversationIds) {
    if (!listEquals(state, conversationIds)) {
      state = List.unmodifiable(conversationIds);
    }
  }
}

/// Conversation tab order per space id, maintained by the IDE layout.
final spaceConversationTabOrderProvider =
    NotifierProvider.family<
      SpaceConversationTabOrderNotifier,
      List<String>,
      String
    >(SpaceConversationTabOrderNotifier.new);

/// [conversations] in [tabOrder]: the ones with a tab in tab order, then the
/// rest in their own order.
List<Conversation> orderByConversationTabs(
  List<Conversation> conversations,
  List<String> tabOrder,
) {
  if (tabOrder.isEmpty) {
    return conversations;
  }
  final rank = {for (final (i, id) in tabOrder.indexed) id: i};
  final indexed = conversations.indexed.toList()
    ..sort((a, b) {
      final ra = rank[a.$2.id];
      final rb = rank[b.$2.id];
      if (ra != null && rb != null) {
        return ra.compareTo(rb);
      }
      if (ra != null) {
        return -1;
      }
      if (rb != null) {
        return 1;
      }
      return a.$1.compareTo(b.$1);
    });
  return [for (final (_, c) in indexed) c];
}
