import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/wake_run_ledger.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart'
    show ReadOnlyRunUnavailableException;
import 'package:cc_harness/context.dart' show newWakeDataNonce;
import 'package:cc_harness/loop.dart' show SteeringMessage, SteeringQueue;
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/wake_dispatch.dart';
import 'package:cc_infra/src/dispatch/wake_held_run.dart';
import 'package:cc_infra/src/dispatch/wake_lineage_carry.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

export 'package:cc_infra/src/dispatch/wake_dispatch.dart';

part 'wake_queue_run_events.dart';

/// The durable wake queue: the one way the server starts an agent run
/// without a person typing (plan section 6).
///
/// Producers insert wakes ([enqueue], [enqueueAndDeliver]); the queue admits
/// each, then delivers it into a live run of its agent in its conversation
/// (the wake's lane, delivered when the run drains it) or starts a run with
/// a [WakeContext] (claim, dispatch, mark delivered). Everything is in the
/// workspace's `agent_wakes` table, so a restart loses nothing: [start]
/// rescans, a claim older than [staleClaimAfter] with no live run goes back
/// to pending, and a claim whose id is on a run that took it is delivered.
///
/// One timer, armed for the earliest due time (a pending wake's
/// `notBefore`, a quiet window's end, the next maintenance sweep). A sweep
/// runs maintenance first, then starts each due key's delivery without
/// waiting for it; at most [maxConcurrentDispatches] dispatches run at once.
/// The clock and the timer factory are injected; [tick] runs one sweep.
class WakeQueueService {
  /// Creates the queue. It subscribes to [AgentRunSettled] on [eventBus]
  /// at once, so it hears the reaper's settlements at boot; it moves state
  /// for them then, and delivers only after [start].
  WakeQueueService({
    required this._wakes,
    required WakeRunLedger runLedger,
    required this._ports,
    DomainEventBus? eventBus,
    this._clock = DateTime.now,
    this._timerFactory = Timer.new,
    this._nonce = newWakeDataNonce,
    String Function()? newId,
  }) : _ledger = runLedger,
       _newId = newId ?? _defaultId {
    _settledSub = eventBus?.on<AgentRunSettled>().listen(_heardSettled);
  }

  final WakeRepository _wakes;
  final WakeRunLedger _ledger;
  final WakeQueuePorts _ports;
  final DateTime Function() _clock;
  final WakeTimerFactory _timerFactory;
  final String Function() _nonce;
  final String Function() _newId;
  StreamSubscription<AgentRunSettled>? _settledSub;

  static int _idSeq = 0;
  static String _defaultId() =>
      'wake-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  /// How long a wake inserted already due waits for siblings (same agent,
  /// same conversation) so they arrive as one delivery.
  static const Duration quietWindow = Duration(seconds: 2);

  /// A claim this old with no delivery under way is returned to pending.
  static const Duration staleClaimAfter = Duration(seconds: 60);

  /// How often the queue sweeps while any workspace has open wakes.
  static const Duration maintenanceEvery = Duration(seconds: 60);

  /// Settled wakes older than this are deleted by the queue's own sweep
  /// (at most once an hour per workspace).
  static const Duration retention = Duration(days: 14);

  /// Most wakes, and most payload characters, one delivery carries.
  static const int maxWakesPerDelivery = 10;

  /// See [maxWakesPerDelivery].
  static const int maxPayloadCharsPerDelivery = 16000;

  /// Wake-started runs per conversation, and per workspace, in an hour.
  static const int maxRunsPerConversationHour = 30;

  /// See [maxRunsPerConversationHour].
  static const int maxRunsPerWorkspaceHour = 300;

  /// Delivery attempts before a wake is skipped (`attempts`).
  static const int maxAttempts = 3;

  /// Dispatches the queue runs at once, server-wide. A dispatch can wait
  /// minutes (a credential park, a busy worktree), so deliveries never wait
  /// for each other; this bound keeps a burst (a restart's backlog) from
  /// provisioning hundreds of worktrees and sandboxes at once. Sixteen is
  /// well above the handful of runs a host keeps busy, so several parked
  /// dispatches still leave room for every other workspace.
  static const int maxConcurrentDispatches = 16;

  /// The most of those dispatches one workspace holds at once (a quarter):
  /// one workspace's credential waits or busy worktrees never take every
  /// slot from the others. Its further dispatches wait their turn; a slot
  /// passes to the oldest waiter whose workspace is under its share.
  static const int maxDispatchesPerWorkspace = 4;

  /// How long a wake waits on a refusal that clears by itself (a budget
  /// block, a paused agent) when it has no `expiresAt` of its own.
  static const Duration maxWaitOnRefusal = Duration(days: 7);

  /// The refusals a wake waits out, then expires on (see
  /// [maxWaitOnRefusal]).
  static const Set<String> waitingRefusals = {
    WakeStateReasons.budgetBlocked,
    WakeStateReasons.agentPaused,
  };

  /// The deferrals that end when the agent's live run in the conversation
  /// settles: the run's settlement delivers them.
  static const Set<String> _waitsForRun = {
    WakeStateReasons.liveRunNoInput,
    WakeStateReasons.liveRunOtherOptions,
    WakeStateReasons.liveRunOtherPerson,
  };

  final List<WakeAdmissionGuard> _guards = [];
  final List<WakeSettledHandler> _settledHandlers = [];
  final List<Future<void> Function(Wake wake)> _enqueuedHandlers = [];

  /// Workspaces with open wakes, swept by the timer.
  final Set<String> _workspaces = {};

  /// End of the quiet window per delivery key.
  final Map<String, DateTime> _quietUntil = {};

  /// Wakes pushed into a live run's lane, not yet drained.
  final Map<String, _LaneEntry> _inLane = {};

  /// Wakes a delivery is claiming or dispatching, per workspace.
  final Map<String, Set<String>> _dispatching = {};

  /// Wakes a person's cancel is moving.
  final Set<String> _cancelling = {};

  /// The nonce of each live run the queue framed wakes for.
  final Map<String, String> _nonceByRun = {};

  /// The live run each wake was pushed into, until that run settles: a
  /// receipt says "pushed" even when the run drained it at once.
  final Map<String, String> _pushedTo = {};

  /// Runs whose settlement the queue heard and how each ended, most recent
  /// last (bounded): a push or a delivery that raced the run's end sees it.
  final LinkedHashMap<String, RunEndReason> _settledRuns = LinkedHashMap();

  /// Delivery chains: one delivery per key at a time.
  final Map<String, Future<void>> _chains = {};

  /// Settlement handling under way ([stop] waits for it).
  final Set<Future<void>> _settling = {};

  final List<({String workspaceId, Completer<void> turn})> _slotWaiters = [];
  int _dispatchesRunning = 0;
  final Map<String, int> _dispatchesByWorkspace = {};

  final Expando<bool> _listening = Expando('wake drain listener');
  final Map<String, DateTime> _lastRetention = {};

  Timer? _timer;
  DateTime? _timerAt;
  DateTime? _lastMaintenance;
  bool _started = false;
  bool _stopping = false;
  bool _stopped = false;
  Future<void>? _sweep;
  bool _sweepAgain = false;

  /// Called when a run drains a pushed wake that carries a chain (the agents
  /// whose messages led to it): the run's own mention chain grows by it, so
  /// depth and cycle checks go on across a lane push. Wired to
  /// `MentionWakes.carryChain`.
  void Function(String workspaceId, String runId, List<String> chain)?
  chainCarried;

  /// The root of the chain of wakes (lineage) the runs `runIds` are in,
  /// the oldest when they are in two; null for none. Wired to the wake
  /// rules: every wake those runs cause carries it ([WakeFields.lineageRoot]).
  Future<String?> Function(String workspaceId, List<String> runIds)?
  lineageRootOfRuns;

  // ---------------------------------------------------------------- public

  /// Adds [guard] to admission, after the guards already registered.
  void registerGuard(WakeAdmissionGuard guard) => _guards.add(guard);

  /// Adds [handler]; it hears every wake once when it settles. A handler of a
  /// delivery's settlements runs after that delivery left its key's chain,
  /// so it may itself deliver for the same key.
  void registerSettledHandler(WakeSettledHandler handler) =>
      _settledHandlers.add(handler);

  /// Adds [handler]; it hears every wake [enqueue] or [enqueueAndDeliver]
  /// wrote, once, before the call returns. It must not throw.
  void registerEnqueuedHandler(Future<void> Function(Wake wake) handler) =>
      _enqueuedHandlers.add(handler);

  Future<void> _enqueued(Wake wake) async {
    for (final handler in _enqueuedHandlers) {
      await handler(wake);
    }
  }

  /// Whether [agentId] is busy in [conv] for a wake: a live run not held
  /// only for background tasks ([busyBeyondBackgroundHold]; `when_busy`).
  Future<bool> agentBusy(String ws, String conv, String agentId) async =>
      await _ports.hasLiveRun(ws, conv, agentId) &&
      busyBeyondBackgroundHold(
        _ports.liveSessions(conv),
        ws: ws,
        agentId: agentId,
      );

  /// Inserts [input] unless its dedup key exists. True when it was written.
  /// A wake inserted already due waits [quietWindow] for siblings. Throws
  /// [WorkspaceMismatchException] when its conversation, space or agent is
  /// not in its workspace.
  Future<bool> enqueue(Wake input) async {
    await _requireOwnRecords(input);
    final wake = await carryWakeLineage(input, lineageRootOfRuns);
    final inserted = await _wakes.insertIfAbsent(wake);
    if (!inserted) {
      return false;
    }
    await _enqueued(wake);
    _workspaces.add(wake.workspaceId);
    final now = _clock();
    if (wake.state == WakeState.pending && wake.isDueAt(now)) {
      _quietUntil.putIfAbsent(_key(wake), () => now.add(quietWindow));
    }
    unawaited(_arm());
    return true;
  }

  /// Inserts [input] and delivers it at once, with no quiet window. Says
  /// what became of it. Throws as [enqueue] does.
  Future<WakeReceipt> enqueueAndDeliver(Wake input) async {
    await _requireOwnRecords(input);
    final wake = await carryWakeLineage(input, lineageRootOfRuns);
    if (!await _wakes.insertIfAbsent(wake)) {
      return const WakeDuplicate();
    }
    await _enqueued(wake);
    _workspaces.add(wake.workspaceId);
    return _deliverAndReport(wake.workspaceId, wake.id);
  }

  /// Cancels the wake [wakeId] in [workspaceId] with [reason]. False when
  /// it already settled, was already taken by a run, or a delivery is
  /// claiming or starting it. Throws [WorkspaceMismatchException] when the
  /// wake is not in [workspaceId].
  Future<bool> cancel(
    String workspaceId,
    String wakeId, {
    required String reason,
  }) async {
    final wake = await _require(workspaceId, wakeId);
    if ((_dispatching[workspaceId]?.contains(wakeId) ?? false) ||
        _cancelling.contains(wakeId)) {
      return false;
    }
    final lane = _inLane[wakeId];
    if (lane == null && wake.state == WakeState.claimed) {
      // Claimed by a delivery that is not this process's (a restart in
      // between): it may already be on a run.
      return false;
    }
    if (lane != null) {
      if (!lane.queue.removeByRef(_ref(wakeId))) {
        return false;
      }
      _inLane.remove(wakeId);
    }
    _cancelling.add(wakeId);
    final int moved;
    try {
      moved = await _wakes.cancel(
        workspaceId,
        ids: [wakeId],
        reason: reason,
        now: _clock(),
      );
    } finally {
      _cancelling.remove(wakeId);
    }
    if (moved == 0) {
      return false;
    }
    await _settled(wake, WakeState.cancelled, reason: reason);
    return true;
  }

  /// Cancels the pending and held wakes matching every given filter.
  /// Returns how many.
  Future<int> cancelWhere(
    String workspaceId, {
    String? goalId,
    String? ruleId,
    String? askId,
    String? conversationId,
    String? requestedByUserId,
    required String reason,
  }) async {
    final cancelled = await _wakes.cancelWhere(
      workspaceId,
      goalId: goalId,
      ruleId: ruleId,
      askId: askId,
      conversationId: conversationId,
      requestedByUserId: requestedByUserId,
      reason: reason,
      now: _clock(),
    );
    for (final wake in cancelled) {
      await _settled(wake, WakeState.cancelled, reason: reason);
    }
    return cancelled.length;
  }

  /// Holds the pending wakes of [agentId] in [conversationId] with
  /// [reason] (a person stopped that agent's run there). A goal's wakes are
  /// never held: the goal governs them (a stopped segment or review pauses
  /// its goal, whose guard defers them), and another agent's wakes are not
  /// the stopped run's. Returns how many.
  Future<int> hold(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required String reason,
  }) async {
    final pending = [
      for (final w in await _wakes.listForConversation(
        workspaceId,
        conversationId,
        states: const {WakeState.pending},
      ))
        if (w.agentId == agentId && w.detail.goalId == null) w,
    ];
    if (pending.isEmpty) {
      return 0;
    }
    return _wakes.hold(
      workspaceId,
      ids: [for (final w in pending) w.id],
      reason: reason,
    );
  }

  /// Releases the held wake [wakeId], or the held wakes of [conversationId],
  /// and delivers what is due: a person's operation, [userId]'s. A wake that
  /// acts for a person is that person's to release; the conversation form
  /// releases [userId]'s and the bot wakes. Returns how many were released.
  /// Throws [WorkspaceMismatchException] when [wakeId] is not in
  /// [workspaceId], [AuthException] ([wakeNotYoursKind]) when the wake, or
  /// every held wake of the conversation, is another person's, and
  /// [ArgumentError] when neither id is given.
  Future<int> release(
    String workspaceId, {
    String? wakeId,
    String? conversationId,
    required String userId,
  }) async {
    final List<Wake> held;
    if (wakeId != null) {
      final wake = await _require(workspaceId, wakeId);
      _requireMayAct(wake, userId);
      held = wake.state == WakeState.held ? [wake] : const [];
    } else if (conversationId != null) {
      final all = await _wakes.listForConversation(
        workspaceId,
        conversationId,
        states: const {WakeState.held},
      );
      held = [
        for (final w in all)
          if (mayAct(w, userId)) w,
      ];
      if (held.isEmpty && all.isNotEmpty) {
        throw const AuthException(
          'The held wakes here act for another person',
          code: wakeNotYoursKind,
        );
      }
    } else {
      throw ArgumentError('release needs a wake id or a conversation id');
    }
    if (held.isEmpty) {
      return 0;
    }
    final moved = await _wakes.release(
      workspaceId,
      ids: [for (final w in held) w.id],
    );
    _workspaces.add(workspaceId);
    for (final key in {for (final w in held) _key(w)}) {
      final w = held.firstWhere((h) => _key(h) == key);
      unawaited(_deliverKey(workspaceId, w.conversationId, w.agentId));
    }
    unawaited(_arm());
    return moved;
  }

  /// Delivers the pending or held wake [wakeId] now, whatever its
  /// `notBefore`: a person's operation, [userId]'s, who must be the person
  /// the wake acts for when it acts for one. Throws
  /// [WorkspaceMismatchException] when it is not in [workspaceId], and
  /// [AuthException] ([wakeNotYoursKind]) when it is another person's.
  Future<WakeReceipt> deliverNow(
    String workspaceId,
    String wakeId, {
    required String userId,
  }) async {
    final wake = await _require(workspaceId, wakeId);
    _requireMayAct(wake, userId);
    if (wake.state == WakeState.held) {
      await _wakes.release(workspaceId, ids: [wakeId]);
    }
    // Due now for this delivery only; its row keeps its time, so a claim
    // another delivery holds is never moved back.
    _workspaces.add(workspaceId);
    return _deliverAndReport(workspaceId, wakeId);
  }

  /// Whether [userId] may release or deliver [wake]: a bot wake is anyone's
  /// with access to its space, a person's wake only that person's.
  static bool mayAct(Wake wake, String userId) {
    final person = wake.requestedByUserId;
    return person == null || person == userId;
  }

  /// Boot: finds every workspace with open wakes, reclaims stale claims and
  /// arms the timer. Runs after the boot reaper, so the runs that were live
  /// before the restart have settled; nothing is delivered before it.
  Future<void> start() async {
    if (_started || _stopping || _stopped) {
      return;
    }
    _started = true;
    try {
      _workspaces.addAll(await _wakes.workspacesWithOpenWakes());
    } on Object catch (e, st) {
      CcInfraLog.error('WakeQueueService: boot scan failed', e, st);
    }
    await tick();
  }

  /// Shutdown, before agent runs are stopped: from now on nothing is
  /// delivered, armed or swept. Settlements still move state (a server
  /// stop reopens a run's wakes, a person's stop holds them, a person's
  /// run leaves its recovery wake), so the next boot delivers them.
  void beginStopping() {
    _stopping = true;
    _timer?.cancel();
    _timer = null;
    _timerAt = null;
  }

  /// Stops the timer and the settlement subscription, after the settlement
  /// handling under way finished. Wakes stay where they are; the next
  /// [start] picks them up.
  Future<void> stop() async {
    beginStopping();
    await Future.wait(_settling.toList());
    _stopped = true;
    await _settledSub?.cancel();
    _settledSub = null;
    await _sweep;
  }

  /// Runs one sweep now: maintenance (expiry, stale claims, retention) in
  /// every workspace, then starts the delivery of what is due, then re-arms
  /// the timer. The timer calls it; tests call it with an injected clock.
  Future<void> tick() async {
    if (_halted || !_started) {
      return;
    }
    if (_sweep != null) {
      _sweepAgain = true;
      return _sweep;
    }
    final run = _runSweeps();
    _sweep = run;
    try {
      await run;
    } finally {
      _sweep = null;
    }
  }

  /// A live run's harness started: the queue listens to its drains and
  /// delivers what waited for it. Wired after the steering queue's own
  /// handler, whose drain callback it chains.
  void handleHarnessStarted(SteeringSessionView session) {
    final ws = session.workspaceId;
    final conv = session.conversationId;
    final agent = session.agentId;
    _listen(session.steeringQueue);
    if (ws == null || conv == null || agent == null) {
      return;
    }
    unawaited(_deliverKey(ws, conv, agent, afterRun: true));
  }

  bool get _halted => _stopping || _stopped;

  /// Whether shutdown began ([beginStopping]): what ends now is the server
  /// going away, not a person or the agent.
  bool get stopping => _halted;

  // ----------------------------------------------------------------- sweep

  Future<void> _runSweeps() async {
    do {
      _sweepAgain = false;
      final now = _clock();
      final maintain =
          _lastMaintenance == null ||
          !now.isBefore(_lastMaintenance!.add(maintenanceEvery));
      if (maintain) {
        _lastMaintenance = now;
      }
      final active = <String>[];
      for (final ws in _workspaces.toList()) {
        try {
          // Registered and not deleted BEFORE its database is opened.
          if (!await _ports.workspaceActive(ws)) {
            _forgetWorkspace(ws);
            continue;
          }
          if (maintain) {
            await _maintain(ws, now);
          }
          active.add(ws);
        } on Object catch (e, st) {
          CcInfraLog.error('WakeQueueService: maintenance of $ws', e, st);
        }
      }
      for (final ws in active) {
        try {
          await _startDue(ws, now);
        } on Object catch (e, st) {
          CcInfraLog.error('WakeQueueService: sweep of $ws failed', e, st);
        }
      }
    } while (_sweepAgain && !_halted);
    await _arm(afterSweep: true);
  }

  /// Starts the delivery of every due key of [ws] that is not already
  /// delivering, without waiting for any of them.
  Future<void> _startDue(String ws, DateTime now) async {
    final due = await _wakes.listDue(ws, now: now);
    final keys = <String, Wake>{};
    for (final wake in due) {
      keys.putIfAbsent(_key(wake), () => wake);
    }
    for (final entry in keys.entries) {
      final quiet = _quietUntil[entry.key];
      if ((quiet != null && now.isBefore(quiet)) ||
          _chains.containsKey(entry.key)) {
        // Still gathering siblings, or a delivery of the key is under way
        // (it re-arms when it is done).
        continue;
      }
      _quietUntil.remove(entry.key);
      unawaited(
        _deliverKey(ws, entry.value.conversationId, entry.value.agentId),
      );
    }
    if (await _wakes.earliestPendingNotBefore(ws) == null &&
        !_hasInFlight(ws) &&
        !await _wakes.hasExpiringHeld(ws)) {
      _workspaces.remove(ws);
    }
  }

  Future<void> _maintain(String ws, DateTime now) async {
    // A wake that waited out a self-clearing refusal for its whole bound:
    // said in the conversation, with the refusal as its kind.
    for (final wake in await _wakes.expireWaiting(
      ws,
      now: now,
      reasons: waitingRefusals,
    )) {
      final kind = wake.stateReason ?? WakeStateReasons.budgetBlocked;
      await _postRow(ws, wake, kind);
      await _settled(wake, WakeState.expired, reason: kind);
    }
    for (final wake in await _wakes.expireDue(ws, now: now)) {
      await _settled(wake, WakeState.expired, reason: wake.stateReason);
    }
    // A claim still being delivered is fresh; only the rest can go stale.
    final inFlight = [
      ...?_dispatching[ws],
      for (final e in _inLane.entries)
        if (e.value.workspaceId == ws) e.key,
    ];
    if (inFlight.isNotEmpty) {
      await _wakes.refreshClaims(ws, ids: inFlight, now: now);
    }
    final reclaimed = await _wakes.reclaimStaleClaims(
      ws,
      claimedBefore: now.subtract(staleClaimAfter),
    );
    for (final wake in reclaimed) {
      // On a run that took it (live, or ended other than by a server stop):
      // the run started before the restart. A run a server stop ended took
      // nothing; the wake stays pending and a new run delivers it.
      final run = await _ledger.runForWake(ws, wake.id);
      if (run != null &&
          run.tookItsWakes &&
          await _wakes.markDelivered(
                ws,
                ids: [wake.id],
                runId: run.runId,
                now: now,
              ) ==
              1) {
        await _settled(wake, WakeState.delivered, runId: run.runId);
      }
    }
    final last = _lastRetention[ws];
    if (last == null || now.difference(last) >= const Duration(hours: 1)) {
      _lastRetention[ws] = now;
      await _wakes.deleteSettledBefore(ws, cutoff: now.subtract(retention));
    }
  }

  bool _hasInFlight(String ws) =>
      (_dispatching[ws]?.isNotEmpty ?? false) ||
      _inLane.values.any((e) => e.workspaceId == ws) ||
      _chains.keys.any((key) => key.startsWith('$ws\u0000'));

  void _forgetWorkspace(String ws) {
    _workspaces.remove(ws);
    _dispatching.remove(ws);
    _lastRetention.remove(ws);
    _quietUntil.removeWhere((key, _) => key.startsWith('$ws\u0000'));
  }

  Future<void> _arm({bool afterSweep = false}) async {
    if (_halted || !_started) {
      return;
    }
    final now = _clock();
    DateTime? next;
    void consider(DateTime? at) {
      if (at != null && (next == null || at.isBefore(next!))) {
        next = at;
      }
    }

    var dueLeft = false;
    for (final ws in _workspaces.toList()) {
      try {
        final at = await _wakes.earliestPendingNotBefore(ws);
        if (at != null && !at.isAfter(now)) {
          dueLeft = true;
        } else {
          consider(at);
        }
      } on Object catch (e) {
        CcInfraLog.warning('WakeQueueService: arming for $ws failed: $e');
      }
    }
    final quiet = _quietUntil.values.toList();
    for (final at in quiet) {
      consider(at);
    }
    if (dueLeft) {
      // Right after a sweep or a delivery, a due wake is waiting for its
      // quiet window (covered above), for a delivery under way, or could not
      // move; look again shortly, never spin.
      consider(afterSweep && quiet.isEmpty ? now.add(_retryGap) : now);
    }
    if (_workspaces.isNotEmpty) {
      consider((_lastMaintenance ?? now).add(maintenanceEvery));
    }
    final at = next;
    if (_halted) {
      return;
    }
    if (at == null) {
      _timer?.cancel();
      _timer = null;
      _timerAt = null;
      return;
    }
    if (_timer != null && _timerAt != null && !_timerAt!.isAfter(at)) {
      return;
    }
    _timer?.cancel();
    _timerAt = at;
    final delay = at.difference(now);
    _timer = _timerFactory(delay.isNegative ? Duration.zero : delay, () {
      _timer = null;
      _timerAt = null;
      unawaited(tick());
    });
  }

  static const Duration _retryGap = Duration(seconds: 5);

  // -------------------------------------------------------------- delivery

  Future<WakeReceipt> _deliverAndReport(String ws, String wakeId) async {
    final wake = await _require(ws, wakeId);
    await _deliverKey(ws, wake.conversationId, wake.agentId, including: wakeId);
    final pushedTo = _pushedTo[wakeId];
    if (pushedTo != null) {
      return WakePushed(pushedTo);
    }
    final after = await _wakes.getById(ws, wakeId);
    unawaited(_arm());
    return switch (after?.state) {
      WakeState.delivered when after!.deliveredRunId != null => WakeStarted(
        after.deliveredRunId!,
      ),
      WakeState.delivered => const WakeWaiting('delivered'),
      WakeState.skipped || WakeState.expired || WakeState.cancelled =>
        WakeSkipped(after!.stateReason ?? after.state.wire),
      WakeState.held => const WakeWaiting('held'),
      WakeState.claimed => const WakeWaiting('claimed'),
      WakeState.pending => WakeWaiting(
        after!.isDueAt(_clock()) ? 'due' : (after.stateReason ?? 'not_due'),
      ),
      null => const WakeSkipped('deleted'),
    };
  }

  /// Delivers the due wakes of [agentId] in [conversationId], one call per
  /// key at a time. [afterRun]: a run of the key just ended or started, so
  /// wakes that waited for it count as due. [including]: a wake to treat as
  /// due whatever its time. The settled handlers hear the delivery's
  /// settlements after it left the chain, before the returned future ends.
  Future<void> _deliverKey(
    String ws,
    String conversationId,
    String agentId, {
    bool afterRun = false,
    String? including,
  }) {
    final key = '$ws\u0000$conversationId\u0000$agentId';
    final buffer = _SettlementBuffer();
    final previous = _chains[key] ?? Future<void>.value();
    final step = previous.then(
      (_) =>
          runZoned(
            () => _deliver(
              ws,
              conversationId,
              agentId,
              afterRun: afterRun,
              including: including,
            ),
            zoneValues: {_SettlementBuffer.zoneKey: buffer},
          ).catchError((Object e, StackTrace st) {
            CcInfraLog.error('WakeQueueService: delivery failed', e, st);
          }),
    );
    _chains[key] = step;
    return step.whenComplete(() async {
      _chains.removeWhere((k, chain) => k == key && identical(chain, step));
      for (final settlement in buffer.close()) {
        await _notify(settlement);
      }
      unawaited(_arm(afterSweep: true));
    });
  }

  Future<void> _deliver(
    String ws,
    String conversationId,
    String agentId, {
    required bool afterRun,
    String? including,
  }) async {
    if (_halted || !_started || !await _ports.workspaceActive(ws)) {
      return;
    }
    final now = _clock();
    final candidates = [
      for (final w in await _wakes.listPendingFor(
        ws,
        conversationId: conversationId,
        agentId: agentId,
      ))
        if (w.id == including ||
            w.isDueAt(now) ||
            (afterRun && _waitsForRun.contains(w.stateReason)))
          if (w.expiresAt == null || now.isBefore(w.expiresAt!)) w,
    ];
    if (candidates.isEmpty) {
      return;
    }
    // The wake a person asked for leads its delivery's batch.
    final asked = candidates.indexWhere((w) => w.id == including);
    if (asked > 0) {
      candidates.insert(0, candidates.removeAt(asked));
    }

    // The agent: exists and is not retired; a paused one is waited for.
    final agent = await _ports.agent(ws, agentId);
    if (agent == null) {
      await _skip(ws, candidates, WakeStateReasons.agentDeleted, now);
      return;
    }
    if (agent.lifecycleStatus == AgentLifecycleStatus.paused) {
      await _waitOut(ws, candidates, WakeStateReasons.agentPaused, now);
      return;
    }
    if (!agent.isDispatchable) {
      await _skip(ws, candidates, WakeStateReasons.agentNotDispatchable, now);
      return;
    }

    // The person each wake acts for is still a member.
    final admitted = <Wake>[];
    for (final wake in candidates) {
      final person = wake.requestedByUserId;
      if (person != null && !await _ports.isMember(ws, person)) {
        await _skip(ws, [wake], WakeStateReasons.personRemoved, now);
        continue;
      }
      admitted.add(wake);
    }
    if (admitted.isEmpty) {
      return;
    }

    // No take-over of the conversation's worktree.
    final spaceId = admitted.first.spaceId;
    if (await _ports.takenOver(ws, spaceId)) {
      await _defer(ws, admitted, WakeStateReasons.takeOver, now, _minute(now));
      return;
    }

    // Budget: a block lifts by itself (a new month, a raised limit).
    if (await _ports.budgetBlocked(ws, agentId)) {
      await _waitOut(ws, admitted, WakeStateReasons.budgetBlocked, now);
      return;
    }

    // Registered guards, per wake.
    final passed = <Wake>[];
    for (final wake in admitted) {
      final answer = await _guard(wake, now);
      switch (answer) {
        case WakeAdmit(:final capMicros):
          passed.add(narrowed(wake, capMicros));
        case WakeDefer(:final reason, :final until):
          await _defer(ws, [wake], reason, now, until ?? _minute(now));
        case WakeSkip(:final kind):
          await _skip(ws, [wake], kind, now);
      }
    }
    if (passed.isEmpty) {
      return;
    }

    // A run live only for its background tasks yields, and the wakes the
    // guards let through wait for its settlement ([agentBusy]: it is not
    // busy for a `when_busy: skip` rule).
    final held = heldRunToYield(
      _ports.liveSessions(conversationId),
      ws: ws,
      agentId: agentId,
      wakes: passed,
      afterRun: afterRun,
      pushable: pushable,
    );
    if (held != null) {
      held.yieldBackgroundHold();
      final until = now.add(const Duration(minutes: 5));
      await _defer(ws, passed, WakeStateReasons.liveRunNoInput, now, until);
      return;
    }

    // A live run of the agent here: its lane for the wakes that run the way
    // it runs and act for whom it acts; the rest wait for it to end.
    final sessions = [
      for (final s in _ports.liveSessions(conversationId))
        if (s.workspaceId == ws &&
            s.agentId == agentId &&
            s.runLogId != null &&
            !(afterRun && yieldedHeldRun(s)))
          s,
    ];
    final accepting = sessions.where((s) => s.acceptsSteering).firstOrNull;
    if (accepting != null) {
      final push = <Wake>[];
      final otherOptions = <Wake>[];
      final otherPerson = <Wake>[];
      for (final wake in passed) {
        if (!pushable(wake.runOptions) ||
            accepting.readOnly ||
            accepting.freshHistory) {
          otherOptions.add(wake);
        } else if (wake.requestedByUserId != accepting.requestedByUserId) {
          otherPerson.add(wake);
        } else {
          push.add(wake);
        }
      }
      final waitUntil = now.add(const Duration(minutes: 5));
      if (otherOptions.isNotEmpty) {
        await _defer(
          ws,
          otherOptions,
          WakeStateReasons.liveRunOtherOptions,
          now,
          waitUntil,
        );
      }
      if (otherPerson.isNotEmpty) {
        await _defer(
          ws,
          otherPerson,
          WakeStateReasons.liveRunOtherPerson,
          now,
          waitUntil,
        );
      }
      if (push.isNotEmpty) {
        await _push(ws, conversationId, accepting, push, now);
      }
      return;
    }
    if (sessions.isNotEmpty ||
        await _ports.hasLiveRun(ws, conversationId, agentId)) {
      await _defer(
        ws,
        passed,
        WakeStateReasons.liveRunNoInput,
        now,
        now.add(const Duration(minutes: 5)),
      );
      return;
    }

    // Rate caps on wake-started runs.
    final hourAgo = now.subtract(const Duration(hours: 1));
    if (await _wakes.countDeliveredRunsSince(
          ws,
          since: hourAgo,
          conversationId: conversationId,
        ) >=
        maxRunsPerConversationHour) {
      await _defer(
        ws,
        passed,
        WakeStateReasons.rateCapConversation,
        now,
        now.add(const Duration(minutes: 10)),
      );
      return;
    }
    if (await _wakes.countDeliveredRunsSince(ws, since: hourAgo) >=
        maxRunsPerWorkspaceHour) {
      await _defer(
        ws,
        passed,
        WakeStateReasons.rateCapWorkspace,
        now,
        now.add(const Duration(minutes: 10)),
      );
      return;
    }

    await _start(ws, agent, takeBatch(passed));
  }

  /// Whether a wake with [options] may join a live run's lane: only one with
  /// none (a read-only, fresh, capped or schema-bound wake runs on its own).
  static bool pushable(WakeRunOptions? options) =>
      options == null ||
      (!options.freshHistory &&
          !options.readOnly &&
          options.costCapMicros == null &&
          options.outputSchema == null);

  /// [wake] with its run's cap lowered to [capMicros] when a guard set a
  /// lower one ([WakeAdmission.admitWithin]); the stored wake keeps its own.
  static Wake narrowed(Wake wake, int? capMicros) {
    final own = wake.runOptions?.costCapMicros;
    if (capMicros == null || (own != null && own <= capMicros)) {
      return wake;
    }
    final options = wake.runOptions;
    return wake.copyWith(
      runOptions: WakeRunOptions(
        freshHistory: options?.freshHistory ?? false,
        readOnly: options?.readOnly ?? false,
        costCapMicros: capMicros,
        outputSchema: options?.outputSchema,
      ),
    );
  }

  /// The first guard's answer that does not admit, else an admit within the
  /// lowest cap any guard set.
  Future<WakeAdmission> _guard(Wake wake, DateTime now) async {
    int? cap;
    for (final guard in _guards) {
      try {
        final answer = await guard.admit(wake, now: now);
        if (answer is! WakeAdmit) {
          return answer;
        }
        final within = answer.capMicros;
        if (within != null && (cap == null || within < cap)) {
          cap = within;
        }
      } on Object catch (e, st) {
        CcInfraLog.error('WakeQueueService: guard threw', e, st);
        return const WakeAdmission.defer(reason: WakeStateReasons.guardFailed);
      }
    }
    return cap == null
        ? const WakeAdmission.admit()
        : WakeAdmission.admitWithin(cap);
  }

  /// The first delivery's worth of [wakes]: those that run the same way
  /// (requester, run options, chain) as the first, up to
  /// [maxWakesPerDelivery] and [maxPayloadCharsPerDelivery].
  static List<Wake> takeBatch(List<Wake> wakes) {
    final first = wakes.first;
    final batch = <Wake>[first];
    var chars = first.payload.length;
    for (final wake in wakes.skip(1)) {
      if (batch.length >= maxWakesPerDelivery) {
        break;
      }
      if (!sameRun(first, wake) ||
          chars + wake.payload.length > maxPayloadCharsPerDelivery) {
        continue;
      }
      batch.add(wake);
      chars += wake.payload.length;
    }
    return batch;
  }

  /// Whether [a] and [b] can be delivered by one run.
  static bool sameRun(Wake a, Wake b) =>
      a.requestedByUserId == b.requestedByUserId &&
      a.runOptions == b.runOptions &&
      _sameList(a.chain, b.chain);

  static bool _sameList(List<String> a, List<String> b) {
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

  Future<void> _push(
    String ws,
    String conversationId,
    SteeringSessionView session,
    List<Wake> wakes,
    DateTime now,
  ) async {
    final runId = session.runLogId!;
    final batch = [
      for (final w in takeBatch(wakes))
        if (!_cancelling.contains(w.id)) w,
    ];
    if (batch.isEmpty) {
      return;
    }
    final ids = [for (final w in batch) w.id];
    final inFlight = _dispatching.putIfAbsent(ws, () => {})..addAll(ids);
    final List<String> claimed;
    try {
      claimed = await _wakes.claim(ws, ids: ids, now: now);
    } finally {
      inFlight.removeAll(ids);
    }
    if (claimed.isEmpty) {
      return;
    }
    // The run may have ended while the claim was written: then nothing of
    // it drains the lane, and its settlement already passed.
    final live =
        !_settledRuns.containsKey(runId) &&
        _ports
            .liveSessions(conversationId)
            .any((s) => s.runLogId == runId && s.acceptsSteering);
    if (!live) {
      await _wakes.releaseClaim(ws, ids: claimed);
      return;
    }
    final queue = session.steeringQueue;
    _listen(queue);
    final nonce = _nonceByRun.putIfAbsent(runId, _nonce);
    for (final wake in batch) {
      if (!claimed.contains(wake.id)) {
        continue;
      }
      _pushedTo[wake.id] = runId;
      _inLane[wake.id] = _LaneEntry(
        workspaceId: ws,
        runId: runId,
        queue: queue,
        wake: wake,
      );
      final text = renderWakeSection(
        [wake],
        nonce: nonce,
        forms: session.toolForms,
      );
      switch (wake.lane) {
        case WakeLane.aside:
          queue.pushAside(text, source: 'wake', now: now, ref: _ref(wake.id));
        case WakeLane.followUp:
          queue.pushFollowUp(
            text,
            source: 'wake',
            now: now,
            ref: _ref(wake.id),
          );
      }
    }
  }

  Future<void> _start(String ws, Agent agent, List<Wake> wanted) async {
    await _acquireSlot(ws);
    try {
      if (_halted) {
        return;
      }
      final batch = [
        for (final w in wanted)
          if (!_cancelling.contains(w.id)) w,
      ];
      if (batch.isEmpty) {
        return;
      }
      final ids = [for (final w in batch) w.id];
      final inFlight = _dispatching.putIfAbsent(ws, () => {})..addAll(ids);
      try {
        await _claimAndDispatch(ws, agent, batch, ids);
      } finally {
        inFlight.removeAll(ids);
      }
    } finally {
      _releaseSlot(ws);
    }
  }

  Future<void> _claimAndDispatch(
    String ws,
    Agent agent,
    List<Wake> batch,
    List<String> ids,
  ) async {
    final claimedIds = await _wakes.claim(ws, ids: ids, now: _clock());
    if (claimedIds.isEmpty) {
      return;
    }
    final claimed = [
      for (final w in batch)
        if (claimedIds.contains(w.id)) w.copyWith(attempt: w.attempt + 1),
    ];
    final first = claimed.first;
    final nonce = _nonce();
    String? runId;
    try {
      runId = await _ports.dispatch(
        WakeDispatchRequest.forWakes(
          claimed,
          wakeContext: WakeContext.fromWakes(claimed, nonce: nonce),
        ),
      );
    } on ReadOnlyRunUnavailableException catch (refusal) {
      // Refused before any run row exists (`AgentDispatchService`): no
      // sandbox, or a backend that cannot hold the run to reading.
      await _skip(
        ws,
        claimed,
        refusal.code == ReadOnlyRunUnavailableException.backendKind
            ? WakeStateReasons.readOnlyUnavailable
            : WakeStateReasons.sandboxUnavailable,
        _clock(),
      );
      return;
    } on Object catch (e, st) {
      CcInfraLog.error('WakeQueueService: dispatch threw', e, st);
    }
    final at = _clock();
    if (runId == null) {
      await _retryOrSkip(ws, claimed, at);
      return;
    }
    _nonceByRun[runId] = nonce;
    final delivered = <Wake>[];
    for (final wake in claimed) {
      if (await _wakes.markDelivered(
            ws,
            ids: [wake.id],
            runId: runId,
            now: at,
          ) ==
          1) {
        delivered.add(wake);
      }
    }
    if (delivered.isEmpty) {
      return;
    }
    if (_settledRuns[runId] == RunEndReason.serverStopped) {
      // A server stop ended the run before its delivery was written: its
      // settlement found these claimed and in flight, and left them. They
      // go back to pending as that settlement's would have.
      await _wakes.reopenDelivered(
        ws,
        ids: [for (final w in delivered) w.id],
        reason: WakeStateReasons.serverStopped,
      );
      await _skip(
        ws,
        [
          for (final w in delivered)
            if (w.attempt >= maxAttempts) w,
        ],
        WakeStateReasons.attempts,
        at,
      );
      return;
    }
    if (wantsDeliveredRow(delivered)) {
      await _ports.postSystemRow(
        workspaceId: ws,
        spaceId: first.spaceId,
        conversationId: first.conversationId,
        content: deliveredRowText(delivered, agentName: agent.name),
        metadata: deliveredRowMetadata(delivered, runId: runId),
      );
    }
    for (final wake in delivered) {
      await _settled(wake, WakeState.delivered, runId: runId);
    }
  }

  Future<void> _acquireSlot(String ws) async {
    final turn = Completer<void>();
    _slotWaiters.add((workspaceId: ws, turn: turn));
    _passSlots();
    await turn.future;
  }

  void _releaseSlot(String ws) {
    _dispatchesRunning--;
    final held = (_dispatchesByWorkspace[ws] ?? 1) - 1;
    if (held <= 0) {
      _dispatchesByWorkspace.remove(ws);
    } else {
      _dispatchesByWorkspace[ws] = held;
    }
    _passSlots();
  }

  /// Gives free slots to the oldest waiters whose workspace is under its
  /// share, so due order holds within a workspace.
  void _passSlots() {
    for (var i = 0; i < _slotWaiters.length;) {
      if (_dispatchesRunning >= maxConcurrentDispatches) {
        return;
      }
      final waiter = _slotWaiters[i];
      final held = _dispatchesByWorkspace[waiter.workspaceId] ?? 0;
      if (held >= maxDispatchesPerWorkspace) {
        i++;
        continue;
      }
      _slotWaiters.removeAt(i);
      _dispatchesRunning++;
      _dispatchesByWorkspace[waiter.workspaceId] = held + 1;
      waiter.turn.complete();
    }
  }

  Future<void> _retryOrSkip(String ws, List<Wake> wakes, DateTime now) async {
    final spent = [
      for (final w in wakes)
        if (w.attempt >= maxAttempts) w,
    ];
    final retry = [
      for (final w in wakes)
        if (w.attempt < maxAttempts) w.id,
    ];
    if (retry.isNotEmpty) {
      await _wakes.defer(
        ws,
        ids: retry,
        until: _minute(now),
        reason: WakeStateReasons.dispatchRefused,
      );
    }
    await _skip(ws, spent, WakeStateReasons.attempts, now);
  }

  Future<void> _defer(
    String ws,
    List<Wake> wakes,
    String reason,
    DateTime now,
    DateTime until,
  ) async {
    await _wakes.defer(
      ws,
      ids: [for (final w in wakes) w.id],
      until: until,
      reason: reason,
    );
    unawaited(_arm());
  }

  /// Defers [wakes] on a refusal that clears by itself ([waitingRefusals]),
  /// looked at again in a minute, each bounded by its own `expiresAt` or
  /// [maxWaitOnRefusal] after its `notBefore`.
  Future<void> _waitOut(
    String ws,
    List<Wake> wakes,
    String reason,
    DateTime now,
  ) async {
    for (final wake in wakes) {
      final from = wake.notBefore.isBefore(wake.createdAt)
          ? wake.createdAt
          : wake.notBefore;
      await _wakes.deferWaiting(
        ws,
        id: wake.id,
        until: _minute(now),
        reason: reason,
        expiresAt: wake.expiresAt ?? from.add(maxWaitOnRefusal),
      );
    }
    unawaited(_arm());
  }

  /// Skips [wakes] for [kind]: one system row per wake that moved.
  Future<void> _skip(
    String ws,
    List<Wake> wakes,
    String kind,
    DateTime now,
  ) async {
    for (final wake in wakes) {
      final moved = await _wakes.markSkipped(
        ws,
        ids: [wake.id],
        reason: kind,
        now: now,
      );
      if (moved == 0) {
        continue;
      }
      await _postRow(ws, wake, kind);
      await _settled(wake, WakeState.skipped, reason: kind);
    }
  }

  /// The "A wake was not delivered (`kind`)" row.
  Future<void> _postRow(String ws, Wake wake, String kind) async {
    try {
      await _ports.postSystemRow(
        workspaceId: ws,
        spaceId: wake.spaceId,
        conversationId: wake.conversationId,
        content: skippedRowText(wake, kind),
        metadata: skippedRowMetadata(wake, kind),
      );
    } on Object catch (e) {
      CcInfraLog.warning('WakeQueueService: skip row failed: $e');
    }
  }

  // --------------------------------------------------------------- helpers

  /// A delivery's settlements wait in its buffer until it left the chain
  /// ([_deliverKey]); every other settlement is heard at once.
  Future<void> _settled(
    Wake wake,
    WakeState state, {
    String? runId,
    String? reason,
  }) async {
    final settlement = WakeSettlement(
      wake: wake,
      state: state,
      runId: runId,
      reason: reason,
    );
    final buffer = Zone.current[_SettlementBuffer.zoneKey];
    if (buffer is _SettlementBuffer && buffer.add(settlement)) {
      return;
    }
    await _notify(settlement);
  }

  Future<void> _notify(WakeSettlement settlement) async {
    for (final handler in _settledHandlers) {
      try {
        await handler(settlement);
      } on Object catch (e, st) {
        CcInfraLog.error('WakeQueueService: settled handler threw', e, st);
      }
    }
  }

  /// The wake's conversation is its workspace's and in its space, and its
  /// agent exists there: a producer can never aim a wake across workspaces.
  Future<void> _requireOwnRecords(Wake wake) async {
    final ws = wake.workspaceId;
    if (!await _ports.workspaceActive(ws)) {
      throw WorkspaceMismatchException('Workspace $ws is not registered');
    }
    final space = await _ports.conversationSpace(ws, wake.conversationId);
    if (space == null) {
      throw WorkspaceMismatchException(
        'Conversation ${wake.conversationId} is not in workspace $ws',
      );
    }
    if (space != wake.spaceId) {
      throw WorkspaceMismatchException(
        'Conversation ${wake.conversationId} is not in space ${wake.spaceId}',
      );
    }
    if (await _ports.agent(ws, wake.agentId) == null) {
      throw WorkspaceMismatchException(
        'Agent ${wake.agentId} is not in workspace $ws',
      );
    }
  }

  static void _requireMayAct(Wake wake, String userId) {
    if (!mayAct(wake, userId)) {
      throw const AuthException(
        'That wake acts for another person',
        code: wakeNotYoursKind,
      );
    }
  }

  Future<Wake> _require(String ws, String wakeId) async {
    final wake = await _wakes.getById(ws, wakeId);
    if (wake == null) {
      throw WorkspaceMismatchException('Wake $wakeId is not in workspace $ws');
    }
    return wake;
  }

  static String _key(Wake wake) =>
      '${wake.workspaceId}\u0000${wake.conversationId}\u0000${wake.agentId}';

  static const String _refPrefix = 'wake:';
  static String _ref(String wakeId) => '$_refPrefix$wakeId';

  static DateTime _minute(DateTime now) => now.add(const Duration(minutes: 1));
}
