import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/messaging_bindings.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter/foundation.dart';
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

/// An "open this agent run" target handed to the messaging IDE from outside it.
///
/// `isSubAgent` decides what opening means: a subagent's work never becomes chat
/// messages, so it opens its own activity tab; a top-level run's activity IS the
/// conversation, so it just brings the chat forward.
typedef PendingAgentRun = ({
  String spaceId,
  String agentId,
  String runId,
  String label,
  bool isSubAgent,
});

/// A one-shot run target, set by a surface that cannot open an IDE tab itself
/// (the global sidebar's space flyout) immediately before navigating to the
/// space. The IDE claims it on the first build where it matches the open
/// conversation, opens the run and clears it — the same
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

/// Side effect: stamps the user's read cursor for a space whenever it becomes
/// selected, so the sidebar's unseen indicator clears on open. Lives in a
/// provider (not in [SelectedSpaceNotifier]) so the notifier stays pure and
/// its unit tests don't need a binding/database and so the write only happens
/// while the sidebar is actually mounted (the provider is watched there).
///
/// The stamp is fire-and-forget and best-effort — a read-cursor write must
/// never block selection or surface an error.
final selectedSpaceReadCursorEffectProvider = Provider<void>((ref) {
  ref.listen<String?>(selectedSpaceIdProvider, (_, id) {
    if (id == null) {
      return;
    }
    ref
        .read(spaceReadRepositoryProvider)
        .markSpaceRead(
          ref.requireWorkspaceId(),
          id,
          ref.read(currentUserIdProvider) ?? '',
        );
  });
});

/// Provider for the messaging service (space lifecycle + agent dispatch),
/// typed as the web-safe [MessagingPort].
///
/// DECLARED here and RESOLVED through the messaging seam: on the VM it builds
/// the real cc_infra `MessagingService` (owning the DB directly via dao* and
/// driving the live `AgentStreamProcessor`); on web it returns an honest "not
/// available on web" stub for the dispatch/streaming actions. The chat UI calls
/// the same `MessagingPort` action methods on both targets.
final messagingServiceProvider = Provider<MessagingPort>(buildMessagingService);

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

/// The active workspace id, but only once [spaceId] is known to belong to it —
/// null while it is not (or not yet) established.
///
/// The gate every space-scoped subscription runs before it reaches the server,
/// because the two halves of the `(workspace_id, space_id)` pair those
/// subscriptions send move INDEPENDENTLY. A space-scoped provider is keyed on
/// a space id alone and takes its workspace from the ambient
/// [activeWorkspaceIdProvider], so on a workspace switch the id flips first and
/// Riverpod recomputes every live space-scoped provider — still keyed on the
/// PREVIOUS workspace's spaces — one frame BEFORE the rebuild that unmounts
/// them. Each of those recomputes opens a subscription for a
/// `(new workspace, old space)` pair the server must reject
/// (`WorkspaceMismatchException` → "Space belongs to a different workspace"),
/// once per surviving row per switch. The persistent shell is what makes this
/// visible: a route-scoped surface is already torn down by then, but the
/// sidebar renders a row per space and stays mounted across the switch, so one
/// switch emits one rejected subscription per visible space.
///
/// Gating on the workspace's OWN space list closes that window: at the moment
/// of the flip the new workspace's list is still loading, so nothing is known
/// to belong to it and no subscription goes out; the rows unmount a frame
/// later and the providers dispose. Nothing is lost by being conservative here
/// — every caller renders "gated" exactly as it renders "still loading" — and
/// the guard is reactive, so a space that legitimately arrives later
/// subscribes the moment it lands in the list.
///
/// The space must match on BOTH its id and its own [Space.workspaceId], not
/// merely on its presence in the list: the list is itself the answer to a
/// workspace-scoped subscription, and if that subscription is ever mis-scoped,
/// presence alone would wave a foreign space straight through. The entity
/// carries its true workspace, so this check stays right regardless.
///
/// Callers MUST thread the returned id into the call rather than letting the
/// RPC client inject its ambient active workspace (which flips on its own
/// schedule), so the pair that was validated is exactly the pair on the wire.
String? _workspaceOwningSpace(Ref ref, String spaceId) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final spaces = ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value;
  final owned =
      spaces?.any((s) => s.id == spaceId && s.workspaceId == workspaceId) ??
      false;
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
/// Sourced from the conversation stream rather than a local "what I typed"
/// log so it survives restarts and includes prompts sent from another
/// surface. Scoped to the CURRENT user: recall is "things I said", and in a
/// multi-member workspace a teammate's prompt has no business resending under
/// your name. Consecutive duplicates collapse (a shell's `ignoredups`), so
/// pressing ↑ steps through distinct prompts.
final conversationUserHistoryProvider = StreamProvider.autoDispose
    .family<List<String>, ({String spaceId, String conversationId})>((
      ref,
      key,
    ) {
      final userId = ref.watch(currentUserIdProvider);
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessages(
            ref.requireWorkspaceId(),
            key.spaceId,
            key.conversationId,
          )
          .map((messages) => userHistoryFromMessages(messages, userId))
          // Same reason as [spaceMessagesProvider]: the subscription re-runs
          // its query on ANY write to `conversation_messages`, and every
          // emission would otherwise rebuild the composer for an identical
          // history.
          .distinct(listEquals);
    });

/// Extracts the recallable prompt history from a conversation's messages:
/// the given user's plain-text messages, trimmed, without compacted rows
/// (those are folded context, not prompts) and with consecutive duplicates
/// collapsed.
@visibleForTesting
List<String> userHistoryFromMessages(List<Message> messages, String? userId) {
  final history = <String>[];
  // The previous prompt in the RAW stream, compacted rows included. Adjacency
  // for dup-collapse is measured against what was actually sent — a compacted
  // row sitting between two identical prompts breaks the run (ignoredups
  // semantics), so folding context away must not silently eat a repeat the
  // user really re-typed later.
  String? previousRaw;
  for (final message in messages) {
    if (userId == null ||
        message.senderId != userId ||
        message.messageType != MessageType.text) {
      continue;
    }
    final content = message.content.trim();
    if (content.isEmpty) {
      continue;
    }
    final duplicate = content == previousRaw;
    previousRaw = content;
    if (message.compacted || duplicate) {
      continue;
    }
    history.add(content);
  }
  return history;
}

/// One message by id (one-shot). Used for out-of-window lookups (a message
/// scrolled past the feed window); returns the FULL wire shape, segments
/// included.
final messageByIdProvider = FutureProvider.autoDispose.family<Message?, String>(
  (ref, messageId) => ref
      .watch(messagingRepositoryProvider)
      .getMessageById(ref.requireWorkspaceId(), messageId),
);

/// Per-space attention status for the conversation list (the fleet-monitor
/// signal: surface running/needs-input state in the nav, not buried a level
/// deep).
enum SpaceStatus {
  /// An agent is waiting on the user (an unanswered question) — actionable.
  needsInput,

  /// An agent run is in flight in this space.
  running,

  /// Nothing pending.
  idle,
}

/// Per-space activity signals for a workspace, keyed by space id — ONE
/// server-computed subscription (`messaging.watchSpaceActivity`) for the
/// whole sidebar, replacing one full message-list watch per space row.
final workspaceSpaceActivityProvider = StreamProvider.autoDispose
    .family<Map<String, SpaceActivity>, String>((ref, workspaceId) {
      return ref
          .watch(messagingSummariesPortProvider)
          .watchSpaceActivity(workspaceId)
          .map((list) => {for (final a in list) a.spaceId: a});
    });

/// The activity signals for one space in the active workspace, or null
/// while loading / when the space has no messages yet.
SpaceActivity? _spaceActivityOf(Ref ref, String spaceId) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  return ref.watch(workspaceSpaceActivityProvider(workspaceId)).value?[spaceId];
}

/// Whether a space has an agent question awaiting the user's answer.
final spaceNeedsInputProvider = Provider.autoDispose.family<bool, String>((
  ref,
  spaceId,
) {
  return _spaceActivityOf(ref, spaceId)?.needsInput ?? false;
});

/// Combined live status for a space row: needsInput > running > idle. Reads
/// the SPACE-scoped run signal — every conversation in the space, threads
/// included — so it reflects real agent activity, not decoration.
final spaceStatusProvider = Provider.autoDispose.family<SpaceStatus, String>((
  ref,
  spaceId,
) {
  if (ref.watch(spaceNeedsInputProvider(spaceId))) {
    return SpaceStatus.needsInput;
  }
  // Ownership-gated: this is a sidebar-row watch, so an ungated read opens a
  // run-log subscription for a `(new workspace, old space)` pair on every
  // workspace switch. See [_workspaceOwningSpace].
  final workspaceId = _workspaceOwningSpace(ref, spaceId);
  if (workspaceId != null) {
    final busy =
        (ref
                    .watch(
                      spaceActiveRunsProvider((
                        workspaceId: workspaceId,
                        spaceId: spaceId,
                      )),
                    )
                    .asData
                    ?.value ??
                const [])
            .isNotEmpty;
    if (busy) {
      return SpaceStatus.running;
    }
  }
  return SpaceStatus.idle;
});

/// Which conversations in a space have an agent run in flight right now.
///
/// Derived from the SPACE-level run stream [spaceStatusProvider] already
/// watches, NOT from one `conversationActiveRunsProvider` per row. The sidebar
/// renders every conversation of every expanded space, so a subscription per
/// row would turn one watch into dozens for a signal the space watch already
/// carries — and each of those is a server subscription, not a local filter.
///
/// A run with no `conversationId` (an older log, or a space-scoped run) is not
/// attributable to a row and is deliberately dropped here: the space row keeps
/// showing it, which is what [spaceStatusProvider] answers.
final spaceBusyConversationIdsProvider = Provider.autoDispose
    .family<Set<String>, String>((ref, spaceId) {
      // Ownership-gated, same as [spaceStatusProvider] — it shares the space
      // run stream, and an unowned pair would open a second one.
      final workspaceId = _workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return const <String>{};
      }
      final runs = ref
          .watch(
            spaceActiveRunsProvider((
              workspaceId: workspaceId,
              spaceId: spaceId,
            )),
          )
          .asData
          ?.value;
      if (runs == null) {
        return const <String>{};
      }
      return {for (final run in runs) ?run.conversationId};
    });

/// When a run last showed a sign of life: its newest of output, completion and
/// start. A pending run has only a start, a streaming one has output, a
/// finished one has all three — so the newest is the honest "this agent was the
/// last to speak here" stamp for every state.
DateTime _runActivityAt(AgentRunLog run) {
  var at = run.startedAt;
  for (final stamp in [run.lastOutputAt, run.completedAt]) {
    if (stamp != null && stamp.isAfter(at)) {
      at = stamp;
    }
  }
  return at;
}

/// The agent whose context window the space header meters.
///
/// A space can hold several agents and the header has room for exactly one
/// reading, so it follows the agent WHOSE TURN IT IS: a run in flight wins, and
/// with nothing running it is whichever agent last produced output here. That
/// is the same agent whose message is at the bottom of the trail, which is what
/// makes the number readable — the alternative (the first participant) pinned
/// the meter to one agent forever and reported the wrong window for every space
/// where somebody else does the talking.
///
/// A single-agent space always answers with that agent, so nothing about the
/// common case changes.
///
/// Ranking is by last activity, never by join order, and it is deliberately
/// derived from the run log rather than remembered: an agent that worked hours
/// ago ranks below one that worked a minute ago, whatever order the client saw
/// the events in. [stateOrNull] only carries the answer across a rebuild where
/// the run stream has nothing to say yet (it is still loading, or the workspace
/// gate is closed), so the meter holds its subject instead of blinking to a
/// different window.
///
/// Being in flight is only a TIE-BREAK, not a trump card. A streaming run
/// stamps `lastOutputAt` as it goes, so a working agent already ranks first on
/// recency; making "active" win outright would instead let one orphaned
/// `running` row (a killed process, a run the reaper has not swept) pin the
/// meter to that agent forever — which is the same "always the same agent"
/// failure this ranking exists to fix.
///
/// A spawned subagent is not a participant, so its run never steals the meter —
/// the parent agent's window is the one the human can act on.
class SpaceMeteredAgentNotifier extends Notifier<String?> {
  /// Creates a [SpaceMeteredAgentNotifier] scoped to [spaceId].
  SpaceMeteredAgentNotifier(this.spaceId);

  /// The space whose agents this tracks.
  final String spaceId;

  @override
  String? build() {
    final participants =
        ref.watch(spaceParticipantsProvider(spaceId)).asData?.value ??
        const <SpaceParticipant>[];
    final agentIds = <String>{
      for (final p in participants)
        if (!p.isUser) p.principalId,
    };
    if (agentIds.isEmpty) {
      return null;
    }
    if (agentIds.length == 1) {
      return agentIds.first;
    }

    // Read BEFORE the run watch below: `stateOrNull` is the previous build's
    // answer (null on the first one), which is what holds the subject steady
    // while the run stream has not answered yet.
    final previous = stateOrNull;

    // Ownership-gated exactly like [spaceStatusProvider]: an ungated read opens
    // a run-log subscription for a `(new workspace, old space)` pair on every
    // workspace switch. See [_workspaceOwningSpace].
    //
    // The SPACE's whole run log, not just the live rows: "who is working" only
    // answers while something is running, and the meter has to keep meaning
    // something in between — which is exactly when a human reads it.
    final workspaceId = _workspaceOwningSpace(ref, spaceId);
    final runs = workspaceId == null
        ? const <AgentRunLog>[]
        : ref
                  .watch(
                    spaceRunLogsProvider((
                      workspaceId: workspaceId,
                      spaceId: spaceId,
                    )),
                  )
                  .asData
                  ?.value ??
              const <AgentRunLog>[];

    String? bestAgentId;
    DateTime? bestAt;
    var bestIsActive = false;
    for (final run in runs) {
      if (!agentIds.contains(run.agentId)) {
        continue;
      }
      final at = _runActivityAt(run);
      final isActive = run.isActive;
      final wins =
          bestAt == null ||
          at.isAfter(bestAt) ||
          (at == bestAt && isActive && !bestIsActive);
      if (wins) {
        bestAgentId = run.agentId;
        bestAt = at;
        bestIsActive = isActive;
      }
    }
    if (bestAgentId != null) {
      return bestAgentId;
    }
    return previous != null && agentIds.contains(previous)
        ? previous
        : agentIds.first;
  }
}

/// Per-space "which agent's context window is on screen" — the header meter's
/// subject. See [SpaceMeteredAgentNotifier]. Null while the participant list is
/// still loading, and for a space with no agents in it.
final spaceMeteredAgentIdProvider = NotifierProvider.family
    .autoDispose<SpaceMeteredAgentNotifier, String?, String>(
      SpaceMeteredAgentNotifier.new,
    );

/// Per-space provisioning status: `provisioning` while the background
/// worktree + overlay + `.mcp.json` setup runs, `ready` when dispatch is
/// unblocked, `failed` when provisioning needs a retry. Derived from the
/// workspace space stream so it reacts live as the server flips the status.
/// Defaults to `ready` when the space is not yet in the stream (e.g. the
/// list is still loading) so the composer never blocks on a transient miss.
final spaceProvisioningStatusProvider = Provider.autoDispose
    .family<SpaceProvisioningStatus, String>((ref, spaceId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final spaces = workspaceId != null
          ? ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value
          : ref.watch(spacesProvider).asData?.value;
      final space = spaces?.where((c) => c.id == spaceId).firstOrNull;
      return space?.provisioningStatus ?? SpaceProvisioningStatus.ready;
    });

/// The granular step an in-flight provision is on ("cloning repo X",
/// "setting up agent Y"), or null when idle / unknown — callers fall back to
/// the generic "preparing workspace" label. Same live space stream as
/// [spaceProvisioningStatusProvider].
final spaceProvisioningStepProvider = Provider.autoDispose
    .family<SpaceProvisioningStep?, String>((ref, spaceId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final spaces = workspaceId != null
          ? ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value
          : ref.watch(spacesProvider).asData?.value;
      return spaces
          ?.where((c) => c.id == spaceId)
          .firstOrNull
          ?.provisioningStep;
    });

/// The user participant's read cursor for a space (when they last opened
/// it), or null when the space has never been opened under the user. Local
/// DB stream — cheap, emits immediately.
final spaceUserLastReadAtProvider = StreamProvider.autoDispose
    .family<DateTime?, String>((ref, spaceId) {
      // Only open the read-cursor subscription for a space that actually
      // belongs to the active workspace, and subscribe AGAINST that same
      // workspace id — never a foreign, deleted or not-yet-loaded space. See
      // [_workspaceOwningSpace] for why the pair has to be established here
      // rather than assembled from the ambient workspace at call time.
      final workspaceId = _workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream<DateTime?>.value(null);
      }
      return ref
          .watch(spaceReadRepositoryProvider)
          .watchUserLastReadAt(
            workspaceId,
            spaceId,
            ref.watch(currentUserIdProvider) ?? '',
          );
    });

/// Whether a space has agent messages the user hasn't seen yet (the sidebar's
/// notification-dot signal). True only when the user has opened the space
/// before (a non-null read cursor exists) AND a top-level agent message landed
/// after that cursor. A never-opened space shows no dot, so legacy rows don't
/// all light up at once. Reads the server-computed activity aggregate — no
/// per-space message-list subscription.
final spaceUnreadProvider = Provider.autoDispose.family<bool, String>((
  ref,
  spaceId,
) {
  final lastReadAt = ref.watch(spaceUserLastReadAtProvider(spaceId)).value;
  if (lastReadAt == null) {
    return false;
  }
  final lastAgentAt = _spaceActivityOf(ref, spaceId)?.lastAgentMessageAt;
  return lastAgentAt != null && lastAgentAt.isAfter(lastReadAt);
});

/// Count of workspace spaces awaiting the user (unanswered agent question) —
/// the "needs attention" badge on the sidebar Conversations entry. One sum
/// over the server-computed activity aggregate.
final workspaceNeedsAttentionCountProvider = Provider.autoDispose
    .family<int, String>((ref, workspaceId) {
      final activity = ref
          .watch(workspaceSpaceActivityProvider(workspaceId))
          .value;
      if (activity == null) {
        return 0;
      }
      return activity.values.where((a) => a.needsInput).length;
    });

/// Initial number of messages shown in a space feed window.
const int kSpaceFeedInitialWindow = 60;

/// How many older messages each "load more" reveals.
const int kSpaceFeedWindowStep = 60;

/// Upper bound on the feed window so a very long space can't load unbounded.
const int kSpaceFeedMaxWindow = 2000;

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

/// Per-conversation feed window size (newest-N shown). `loadMore()` grows it by
/// [kSpaceFeedWindowStep] up to [kSpaceFeedMaxWindow]. Keyed by
/// conversation id.
class SpaceFeedWindowNotifier extends Notifier<int> {
  /// Creates a [SpaceFeedWindowNotifier] for [conversationId].
  SpaceFeedWindowNotifier(this.conversationId);

  /// The conversation this window belongs to.
  final String conversationId;

  @override
  int build() => kSpaceFeedInitialWindow;

  /// Reveals an older page of messages.
  void loadMore() {
    state = (state + kSpaceFeedWindowStep).clamp(
      kSpaceFeedInitialWindow,
      kSpaceFeedMaxWindow,
    );
  }
}

/// Provides the per-conversation feed window size (keyed by conversation id).
final spaceFeedWindowProvider =
    NotifierProvider.family<SpaceFeedWindowNotifier, int, String>(
      SpaceFeedWindowNotifier.new,
    );

/// Windowed message feed for a conversation: the newest N messages (N = the
/// conversation's window size) plus whether older messages exist beyond it.
final spaceFeedWindowedProvider = StreamProvider.autoDispose
    .family<({List<Message> messages, bool hasMore}), ConversationRef>((
      ref,
      ref2,
    ) {
      final limit = ref.watch(spaceFeedWindowProvider(ref2.conversationId));
      return ref
          .watch(messagingRepositoryProvider)
          .watchMessagesWindow(
            ref.requireWorkspaceId(),
            ref2.spaceId,
            ref2.conversationId,
            limit: limit,
          );
    });

/// Auto-disposed stream of participants for a space.

final spaceParticipantsProvider = StreamProvider.autoDispose
    .family<List<SpaceParticipant>, String>((ref, spaceId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchParticipants(ref.requireWorkspaceId(), spaceId);
    });

/// Sidebar-visible spaces (all workspaces), excluding pipeline-managed
/// (hidden) ones, archived ones and PR-workbench spaces (which need the
/// workspace-scoped activity aggregate to know whether they've been messaged —
/// without an active workspace they stay hidden). Used as the fallback when no
/// active workspace is resolved.
final visibleSpacesProvider = Provider<List<Space>>((ref) {
  return ref
      .watch(spacesProvider)
      .maybeWhen(
        data: (spaces) => spaces
            .where(
              (c) => c.pipelineRunId == null && !c.kind.isPr && !c.isArchived,
            )
            .toList(),
        orElse: () => const [],
      );
});

/// Workspace-scoped sidebar-visible spaces, excluding pipeline-managed
/// (hidden) ones, archived ones (shelved until restored from the archive
/// dialog) and never-messaged PR-workbench spaces.
///
/// A PR-workbench space is minted the moment any PR surface (chat/terminal/
/// files) needs a worktree anchor — merely opening a PR must not clutter the
/// sidebar. It surfaces once someone actually messages in it (the server-
/// computed activity aggregate reports a non-null `lastMessageAt`), i.e. once
/// the user engaged an agent on that PR.
final workspaceVisibleSpacesProvider = Provider.family<List<Space>, String>((
  ref,
  workspaceId,
) {
  final activity = ref.watch(workspaceSpaceActivityProvider(workspaceId)).value;
  return ref
      .watch(workspaceSpacesProvider(workspaceId))
      .maybeWhen(
        data: (spaces) => spaces.where((c) {
          if (c.isArchived) {
            return false;
          }
          if (c.pipelineRunId != null) {
            return false;
          }
          if (c.kind.isPr) {
            // Hidden while the aggregate is still loading too — a brief delay
            // before an interacted PR space appears beats a flash of clutter.
            return activity?[c.id]?.lastMessageAt != null;
          }
          return true;
        }).toList(),
        orElse: () => const [],
      );
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
      // every switch. See [_workspaceOwningSpace].
      final workspaceId = _workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream.value(const <Conversation>[]);
      }
      return ref
          .watch(conversationRepositoryProvider)
          .watchForSpace(workspaceId: workspaceId, spaceId: spaceId);
    });

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
      final conversation = await ref
          .watch(conversationRepositoryProvider)
          .ensure(workspaceId: workspaceId, spaceId: spaceId);
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
      final workspaceId = _workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream.value(const <String, ThreadSummary>{});
      }
      return ref
          .watch(conversationRepositoryProvider)
          .watchThreadSummaries(workspaceId: workspaceId, spaceId: spaceId)
          .map((list) => {for (final t in list) t.anchorMessageId: t});
    });

/// The conversation currently shown in a space's chat pane. Null defers to the
/// space's standing conversation. Keyed by space id; the messaging IDE / PR
/// page set it when the user switches conversations.
class SelectedConversationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects [conversationId] (null defers to the standing conversation).
  void select(String? conversationId) => state = conversationId;
}

/// Per-space selected conversation id (null = the standing conversation).
final selectedConversationIdProvider =
    NotifierProvider<SelectedConversationNotifier, String?>(
      SelectedConversationNotifier.new,
    );
