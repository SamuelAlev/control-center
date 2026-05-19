import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_supervision_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart'
    show defaultRunCostCapCents;
import 'package:uuid/uuid.dart';

/// Dispatches one bounded agent run for a goal. Wired by the runtime to
/// `MessagingService.dispatchAgentRun` (never `dispatchAgent` — the first
/// run re-sends the `/goal ...` prompt and must not re-enter goal-command
/// detection). Returns the run-log id of the started run, or null when the
/// dispatch was refused.
typedef GoalDispatcher =
    Future<String?> Function({
      required String workspaceId,
      required String channelId,
      required String agentId,
      required String prompt,
      String? conversationId,
      String? requestedByUserId,
      int? costCapCents,
    });

/// Posts a system message into the goal's channel. Wired by the runtime to
/// `MessagingService.postSystemMessage` (senderId 'system', senderType
/// 'agent', messageType 'system' — the take-over refusal shape).
typedef GoalSystemMessageSender =
    Future<void> Function({
      required String workspaceId,
      required String channelId,
      required String content,
      String? conversationId,
    });

/// Keeps a durable `/goal` or `/loop` objective alive: persists it, dispatches
/// bounded runs and — on each [AgentRunCompleted] — decides whether to
/// continue, give up, or stop at a budget wall. State lives in SQLite, so the
/// startup reconciler ([reconcileOnStartup]) resumes objectives across server
/// restarts.
class GoalSupervisor implements GoalSupervisionPort {
  /// Creates a [GoalSupervisor]. When [eventBus] is supplied, the supervisor
  /// subscribes to [AgentRunCompleted] and drives the continue/stop decision
  /// after every finished run. [now] and [backoff] are test seams.
  GoalSupervisor({
    required AgentGoalRunRepository goalRepository,
    required AgentRunLogRepository runLogRepository,
    required GoalDispatcher dispatcher,
    required GoalSystemMessageSender systemMessageSender,
    DomainEventBus? eventBus,
    DateTime Function() now = DateTime.now,
    Duration Function(int consecutiveFailures)? backoff,
  }) : _goalRepository = goalRepository,
       _runLogRepository = runLogRepository,
       _dispatcher = dispatcher,
       _systemMessageSender = systemMessageSender,
       _now = now,
       _backoff = backoff ?? _defaultBackoff {
    _subscription = eventBus?.on<AgentRunCompleted>().listen(
      (event) => unawaited(_onRunCompletedSafely(event)),
    );
  }

  /// Hard cost cap for a whole goal, in cents (priced models only). The
  /// budget is what bounds an unattended goal — there is deliberately no
  /// default deadline or run-count cap (a hard iteration wall kills
  /// legitimate long-term goals; opt in with `/goal --days N` / `--max N`).
  static const int defaultCostCapCents = 5000;

  /// Consecutive failed runs after which the supervisor gives up.
  static const int maxConsecutiveFailures = 3;

  /// Cap for the failure re-dispatch backoff.
  static const Duration maxBackoff = Duration(minutes: 15);

  final AgentGoalRunRepository _goalRepository;
  final AgentRunLogRepository _runLogRepository;
  final GoalDispatcher _dispatcher;
  final GoalSystemMessageSender _systemMessageSender;
  final DateTime Function() _now;
  final Duration Function(int consecutiveFailures) _backoff;
  final _uuid = const Uuid();
  final _timers = <String, Timer>{};
  StreamSubscription<AgentRunCompleted>? _subscription;

  /// 30s × 2^(n-1), capped at 15 min: first retry after 30s, then 60s, 120s…
  static Duration _defaultBackoff(int consecutiveFailures) {
    final shift = consecutiveFailures <= 1 ? 0 : consecutiveFailures - 1;
    final delay = Duration(seconds: 30 << shift);
    return delay > maxBackoff ? maxBackoff : delay;
  }

  /// Starts a durable goal for [agentId] and dispatches its first run with the
  /// verbatim slash command (`/goal <userText>`), so the run behaves exactly
  /// like a human-typed command. Refuses (returns null + system message) when
  /// the agent already has an active goal in this workspace.
  Future<AgentGoalRun?> startGoal({
    required String workspaceId,
    required String channelId,
    required String conversationId,
    required String agentId,
    required String userText,
    required AgentGoalKind kind,
    String? requestedByUserId,
  }) async {
    final existing = await _goalRepository.getActiveForAgent(
      workspaceId,
      agentId,
    );
    if (existing != null) {
      await _systemMessageSender(
        workspaceId: workspaceId,
        channelId: channelId,
        conversationId: conversationId,
        content:
            'This agent already has an active durable '
            '/${existing.kind.wire} goal in this workspace. Complete it with '
            'the complete_goal tool or cancel it before starting a new one.',
      );
      return null;
    }

    final now = _now();
    final flags = _GoalFlags.parse(userText);
    final goal = AgentGoalRun(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      channelId: channelId,
      conversationId: conversationId,
      agentId: agentId,
      userText: flags.objective,
      kind: kind,
      deadlineAt: flags.days == null
          ? null
          : now.add(Duration(days: flags.days!)),
      costCapCents: flags.budgetCents ?? defaultCostCapCents,
      maxRuns: flags.maxRuns,
      requestedByUserId: requestedByUserId,
      createdAt: now,
      updatedAt: now,
    );
    await _goalRepository.upsert(goal);
    await _systemMessageSender(
      workspaceId: workspaceId,
      channelId: channelId,
      conversationId: conversationId,
      content:
          'Started a durable /${kind.wire} goal: ${flags.objective}\n\n'
          'It keeps running until the agent declares it complete with the '
          'complete_goal tool, a human stops it, or the cost cap '
          '(${_dollars(goal.costCapCents)}) is hit'
          '${goal.maxRuns == null ? '' : ', or the run budget of ${goal.maxRuns} runs is exhausted'}'
          '${goal.deadlineAt == null ? '' : ', or the deadline passes'}'
          '.',
    );
    return _dispatchRun(goal, prompt: '/${kind.wire} ${flags.objective}');
  }

  /// `\$x.xx` from cents — budgets are priced in dollars.
  static String _dollars(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  Future<AgentGoalRun?> activeGoalForAgent(
    String workspaceId,
    String agentId,
  ) => _goalRepository.getActiveForAgent(workspaceId, agentId);

  @override
  Future<void> completeGoal(
    String workspaceId,
    String agentId, {
    required String summary,
  }) async {
    final goal = await _goalRepository.getActiveForAgent(workspaceId, agentId);
    if (goal == null) {
      throw StateError('You have no active goal in this workspace.');
    }
    await _terminate(
      goal,
      AgentGoalStatus.completed,
      'Durable /${goal.kind.wire} goal completed: $summary',
      summary: summary,
    );
  }

  /// Pauses [goalId]: no further runs are dispatched until [resumeGoal]. An
  /// in-flight run is left alone; its completion is ignored while paused.
  Future<void> pauseGoal(String workspaceId, String goalId) async {
    final goal = await _goalRepository.getById(workspaceId, goalId);
    if (goal == null || goal.status != AgentGoalStatus.active) {
      return;
    }
    _timers[goal.id]?.cancel();
    await _goalRepository.upsert(
      goal.copyWith(status: AgentGoalStatus.paused, updatedAt: _now()),
    );
    await _systemMessageSender(
      workspaceId: goal.workspaceId,
      channelId: goal.channelId,
      conversationId: goal.conversationId,
      content:
          'Durable /${goal.kind.wire} goal paused. Resume it to keep '
          'dispatching runs.',
    );
  }

  /// Resumes a paused [goalId]: flips it back to active and re-dispatches
  /// immediately (unless its run is still live).
  ///
  /// A `budgetExhausted` goal is also resumable — budget exhaustion is not
  /// completion — but only by RAISING the budget: [raiseCostCapCents] must
  /// lift the cap above the spend that tripped it, otherwise the resume is
  /// refused (re-dispatching into the same wall would burn a run for
  /// nothing). Paused goals resume as-is.
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapCents,
  }) async {
    final goal = await _goalRepository.getById(workspaceId, goalId);
    final fromBudget = goal?.status == AgentGoalStatus.budgetExhausted;
    if (goal == null ||
        (goal.status != AgentGoalStatus.paused && !fromBudget)) {
      return;
    }
    if (fromBudget &&
        (raiseCostCapCents == null || raiseCostCapCents <= goal.costCents)) {
      await _systemMessageSender(
        workspaceId: goal.workspaceId,
        channelId: goal.channelId,
        conversationId: goal.conversationId,
        content:
            'Durable /${goal.kind.wire} goal is stopped at its cost cap '
            '(${_dollars(goal.costCapCents)} spent: ${_dollars(goal.costCents)}). '
            'Resume it with a raised budget to continue.',
      );
      return;
    }
    final resumed = goal.copyWith(
      status: AgentGoalStatus.active,
      costCapCents: raiseCostCapCents,
      updatedAt: _now(),
    );
    await _goalRepository.upsert(resumed);
    final wall = _budgetWall(resumed);
    if (wall != null) {
      await _terminate(
        resumed,
        AgentGoalStatus.budgetExhausted,
        'Durable /${resumed.kind.wire} goal stopped: $wall.',
      );
      return;
    }
    await _systemMessageSender(
      workspaceId: resumed.workspaceId,
      channelId: resumed.channelId,
      conversationId: resumed.conversationId,
      content: 'Durable /${resumed.kind.wire} goal resumed.',
    );
    if (await _hasLiveRun(resumed)) {
      // The in-flight run's completion drives the next step.
      return;
    }
    await _dispatchRun(
      resumed.copyWith(removeActiveRunId: true, updatedAt: _now()),
      prompt: _continuationPrompt(resumed, resumed.runCount + 1),
    );
  }

  /// Cancels [goalId] (terminal): stops any pending re-dispatch. An in-flight
  /// run is orphaned — its completion is ignored because the goal is no
  /// longer active.
  Future<void> cancelGoal(String workspaceId, String goalId) async {
    final goal = await _goalRepository.getById(workspaceId, goalId);
    if (goal == null || goal.status.isTerminal) {
      return;
    }
    await _terminate(
      goal,
      AgentGoalStatus.cancelled,
      'Durable /${goal.kind.wire} goal cancelled.',
    );
  }

  /// Resumes every still-active goal after a server restart: any goal whose
  /// last run died with the process (no active run id, or a terminal run log)
  /// is re-dispatched immediately with the continuation prompt. Paused goals
  /// stay paused; goals already at a budget wall are closed instead.
  Future<void> reconcileOnStartup() async {
    for (final goal in await _goalRepository.listActive()) {
      if (goal.status != AgentGoalStatus.active) {
        continue;
      }
      final wall = _budgetWall(goal);
      if (wall != null) {
        await _terminate(
          goal,
          AgentGoalStatus.budgetExhausted,
          'Durable /${goal.kind.wire} goal stopped: $wall.',
        );
        continue;
      }
      if (await _hasLiveRun(goal)) {
        continue;
      }
      final next = goal.runCount + 1;
      await _systemMessageSender(
        workspaceId: goal.workspaceId,
        channelId: goal.channelId,
        conversationId: goal.conversationId,
        content:
            'Server restarted; continuing the durable '
            '/${goal.kind.wire} goal (run $next'
            '${goal.maxRuns == null ? '' : ' of ${goal.maxRuns}'}).',
      );
      await _dispatchRun(
        goal.copyWith(removeActiveRunId: true, updatedAt: _now()),
        prompt: _continuationPrompt(goal, next),
      );
    }
  }

  /// Cancels pending re-dispatch timers and the event subscription.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  /// Whether the goal's [AgentGoalRun.activeRunId] points at a run that is
  /// still pending or running.
  Future<bool> _hasLiveRun(AgentGoalRun goal) async {
    final runId = goal.activeRunId;
    if (runId == null) {
      return false;
    }
    final log = await _runLogRepository.getById(goal.workspaceId, runId);
    return log != null && log.isActive;
  }

  /// Names the budget wall [goal] sits at, or null when it is within budget.
  String? _budgetWall(AgentGoalRun goal) {
    if (goal.deadlinePassed(_now())) {
      return 'the deadline passed';
    }
    if (goal.costCapReached) {
      return 'the cost cap of ${goal.costCapCents} cents was reached';
    }
    if (goal.runBudgetExhausted) {
      return 'the run budget of ${goal.maxRuns} runs was exhausted';
    }
    return null;
  }

  String _continuationPrompt(AgentGoalRun goal, int nextRun) =>
      'AUTOMATIC CONTINUATION of your durable /${goal.kind.wire} '
      '(run $nextRun${goal.maxRuns == null ? '' : ' of ${goal.maxRuns}'}): '
      '${goal.userText}\n\n'
      'Your previous segment ended; the conversation above + your notes hold '
      'the state. Continue without restarting. Declare the objective achieved '
      'with the complete_goal tool when done.';

  /// Dispatches one run for [goal] and records the returned run-log id as the
  /// goal's active run. Returns the updated goal.
  Future<AgentGoalRun> _dispatchRun(
    AgentGoalRun goal, {
    required String prompt,
  }) async {
    // Thread the goal's REMAINING budget as the run's cost cap so a
    // segment can never overshoot an explicit `/goal --budget` by a whole
    // segment's worth of spend (the default cap is only the upper bound).
    final remaining = goal.costCapCents - goal.costCents;
    final runId = await _dispatcher(
      workspaceId: goal.workspaceId,
      channelId: goal.channelId,
      agentId: goal.agentId,
      prompt: prompt,
      conversationId: goal.conversationId,
      requestedByUserId: goal.requestedByUserId,
      costCapCents:
          (remaining < defaultRunCostCapCents
                  ? remaining
                  : defaultRunCostCapCents)
              .clamp(1, defaultRunCostCapCents),
    );
    final updated = goal.copyWith(
      activeRunId: runId,
      removeActiveRunId: runId == null,
      updatedAt: _now(),
    );
    await _goalRepository.upsert(updated);
    return updated;
  }

  /// Marks [goal] terminal, cancels any pending re-dispatch and narrates the
  /// outcome into the channel.
  Future<void> _terminate(
    AgentGoalRun goal,
    AgentGoalStatus status,
    String message, {
    String? summary,
  }) async {
    _timers[goal.id]?.cancel();
    _timers.remove(goal.id);
    await _goalRepository.upsert(
      goal.copyWith(
        status: status,
        summary: summary,
        removeSummary: summary == null,
        removeActiveRunId: true,
        updatedAt: _now(),
      ),
    );
    await _systemMessageSender(
      workspaceId: goal.workspaceId,
      channelId: goal.channelId,
      conversationId: goal.conversationId,
      content: message,
    );
  }

  Future<void> _onRunCompletedSafely(AgentRunCompleted event) async {
    try {
      await _onRunCompleted(event);
    } catch (_) {
      // A supervisor hiccup must never take down the event bus; the next run
      // completion or the startup reconciler re-drives the goal.
    }
  }

  Future<void> _onRunCompleted(AgentRunCompleted event) async {
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    if (workspaceId == null || runId == null) {
      return;
    }
    final goal = await _goalRepository.getActiveForAgent(
      workspaceId,
      event.agentId,
    );
    if (goal == null || goal.activeRunId != runId) {
      // Not a goal run, or the goal was completed/paused/cancelled meanwhile.
      return;
    }

    final runLog = await _runLogRepository.getById(workspaceId, runId);
    final failed = runLog?.status == RunStatus.error;
    final finished = goal.copyWith(
      costCents: goal.costCents + (runLog?.cost.estimatedCostCents ?? 0),
      runCount: goal.runCount + 1,
      removeActiveRunId: true,
      consecutiveFailures: failed ? goal.consecutiveFailures + 1 : 0,
      updatedAt: _now(),
    );
    await _goalRepository.upsert(finished);

    final wall = _budgetWall(finished);
    if (wall != null) {
      await _terminate(
        finished,
        AgentGoalStatus.budgetExhausted,
        'Durable /${finished.kind.wire} goal stopped: $wall.',
      );
      return;
    }
    if (finished.consecutiveFailures >= maxConsecutiveFailures) {
      await _terminate(
        finished,
        AgentGoalStatus.failed,
        'Durable /${finished.kind.wire} goal failed: '
        '${finished.consecutiveFailures} consecutive runs ended in '
        'error. Giving up.',
      );
      return;
    }

    final next = finished.runCount + 1;
    await _systemMessageSender(
      workspaceId: finished.workspaceId,
      channelId: finished.channelId,
      conversationId: finished.conversationId,
      content:
          'Run ${finished.runCount} finished, continuing '
          '(run $next${finished.maxRuns == null ? '' : ' of ${finished.maxRuns}'}).',
    );
    final prompt = _continuationPrompt(finished, next);
    if (!failed) {
      await _dispatchRun(finished, prompt: prompt);
      return;
    }
    // Failed run: back off before re-dispatching. The goal is reloaded when
    // the timer fires so a pause/cancel meanwhile stops the retry.
    _timers[finished.id]?.cancel();
    _timers[finished.id] = Timer(
      _backoff(finished.consecutiveFailures),
      () =>
          unawaited(_retryDispatch(finished.workspaceId, finished.id, prompt)),
    );
  }

  Future<void> _retryDispatch(
    String workspaceId,
    String goalId,
    String prompt,
  ) async {
    _timers.remove(goalId);
    final goal = await _goalRepository.getById(workspaceId, goalId);
    if (goal == null || goal.status != AgentGoalStatus.active) {
      return;
    }
    try {
      await _dispatchRun(goal, prompt: prompt);
    } catch (_) {
      // Same rationale as _onRunCompletedSafely.
    }
  }
}

/// Optional flags parsed out of a `/goal` or `/loop` body: `--max N` (run
/// budget), `--budget D` (cost cap in dollars, `$` prefix tolerated) and
/// `--days N` (wall-clock deadline). Absent flags mean NO cap — the default
/// goal is bounded only by the cost budget (default or `--budget`), never by
/// an iteration count or a clock.
class _GoalFlags {
  const _GoalFlags({
    required this.objective,
    this.maxRuns,
    this.budgetCents,
    this.days,
  });

  /// The objective with every recognized flag stripped.
  final String objective;

  /// Run budget (`--max N`), or null for uncapped.
  final int? maxRuns;

  /// Cost cap in cents (`--budget D`), or null for the default.
  final int? budgetCents;

  /// Deadline in days from start (`--days N`), or null for no deadline.
  final int? days;

  static const _flagNames = {'--max', '--budget', '--days'};

  /// Splits [text] into the objective and any flags it carries. A flag whose
  /// value is missing or unparseable is left in the objective verbatim — the
  /// model reading the transcript sees exactly what the human typed rather
  /// than a silently dropped half-flag.
  static _GoalFlags parse(String text) {
    final tokens = text.split(RegExp(r'\s+'));
    final kept = <String>[];
    int? maxRuns;
    int? budgetCents;
    int? days;
    var i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (_flagNames.contains(token) && i + 1 < tokens.length) {
        final value = tokens[i + 1];
        final parsed = switch (token) {
          '--max' => int.tryParse(value),
          '--days' => int.tryParse(value),
          _ => _dollarsToCents(value),
        };
        if (parsed != null && parsed > 0) {
          switch (token) {
            case '--max':
              maxRuns = parsed;
            case '--days':
              days = parsed;
            default:
              budgetCents = parsed;
          }
          i += 2;
          continue;
        }
      }
      kept.add(token);
      i++;
    }
    return _GoalFlags(
      objective: kept.join(' ').trim(),
      maxRuns: maxRuns,
      budgetCents: budgetCents,
      days: days,
    );
  }

  /// Parses a dollar amount (`25`, `25.50`, `\$25`) into cents, or null.
  static int? _dollarsToCents(String raw) {
    final dollars = double.tryParse(raw.replaceFirst('\$', ''));
    return dollars == null ? null : (dollars * 100).round();
  }
}
