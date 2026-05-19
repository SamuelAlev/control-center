import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/data/services/agent_question_service.dart';
import 'package:control_center/features/messaging/data/services/agent_stream_processor.dart';
import 'package:control_center/features/messaging/data/services/messaging_service.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the active stream registry.

final activeStreamRegistryProvider = Provider<ActiveStreamRegistry>((_) {
  return ActiveStreamRegistry();
});

/// Shared, singleton service backing agent "ask the user a question" forms.
/// The in-process MCP server and the UI resolve the same instance, so a
/// blocked agent's question and the user's answer meet on one pending map.
final agentQuestionServiceProvider = Provider<AgentQuestionService>((ref) {
  return AgentQuestionService(ref.watch(messagingRepositoryProvider));
});

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

/// Provider for the agent stream processor.

final agentStreamProcessorProvider = Provider<AgentStreamProcessor>((ref) {
  return AgentStreamProcessor(
    agentDispatchService: ref.watch(agentDispatchServiceProvider),
    repo: ref.watch(messagingRepositoryProvider),
    streamRegistry: ref.watch(activeStreamRegistryProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provider for the messaging service.

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    ref.watch(messagingRepositoryProvider),
    agentRepo: ref.watch(agentRepositoryProvider),
    agentDispatchService: ref.watch(agentDispatchServiceProvider),
    streamRegistry: ref.watch(activeStreamRegistryProvider),
    streamProcessor: ref.watch(agentStreamProcessorProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
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

/// Workspace-scoped DM channels.
final workspaceDmChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) => channels.where((c) => c.isDm).toList(),
    orElse: () => const [],
  );
});

/// Workspace-scoped group channels.
final workspaceGroupChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) => channels.where((c) => !c.isDm).toList(),
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
