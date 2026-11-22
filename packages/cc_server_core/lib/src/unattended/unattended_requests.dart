import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';

/// A pending approval as the expiry reads it.
typedef PendingApprovalView = ({
  String title,
  String? runId,
  DateTime createdAt,
});

/// A request that waits on a person with a deadline, as the daily digest
/// lists it ([UnattendedRequests.pendingIn]).
typedef PendingRequestView = ({
  String waitId,
  AgentInputKind kind,
  String summary,
  String runId,
  String agentId,
  String? requestedByUserId,
  String? goalId,
  String? spaceId,
  String? conversationId,
  DateTime deadline,
});

/// What [UnattendedRequests] reaches. Production binds the approvals
/// registry, the question service, the run log, the goal store, the
/// dispatch service and the workspace settings
/// (`runtime/server_unattended_wiring.dart`).
class UnattendedRequestPorts {
  /// Creates the ports.
  const UnattendedRequestPorts({
    required this.readSetting,
    required this.writeSetting,
    required this.runById,
    required this.approval,
    required this.denyApprovalAfter,
    required this.denyApproval,
    required this.questionWaitUntil,
    required this.questionPending,
    required this.releaseQuestion,
    required this.segmentGoalOf,
    required this.transitionGoal,
    required this.cancelGoalWakes,
    required this.publishGoalSettled,
    required this.postRow,
    required this.tellRun,
    required this.stopping,
  });

  /// A workspace setting's stored text, or null.
  final Future<String?> Function(String workspaceId, String key) readSetting;

  /// Writes a workspace setting; null removes it.
  final Future<void> Function(String workspaceId, String key, String? value)
  writeSetting;

  /// The run `runId` of the workspace, or null.
  final Future<AgentRunLog?> Function(String workspaceId, String runId) runById;

  /// The approval pending as `waitId`, or null when it is not pending.
  final PendingApprovalView? Function(String waitId) approval;

  /// Moves the approval's own deadline: denied once `after` has passed.
  final bool Function(String waitId, Duration after) denyApprovalAfter;

  /// Denies the pending approval `waitId` now. Only ever denies.
  final bool Function(String waitId) denyApproval;

  /// Moves the question's own deadline to `until`.
  final Future<bool> Function(String messageId, DateTime until)
  questionWaitUntil;

  /// Whether the question `messageId` still waits for an answer.
  final bool Function(String messageId) questionPending;

  /// Ends the wait on a question with a server notice (never a person's
  /// answer). Returns whether it was still pending.
  final bool Function(String messageId, AgentQuestionAnswer answer)
  releaseQuestion;

  /// The goal whose current segment is `runId`, or null (a review run, a
  /// run that is no goal's segment).
  final Future<AgentGoalRun?> Function(String workspaceId, String runId)
  segmentGoalOf;

  /// Moves a goal with a compare-and-set write (`GoalStore.transition`).
  final Future<AgentGoalRun?> Function(
    AgentGoalRun goal,
    AgentGoalRun? Function(AgentGoalRun current) next,
  )
  transitionGoal;

  /// Cancels the goal's open wakes.
  final Future<void> Function(AgentGoalRun goal) cancelGoalWakes;

  /// Announces a goal that now needs a person (`goal_settled`).
  final void Function(AgentGoalRun goal) publishGoalSettled;

  /// Posts a system row into a conversation.
  final Future<void> Function({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  })
  postRow;

  /// Tells a live run something, as steering that is not a person's words.
  final Future<bool> Function(String runId, String notice) tellRun;

  /// Whether the server is shutting down: nothing it ends is a person's
  /// silence.
  final bool Function() stopping;
}

/// One request [UnattendedRequests] holds a deadline for.
class _Wait {
  _Wait({
    required this.workspaceId,
    required this.waitId,
    required this.kind,
    required this.summary,
    required this.run,
    required this.goal,
    required this.expiry,
    required this.markerKey,
    required this.deadline,
  });

  final String workspaceId;
  final String waitId;
  final AgentInputKind kind;
  final String summary;
  final AgentRunLog run;
  final AgentGoalRun? goal;
  final Duration expiry;
  final String markerKey;
  final DateTime deadline;
  Timer? expire;
  Timer? assume;

  void cancel() {
    expire?.cancel();
    assume?.cancel();
  }
}

/// What happens to a request nobody answers (plan section 12, "When nobody
/// answers"; D21).
///
/// A run the server started (its run log's `wakeReason` is set and is not
/// `userMessage`) that waits on a person's approval or answer waits the
/// workspace's expiry ([UnattendedPolicy.expiry], default 72 hours) and no
/// longer: then an approval is denied and a question withdrawn as
/// unanswered, the run is told and ends its turn, and the goal whose
/// segment it is goes to `paused` with `hold: needsReview`, `holdDetail:
/// unanswered`. Nothing here ever approves anything: an expiry only denies.
/// A run a person started is never touched.
///
/// The deadline counts from when the request was made, and holds across a
/// restart: the first wait of a run is recorded in a workspace setting
/// ([markerKeyOf]) with the run's wakes, and only a run that delivers one of
/// those wakes again (the run a restart interrupted, resumed) keeps that
/// start. The record is dropped when a person answers, when a person
/// pauses, resumes, cancels or closes the goal ([forgetGoal]), and when the
/// run ends for any reason but the server stopping.
///
/// Once a request of a run expired, nobody is there: for the rest of that
/// run a later approval is refused and a later question counts as
/// unanswered at once, with no card or form ([refuseApproval],
/// [answerQuestion]). Only an expiry sets this, and only the run's end
/// clears it; a person's answer in the run does not.
///
/// A goal started with `--unattended assume` gets its question (never an
/// approval) released after [unattendedAssumeAfter] with
/// [unattendedAssumeAnswer].
class UnattendedRequests {
  /// Creates the service.
  UnattendedRequests({
    required DomainEventBus eventBus,
    required this._ports,
    DateTime Function()? now,
  }) : _bus = eventBus,
       _now = now ?? DateTime.now;

  final DomainEventBus _bus;
  final UnattendedRequestPorts _ports;
  final DateTime Function() _now;
  final List<StreamSubscription<Object?>> _subs = [];
  final Map<String, _Wait> _waits = {};

  /// Runs (`<workspaceId>/<runId>`) one of whose requests expired.
  final Set<String> _expiredRuns = {};

  /// How long after the expiry the request's own deadline falls, so the
  /// expiry, not the default timeout, decides.
  static const Duration backstop = Duration(minutes: 5);

  /// A recorded first wait older than the longest expiry by this much is
  /// stale and not inherited.
  static const Duration markerTtl = Duration(days: 7);

  /// The workspace setting that records when [agentId]'s first unanswered
  /// request in [conversationId] was made.
  static String markerKeyOf(String agentId, String conversationId) =>
      'unattended_wait:$agentId:$conversationId';

  /// Whether [run] is one the server started: its expiry applies.
  static bool serverStarted(AgentRunLog run) {
    final reason = run.wakeReason;
    return reason != null && reason != WakeReason.userMessage;
  }

  /// Subscribes to the bus.
  void start() {
    _subs
      ..add(_bus.on<AgentAwaitingInput>().listen(_guard(_onAwaiting)))
      ..add(_bus.on<AgentInputResolved>().listen(_guard(_onResolved)))
      ..add(_bus.on<AgentRunSettled>().listen(_guard(_onSettled)));
  }

  /// Requests with a deadline now, by wait id.
  Iterable<String> get tracked => _waits.keys;

  /// The requests of [workspaceId] that wait with a deadline now, oldest
  /// deadline first.
  List<PendingRequestView> pendingIn(String workspaceId) => [
    for (final w in _waits.values)
      if (w.workspaceId == workspaceId)
        (
          waitId: w.waitId,
          kind: w.kind,
          summary: w.summary,
          runId: w.run.id,
          agentId: w.run.agentId,
          requestedByUserId: w.run.requestedByUserId,
          goalId: w.goal?.id,
          spaceId: w.run.spaceId ?? w.goal?.spaceId,
          conversationId: w.run.conversationId,
          deadline: w.deadline,
        ),
  ]..sort((a, b) => a.deadline.compareTo(b.deadline));

  /// Whether a request of run [runId] in [workspaceId] already expired.
  bool expiredIn(String? workspaceId, String? runId) =>
      workspaceId != null &&
      runId != null &&
      _expiredRuns.contains('$workspaceId/$runId');

  /// The approvals registry's check before a card is shown: true refuses
  /// [request] at once (an earlier request of its run expired), and the run
  /// is told nobody is there. Synchronous; never approves.
  bool refuseApproval(ConfirmationRequest request) {
    final runId = request.runId;
    if (_ports.stopping() || !expiredIn(request.workspaceId, runId)) {
      return false;
    }
    unawaited(
      _ports
          .tellRun(runId!, unattendedAfterExpiryApprovalNotice(request.title))
          .then((_) {}, onError: (Object _) {}),
    );
    return true;
  }

  /// The question service's check before a form is posted: an answer for
  /// [request] when an earlier request of its run expired, else null.
  AgentQuestionAnswer? answerQuestion(AgentQuestionRequest request) {
    if (_ports.stopping() || !expiredIn(request.workspaceId, request.runId)) {
      return null;
    }
    return const AgentQuestionAnswer.unanswered(
      unattendedAfterExpiryQuestionNotice,
      proceed: false,
    );
  }

  void Function(T) _guard<T>(Future<void> Function(T) body) => (event) {
    unawaited(
      body(event).catchError((Object e) {
        // A failed expiry leaves the request's own deadline in place.
      }),
    );
  };

  Future<void> _onAwaiting(AgentAwaitingInput event) async {
    if (event.kind == AgentInputKind.credential || _ports.stopping()) {
      return;
    }
    final approval = event.kind == AgentInputKind.approval
        ? _ports.approval(event.waitId)
        : null;
    if (event.kind == AgentInputKind.approval && approval == null) {
      return;
    }
    final run = await _runOf(event, approval);
    if (run == null ||
        !serverStarted(run) ||
        run.workspaceId != event.workspaceId) {
      return;
    }
    final conversationId = run.conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }
    final policy = UnattendedPolicy.fromSetting(
      await _ports.readSetting(event.workspaceId, unattendedPolicySettingKey),
    );
    final goal = await _ports.segmentGoalOf(event.workspaceId, run.id);
    final askedAt = approval?.createdAt ?? event.occurredAt;
    final key = markerKeyOf(run.agentId, conversationId);
    final since = await _since(event.workspaceId, key, run, goal, askedAt);
    final deadline = since.add(policy.expiry);
    final wait = _Wait(
      workspaceId: event.workspaceId,
      waitId: event.waitId,
      kind: event.kind,
      summary: approval?.title ?? event.summary,
      run: run,
      goal: goal,
      expiry: policy.expiry,
      markerKey: key,
      deadline: deadline,
    );
    _waits.remove(event.waitId)?.cancel();
    _waits[event.waitId] = wait;
    final now = _now();
    // The request's own deadline moves past this one, so the workspace's
    // expiry decides rather than the default timeout.
    if (event.kind == AgentInputKind.approval) {
      _ports.denyApprovalAfter(
        event.waitId,
        deadline.difference(now) + backstop,
      );
    } else {
      await _ports.questionWaitUntil(event.waitId, deadline.add(backstop));
    }
    final left = deadline.difference(now);
    wait.expire = Timer(left.isNegative ? Duration.zero : left, () {
      unawaited(_expire(wait).catchError((Object _) {}));
    });
    if (event.kind == AgentInputKind.question &&
        goal != null &&
        goal.unattended == GoalUnattendedPolicy.assume) {
      final release = askedAt.add(unattendedAssumeAfter).difference(now);
      if (release < left) {
        wait.assume = Timer(release.isNegative ? Duration.zero : release, () {
          unawaited(_assume(wait).catchError((Object _) {}));
        });
      }
    }
  }

  /// The run that asked, by its id only: a request whose run is unknown
  /// keeps the person-run defaults (never another run's expiry or goal).
  Future<AgentRunLog?> _runOf(
    AgentAwaitingInput event,
    PendingApprovalView? approval,
  ) async {
    final runId = event.runId ?? approval?.runId;
    if (runId == null || runId.isEmpty) {
      return null;
    }
    return _ports.runById(event.workspaceId, runId);
  }

  /// When the unanswered stretch began: a recorded first wait of the same
  /// goal or wake, else [askedAt] (which is then recorded).
  Future<DateTime> _since(
    String workspaceId,
    String key,
    AgentRunLog run,
    AgentGoalRun? goal,
    DateTime askedAt,
  ) async {
    final recorded = _Marker.parse(await _ports.readSetting(workspaceId, key));
    final now = _now();
    // Only a run that delivers one of the recorded run's wakes again (the
    // same request, resumed after a restart) carries the stretch on; a later
    // segment of the goal, started by a new wake, starts its own.
    if (recorded != null &&
        now.difference(recorded.since) <=
            UnattendedPolicy.maxExpiry + markerTtl &&
        recorded.wakeIds.any(run.wakeIds.contains)) {
      return recorded.since.isBefore(askedAt) ? recorded.since : askedAt;
    }
    await _ports.writeSetting(
      workspaceId,
      key,
      _Marker(since: askedAt, goalId: goal?.id, wakeIds: run.wakeIds).encode(),
    );
    return askedAt;
  }

  /// Nobody answered in time: deny or withdraw, pause the goal, tell the
  /// run. Never approves.
  Future<void> _expire(_Wait wait) async {
    if (!identical(_waits[wait.waitId], wait) || _ports.stopping()) {
      return;
    }
    _waits.remove(wait.waitId);
    wait.cancel();
    final pending = wait.kind == AgentInputKind.approval
        ? _ports.approval(wait.waitId) != null
        : _ports.questionPending(wait.waitId);
    if (!pending) {
      return;
    }
    // The goal first: the segment that ends next must find it paused, so
    // its settlement counts the cost and starts nothing.
    final paused = await _pauseGoal(wait);
    final released = switch (wait.kind) {
      AgentInputKind.approval => _ports.denyApproval(wait.waitId),
      _ => _ports.releaseQuestion(
        wait.waitId,
        AgentQuestionAnswer.unanswered(
          unattendedQuestionNotice(wait.expiry),
          proceed: false,
        ),
      ),
    };
    if (!released) {
      return;
    }
    // Nobody is there: the run's later requests are refused at once.
    _expiredRuns.add('${wait.workspaceId}/${wait.run.id}');
    if (wait.kind == AgentInputKind.approval) {
      await _ports.tellRun(
        wait.run.id,
        unattendedApprovalNotice(wait.summary, wait.expiry),
      );
    }
    await _postExpired(wait, goalPaused: paused != null);
    await _ports.writeSetting(wait.workspaceId, wait.markerKey, null);
  }

  Future<AgentGoalRun?> _pauseGoal(_Wait wait) async {
    final goal = wait.goal;
    if (goal == null) {
      return null;
    }
    final paused = await _ports.transitionGoal(
      goal,
      (g) => g.status != AgentGoalStatus.active || g.activeRunId != wait.run.id
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.needsReview,
              holdDetail: goalHoldUnanswered,
              removeHoldUntil: true,
              updatedAt: _now(),
            ),
    );
    if (paused != null) {
      await _ports.cancelGoalWakes(paused);
      _ports.publishGoalSettled(paused);
    }
    return paused;
  }

  Future<void> _postExpired(_Wait wait, {required bool goalPaused}) async {
    final spaceId = wait.run.spaceId ?? wait.goal?.spaceId;
    final conversationId = wait.run.conversationId;
    if (spaceId == null || conversationId == null) {
      return;
    }
    await _ports.postRow(
      workspaceId: wait.workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: unattendedExpiredRow(
        what: wait.kind == AgentInputKind.approval ? 'approval' : 'question',
        summary: wait.summary,
        expiry: wait.expiry,
        goalPaused: goalPaused,
      ),
    );
  }

  /// An `--unattended assume` goal's question, still unanswered after
  /// [unattendedAssumeAfter]: released with [unattendedAssumeAnswer].
  Future<void> _assume(_Wait wait) async {
    if (!identical(_waits[wait.waitId], wait) ||
        wait.kind != AgentInputKind.question ||
        _ports.stopping()) {
      return;
    }
    if (!_ports.releaseQuestion(
      wait.waitId,
      const AgentQuestionAnswer.unanswered(
        unattendedAssumeAnswer,
        proceed: true,
      ),
    )) {
      return;
    }
    _waits.remove(wait.waitId)?.cancel();
  }

  Future<void> _onResolved(AgentInputResolved event) async {
    final wait = _waits.remove(event.waitId);
    if (wait == null) {
      return;
    }
    wait.cancel();
    // A shutdown abandons every wait: that is not an answer, and the
    // unanswered stretch carries over to the resumed run.
    if (_ports.stopping()) {
      return;
    }
    final siblings = _waits.values.any(
      (w) => w.workspaceId == wait.workspaceId && w.markerKey == wait.markerKey,
    );
    if (!siblings) {
      await _ports.writeSetting(wait.workspaceId, wait.markerKey, null);
    }
  }

  Future<void> _onSettled(AgentRunSettled event) async {
    for (final id in [
      for (final e in _waits.entries)
        if (e.value.run.id == event.runId &&
            e.value.workspaceId == event.workspaceId)
          e.key,
    ]) {
      _waits.remove(id)?.cancel();
    }
    _expiredRuns.remove('${event.workspaceId}/${event.runId}');
    final conversationId = event.conversationId;
    final reason = event.wakeReason;
    if (event.endReason == RunEndReason.serverStopped ||
        _ports.stopping() ||
        conversationId == null ||
        reason == null ||
        reason == WakeReason.userMessage) {
      return;
    }
    final key = markerKeyOf(event.agentId, conversationId);
    if (await _ports.readSetting(event.workspaceId, key) != null) {
      await _ports.writeSetting(event.workspaceId, key, null);
    }
  }

  /// A person paused, resumed, cancelled or closed [goal]: its recorded
  /// unanswered stretch is forgotten, so a later request starts afresh.
  Future<void> forgetGoal(AgentGoalRun goal) async {
    final key = markerKeyOf(goal.agentId, goal.conversationId);
    final recorded = _Marker.parse(
      await _ports.readSetting(goal.workspaceId, key),
    );
    if (recorded != null && recorded.goalId == goal.id) {
      await _ports.writeSetting(goal.workspaceId, key, null);
    }
  }

  /// Stops listening and drops every deadline it holds; the requests keep
  /// their own.
  Future<void> dispose() async {
    for (final w in _waits.values) {
      w.cancel();
    }
    _waits.clear();
    _expiredRuns.clear();
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}

/// The recorded first unanswered request of a run, goal or wake.
class _Marker {
  _Marker({required this.since, required this.goalId, required this.wakeIds});

  final DateTime since;
  final String? goalId;
  final List<String> wakeIds;

  static _Marker? parse(String? stored) {
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(stored);
      if (json is! Map) {
        return null;
      }
      final since = DateTime.tryParse('${json['since']}');
      if (since == null) {
        return null;
      }
      final wakes = json['wake_ids'];
      return _Marker(
        since: since,
        goalId: json['goal_id'] is String ? json['goal_id'] as String : null,
        wakeIds: wakes is List ? [for (final w in wakes) '$w'] : const [],
      );
    } on FormatException {
      return null;
    }
  }

  String encode() => jsonEncode({
    'since': since.toUtc().toIso8601String(),
    'goal_id': ?goalId,
    'wake_ids': wakeIds,
  });
}
