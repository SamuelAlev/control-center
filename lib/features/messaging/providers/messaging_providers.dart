import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/messaging_bindings.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Shared service backing agent "ask the user a question" forms.
///
/// DECLARED here (web-safe) and RESOLVED through the messaging seam: on the VM
/// the in-process MCP server and the UI resolve the same DB-owning instance, so
/// a blocked agent's question and the user's answer meet on one pending map; on
/// web it answers over RPC (marking the persisted question answered
/// server-side). Reading the RPC-flipped public provider on the VM would cycle
/// (registry → messaging RPC → rpcClient → MCP dispatcher → registry), which is
/// why the VM binding owns the DB directly via dao*.
final agentQuestionServiceProvider = Provider<AgentQuestionService>(
  buildAgentQuestionService,
);

/// Notifier for the currently selected channel ID.

class SelectedChannelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects the given channel [id], or deselects when null.
  void select(String? id) => state = id;
}

/// Provider for the selected channel ID notifier.

final selectedChannelIdProvider =
    NotifierProvider<SelectedChannelNotifier, String?>(
      SelectedChannelNotifier.new,
    );

/// Side effect: stamps the user's read cursor for a channel whenever it becomes
/// selected, so the sidebar's unseen indicator clears on open. Lives in a
/// provider (not in [SelectedChannelNotifier]) so the notifier stays pure and
/// its unit tests don't need a binding/database, and so the write only happens
/// while the sidebar is actually mounted (the provider is watched there).
///
/// The stamp is fire-and-forget and best-effort — a read-cursor write must
/// never block selection or surface an error.
final selectedChannelReadCursorEffectProvider = Provider<void>((ref) {
  ref.listen<String?>(selectedChannelIdProvider, (_, id) {
    if (id == null) {
      return;
    }
    ref.read(channelReadRepositoryProvider).markChannelRead(id);
  });
});

/// Provider for the messaging service (channel lifecycle + agent dispatch),
/// typed as the web-safe [MessagingPort].
///
/// DECLARED here and RESOLVED through the messaging seam: on the VM it builds
/// the real cc_infra `MessagingService` (owning the DB directly via dao* and
/// driving the live `AgentStreamProcessor`); on web it returns an honest "not
/// available on web" stub for the dispatch/streaming actions. The chat UI calls
/// the same `MessagingPort` action methods on both targets.
final messagingServiceProvider = Provider<MessagingPort>(buildMessagingService);

/// Provides the [SendChannelMessageUseCase] used by the composer to post a
/// user message and dispatch mentioned agents. Drives the messaging service
/// (channel lifecycle + agent dispatch) via the [MessagingPort].
final sendChannelMessageUseCaseProvider = Provider<SendChannelMessageUseCase>((
  ref,
) {
  return SendChannelMessageUseCase(ref.watch(messagingServiceProvider));
});

/// Stream of all channels.

final channelsProvider = StreamProvider<List<Channel>>((ref) {
  return ref.watch(messagingRepositoryProvider).watchChannels();
});

/// Workspace-scoped channel stream.
final workspaceChannelsProvider =
    StreamProvider.family<List<Channel>, String>((ref, workspaceId) {
  return ref
      .watch(messagingRepositoryProvider)
      .watchChannelsByWorkspace(workspaceId);
});

/// Auto-disposed stream of messages for a channel.

final channelMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>((ref, channelId) {
      return ref.watch(messagingRepositoryProvider).watchMessages(channelId);
    });

/// Auto-disposed stream of top-level messages for a channel.

final channelTopLevelMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>((ref, channelId) {
      return ref.watch(messagingRepositoryProvider).watchTopLevelMessages(channelId);
    });

/// Per-channel attention status for the conversation list (the fleet-monitor
/// signal: surface running/needs-input state in the nav, not buried a level
/// deep).
enum ChannelStatus {
  /// An agent is waiting on the user (an unanswered question) — actionable.
  needsInput,

  /// An agent run is in flight in this channel.
  running,

  /// Nothing pending.
  idle,
}

/// Whether a channel has an agent question awaiting the user's answer.
final channelNeedsInputProvider = Provider.autoDispose.family<bool, String>((
  ref,
  channelId,
) {
  final messages =
      ref.watch(channelTopLevelMessagesProvider(channelId)).asData?.value;
  if (messages == null) {
    return false;
  }
  return messages.any((m) => m.isUserQuestion && !m.isQuestionAnswered);
});

/// Combined live status for a channel row: needsInput > running > idle. Reuses
/// the conversation-scoped run signal (`conversationId == channelId` for chat
/// runs) so it reflects real agent activity, not decoration.
final channelStatusProvider =
    Provider.autoDispose.family<ChannelStatus, String>((ref, channelId) {
      if (ref.watch(channelNeedsInputProvider(channelId))) {
        return ChannelStatus.needsInput;
      }
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId != null) {
        final busy = ref.watch(
          conversationBusyProvider(
            (workspaceId: workspaceId, conversationId: channelId),
          ),
        );
        if (busy) {
          return ChannelStatus.running;
        }
      }
      return ChannelStatus.idle;
    });

/// The user participant's read cursor for a channel (when they last opened
/// it), or null when the channel has never been opened under the user. Local
/// DB stream — cheap, emits immediately.
final channelUserLastReadAtProvider =
    StreamProvider.autoDispose.family<DateTime?, String>((ref, channelId) {
      return ref
          .watch(channelReadRepositoryProvider)
          .watchUserLastReadAt(channelId);
    });

/// Whether a channel has agent messages the user hasn't seen yet (the sidebar's
/// notification-dot signal). True only when the user has opened the channel
/// before (a non-null read cursor exists) AND a top-level agent message landed
/// after that cursor. A never-opened channel shows no dot, so legacy rows don't
/// all light up at once. Renders from cached DB state first (non-blocking).
final channelUnreadProvider =
    Provider.autoDispose.family<bool, String>((ref, channelId) {
      final lastReadAt = ref
          .watch(channelUserLastReadAtProvider(channelId))
          .value;
      if (lastReadAt == null) {
        return false;
      }
      final messages = ref
          .watch(channelTopLevelMessagesProvider(channelId))
          .value;
      if (messages == null) {
        return false;
      }
      return messages.any(
        (m) =>
            m.senderType == ChannelSenderType.agent &&
            m.createdAt.isAfter(lastReadAt),
      );
    });

/// Count of workspace channels awaiting the user (unanswered agent question) —
/// the "needs attention" badge on the sidebar Conversations entry.
final workspaceNeedsAttentionCountProvider =
    Provider.autoDispose.family<int, String>((ref, workspaceId) {
      final channels =
          ref.watch(workspaceChannelsProvider(workspaceId)).asData?.value ??
          const <Channel>[];
      var count = 0;
      for (final c in channels) {
        if (ref.watch(channelNeedsInputProvider(c.id))) {
          count++;
        }
      }
      return count;
    });

/// Initial number of messages shown in a channel feed window.
const int kChannelFeedInitialWindow = 60;

/// How many older messages each "load more" reveals.
const int kChannelFeedWindowStep = 60;

/// Upper bound on the feed window so a very long channel can't load unbounded.
const int kChannelFeedMaxWindow = 2000;

/// Per-channel feed window size (newest-N shown). `loadMore()` grows it by
/// [kChannelFeedWindowStep] up to [kChannelFeedMaxWindow].
class ChannelFeedWindowNotifier extends Notifier<int> {
  /// Creates a [ChannelFeedWindowNotifier] for [channelId].
  ChannelFeedWindowNotifier(this.channelId);

  /// The channel this window belongs to.
  final String channelId;

  @override
  int build() => kChannelFeedInitialWindow;

  /// Reveals an older page of messages.
  void loadMore() {
    state = (state + kChannelFeedWindowStep)
        .clamp(kChannelFeedInitialWindow, kChannelFeedMaxWindow);
  }
}

/// Provides the per-channel feed window size.
final channelFeedWindowProvider =
    NotifierProvider.family<ChannelFeedWindowNotifier, int, String>(
  ChannelFeedWindowNotifier.new,
);

/// Windowed top-level message feed: the newest N messages (N = the channel's
/// window size) plus whether older messages exist beyond the window.
final channelFeedWindowedProvider = StreamProvider.autoDispose
    .family<({List<ChannelMessage> messages, bool hasMore}), String>(
  (ref, channelId) {
    final limit = ref.watch(channelFeedWindowProvider(channelId));
    return ref
        .watch(messagingRepositoryProvider)
        .watchTopLevelMessagesWindow(channelId, limit: limit);
  },
);

/// Auto-disposed stream of participants for a channel.

final channelParticipantsProvider =
    StreamProvider.autoDispose.family<List<ChannelParticipant>, String>((ref, channelId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchParticipants(channelId);
    });

/// List of direct message channels.

final dmChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(channelsProvider).maybeWhen(
    data: (channels) => channels.where((c) => c.isDm).toList(),
    orElse: () => const [],
  );
});

/// List of group channels.

final groupChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(channelsProvider).maybeWhen(
    data: (channels) => channels.where((c) => !c.isDm).toList(),
    orElse: () => const [],
  );
});

/// Workspace-scoped DM channels, excluding pipeline-managed (hidden) ones.
final workspaceDmChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) =>
        channels.where((c) => c.isDm && c.pipelineRunId == null).toList(),
    orElse: () => const [],
  );
});

/// Workspace-scoped group channels, excluding pipeline-managed (hidden) ones.
final workspaceGroupChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) =>
        channels.where((c) => !c.isDm && c.pipelineRunId == null).toList(),
    orElse: () => const [],
  );
});

/// Notifier that exposes the [ConversationMode] of the currently selected
/// channel and lets the UI mutate it via [setMode].
///
/// Reactive: changing the mode in the DB triggers a re-emission from
/// [channelsProvider], which causes [build] to re-evaluate and the UI
/// to rebuild with the new mode.
class ActiveChannelModeNotifier extends Notifier<ConversationMode> {
  @override
  ConversationMode build() {
    final channelId = ref.watch(selectedChannelIdProvider);
    if (channelId == null) {
      return ConversationMode.chat;
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];
    final ch = channels.where((c) => c.id == channelId).firstOrNull;
    return ch?.mode ?? ConversationMode.chat;
  }

  /// Switches the active channel to the given [mode].
  Future<void> setMode(ConversationMode mode) async {
    final channelId = ref.read(selectedChannelIdProvider);
    if (channelId == null) {
      return;
    }
    await ref.read(messagingRepositoryProvider).setChannelMode(channelId, mode);
  }
}

/// Provides the [ActiveChannelModeNotifier] instance.
final activeChannelModeProvider =
    NotifierProvider<ActiveChannelModeNotifier, ConversationMode>(
      ActiveChannelModeNotifier.new,
    );
/// Notifier for the currently-open thread's parent message ID.
class SelectedThreadNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Open a thread for the given `messageId`, or close by passing null.
  @override
  set state(String? id) => super.state = id;
}

/// Currently-open thread's parent message ID (null = no thread open).
final selectedThreadMessageIdProvider =
    NotifierProvider<SelectedThreadNotifier, String?>(
      SelectedThreadNotifier.new,
    );

/// Watches thread replies for a specific parent message.
final threadMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>(
      (ref, parentMessageId) =>
          ref.watch(messagingRepositoryProvider).watchThread(parentMessageId),
    );

/// Holds reply count and the last reply for a thread parent.
typedef ThreadPreviewData = ({int count, ChannelMessage lastReply});

/// Derived map: parentMessageId → {count, lastReply} for the active channel.
/// Computed from all messages so thread preview bars can show reply metadata.
final threadReplyMapProvider = Provider.autoDispose
    .family<Map<String, ThreadPreviewData>, String>((ref, channelId) {
  final messages = ref.watch(channelMessagesProvider(channelId)).value ?? [];
  final map = <String, List<ChannelMessage>>{};
  for (final m in messages) {
    if (m.parentMessageId != null) {
      map.putIfAbsent(m.parentMessageId!, () => []).add(m);
    }
  }
  return {
    for (final e in map.entries)
      e.key: (
        count: e.value.length,
        lastReply: e.value.last,
      ),
  };
});
