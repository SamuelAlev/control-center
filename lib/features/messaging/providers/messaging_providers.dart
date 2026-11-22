import 'package:cc_data/cc_data.dart'
    show RpcMessagingPort, RpcMessagingRepository;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/services/prompt_history.dart';
import 'package:cc_domain/features/messaging/domain/services/question_answer_submitter.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/features/messaging/providers/space_sidebar_providers.dart';
export 'package:control_center/features/messaging/providers/space_status_providers.dart';
export 'package:control_center/features/messaging/providers/space_unread_providers.dart';

/// Provider for the active stream registry.
///
/// Web-safe: a pure in-memory registry. On the VM the dispatch stack
/// (`AgentStreamProcessor` / `MessagingService`) publishes live agent-turn
/// snapshots into it; on web nothing publishes, so the live-stream view simply
/// reads the empty registry and falls back to the persisted messages (loaded
/// over RPC).
final activeStreamRegistryProvider = Provider<ActiveStreamRegistry>((_) {
  return ActiveStreamRegistry();
});

/// Answers an agent's `ask_user` question on the server.
///
/// The waiter lives in the server process; this only sends the answer and
/// lets the server's refusal propagate, so the form can say why an answer did
/// not count (answered elsewhere, the agent stopped waiting, no repo grant).
final questionAnswerSubmitterProvider = Provider<QuestionAnswerSubmitter>((
  ref,
) {
  final repository = RpcMessagingRepository(ref.watch(rpcClientProvider));
  return QuestionAnswerSubmitter(
    (workspaceId, messageId, metadata) =>
        repository.updateMessage(workspaceId, messageId, metadata: metadata),
  );
});

/// Notifier for the currently selected space ID.

class SelectedSpaceNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects the given space [id], or deselects when null.
  void select(String? id) => state = id;
}

/// Provider for the selected space ID notifier.

final selectedSpaceIdProvider =
    NotifierProvider<SelectedSpaceNotifier, String?>(SelectedSpaceNotifier.new);

/// A one-shot permalink target: `({spaceId, messageId})?` set when the route
/// carries a `?m=<id>` deep link (notification tap, copied link, future
/// search). The space feed consumes it when it matches the open space and
/// clears it, scrolling to (and anchoring) that message. Uniform path for any
/// "jump to this message" entry point.
class PendingFocusMessageNotifier
    extends Notifier<({String spaceId, String messageId})?> {
  @override
  ({String spaceId, String messageId})? build() => null;

  /// Sets the pending focus target, or clears it when null.
  void set(({String spaceId, String messageId})? value) => state = value;
}

/// Provider for [PendingFocusMessageNotifier].
final pendingFocusMessageProvider =
    NotifierProvider<
      PendingFocusMessageNotifier,
      ({String spaceId, String messageId})?
    >(PendingFocusMessageNotifier.new);

/// A transcript row to bring into view: a tool call in a space, and in one
/// conversation of it when the request named one.
typedef PendingToolCallFocus = ({
  String spaceId,
  String? conversationId,
  String toolCallId,
});

/// A one-shot "show this tool call" target, set by the "Show script" link on
/// an approval or a question a script raised. The conversation's feed
/// consumes it when it is on screen, scrolls the row into view and clears it,
/// the way [pendingFocusMessageProvider] works for a message.
class PendingFocusToolCallNotifier extends Notifier<PendingToolCallFocus?> {
  @override
  PendingToolCallFocus? build() => null;

  /// Sets the pending target, or clears it when null.
  void set(PendingToolCallFocus? value) => state = value;
}

/// Provider for [PendingFocusToolCallNotifier].
final pendingFocusToolCallProvider =
    NotifierProvider<PendingFocusToolCallNotifier, PendingToolCallFocus?>(
      PendingFocusToolCallNotifier.new,
    );

/// Provider for the messaging service (space lifecycle + agent dispatch),
/// typed as the web-safe [MessagingPort].
///
/// Every action executes on the connected server over RPC — desktop and web
/// alike; the reply streams back through the existing
/// `messaging.watchMessages` subscription.
final messagingServiceProvider = Provider<MessagingPort>(
  (ref) => RpcMessagingPort(ref.watch(rpcClientProvider)),
);

/// Stream of all spaces.

final spacesProvider = StreamProvider<List<Space>>((ref) {
  return ref.watch(messagingRepositoryProvider).watchSpaces();
});

/// Workspace-scoped space stream.
final workspaceSpacesProvider = StreamProvider.family<List<Space>, String>((
  ref,
  workspaceId,
) {
  return ref
      .watch(messagingRepositoryProvider)
      .watchSpacesByWorkspace(workspaceId);
});

/// Active workspace id once [spaceId] is known to belong to it; else null.
///
/// Space-scoped providers key on space id alone and take workspace from
/// [activeWorkspaceIdProvider]. On a switch the workspace flips one frame
/// before rows unmount, so ungated watches would open `(new workspace, old
/// space)` and get `WorkspaceMismatchException`. Gate on the new workspace's
/// space list (still loading → null) and require both id and
/// [Space.workspaceId]. Callers must pass the returned id on the wire — do not
/// let the RPC client inject ambient workspace.
String? workspaceOwningSpace(Ref ref, String spaceId) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  // A `.select`, not the list: every message bumps its space's `updatedAt`,
  // so the list re-emits constantly, and each per-space subscription gated
  // here would otherwise be torn down and reopened over RPC on every emit.
  // Only a change to the ownership answer itself re-runs the caller.
  final owned = ref.watch(
    workspaceSpacesProvider(workspaceId).select(
      (spaces) =>
          spaces.asData?.value.any(
            (s) => s.id == spaceId && s.workspaceId == workspaceId,
          ) ??
          false,
    ),
  );
  return owned ? workspaceId : null;
}

/// Archived spaces of the workspace, most-recently-archived first — the
/// archived-spaces dialog's list. Restoring one drops it here and returns it
/// to the visible-spaces list (at its recency position — archiving never
/// touched `updatedAt`).
final archivedSpacesProvider = Provider.family<List<Space>, String>((
  ref,
  workspaceId,
) {
  final archived =
      ref
          .watch(workspaceSpacesProvider(workspaceId))
          .maybeWhen(
            data: (spaces) => spaces.where((c) => c.isArchived).toList(),
            orElse: () => const <Space>[],
          )
        ..sort(
          (a, b) => (b.archivedAt ?? b.updatedAt).compareTo(
            a.archivedAt ?? a.updatedAt,
          ),
        );
  return archived;
});

/// Auto-disposed stream of a space's STANDING conversation's messages.
///
/// The FULL message list of that one stream (lite wire). Reserved for surfaces
/// that genuinely need every message (context meters, friction analysis) — feed
/// surfaces use the windowed, conversation-scoped [spaceFeedWindowedProvider]
/// and the server-computed aggregates instead.
///
/// Conversation-scoped ON PURPOSE, and the distinction is load-bearing: a
/// context meter measures what one agent's turn actually carries, so counting
/// the whole room would over-report it by every sibling thread. Surfaces that
/// want the room — the review ones — use [spaceWideMessagesProvider].
///
/// The conversation is RESOLVED, never assumed: it owns its own uuid, so the
/// retired "the main conversation's id IS the space id" shortcut watched a
/// stream that does not exist and these surfaces came back empty.
final spaceMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, spaceId) {
      final conversationId = ref
          .watch(standingConversationIdProvider(spaceId))
          .value;
      if (conversationId == null) {
        return Stream.value(const <Message>[]);
      }
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessages(ref.requireWorkspaceId(), spaceId, conversationId)
          // Deduped, because the subscription re-runs its query on ANY write to
          // `conversation_messages` — a reaction, a read cursor, a message in
          // another conversation of the same space — and re-sends the whole
          // list even when nothing in it changed. Every widget watching this
          // then rebuilt for a snapshot identical to the one it already had;
          // in a review space that is the verdict banner, the accordion and
          // every expanded finding, several times a minute, for nothing.
          //
          // `Message` has full value equality (content and metadata
          // included), so this suppresses only genuinely-identical snapshots —
          // an edit still changes the list and still propagates.
          .distinct(listEquals);
    });

/// Auto-disposed stream of EVERY message in a space, across ALL of its
/// conversations.
///
/// The room, not one thread — the review surfaces' provider. A review space
/// fans out into a stream per reviewer and each files its findings in its own,
/// so the accordion and the verdict banner watching a single conversation
/// would render one reviewer's findings and present them as the review.
///
/// Deliberately separate from [spaceMessagesProvider] rather than a widening of
/// it: the context meters on that provider measure one agent's conversation and
/// would silently over-report if handed the whole room.
final spaceWideMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, spaceId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchSpaceMessages(ref.requireWorkspaceId(), spaceId)
          // Deduped for the same reason as the conversation-scoped watch, and
          // more so here: this subscription re-runs on ANY write in the room,
          // and a review space is the busiest kind there is.
          .distinct(listEquals);
    });

/// The current user's own prompts in one conversation, oldest first — the
/// composer's terminal-style ↑/↓ recall history.
///
/// Computed on the server (`messaging.watchUserPromptHistory`) from this
/// caller's recent text rows. Subscribing to the whole conversation and
/// filtering it here re-sent every message on every write, which is what
/// opening a long thread was paying for an up-arrow.
final conversationUserHistoryProvider = StreamProvider.autoDispose
    .family<List<String>, ({String spaceId, String conversationId})>((
      ref,
      key,
    ) {
      return ref
          .watch(messagingSummariesPortProvider)
          .watchUserPromptHistory(
            ref.requireWorkspaceId(),
            key.spaceId,
            key.conversationId,
          );
    });

/// Extracts the recallable prompt history from a conversation's messages:
/// the given user's plain-text messages, trimmed, without compacted rows
/// (those are folded context, not prompts) and with consecutive duplicates
/// collapsed.
@visibleForTesting
List<String> userHistoryFromMessages(List<Message> messages, String? userId) {
  if (userId == null) {
    return const [];
  }
  // Same collapse the server applies. Kept here so the attribution rules
  // (this user, plain text only) stay next to the tests that pin them.
  return collapsePromptHistory([
    for (final message in messages)
      if (message.senderId == userId && message.messageType == MessageType.text)
        (content: message.content, compacted: message.compacted),
  ]);
}

/// How many of the newest messages the feed keeps subscribed (the live
/// window). Older messages come from the conversation outline and load in
/// ranges around where the reader is (see [spaceFeedRangeProvider]).
const int kSpaceFeedLiveWindow = 60;

/// Messages loaded on each side of a history range's anchor.
const int kSpaceFeedRangeHalf = 60;

/// Identifies one thread's anchor message inside a workspace.
typedef ThreadAnchorKey = ({String workspaceId, String anchorMessageId});

/// Fetches a thread's anchor message by id (workspace-scoped; foreign or
/// missing anchors resolve to null). Used by the thread parent link and the
/// switcher's thread-chip tooltip.
final threadAnchorProvider = FutureProvider.autoDispose
    .family<Message?, ThreadAnchorKey>((ref, key) {
      return ref
          .watch(messagingRepositoryProvider)
          .getMessageById(key.workspaceId, key.anchorMessageId);
    });

/// Identifies one conversation (stream) inside a space.
typedef ConversationRef = ({String spaceId, String conversationId});

/// The live window of a conversation: its newest [kSpaceFeedLiveWindow]
/// messages, plus whether older messages exist beyond it.
final spaceFeedWindowedProvider = StreamProvider.autoDispose
    .family<({List<Message> messages, bool hasMore}), ConversationRef>((
      ref,
      ref2,
    ) {
      const limit = kSpaceFeedLiveWindow;
      // Every emission decodes fresh [Message] instances. Hand back the
      // previous instance for a message that did not change, so the dedupe
      // below and the feed's kept-row check hit `identical` instead of a deep
      // compare per row, and per-instance memos (the parsed transcript)
      // survive an emission that changed some other row.
      var previous = const <String, Message>{};
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessagesWindow(
            ref.requireWorkspaceId(),
            ref2.spaceId,
            ref2.conversationId,
            limit: limit,
          )
          .map((window) {
            final byId = <String, Message>{};
            final messages = <Message>[
              for (final m in window.messages)
                byId[m.id] = switch (previous[m.id]) {
                  final p? when p == m => p,
                  _ => m,
                },
            ];
            previous = byId;
            return (messages: messages, hasMore: window.hasMore);
          })
          // Same dedupe as [spaceMessagesProvider]. A transcript flush that
          // does not change the list projection must not rebuild the feed.
          .distinct(
            (a, b) =>
                a.hasMore == b.hasMore && listEquals(a.messages, b.messages),
          );
    });

/// A history range of a conversation: where the feed loads messages it is
/// showing outside the live window.
typedef FeedRangeKey = ({
  String spaceId,
  String conversationId,
  String anchorId,
});

/// The messages around one anchor in a conversation's history: the anchor
/// and up to [kSpaceFeedRangeHalf] on each side, kept current like the live
/// window. The feed points it at whatever history the reader is looking at
/// (a permalink target, a stretch of placeholders scrolled into view).
final spaceFeedRangeProvider = StreamProvider.autoDispose
    .family<
      ({List<Message> messages, bool hasOlder, bool hasNewer}),
      FeedRangeKey
    >((ref, key) {
      var previous = const <String, Message>{};
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessagesRange(
            ref.requireWorkspaceId(),
            key.spaceId,
            key.conversationId,
            anchorId: key.anchorId,
            before: kSpaceFeedRangeHalf,
            after: kSpaceFeedRangeHalf,
          )
          .map((range) {
            final byId = <String, Message>{};
            final messages = <Message>[
              for (final m in range.messages)
                byId[m.id] = switch (previous[m.id]) {
                  final p? when p == m => p,
                  _ => m,
                },
            ];
            previous = byId;
            return (
              messages: messages,
              hasOlder: range.hasOlder,
              hasNewer: range.hasNewer,
            );
          })
          .distinct(
            (a, b) =>
                a.hasOlder == b.hasOlder &&
                a.hasNewer == b.hasNewer &&
                listEquals(a.messages, b.messages),
          );
    });

/// Every message of a conversation as a size outline (no content): what the
/// feed lays out the history it has not loaded from, so the scrollbar covers
/// the whole conversation. Refreshed by the feed when it falls out of step
/// with the live window.
final conversationOutlineProvider = FutureProvider.autoDispose
    .family<List<ConversationOutlineEntry>, ConversationRef>((ref, key) {
      return ref
          .watch(messagingRepositoryProvider)
          .getConversationOutline(
            ref.requireWorkspaceId(),
            key.spaceId,
            key.conversationId,
          );
    });

/// Auto-disposed stream of participants for a space.

final spaceParticipantsProvider = StreamProvider.autoDispose
    .family<List<SpaceParticipant>, String>((ref, spaceId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchParticipants(ref.requireWorkspaceId(), spaceId);
    });

/// Notifier that exposes the [Mode] of the currently selected
/// space and lets the UI mutate it via [setMode].
///
/// Reactive: changing the mode in the DB triggers a re-emission from
/// [spacesProvider], which causes [build] to re-evaluate and the UI
/// to rebuild with the new mode.
class ActiveSpaceModeNotifier extends Notifier<Mode> {
  @override
  Mode build() {
    final spaceId = ref.watch(selectedSpaceIdProvider);
    if (spaceId == null) {
      return Mode.chat;
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final spaces = workspaceId != null
        ? ref.watch(workspaceSpacesProvider(workspaceId)).value ?? const []
        : ref.watch(spacesProvider).value ?? const [];
    final ch = spaces.where((c) => c.id == spaceId).firstOrNull;
    return ch?.mode ?? Mode.chat;
  }

  /// Switches the active space to the given [mode].
  Future<void> setMode(Mode mode) async {
    final spaceId = ref.read(selectedSpaceIdProvider);
    if (spaceId == null) {
      return;
    }
    await ref
        .read(messagingRepositoryProvider)
        .setSpaceMode(ref.requireWorkspaceId(), spaceId, mode);
  }
}

/// Provides the [ActiveSpaceModeNotifier] instance.
final activeSpaceModeProvider = NotifierProvider<ActiveSpaceModeNotifier, Mode>(
  ActiveSpaceModeNotifier.new,
);

/// Live conversations (streams) inside a space. Conversations are flat equals;
/// one whose `anchorMessageId` is set is a thread.
final spaceConversationsProvider = StreamProvider.autoDispose
    .family<List<Conversation>, String>((ref, spaceId) {
      // Gated on ownership: the sidebar watches this once per space row and
      // stays mounted across a workspace switch, so an ungated read handed the
      // server one rejected `conversation.watchForSpace` per visible space on
      // every switch. See [workspaceOwningSpace].
      final workspaceId = workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream.value(const <Conversation>[]);
      }
      return ref
          .watch(conversationRepositoryProvider)
          .watchForSpace(workspaceId: workspaceId, spaceId: spaceId);
    });

/// Which conversations in a space are having their title generated right now
/// (the automatic pass after the first message). The tab, header and sidebar
/// scramble the label while an id is in here.
///
/// One subscription per space, ownership-gated like
/// [spaceConversationsProvider]. A host without automatic titling has no
/// `conversation.watchTitleGenerating`; that error reads as "none", since the
/// signal is decoration and a missing one must not break the label.
final spaceTitleGeneratingIdsProvider = StreamProvider.autoDispose
    .family<Set<String>, String>((ref, spaceId) {
      final workspaceId = workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream.value(const <String>{});
      }
      return ref
          .watch(conversationTitlePortProvider)
          .watchGenerating(workspaceId: workspaceId, spaceId: spaceId)
          .handleError((Object _) {});
    });

/// Whether the keyed conversation's title is being generated right now.
final conversationTitleGeneratingProvider = Provider.autoDispose
    .family<bool, ({String spaceId, String conversationId})>(
      (ref, key) =>
          ref
              .watch(spaceTitleGeneratingIdsProvider(key.spaceId))
              .asData
              ?.value
              .contains(key.conversationId) ??
          false,
    );

/// The space's STANDING conversation id — its oldest active conversation,
/// minted server-side (titled after the space) when the space has none yet.
///
/// Every surface that opens a space without naming a conversation resolves it
/// here. It cannot be assumed: conversations own their own uuid, so the
/// retired "the main conversation's id IS the space id" shortcut names no row
/// — a feed keyed on it comes back empty and a send against it violates
/// `conversation_messages.conversation_id`'s foreign key.
final standingConversationIdProvider = FutureProvider.autoDispose
    .family<String, String>((ref, spaceId) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        throw StateError('No active workspace to resolve a conversation in');
      }
      // A resolved id is re-derived from the persisted conversation snapshot
      // on revisit; keeping this provider alive would also keep its pending
      // conversation-list revalidation attached after navigation.
      final repository = ref.watch(conversationRepositoryProvider);
      bool owns(List<Space> spaces) => spaces.any(
        (space) => space.id == spaceId && space.workspaceId == workspaceId,
      );
      // The ownership ANSWER, selected: the space list re-emits on every
      // message (each bumps its space's `updatedAt`), and watching its
      // `.future` re-ran this resolution — and flashed every watcher of the
      // open space through loading — once per message.
      final ownership = ref.watch(
        workspaceSpacesProvider(
          workspaceId,
        ).select((spaces) => spaces.whenData(owns)),
      );
      // Only the first load waits on the list itself.
      final spaces = ownership.hasValue || ownership.hasError
          ? null
          : ref.watch(workspaceSpacesProvider(workspaceId).future);
      final conversations = ref.watch(spaceConversationsProvider(spaceId));
      // Resolving an existing chat is a read. The cached conversation list
      // must be enough to open it without waiting for an ensure mutation.
      if (ownership.hasError && !ownership.hasValue) {
        Error.throwWithStackTrace(ownership.error!, ownership.stackTrace!);
      }
      final owned = spaces == null
          ? ownership.requireValue
          : owns(await spaces);
      if (!ref.mounted) {
        throw StateError('Conversation resolution was disposed');
      }
      if (!owned) {
        throw StateError('Space does not belong to the active workspace');
      }
      if (conversations.hasError) {
        Error.throwWithStackTrace(
          conversations.error!,
          conversations.stackTrace!,
        );
      }
      final List<Conversation> rows = conversations.hasValue
          ? conversations.requireValue
          : await ref.watch(spaceConversationsProvider(spaceId).future);
      if (!ref.mounted) {
        throw StateError('Conversation resolution was disposed');
      }
      Conversation? standing;
      for (final candidate in rows) {
        if (candidate.workspaceId != workspaceId ||
            candidate.spaceId != spaceId ||
            candidate.isArchived ||
            candidate.isThread) {
          continue;
        }
        if (standing == null ||
            candidate.createdAt.isBefore(standing.createdAt)) {
          standing = candidate;
        }
      }
      final conversation =
          standing ??
          await repository.ensure(workspaceId: workspaceId, spaceId: spaceId);
      return conversation.id;
    });

/// Live thread rollups for a space, keyed by the message each thread hangs
/// off — what the feed draws its "N replies" row from.
///
/// One subscription per space, not per thread: the indicator has to appear
/// under any message in the open stream that started a thread, and a busy
/// space can hold dozens.
final spaceThreadSummariesProvider = StreamProvider.autoDispose
    .family<Map<String, ThreadSummary>, String>((ref, spaceId) {
      // Ownership-gated for the same reason as [spaceConversationsProvider]:
      // `conversation.watchThreadSummaries` asserts the same pair.
      final workspaceId = workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream.value(const <String, ThreadSummary>{});
      }
      return ref
          .watch(conversationRepositoryProvider)
          .watchThreadSummaries(workspaceId: workspaceId, spaceId: spaceId)
          .map((list) => {for (final t in list) t.anchorMessageId: t});
    });
