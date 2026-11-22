import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart'
    show AttentionDot;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:flutter/widgets.dart';

/// What the messaging IDE's chat tabs show about the open space's
/// conversations, refreshed on every build from the live providers so a
/// rename lands in the tab strip immediately and a thread keeps its badge.
class IdeConversationView {
  /// Creates a view.
  const IdeConversationView({
    this.byId = const {},
    this.standingId,
    this.titleGeneratingIds = const {},
    this.busyIds = const {},
    this.unreadIds = const {},
  });

  /// The open space's conversations by id. Empty until the list arrives.
  final Map<String, Conversation> byId;

  /// The standing conversation id, so the seeded chat tab — which carries no
  /// conversation arg — can still name what it shows.
  final String? standingId;

  /// Conversations whose title is being generated; their tabs scramble.
  final Set<String> titleGeneratingIds;

  /// Conversations with an agent run in flight (a spinner on the tab).
  final Set<String> busyIds;

  /// Conversations with unseen agent messages (the unread dot).
  final Set<String> unreadIds;

  /// How many of the space's conversations are not archived.
  int get activeCount => byId.values.where((c) => !c.isArchived).length;

  /// The conversation a chat [tab] renders, or null while it is still
  /// resolving. A tab with no `conversationId` arg shows the standing
  /// conversation — the one place the two are allowed to differ.
  Conversation? conversationOf(EditorTab tab) {
    if (tab.kind != MessagingTabKinds.chat) {
      return null;
    }
    final id = tab.args['conversationId'] as String? ?? standingId;
    return id == null ? null : byId[id];
  }

  /// A chat tab's header: the conversation's own title. A thread is prefixed
  /// so it can never be mistaken for the stream it was branched from.
  String chatLabel(EditorTab tab, AppLocalizations l10n) {
    final conversation = conversationOf(tab);
    if (conversation == null) {
      return tab.label;
    }
    final name = conversationDisplayName(conversation, l10n);
    return conversation.isThread ? l10n.threadTabTitle(name) : name;
  }

  /// Whether [tab] shows a thread (it wears the branch glyph).
  bool isThreadTab(EditorTab tab) => conversationOf(tab)?.isThread ?? false;

  /// Whether a chat [tab]'s title is being generated.
  bool isScrambling(EditorTab tab) =>
      tab.kind == MessagingTabKinds.chat &&
      titleGeneratingIds.contains(conversationOf(tab)?.id);

  /// A chat tab's activity mark, mirroring the sidebar's conversation row: a
  /// spinner while an agent is working, the accent dot when there are unseen
  /// messages. Null when idle, so the tab keeps its kind icon.
  Widget Function(Color color)? activityLeading(EditorTab tab) {
    final id = conversationOf(tab)?.id;
    if (id == null) {
      return null;
    }
    if (busyIds.contains(id)) {
      return (_) => const CcSpinner(size: 14, strokeWidth: 1.5);
    }
    if (unreadIds.contains(id)) {
      return (_) => const SizedBox.square(
        dimension: 14,
        child: Center(child: AttentionDot(selected: false)),
      );
    }
    return null;
  }

  /// The chat tabs in [tabs] whose conversation has been archived.
  List<EditorTab> archivedTabs(Iterable<EditorTab> tabs) => [
    for (final t in tabs)
      if (t.kind == MessagingTabKinds.chat &&
          (byId[t.args['conversationId']]?.isArchived ?? false))
        t,
  ];
}

/// Mirrors [spaceId]'s ACTIVE [conversations] into chat tabs of [layout]:
/// opening a space opens its conversations in the top tab strip.
///
/// A persisted layout can still carry a conversation archived elsewhere; its
/// tab closes rather than resurrecting an archived stream. A conversation
/// already shown by some chat tab is left alone — including the standing one
/// shown by the no-arg seeded tab. Tabs are added WITHOUT stealing focus
/// ([EditorLayoutController.ensureBackgroundTab]).
void mirrorConversationTabs(
  EditorLayoutController layout, {
  required String spaceId,
  required String standingId,
  required List<Conversation> conversations,
  required IdeConversationView view,
}) {
  final active = conversations
      .where((c) => !c.isArchived)
      .toList(growable: false);
  final open = layout
      .allTabs()
      .where((t) => t.kind == MessagingTabKinds.chat)
      .toList(growable: false);
  for (final t in open) {
    final id = t.args['conversationId'] as String?;
    final conv = id == null ? null : view.byId[id];
    if (conv != null && conv.isArchived) {
      layout.closeTabByIdentity(t);
    }
  }
  bool covered(Conversation c) => open.any(
    (t) =>
        t.args['conversationId'] == c.id ||
        (t.args['conversationId'] == null &&
            t.args['spaceId'] == spaceId &&
            c.id == standingId),
  );
  // The standing conversation goes first (as the no-arg tab, like the seed)
  // so the reversed walk below can insert every other conversation right
  // after the first chat tab and come out in list order.
  final standing = view.byId[standingId];
  if (standing != null && !standing.isArchived && !covered(standing)) {
    layout.ensureBackgroundTab(
      MessagingIdeTabs.chat(spaceId, title: standing.title),
      afterKind: MessagingTabKinds.chat,
    );
  }
  for (final c in active.reversed) {
    if (c.id == standingId || covered(c)) {
      continue;
    }
    layout.ensureBackgroundTab(
      MessagingIdeTabs.chat(spaceId, conversationId: c.id, title: c.title),
      afterKind: MessagingTabKinds.chat,
    );
  }
}

/// Focuses the tab a `?tab=` [key] names, mapping across the standing
/// conversation's two identities: the seeded chat tab carries the space key
/// ([MessagingTabKinds.chatSpaceTabKey]) while a deep link names the
/// conversation id — both mean the same stream, so a miss on one is retried
/// as the other.
///
/// A chat key with no open tab at all re-OPENS it ([openConversation]): the
/// sidebar's conversation rows must keep working after the user closed that
/// conversation's tab. Guarded to conversations that exist in this space and
/// aren't archived; any other stale key keeps the current selection.
void focusIdeTabByKey(
  EditorLayoutController layout,
  String key, {
  required String? spaceId,
  required IdeConversationView view,
  required void Function(String spaceId, String conversationId)
  openConversation,
}) {
  if (focusEditorTabByKey(layout, key) || spaceId == null) {
    return;
  }
  final standingId = view.standingId;
  final spaceKey = MessagingTabKinds.chatSpaceTabKey(spaceId);
  if (standingId != null &&
      key == spaceKey &&
      focusEditorTabByKey(layout, MessagingTabKinds.chatTabKey(standingId))) {
    return;
  }
  if (standingId != null &&
      key == MessagingTabKinds.chatTabKey(standingId) &&
      focusEditorTabByKey(layout, spaceKey)) {
    return;
  }
  if (key == spaceKey) {
    layout.openInActiveLeaf(MessagingIdeTabs.chat(spaceId));
    return;
  }
  final conversationId = MessagingTabKinds.conversationIdFromChatTabKey(key);
  final conv = conversationId == null ? null : view.byId[conversationId];
  if (conv == null || conv.isArchived) {
    return;
  }
  openConversation(spaceId, conv.id);
}

/// The conversation ids of the chat tabs in [tabs], in tab order, per space.
///
/// Each chat tab names its space, so a tab order can never be filed under
/// another space mid-switch. The no-arg tab shows the standing conversation,
/// known ([standingId]) only for the open space ([openSpaceId]); elsewhere it
/// is left out. A conversation shown by two tabs counts once, at its first.
Map<String, List<String>> conversationTabOrders(
  Iterable<EditorTab> tabs, {
  required String? openSpaceId,
  required String? standingId,
}) {
  final orders = <String, List<String>>{};
  for (final tab in tabs) {
    if (tab.kind != MessagingTabKinds.chat) {
      continue;
    }
    final spaceId = tab.args['spaceId'] as String?;
    if (spaceId == null) {
      continue;
    }
    final conversationId =
        tab.args['conversationId'] as String? ??
        (spaceId == openSpaceId ? standingId : null);
    if (conversationId == null) {
      continue;
    }
    final order = orders.putIfAbsent(spaceId, () => []);
    if (!order.contains(conversationId)) {
      order.add(conversationId);
    }
  }
  return orders;
}
