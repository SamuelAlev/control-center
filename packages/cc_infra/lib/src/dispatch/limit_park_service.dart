import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/steering_queue_service.dart';
import 'package:uuid/uuid.dart';

/// Releases `senderId`'s steering cards held under `heldBy` (a park's
/// `limit:<runId>`), in order, into the run that is live there
/// (`SteeringQueueService.releaseHeldBy`). Returns how many.
typedef LimitParkCardRelease =
    Future<int> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String heldBy,
      required String senderId,
    });

/// Puts the cards held at run `runId`'s usage limit under `heldBy`, with
/// `resetsAt` (`SteeringQueueService.holdRunCards`). Returns how many moved.
typedef LimitParkCardHold =
    Future<int> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String runId,
      required String heldBy,
      required DateTime? resetsAt,
      required String? pausePerson,
    });

/// Merges `fields` into the person's park row of the wake `wakeId`, once
/// (`LimitParkRowStamp`). True when the row changed.
typedef LimitParkRowStamper =
    Future<bool> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String wakeId,
      required Map<String, Object?> fields,
    });

/// The workspace's held steering cards, every conversation
/// (`DaoMessagingRepository.heldSteeringMessages`), for the boot sweep.
typedef LimitParkHeldCards =
    Future<List<Message>> Function(String workspaceId);

/// The workspace's park rows ([LimitPark.rowKind]) with no outcome yet
/// (`DaoMessagingRepository.openLimitParkRows`), for the boot sweep.
typedef LimitParkOpenRows = Future<List<Message>> Function(String workspaceId);

/// Posts a system row in a conversation; returns its message id.
typedef LimitParkRowPoster =
    Future<String?> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String content,
      required Map<String, Object?> metadata,
    });

/// A person's run held at its provider's usage limit before it could go on
/// (the credential park), as the dispatch layer describes it.
class LimitParkRun {
  /// Creates the description. Throws [ArgumentError] for an empty id.
  LimitParkRun({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.runId,
    required this.requestedByUserId,
    required this.wakeReason,
    required this.wakeIds,
    required this.adapter,
    required this.modelId,
  }) {
    for (final (name, value) in [
      ('workspaceId', workspaceId),
      ('runId', runId),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
  }

  /// The run's workspace.
  final String workspaceId;

  /// Its space, conversation and agent (null or empty: nothing to park in).
  final String? spaceId;

  /// See [spaceId].
  final String? conversationId;

  /// See [spaceId].
  final String? agentId;

  /// The run log id (the run row may not exist yet).
  final String runId;

  /// The person the run is for; null for a server run.
  final String? requestedByUserId;

  /// Why the run started.
  final WakeReason? wakeReason;

  /// The wakes the run delivers.
  final List<String> wakeIds;

  /// The run's adapter and model, for the provider's label.
  final String? adapter;

  /// See [adapter].
  final String? modelId;

  /// Whether a restart would lose this park: a person's own run that no
  /// wake started (a wake-started run's claimed wakes return to pending
  /// after a restart, a goal's sweep resumes its goal).
  bool get lostOnRestart =>
      (requestedByUserId?.isNotEmpty ?? false) &&
      wakeReason == WakeReason.userMessage &&
      wakeIds.isEmpty &&
      (spaceId?.isNotEmpty ?? false) &&
      (conversationId?.isNotEmpty ?? false) &&
      (agentId?.isNotEmpty ?? false);

  @override
  bool operator ==(Object other) =>
      other is LimitParkRun &&
      other.workspaceId == workspaceId &&
      other.spaceId == spaceId &&
      other.conversationId == conversationId &&
      other.agentId == agentId &&
      other.runId == runId &&
      other.requestedByUserId == requestedByUserId &&
      other.wakeReason == wakeReason &&
      _sameIds(other.wakeIds, wakeIds) &&
      other.adapter == adapter &&
      other.modelId == modelId;

  @override
  int get hashCode => Object.hash(
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    runId,
    requestedByUserId,
    wakeReason,
    Object.hashAll(wakeIds),
    adapter,
    modelId,
  );

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// The durable record of one credential park: the `limitReset` wake that
/// resumes the run after a restart.
class LimitParkTicket {
  /// Creates the ticket.
  const LimitParkTicket({
    required this.workspaceId,
    required this.runId,
    required this.wakeId,
  });

  /// The run's workspace.
  final String workspaceId;

  /// The parked run.
  final String runId;

  /// Its `limitReset` wake.
  final String wakeId;
}

/// Thrown by a dispatch whose credential park resolved after its
/// `limitReset` wake was already taken by the wake queue: the queue's run
/// carries the work on, so this one must not start (the run was never
/// recorded).
class LimitParkSupersededException implements Exception {
  /// Creates the exception.
  const LimitParkSupersededException(this.runId);

  /// The run that did not start.
  final String runId;

  @override
  String toString() =>
      'LimitParkSupersededException: run $runId resumed from its limit wake';
}

/// The durable park of a person's run at its provider's usage limit (plan
/// section 11, D23), and the credential park's durable record.
///
/// - **A person's run** that ended on `usageLimit` with a reported reset at
///   most [LimitPark.maxWait] away (and that no goal or rule owns) gets one
///   `limitReset` wake, created **held** (`stateReason: limit`) for that
///   person, due at the reset plus [LimitPark.resetSlack], and one compact
///   system row ([LimitPark.rowKind], keys [LimitPark.rowKeys]). The person
///   resumes it with `wakes.release` (it then waits for its `notBefore`) or
///   drops it with `wakes.cancel`.
/// - **The credential park before a run goes on** (a Claude Code run whose
///   accounts are all spent, a harness run its pool refuses): for a run a
///   restart would lose ([LimitParkRun.lostOnRestart]), [credentialParked]
///   writes the same wake, pending, before the in-memory park waits. While
///   the in-memory park lives, this guard defers the wake
///   ([WakeStateReasons.limitRunLive]). When the park resolves,
///   [credentialParkEnded] cancels the wake; a wake the queue already took
///   means the queue's run goes on and the dispatch must not
///   ([LimitParkSupersededException]). After a restart nothing defers it,
///   and it starts the run at the reset. When the park gives up, the wake
///   is held for the person; the run's settlement posts the row.
///
/// The wake's dedup key is `limit:<runId>` on every path, so a run is parked
/// once whichever path writes first.
class LimitParkService implements WakeAdmissionGuard {
  /// Creates the service. [start] registers it on the queue.
  LimitParkService({
    required this._wakes,
    required this._queue,
    required this._runLogs,
    required this._postRow,
    required this._releaseCards,
    required this._holdCards,
    required this._heldCards,
    required this._openParkRows,
    required this._stampRow,
    required this._eventBus,
    this._clock = DateTime.now,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final WakeRepository _wakes;
  final WakeQueueService _queue;
  final AgentRunLogRepository _runLogs;
  final LimitParkRowPoster _postRow;
  final LimitParkCardRelease _releaseCards;

  /// Puts a run's held cards under its pause or a Stop ([reconcileCards]).
  final LimitParkCardHold _holdCards;
  final LimitParkHeldCards _heldCards;
  final LimitParkOpenRows _openParkRows;
  final LimitParkRowStamper _stampRow;
  final DomainEventBus? _eventBus;
  final DateTime Function() _clock;
  final String Function() _newId;
  StreamSubscription<AgentRunSettled>? _sub;

  /// Runs parked in memory now (`workspaceId\u0000runId`).
  final Set<String> _live = {};

  /// How long the guard defers a wake whose run is still parked in memory.
  static const Duration liveDeferral = Duration(minutes: 1);

  /// The wake reasons of a person's own run: their message, the Resume of a
  /// recovery, or the Resume of an earlier park.
  static const Set<WakeReason> personReasons = {
    WakeReason.userMessage,
    WakeReason.recovery,
    WakeReason.limitReset,
  };

  /// The stateReason of a credential park's wake the park cancelled itself
  /// (it resumed in place).
  static const String resumedInPlace = 'limit_resumed_in_place';

  /// The cancel reason of a park wake whose run a person cancelled at its
  /// credential block.
  static const String declined = 'limit_park_declined';

  /// Registers the guard on the queue and listens for run ends. Call once,
  /// after the queue is built.
  void start() {
    if (_sub != null) {
      return;
    }
    _queue
      ..registerGuard(this)
      ..registerSettledHandler(onWakeSettled)
      ..registerEnqueuedHandler(onWakeEnqueued);
    _sub = _eventBus?.on<AgentRunSettled>().listen(
      (event) => unawaited(_safely(onRunSettled(event))),
    );
  }

  /// Stops listening.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  // ---------------------------------------------------------------- guard

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) async {
    final source = wake.detail.sourceRunId;
    if (wake.reason != WakeReason.limitReset ||
        source == null ||
        !_live.contains(_key(wake.workspaceId, source))) {
      return const WakeAdmission.admit();
    }
    return WakeAdmission.defer(
      reason: WakeStateReasons.limitRunLive,
      until: now.add(liveDeferral),
    );
  }

  // -------------------------------------------------------- person's park

  /// A run ended. Parks it when it is a person's run that reached its
  /// provider's usage limit with a reset to honour; anything else (a goal's
  /// or a rule's run, a server stop, no reset) is left alone.
  Future<void> onRunSettled(AgentRunSettled event) async {
    if (event.endReason != RunEndReason.usageLimit || _queue.stopping) {
      return;
    }
    final now = _clock();
    final reset = LimitPark.honouredReset(event.limitResetsAt, now);
    final person = event.requestedByUserId;
    final spaceId = event.spaceId;
    final conversationId = event.conversationId;
    if (reset == null ||
        person == null ||
        person.isEmpty ||
        spaceId == null ||
        spaceId.isEmpty ||
        conversationId == null ||
        conversationId.isEmpty ||
        !personReasons.contains(event.wakeReason) ||
        await _ownedByGoalOrRule(event)) {
      return;
    }
    final ws = event.workspaceId;
    final log = await _runLogs.getById(ws, event.runId);
    final provider = LimitPark.providerLabel(
      adapter: log?.adapter,
      modelId: log?.modelId,
    );
    final wake = _limitWake(
      workspaceId: ws,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: event.agentId,
      runId: event.runId,
      person: person,
      reset: reset,
      provider: provider,
      held: true,
    );
    final String wakeId;
    if (await _enqueue(wake)) {
      wakeId = wake.id;
    } else {
      // The credential park wrote it first (same key). Its in-memory park
      // gave up and the run ended: from now on the person resumes it.
      final existing = await _wakes.getByDedupKey(ws, wake.dedupKey);
      if (existing == null ||
          existing.reason != WakeReason.limitReset ||
          existing.state.isSettled ||
          existing.state == WakeState.claimed) {
        return;
      }
      if (existing.state == WakeState.pending &&
          await _wakes.hold(
                ws,
                ids: [existing.id],
                reason: LimitPark.heldReason,
              ) ==
              0) {
        return;
      }
      wakeId = existing.id;
    }
    await _postParkRow(
      workspaceId: ws,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: event.agentId,
      runId: event.runId,
      wakeId: wakeId,
      person: person,
      reset: reset,
      provider: provider,
    );
  }

  Future<bool> _ownedByGoalOrRule(AgentRunSettled event) async {
    for (final id in event.wakeIds) {
      final wake = await _wakes.getById(event.workspaceId, id);
      if (wake != null &&
          (wake.detail.goalId != null ||
              wake.detail.ruleId != null ||
              // A peer ask's own park resumed this run: the ask parks it
              // again (or fails), never a person's park.
              (wake.reason == WakeReason.limitReset &&
                  wake.detail.askId != null))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _postParkRow({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String runId,
    required String wakeId,
    required String person,
    required DateTime reset,
    required String provider,
  }) async {
    try {
      await _postRow(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        content:
            'Paused at the $provider usage limit. It resets at '
            '${LimitPark.stamp(reset)}; resume to continue after the reset, '
            'or cancel.',
        metadata: {
          'kind': LimitPark.rowKind,
          'wakeId': wakeId,
          'runId': runId,
          'agentId': agentId,
          'provider': provider,
          'resetsAt': reset.toUtc().toIso8601String(),
          'resumesAt': LimitPark.resumeAt(reset).toIso8601String(),
          'requestedByUserId': person,
        },
      );
    } on Object catch (e) {
      CcInfraLog.warning('LimitParkService: park row for $runId failed: $e');
    }
  }

  // ------------------------------------------------------- park endings

  /// A `limitReset` wake settled (any park: a person's, a rule's, a goal's,
  /// a credential park's, an ask's).
  ///
  /// - Delivered (at the reset, or after its person released it early):
  ///   the cards the park holds (`limit:<sourceRunId>`) that the person it
  ///   acts for wrote are released, in order, into the resumed run.
  /// - Then, whatever the ending, the run's remaining cards follow
  ///   [reconcileCards]: still the pause's while another wake of the run
  ///   waits (a goal's reissue), else a Stop's, unsent, for their writers.
  /// - A person's park (no goal, rule or ask) records how it ended on its
  ///   row, once: [LimitPark.rowOutcomeKey] and [LimitPark.rowSettledAtKey]
  ///   (and [LimitPark.rowSkipKindKey] for a skip).
  ///
  /// A restart before this runs is repaired by [sweepAtBoot].
  Future<void> onWakeSettled(WakeSettlement settled) async {
    final wake = settled.wake;
    final source = wake.detail.sourceRunId;
    if (wake.reason != WakeReason.limitReset ||
        source == null ||
        !settled.state.isSettled) {
      return;
    }
    final ws = wake.workspaceId;
    final person = wake.requestedByUserId;
    try {
      if (settled.state == WakeState.delivered &&
          person != null &&
          person.isNotEmpty) {
        await _releaseCards(
          workspaceId: ws,
          spaceId: wake.spaceId,
          conversationId: wake.conversationId,
          heldBy: LimitPark.dedupKey(source),
          senderId: person,
        );
      }
      await reconcileCards(
        workspaceId: ws,
        spaceId: wake.spaceId,
        conversationId: wake.conversationId,
        runId: source,
      );
    } on Object catch (e) {
      CcInfraLog.warning('LimitParkService: cards of $source kept: $e');
    }
    await _stampOutcome(
      ws,
      wake.spaceId,
      wake.conversationId,
      wake.id,
      wake.detail,
      settled.state,
      settled.reason,
    );
  }

  /// A wake was written: a `limitReset` wake makes the cards held at its
  /// run's limit the pause's ([reconcileCards]).
  Future<void> onWakeEnqueued(Wake wake) async {
    final source = wake.detail.sourceRunId;
    if (wake.reason != WakeReason.limitReset || source == null) {
      return;
    }
    try {
      await reconcileCards(
        workspaceId: wake.workspaceId,
        spaceId: wake.spaceId,
        conversationId: wake.conversationId,
        runId: source,
      );
    } on Object catch (e) {
      CcInfraLog.warning('LimitParkService: cards of $source kept: $e');
    }
  }

  /// The one place that decides whose hold the cards held at run [runId]'s
  /// usage limit are under. A card is the pause's (`limit:<runId>`, sent
  /// when it resumes) only while a `limitReset` wake of that run is open
  /// (pending, held or claimed); otherwise it is a Stop's, with no reset,
  /// sent only by its writer, never by the server. Called when the run
  /// ends (the steering queue), when any `limitReset` wake is written
  /// ([onWakeEnqueued]) or settles ([onWakeSettled]), and at boot
  /// ([sweepAtBoot]); each caller acts after its own write, so whichever
  /// order the run's end and its pause land in, the cards agree. Returns
  /// how many cards moved.
  Future<int> reconcileCards({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String runId,
  }) async {
    final pause = await _openPause(workspaceId, conversationId, runId);
    return _holdCards(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      runId: runId,
      heldBy: pause == null
          ? SteeringQueueService.heldByStop
          : LimitPark.dedupKey(runId),
      resetsAt: pause == null
          ? null
          : DateTime.tryParse('${pause.detail.fields['resetsAt']}'),
      // Only the cards of the person the pause acts for wait with it.
      pausePerson: pause?.requestedByUserId,
    );
  }

  /// The open `limitReset` wake of the run [runId] in [conversationId]
  /// (pending, held, or being delivered), or null.
  Future<Wake?> _openPause(
    String ws,
    String conversationId,
    String runId,
  ) async {
    for (final w in await _wakes.listForConversation(
      ws,
      conversationId,
      states: const {WakeState.pending, WakeState.held, WakeState.claimed},
    )) {
      if (w.reason == WakeReason.limitReset && w.detail.sourceRunId == runId) {
        return w;
      }
    }
    return null;
  }

  /// Records how a person's park ended on the row of its wake [wakeId]
  /// (a park with no goal, rule or ask in its [detail]).
  Future<void> _stampOutcome(
    String ws,
    String spaceId,
    String conversationId,
    String wakeId,
    WakeDetail detail,
    WakeState state,
    String? why,
  ) async {
    final outcome = switch (state) {
      WakeState.delivered => LimitPark.outcomeResumed,
      WakeState.cancelled => LimitPark.outcomeCancelled,
      WakeState.expired => LimitPark.outcomeExpired,
      WakeState.skipped => LimitPark.outcomeSkipped,
      _ => null,
    };
    if (outcome == null ||
        detail.goalId != null ||
        detail.ruleId != null ||
        detail.askId != null) {
      return;
    }
    try {
      await _stampRow(
        workspaceId: ws,
        spaceId: spaceId,
        conversationId: conversationId,
        wakeId: wakeId,
        fields: {
          LimitPark.rowOutcomeKey: outcome,
          LimitPark.rowSettledAtKey: _clock().toUtc().toIso8601String(),
          if (outcome == LimitPark.outcomeSkipped)
            LimitPark.rowSkipKindKey: why,
        },
      );
    } on Object catch (e) {
      CcInfraLog.warning('LimitParkService: row of $wakeId kept: $e');
    }
  }

  /// Boot, then the queue: [sweepAtBoot] runs before [WakeQueueService.start]
  /// so that no delivery the queue starts is in flight while the sweep
  /// decides (a pause being delivered has a settled wake but its cards are
  /// still to be released). The queue starts even when listing the
  /// workspaces or the sweep fails (logged): a repair never costs the
  /// server its wakes.
  Future<void> startQueueAfterSweep(
    Future<Iterable<String>> Function() workspaceIds,
  ) async {
    try {
      await sweepAtBoot(await workspaceIds());
    } on Object catch (e) {
      CcInfraLog.warning('LimitParkService: boot sweep failed: $e');
    } finally {
      await _queue.start();
    }
  }

  /// Boot, before the queue starts: repairs what a lost settlement left
  /// (a restart between a wake's write and its handler, a handler that
  /// failed, a settled wake purged).
  ///
  /// - Cards held at a run's limit ([SteeringQueueService.heldRunKey] or
  ///   `limit:<runId>`) follow [reconcileCards].
  /// - A person's park row with no outcome whose wake settled gets it; a
  ///   row whose wake is gone (purged after its retention) is stamped
  ///   skipped with no kind: it ended, how is no longer known.
  ///
  /// Returns how many runs' cards and rows changed.
  Future<int> sweepAtBoot(Iterable<String> workspaceIds) async {
    var changed = 0;
    for (final ws in workspaceIds) {
      try {
        final runs = <(String, String, String)>{};
        for (final card in await _heldCards(ws)) {
          final meta = card.metadata;
          final heldBy = meta?[SteeringQueueService.heldByKey];
          final runId = switch (meta?[SteeringQueueService.heldRunKey]) {
            final String id when id.isNotEmpty => id,
            _ when heldBy is String && heldBy.startsWith(_pausePrefix) =>
              heldBy.substring(_pausePrefix.length),
            _ => '',
          };
          if (runId.isNotEmpty) {
            runs.add((card.spaceId, card.conversationId, runId));
          }
        }
        for (final (spaceId, conversationId, runId) in runs) {
          if (await reconcileCards(
                workspaceId: ws,
                spaceId: spaceId,
                conversationId: conversationId,
                runId: runId,
              ) >
              0) {
            changed++;
          }
        }
        for (final row in await _openParkRows(ws)) {
          final wakeId = row.metadata?['wakeId'];
          if (wakeId is! String || wakeId.isEmpty) {
            continue;
          }
          final wake = await _wakes.getById(ws, wakeId);
          if (wake != null && !wake.state.isSettled) {
            continue;
          }
          await _stampOutcome(
            ws,
            row.spaceId,
            row.conversationId,
            wakeId,
            wake?.detail ?? WakeDetail(),
            wake?.state ?? WakeState.skipped,
            wake?.stateReason,
          );
          changed++;
        }
      } on Object catch (e) {
        CcInfraLog.warning('LimitParkService: boot sweep of $ws failed: $e');
      }
    }
    return changed;
  }

  static final String _pausePrefix = LimitPark.dedupKey('');

  // ------------------------------------------------------ credential park

  /// The credential park of [run] begins, waiting for [resetsAt]. Writes
  /// the run's pending `limitReset` wake when a restart would lose the park
  /// and the reset is one to honour, and marks the run parked in memory.
  /// Returns the ticket to end the park with, or null when nothing durable
  /// was written (the park is in memory only, as before).
  Future<LimitParkTicket?> credentialParked(
    LimitParkRun run, {
    required DateTime? resetsAt,
  }) async {
    if (_queue.stopping || !run.lostOnRestart) {
      return null;
    }
    final reset = LimitPark.honouredReset(resetsAt, _clock());
    if (reset == null) {
      return null;
    }
    final ws = run.workspaceId;
    final key = _key(ws, run.runId);
    // Marked first: the guard never admits the wake while this park lives.
    _live.add(key);
    try {
      final wake = _limitWake(
        workspaceId: ws,
        spaceId: run.spaceId!,
        conversationId: run.conversationId!,
        agentId: run.agentId!,
        runId: run.runId,
        person: run.requestedByUserId!,
        reset: reset,
        provider: LimitPark.providerLabel(
          adapter: run.adapter,
          modelId: run.modelId,
        ),
        held: false,
      );
      if (await _enqueue(wake)) {
        return LimitParkTicket(
          workspaceId: ws,
          runId: run.runId,
          wakeId: wake.id,
        );
      }
      final existing = await _wakes.getByDedupKey(ws, wake.dedupKey);
      if (existing != null &&
          (existing.state == WakeState.pending ||
              existing.state == WakeState.held)) {
        return LimitParkTicket(
          workspaceId: ws,
          runId: run.runId,
          wakeId: existing.id,
        );
      }
    } on Object catch (e, st) {
      CcInfraLog.error('LimitParkService: park of ${run.runId}', e, st);
    }
    _live.remove(key);
    return null;
  }

  /// The credential park of [ticket]'s run ended with [outcome].
  ///
  /// - `resolved`: the run may go on now; its wake is cancelled, and false
  ///   is returned when the queue took the wake first (its run carries the
  ///   work on; this one must not start).
  /// - `cancelled`: a person declined and cancelled the run; the wake is
  ///   dropped too, so nothing restarts it at the reset. Returns false.
  /// - `timedOut`: the park gave up; the wake is held for the person
  ///   (`stateReason: limit`) here, not at the run's settlement, so a
  ///   dispatch that then fails before its run row starts nothing nobody
  ///   asked to resume. The settlement still posts the row. Returns false.
  ///
  /// Never throws.
  Future<bool> credentialParkEnded(
    LimitParkTicket ticket, {
    required RunCredentialOutcome outcome,
  }) async {
    final ws = ticket.workspaceId;
    try {
      switch (outcome) {
        case RunCredentialOutcome.timedOut:
          await _wakes.hold(
            ws,
            ids: [ticket.wakeId],
            reason: LimitPark.heldReason,
          );
          return false;
        case RunCredentialOutcome.cancelled:
          await _queue.cancel(ws, ticket.wakeId, reason: declined);
          return false;
        case RunCredentialOutcome.resolved:
          break;
      }
      if (await _queue.cancel(ws, ticket.wakeId, reason: resumedInPlace)) {
        return true;
      }
      final wake = await _wakes.getById(ws, ticket.wakeId);
      // A person's cancel leaves nothing to start the work: go on.
      return wake?.state == WakeState.cancelled;
    } on Object catch (e, st) {
      CcInfraLog.error(
        'LimitParkService: ending the park of ${ticket.runId}',
        e,
        st,
      );
      return false;
    } finally {
      _live.remove(_key(ws, ticket.runId));
    }
  }

  // --------------------------------------------------------------- shared

  Wake _limitWake({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String runId,
    required String person,
    required DateTime reset,
    required String provider,
    required bool held,
  }) => Wake(
    id: _newId(),
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: agentId,
    reason: WakeReason.limitReset,
    payload: '',
    detail: WakeDetail(
      sourceRunId: runId,
      fields: LimitPark.wakeFields(provider: provider, reset: reset),
    ),
    dedupKey: LimitPark.dedupKey(runId),
    notBefore: LimitPark.resumeAt(reset),
    // A person's pause ends a week after the reset if they never resume it,
    // held or (the credential park's) pending alike.
    expiresAt: LimitPark.personParkExpiresAt(reset),
    requestedByUserId: person,
    state: held ? WakeState.held : WakeState.pending,
    stateReason: held ? LimitPark.heldReason : null,
    createdAt: _clock(),
  );

  Future<bool> _enqueue(Wake wake) async {
    try {
      return await _queue.enqueue(wake);
    } on WorkspaceMismatchException catch (e) {
      CcInfraLog.warning('LimitParkService: wake ${wake.dedupKey}: $e');
      return false;
    }
  }

  static String _key(String workspaceId, String runId) =>
      '$workspaceId\u0000$runId';

  Future<void> _safely(Future<void> work) async {
    try {
      await work;
    } on Object catch (e, st) {
      CcInfraLog.error('LimitParkService: run settlement', e, st);
    }
  }
}
