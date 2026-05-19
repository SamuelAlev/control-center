import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/messaging_bindings.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
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

/// A one-shot permalink target: `({channelId, messageId})?` set when the route
/// carries a `?m=<id>` deep link (notification tap, copied link, future
/// search). The channel feed consumes it when it matches the open channel and
/// clears it, scrolling to (and anchoring) that message. Uniform path for any
/// "jump to this message" entry point.
class PendingFocusMessageNotifier
    extends Notifier<({String channelId, String messageId})?> {
  @override
  ({String channelId, String messageId})? build() => null;

  /// Sets the pending focus target, or clears it when null.
  void set(({String channelId, String messageId})? value) => state = value;
}

/// Provider for [PendingFocusMessageNotifier].
final pendingFocusMessageProvider =
    NotifierProvider<
      PendingFocusMessageNotifier,
      ({String channelId, String messageId})?
    >(PendingFocusMessageNotifier.new);

/// An "open this agent run" target handed to the messaging IDE from outside it.
///
/// `isSubAgent` decides what opening means: a subagent's work never becomes chat
/// messages, so it opens its own activity tab; a top-level run's activity IS the
/// conversation, so it just brings the chat forward.
typedef PendingAgentRun = ({
  String channelId,
  String agentId,
  String runId,
  String label,
  bool isSubAgent,
});

/// A one-shot run target, set by a surface that cannot open an IDE tab itself
/// (the global sidebar's channel flyout) immediately before navigating to the
/// channel. The IDE claims it on the first build where it matches the open
/// conversation, opens the run, and clears it — the same
/// set-then-claim handshake [pendingFocusMessageProvider] uses for permalinks.
class PendingAgentRunNotifier extends Notifier<PendingAgentRun?> {
  @override
  PendingAgentRun? build() => null;

  /// Sets the pending run target, or clears it when null.
  void set(PendingAgentRun? value) => state = value;
}

/// Provider for [PendingAgentRunNotifier].
final pendingAgentRunProvider =
    NotifierProvider<PendingAgentRunNotifier, PendingAgentRun?>(
      PendingAgentRunNotifier.new,
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
    ref
        .read(channelReadRepositoryProvider)
        .markChannelRead(
          ref.requireWorkspaceId(),
          id,
          ref.read(currentUserIdProvider) ?? '',
        );
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
final workspaceChannelsProvider = StreamProvider.family<List<Channel>, String>((
  ref,
  workspaceId,
) {
  return ref
      .watch(messagingRepositoryProvider)
      .watchChannelsByWorkspace(workspaceId);
});

/// Auto-disposed stream of the `main` conversation's messages for a channel.
///
/// The FULL message list of the channel's `main` conversation (lite wire).
/// Reserved for surfaces that genuinely need every message (review accordions,
/// context meters) — feed surfaces use the windowed,
/// conversation-scoped [channelFeedWindowedProvider] and the server-computed
/// aggregates instead. `main`'s id equals the channel id.
final channelMessagesProvider = StreamProvider.autoDispose
    .family<List<ChannelMessage>, String>((ref, channelId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessages(ref.requireWorkspaceId(), channelId, channelId);
    });

/// One message by id (one-shot). Used for out-of-window lookups (a message
/// scrolled past the feed window); returns the FULL wire shape, segments
/// included.
final messageByIdProvider = FutureProvider.autoDispose
    .family<ChannelMessage?, String>(
      (ref, messageId) => ref
          .watch(messagingRepositoryProvider)
          .getMessageById(ref.requireWorkspaceId(), messageId),
    );

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

/// Per-channel activity signals for a workspace, keyed by channel id — ONE
/// server-computed subscription (`messaging.watchChannelActivity`) for the
/// whole sidebar, replacing one full message-list watch per channel row.
final workspaceChannelActivityProvider = StreamProvider.autoDispose
    .family<Map<String, ChannelActivity>, String>((ref, workspaceId) {
      return ref
          .watch(messagingSummariesPortProvider)
          .watchChannelActivity(workspaceId)
          .map((list) => {for (final a in list) a.channelId: a});
    });

/// The activity signals for one channel in the active workspace, or null
/// while loading / when the channel has no messages yet.
ChannelActivity? _channelActivityOf(Ref ref, String channelId) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  return ref
      .watch(workspaceChannelActivityProvider(workspaceId))
      .value?[channelId];
}

/// Whether a channel has an agent question awaiting the user's answer.
final channelNeedsInputProvider = Provider.autoDispose.family<bool, String>((
  ref,
  channelId,
) {
  return _channelActivityOf(ref, channelId)?.needsInput ?? false;
});

/// Combined live status for a channel row: needsInput > running > idle. Reuses
/// the conversation-scoped run signal (`conversationId == channelId` for chat
/// runs) so it reflects real agent activity, not decoration.
final channelStatusProvider = Provider.autoDispose
    .family<ChannelStatus, String>((ref, channelId) {
      if (ref.watch(channelNeedsInputProvider(channelId))) {
        return ChannelStatus.needsInput;
      }
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId != null) {
        final busy = ref.watch(
          conversationBusyProvider((
            workspaceId: workspaceId,
            conversationId: channelId,
          )),
        );
        if (busy) {
          return ChannelStatus.running;
        }
      }
      return ChannelStatus.idle;
    });

/// Per-channel provisioning status: `provisioning` while the background
/// worktree + overlay + `.mcp.json` setup runs, `ready` when dispatch is
/// unblocked, `failed` when provisioning needs a retry. Derived from the
/// workspace channel stream so it reacts live as the server flips the status.
/// Defaults to `ready` when the channel is not yet in the stream (e.g. the
/// list is still loading) so the composer never blocks on a transient miss.
final channelProvisioningStatusProvider = Provider.autoDispose
    .family<ChannelProvisioningStatus, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final channels = workspaceId != null
          ? ref.watch(workspaceChannelsProvider(workspaceId)).asData?.value
          : ref.watch(channelsProvider).asData?.value;
      final channel = channels?.where((c) => c.id == channelId).firstOrNull;
      return channel?.provisioningStatus ?? ChannelProvisioningStatus.ready;
    });

/// The granular step an in-flight provision is on ("cloning repo X",
/// "setting up agent Y"), or null when idle / unknown — callers fall back to
/// the generic "preparing workspace" label. Same live channel stream as
/// [channelProvisioningStatusProvider].
final channelProvisioningStepProvider = Provider.autoDispose
    .family<ChannelProvisioningStep?, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final channels = workspaceId != null
          ? ref.watch(workspaceChannelsProvider(workspaceId)).asData?.value
          : ref.watch(channelsProvider).asData?.value;
      return channels
          ?.where((c) => c.id == channelId)
          .firstOrNull
          ?.provisioningStep;
    });

/// The user participant's read cursor for a channel (when they last opened
/// it), or null when the channel has never been opened under the user. Local
/// DB stream — cheap, emits immediately.
final channelUserLastReadAtProvider = StreamProvider.autoDispose
    .family<DateTime?, String>((ref, channelId) {
      // Only open the read-cursor subscription for a channel that actually
      // belongs to the active workspace, and subscribe AGAINST that same
      // workspace id. The server rejects a cross-workspace `channel_id`
      // (WorkspaceMismatchException → sub error), so gating on the workspace's
      // own channel list means we never ask about a foreign, deleted, or
      // not-yet-loaded channel, and we re-subscribe reactively the moment the
      // channel appears in the list. Threading the SAME `workspaceId` into the
      // call (rather than letting the RPC client inject its ambient active
      // workspace, which flips independently on a switch) keeps the request
      // self-consistent — the `(workspace_id, channel_id)` pair we validated is
      // exactly the one sent — so a switch can't briefly pair this channel with
      // the newly-active workspace and spam the server log.
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream<DateTime?>.value(null);
      }
      //
      // The channel must match on BOTH its id and its OWN `workspaceId`, not
      // just its presence in the list: the list is the answer to a
      // workspace-scoped subscription, and if that subscription is ever
      // mis-scoped (as it was while `watchChannelsByWorkspace` let the RPC
      // client's ambient workspace decide), presence alone would wave a
      // foreign channel straight through and hand the server a pair it must
      // reject — once per resubscribe, forever. The entity carries its true
      // workspace, so this check stays right regardless.
      final channels = ref
          .watch(workspaceChannelsProvider(workspaceId))
          .asData
          ?.value;
      final known =
          channels?.any(
            (c) => c.id == channelId && c.workspaceId == workspaceId,
          ) ??
          false;
      if (!known) {
        return Stream<DateTime?>.value(null);
      }
      return ref
          .watch(channelReadRepositoryProvider)
          .watchUserLastReadAt(
            workspaceId,
            channelId,
            ref.watch(currentUserIdProvider) ?? '',
          );
    });

/// Whether a channel has agent messages the user hasn't seen yet (the sidebar's
/// notification-dot signal). True only when the user has opened the channel
/// before (a non-null read cursor exists) AND a top-level agent message landed
/// after that cursor. A never-opened channel shows no dot, so legacy rows don't
/// all light up at once. Reads the server-computed activity aggregate — no
/// per-channel message-list subscription.
final channelUnreadProvider = Provider.autoDispose.family<bool, String>((
  ref,
  channelId,
) {
  final lastReadAt = ref.watch(channelUserLastReadAtProvider(channelId)).value;
  if (lastReadAt == null) {
    return false;
  }
  final lastAgentAt = _channelActivityOf(ref, channelId)?.lastAgentMessageAt;
  return lastAgentAt != null && lastAgentAt.isAfter(lastReadAt);
});

/// Count of workspace channels awaiting the user (unanswered agent question) —
/// the "needs attention" badge on the sidebar Conversations entry. One sum
/// over the server-computed activity aggregate.
final workspaceNeedsAttentionCountProvider = Provider.autoDispose
    .family<int, String>((ref, workspaceId) {
      final activity = ref
          .watch(workspaceChannelActivityProvider(workspaceId))
          .value;
      if (activity == null) {
        return 0;
      }
      return activity.values.where((a) => a.needsInput).length;
    });

/// Initial number of messages shown in a channel feed window.
const int kChannelFeedInitialWindow = 60;

/// How many older messages each "load more" reveals.
const int kChannelFeedWindowStep = 60;

/// Upper bound on the feed window so a very long channel can't load unbounded.
const int kChannelFeedMaxWindow = 2000;

/// Identifies one conversation (stream) inside a channel. `main`'s
/// `conversationId` equals the `channelId`.
typedef ConversationRef = ({String channelId, String conversationId});

/// Per-conversation feed window size (newest-N shown). `loadMore()` grows it by
/// [kChannelFeedWindowStep] up to [kChannelFeedMaxWindow]. Keyed by
/// conversation id.
class ChannelFeedWindowNotifier extends Notifier<int> {
  /// Creates a [ChannelFeedWindowNotifier] for [conversationId].
  ChannelFeedWindowNotifier(this.conversationId);

  /// The conversation this window belongs to.
  final String conversationId;

  @override
  int build() => kChannelFeedInitialWindow;

  /// Reveals an older page of messages.
  void loadMore() {
    state = (state + kChannelFeedWindowStep).clamp(
      kChannelFeedInitialWindow,
      kChannelFeedMaxWindow,
    );
  }
}

/// Provides the per-conversation feed window size (keyed by conversation id).
final channelFeedWindowProvider =
    NotifierProvider.family<ChannelFeedWindowNotifier, int, String>(
      ChannelFeedWindowNotifier.new,
    );

/// Windowed message feed for a conversation: the newest N messages (N = the
/// conversation's window size) plus whether older messages exist beyond it.
final channelFeedWindowedProvider = StreamProvider.autoDispose
    .family<({List<ChannelMessage> messages, bool hasMore}), ConversationRef>((
      ref,
      ref2,
    ) {
      final limit = ref.watch(channelFeedWindowProvider(ref2.conversationId));
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessagesWindow(
            ref.requireWorkspaceId(),
            ref2.channelId,
            ref2.conversationId,
            limit: limit,
          );
    });

/// Auto-disposed stream of participants for a channel.

final channelParticipantsProvider = StreamProvider.autoDispose
    .family<List<ChannelParticipant>, String>((ref, channelId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchParticipants(ref.requireWorkspaceId(), channelId);
    });

/// Sidebar-visible channels (all workspaces), excluding pipeline-managed
/// (hidden) ones and PR-workbench channels (which need the workspace-scoped
/// activity aggregate to know whether they've been messaged — without an
/// active workspace they stay hidden). Used as the fallback when no active
/// workspace is resolved.
final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  return ref
      .watch(channelsProvider)
      .maybeWhen(
        data: (channels) => channels
            .where((c) => c.pipelineRunId == null && !c.origin.isPrWorkbench)
            .toList(),
        orElse: () => const [],
      );
});

/// Workspace-scoped sidebar-visible channels, excluding pipeline-managed
/// (hidden) ones and never-messaged PR-workbench channels.
///
/// A PR-workbench channel is minted the moment any PR surface (chat/terminal/
/// files) needs a worktree anchor — merely opening a PR must not clutter the
/// sidebar. It surfaces once someone actually messages in it (the server-
/// computed activity aggregate reports a non-null `lastMessageAt`), i.e. once
/// the user engaged an agent on that PR.
final workspaceVisibleChannelsProvider = Provider.family<List<Channel>, String>((
  ref,
  workspaceId,
) {
  final activity = ref
      .watch(workspaceChannelActivityProvider(workspaceId))
      .value;
  return ref
      .watch(workspaceChannelsProvider(workspaceId))
      .maybeWhen(
        data: (channels) => channels.where((c) {
          if (c.pipelineRunId != null) {
            return false;
          }
          if (c.origin.isPrWorkbench) {
            // Hidden while the aggregate is still loading too — a brief delay
            // before an interacted PR channel appears beats a flash of clutter.
            return activity?[c.id]?.lastMessageAt != null;
          }
          return true;
        }).toList(),
        orElse: () => const [],
      );
});

/// Notifier that exposes the [Mode] of the currently selected
/// channel and lets the UI mutate it via [setMode].
///
/// Reactive: changing the mode in the DB triggers a re-emission from
/// [channelsProvider], which causes [build] to re-evaluate and the UI
/// to rebuild with the new mode.
class ActiveChannelModeNotifier extends Notifier<Mode> {
  @override
  Mode build() {
    final channelId = ref.watch(selectedChannelIdProvider);
    if (channelId == null) {
      return Mode.chat;
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];
    final ch = channels.where((c) => c.id == channelId).firstOrNull;
    return ch?.mode ?? Mode.chat;
  }

  /// Switches the active channel to the given [mode].
  Future<void> setMode(Mode mode) async {
    final channelId = ref.read(selectedChannelIdProvider);
    if (channelId == null) {
      return;
    }
    await ref
        .read(messagingRepositoryProvider)
        .setChannelMode(ref.requireWorkspaceId(), channelId, mode);
  }
}

/// Provides the [ActiveChannelModeNotifier] instance.
final activeChannelModeProvider =
    NotifierProvider<ActiveChannelModeNotifier, Mode>(
      ActiveChannelModeNotifier.new,
    );

/// Live conversations (streams) inside a channel: `main` + open parentheses.
final channelConversationsProvider = StreamProvider.autoDispose
    .family<List<Conversation>, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const <Conversation>[]);
      }
      return ref
          .watch(conversationRepositoryProvider)
          .watchForChannel(workspaceId: workspaceId, channelId: channelId);
    });

/// The conversation currently shown in a channel's chat pane. Defaults to the
/// channel's `main` conversation (== the channel id). Keyed by channel id;
/// the messaging IDE / PR page set it when the user switches parentheses.
class SelectedConversationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects [conversationId] (null resets to `main`).
  void select(String? conversationId) => state = conversationId;
}

/// Per-channel selected conversation id (null = `main`).
final selectedConversationIdProvider =
    NotifierProvider<SelectedConversationNotifier, String?>(
      SelectedConversationNotifier.new,
    );
