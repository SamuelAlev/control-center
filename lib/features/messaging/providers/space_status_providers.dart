/// Per-space attention, run and provisioning signals for the sidebar and
/// the space header.
library;

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
SpaceActivity? spaceActivityOf(Ref ref, String spaceId) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  // This space's entry only (SpaceActivity compares by value): the aggregate
  // re-emits on every message in the workspace, and every row's status and
  // unread providers read through here.
  return ref.watch(
    workspaceSpaceActivityProvider(
      workspaceId,
    ).select((activity) => activity.value?[spaceId]),
  );
}

/// Whether a space has an agent question awaiting the user's answer.
final spaceNeedsInputProvider = Provider.autoDispose.family<bool, String>((
  ref,
  spaceId,
) {
  return spaceActivityOf(ref, spaceId)?.needsInput ?? false;
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
  // workspace switch. See [workspaceOwningSpace].
  final workspaceId = workspaceOwningSpace(ref, spaceId);
  if (workspaceId != null) {
    // Selected down to the one bit this needs: the run stream re-emits about
    // once a second per running agent (its output stamp), which must not
    // re-run every row's status.
    final busy = ref.watch(
      spaceActiveRunsProvider((
        workspaceId: workspaceId,
        spaceId: spaceId,
      )).select((runs) => runs.asData?.value.isNotEmpty ?? false),
    );
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
/// A run with no `conversationId` (a space-scoped run) is not
/// attributable to a row and is deliberately dropped here: the space row keeps
/// showing it, which is what [spaceStatusProvider] answers.
final spaceBusyConversationIdsProvider = Provider.autoDispose
    .family<Set<String>, String>((ref, spaceId) {
      // Ownership-gated, same as [spaceStatusProvider] — it shares the space
      // run stream, and an unowned pair would open a second one. The busy set
      // is exactly the keys of the start map, which is already value-stable,
      // so this re-runs (and hands out a new set) only when the SET changes —
      // not when a start time or a run's output stamp does.
      return ref
          .watch(
            spaceRunStartedAtProvider(
              spaceId,
            ).select((started) => _ConversationIds(started.keys.toSet())),
          )
          .ids;
    });

/// Earliest start of an in-flight run on each conversation in the space.
///
/// Same space run stream as [spaceBusyConversationIdsProvider]. The sidebar
/// caption is how long that agent has been running, so the oldest start wins
/// when a conversation holds more than one active run. A run with no
/// `conversationId` is dropped, same as the busy-id set.
///
/// Value-stable: the server rewrites a running agent's `lastOutputAt` about
/// once a second, so the run stream re-emits with the same starts; the map
/// is compared by value and only a real change notifies.
final spaceRunStartedAtProvider = Provider.autoDispose
    .family<Map<String, DateTime>, String>((ref, spaceId) {
      final workspaceId = workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return const <String, DateTime>{};
      }
      return ref
          .watch(
            spaceActiveRunsProvider((
              workspaceId: workspaceId,
              spaceId: spaceId,
            )).select((runs) => _RunStarts.of(runs.asData?.value)),
          )
          .byConversation;
    });

/// The earliest in-flight start per conversation, compared by value so a
/// run-stream emission that changes nothing here is dropped by `.select`.
@immutable
class _RunStarts {
  const _RunStarts(this.byConversation);

  factory _RunStarts.of(List<AgentRunLog>? runs) {
    if (runs == null || runs.isEmpty) {
      return const _RunStarts(<String, DateTime>{});
    }
    final started = <String, DateTime>{};
    for (final run in runs) {
      final id = run.conversationId;
      if (id == null) {
        continue;
      }
      final current = started[id];
      if (current == null || run.startedAt.isBefore(current)) {
        started[id] = run.startedAt;
      }
    }
    return _RunStarts(started);
  }

  final Map<String, DateTime> byConversation;

  @override
  bool operator ==(Object other) =>
      other is _RunStarts && mapEquals(other.byConversation, byConversation);

  @override
  int get hashCode => Object.hashAllUnordered(
    byConversation.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

/// A set of conversation ids compared by value (see [_RunStarts]).
@immutable
class _ConversationIds {
  const _ConversationIds(this.ids);

  final Set<String> ids;

  @override
  bool operator ==(Object other) =>
      other is _ConversationIds && setEquals(other.ids, ids);

  @override
  int get hashCode => Object.hashAllUnordered(ids);
}

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

/// Agent whose context window the space header meters.
///
/// Rank by last activity from the run log (not join order). In-flight is a
/// tie-break only — an orphaned `running` row must not pin forever.
/// [stateOrNull] holds across loading/gate. Subagent runs never steal the meter.
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
    // workspace switch. See [workspaceOwningSpace].
    //
    // The SPACE's whole run log, not just the live rows: "who is working" only
    // answers while something is running, and the meter has to keep meaning
    // something in between — which is exactly when a human reads it.
    final workspaceId = workspaceOwningSpace(ref, spaceId);
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
      // Selected to this space's field, so a message elsewhere (which
      // re-emits the whole list) leaves the composer alone.
      SpaceProvisioningStatus? select(AsyncValue<List<Space>> spaces) => spaces
          .asData
          ?.value
          .where((c) => c.id == spaceId)
          .firstOrNull
          ?.provisioningStatus;
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final status = workspaceId != null
          ? ref.watch(workspaceSpacesProvider(workspaceId).select(select))
          : ref.watch(spacesProvider.select(select));
      return status ?? SpaceProvisioningStatus.ready;
    });

/// The granular step an in-flight provision is on ("cloning repo X",
/// "setting up agent Y"), or null when idle / unknown — callers fall back to
/// the generic "preparing workspace" label. Same live space stream as
/// [spaceProvisioningStatusProvider].
final spaceProvisioningStepProvider = Provider.autoDispose
    .family<SpaceProvisioningStep?, String>((ref, spaceId) {
      // Selected to this space's field, like the status above.
      SpaceProvisioningStep? select(AsyncValue<List<Space>> spaces) => spaces
          .asData
          ?.value
          .where((c) => c.id == spaceId)
          .firstOrNull
          ?.provisioningStep;
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      return workspaceId != null
          ? ref.watch(workspaceSpacesProvider(workspaceId).select(select))
          : ref.watch(spacesProvider.select(select));
    });
