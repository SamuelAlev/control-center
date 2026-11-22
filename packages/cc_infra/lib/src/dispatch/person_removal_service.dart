import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The summary on the row of a run stopped because the person it acted for
/// left the workspace (its end is `serverStopped`).
const kRunStoppedPersonRemovedSummary =
    'Stopped: the person it acted for left the workspace';

/// What one removal changed: goals paused, wakes cancelled (before and
/// after the runs stopped), cards deleted, runs stopped.
typedef PersonRemovalOutcome = ({int goals, int wakes, int cards, int runs});

/// What happens to a person's waiting work when they are removed from a
/// workspace ([WorkspaceMemberRemoved]), in that workspace only. Nothing
/// runs on their identity afterwards, and nothing of theirs is handed to
/// someone else to continue as them:
///
/// 1. their active goals are paused for a person ([pauseGoals]: the goal
///    side, `needsReview`, `wake_skipped: person_removed`), first, so the
///    steps below start nothing for them;
/// 2. every pending or held wake that acts for them is cancelled with
///    `person_removed` ([cancelWakes]); a usage-limit pause among them
///    ends as a cancelled pause does (its row, its cards);
/// 3. their queued and held steering cards are deleted ([deleteCard]), so
///    none is sent as them by a run's end or a release;
/// 4. every live top-level run that acts for them is stopped on the
///    server's authority ([stopRun]: it ends `serverStopped`, neither a
///    person's stop nor a failure); runs acting for nobody or for someone
///    else go on;
/// 5. the wakes are cancelled once more, for any a stopped run's end
///    reopened.
///
/// A person who is a member again by the time the event is handled is left
/// alone. Every step only moves what is still open, so a second event (or
/// one that arrives while a run is ending) changes nothing more. Removals
/// are handled one at a time.
class PersonRemovalService {
  /// Listens for removals on [eventBus] (null in tests, which call
  /// [handle]).
  PersonRemovalService({
    required DomainEventBus? eventBus,
    required this.isMember,
    required this.cancelWakes,
    required this.liveRuns,
    required this.stopRun,
    required this.cardsOf,
    required this.deleteCard,
  }) {
    _sub = eventBus?.on<WorkspaceMemberRemoved>().listen((event) {
      unawaited(handle(event));
    });
  }

  /// Whether the person is a member of the workspace now.
  final Future<bool> Function(String workspaceId, String userId) isMember;

  /// Cancels every pending and held wake acting for the person with
  /// `person_removed`; returns how many.
  final Future<int> Function(String workspaceId, String userId) cancelWakes;

  /// The workspace's runs that have not finished.
  final Future<List<AgentRunLog>> Function(String workspaceId) liveRuns;

  /// Stops one live run on the server's authority; false when nothing here
  /// runs it.
  final Future<bool> Function(String workspaceId, String runId) stopRun;

  /// The person's queued and held steering cards in the workspace.
  final Future<List<Message>> Function(String workspaceId, String userId)
  cardsOf;

  /// Deletes one card (its row and any live lane's copy); false when it was
  /// already gone.
  final Future<bool> Function(String workspaceId, Message card) deleteCard;

  /// Pauses the person's active goals for a person; returns how many.
  /// Late-bound by the goal side; unbound pauses none.
  Future<int> Function(String workspaceId, String userId)? pauseGoals;

  StreamSubscription<WorkspaceMemberRemoved>? _sub;
  Future<void> _chain = Future<void>.value();

  /// Handles one removal (see the class). Returns what it changed.
  Future<PersonRemovalOutcome> handle(WorkspaceMemberRemoved event) {
    final done = _chain.then((_) => _handle(event));
    _chain = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<PersonRemovalOutcome> _handle(WorkspaceMemberRemoved event) async {
    const nothing = (goals: 0, wakes: 0, cards: 0, runs: 0);
    final ws = event.workspaceId;
    final user = event.userId;
    if (ws.isEmpty || user.isEmpty) {
      return nothing;
    }
    try {
      if (await isMember(ws, user)) {
        return nothing;
      }
      final goals = await pauseGoals?.call(ws, user) ?? 0;
      var wakes = await cancelWakes(ws, user);
      var cards = 0;
      for (final card in await cardsOf(ws, user)) {
        if (card.senderId == user && await deleteCard(ws, card)) {
          cards++;
        }
      }
      var runs = 0;
      for (final run in await liveRuns(ws)) {
        if (run.workspaceId == ws &&
            run.requestedByUserId == user &&
            run.parentRunId == null &&
            run.completedAt == null &&
            await stopRun(ws, run.id)) {
          runs++;
        }
      }
      wakes += await cancelWakes(ws, user);
      return (goals: goals, wakes: wakes, cards: cards, runs: runs);
    } on Object catch (e, st) {
      CcInfraLog.error(
        'PersonRemovalService: cleaning up after $user left $ws',
        e,
        st,
      );
      return nothing;
    }
  }

  /// Stops listening.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
