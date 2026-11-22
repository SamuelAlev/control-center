import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/environment_events.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:cc_domain/features/pipelines/domain/services/schedule_spec.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_pr_watch_events.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

part 'wake_rule_firing.dart';
part 'wake_rule_limit_park.dart';
part 'wake_rule_lineage.dart';
part 'wake_rule_watches.dart';

/// Why a watch could never fire: a `data.kind` ([WakeRuleRefusals]) and a
/// sentence the model can act on.
typedef WakeWatchRefusal = ({String kind, String message});

/// Whether a watch's target may be seen by the rule that watches it, asked
/// when the watch is created and again each time it fires (plan section 9,
/// "Watches"). The server answers from its repositories and forge checks;
/// tests fake it.
abstract interface class WakeWatchAccess {
  /// Why a pull request watch of [spaceId] could never fire, or null when
  /// it can: [target] names one pull request (in a repository the space
  /// exposes), null watches the space's own. Refused when no poll reaches
  /// the target's repository (none exposed, no forge remote, or the server
  /// cannot read it now), or [userId] (the rule's person; null for a bot's
  /// rule) fails the space's read gate.
  Future<WakeWatchRefusal?> prWatchRefusal({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
  });

  /// Whether polled pull request [number] of `repoOwner/repoName`, whose head
  /// branch is [headRef], is one a watch of [spaceId] hears: [target] when it
  /// names one, else the space's own (its worktree's branch in a repository
  /// it exposes, or a pull request the space reviews); and [userId] still
  /// passes the space's read gate.
  Future<bool> prWatched({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
    required String repoOwner,
    required String repoName,
    required int number,
    required String headRef,
  });

  /// Whether the ticket [ticketId] is in the workspace and was delegated by
  /// or is assigned to [agentId].
  Future<bool> ticketWatchable({
    required String workspaceId,
    required String agentId,
    required String ticketId,
  });

  /// Whether the pipeline run [runId], looked up in [workspaceId], belongs
  /// to [spaceId], or (for a rule with a person, [userId]) is one that
  /// person may read.
  Future<bool> pipelineRunWatchable({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required String runId,
  });

}

/// What the rule service asks of the rest of the server, as functions so the
/// runtime wires them and tests fake them.
class WakeRulePorts {
  /// Creates the ports.
  const WakeRulePorts({
    required this.workspaceActive,
    required this.conversationSpace,
    required this.agentInWorkspace,
    required this.agentBusy,
    required this.agentName,
    required this.postRow,
    required this.readSetting,
    required this.writeSetting,
    required this.isKnownZone,
    required this.goalOfRun,
    required this.runWakeIds,
    required this.goalTerminal,
    required this.watchAccess,
    required this.runProvider,
    required this.runFacts,
    required this.startedByRun,
  });

  /// Whether the workspace is registered and not deleted.
  final Future<bool> Function(String workspaceId) workspaceActive;

  /// The space of `conversationId` when the conversation is in the
  /// workspace, else null.
  final Future<String?> Function(String workspaceId, String conversationId)
  conversationSpace;

  /// Whether `agentId` is an agent of the workspace.
  final Future<bool> Function(String workspaceId, String agentId)
  agentInWorkspace;

  /// Whether the agent has a live run in the conversation.
  final Future<bool> Function(
    String workspaceId,
    String conversationId,
    String agentId,
  )
  agentBusy;

  /// The agent's display name, or null when it is not in the workspace.
  final Future<String?> Function(String workspaceId, String agentId)
  agentName;

  /// Posts a system row in a conversation; returns its message id.
  final Future<String?> Function({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required Map<String, Object?> metadata,
  })
  postRow;

  /// Reads a workspace setting's stored text.
  final Future<String?> Function(String workspaceId, String key) readSetting;

  /// Writes a workspace setting's text.
  final Future<void> Function(String workspaceId, String key, String value)
  writeSetting;

  /// Whether an IANA time zone exists.
  final bool Function(String zone) isKnownZone;

  /// The goal whose segment the run `runId` is, or null.
  final Future<String?> Function(String workspaceId, String runId) goalOfRun;

  /// The ids of the wakes the run `runId` carried (empty for none or no
  /// such run): how a rule made in a run finds the rule that started it.
  final Future<List<String>> Function(String workspaceId, String runId)
  runWakeIds;

  /// Whether the goal `goalId` has ended (null when there is no such goal).
  final Future<bool?> Function(String workspaceId, String goalId) goalTerminal;

  /// Watch target checks.
  final WakeWatchAccess watchAccess;

  /// A display label for the provider the run `runId` used
  /// (`LimitPark.providerLabel` of its adapter and model), for the
  /// `[limit-reset]` headline of a rule's run parked at its usage limit.
  final Future<String> Function(String workspaceId, String runId) runProvider;

  /// The run `runId` of the workspace as a rule's history shows it; null
  /// when there is no such run.
  final Future<WakeRuleRunFacts?> Function(String workspaceId, String runId)
  runFacts;

  /// The run whose tool call started the run `runId` by a direct dispatch
  /// (its run log's `started_by_run_id`: a reviewer `dispatch_reviewers`
  /// started, a team leader an agent's `assign_ticket` routed to), when
  /// that run is in the same workspace; null for any other run.
  final Future<String?> Function(String workspaceId, String runId)
  startedByRun;
}

/// A run a rule's wake started: its status (`RunStatus` name), why it ended
/// (`RunEndReason` wire), what it cost in micro-dollars (its subagents'
/// included), when it started and ended (UTC).
typedef WakeRuleRunFacts = ({
  String id,
  String status,
  String? endReason,
  int costMicros,
  DateTime startedAt,
  DateTime? endedAt,
});

/// A draft cron's next fire times (UTC) and whether its zone is known
/// (`WakeRuleService.previewCron`).
typedef WakeCronPreview = ({List<DateTime> nextFires, bool zoneKnown});

/// A page of a rule's wakes, newest first, each with the run it started,
/// and the cursor of the next page (null on the last).
typedef WakeRuleHistoryPage = ({
  List<({Wake wake, WakeRuleRunFacts? run})> wakes,
  String? nextCursor,
});

/// What a person, an agent or an operation asks to create.
class WakeRuleRequest {
  /// Creates a request.
  const WakeRuleRequest({
    required this.workspaceId,
    required this.conversationId,
    required this.agentId,
    required this.when,
    required this.note,
    required this.origin,
    this.timeZone,
    this.clock,
    this.maxRuns,
    this.expiresIn,
    this.costCapMicros,
    this.whenBusy,
    this.deliver = WakeDeliver.run,
    this.createdByRunId,
    this.createdByUserId,
    this.requestedByUserId,
    this.fireNow = false,
  });

  /// The workspace.
  final String workspaceId;

  /// The conversation the rule wakes.
  final String conversationId;

  /// The agent the rule wakes.
  final String agentId;

  /// The `when` grammar (`in:20m`, `every:30m`, `cron:…`, `next`, `on:…`);
  /// null only with [clock].
  final String? when;

  /// A `cron:` rule's zone; null is the workspace's.
  final String? timeZone;

  /// `/schedule at HH:MM`: the next such wall-clock time in the zone.
  final ({int hour, int minute})? clock;

  /// What the rule's runs start from.
  final String note;

  /// Who makes it.
  final WakeRuleOrigin origin;

  /// The run cap asked for.
  final int? maxRuns;

  /// How long the rule lives, asked for.
  final Duration? expiresIn;

  /// The cost cap asked for, in micro-dollars.
  final int? costCapMicros;

  /// What a fire that finds the agent busy does; null is the default
  /// (`skip` for a time rule, `queue` for a watch).
  final WakeWhenBusy? whenBusy;

  /// Start a run or only notify.
  final WakeDeliver deliver;

  /// The run that asked (an agent's `wake_me`).
  final String? createdByRunId;

  /// The person who asked (a command, an operation).
  final String? createdByUserId;

  /// The person the rule acts for: the person for a person's rule, the
  /// creating run's requester for an agent's (null: a bot run).
  final String? requestedByUserId;

  /// Fire the first run at once (a person's `/loop`), rather than at the
  /// first slot.
  final bool fireNow;
}

/// Schedules, loops and event watches on top of the durable wake queue (plan
/// section 9): creates rules within the limits, keeps exactly one pending
/// wake per time rule, records each fire, skip and cost, ends rules for
/// every reason they end, turns watched events into debounced wakes, and
/// re-arms every active rule at boot.
///
/// A rule's wake carries `detail.ruleId` and its slot (`dedupKey`
/// `rule:<id>:<slot ISO>`); the rule row is updated before the next wake is
/// written, so a crash between the two leaves a rule the boot scan re-arms,
/// and a wake whose slot is not the rule's `nextFireAt` is superseded.
class WakeRuleService implements WakeAdmissionGuard {
  /// Creates the service. [start] subscribes it and re-arms rules.
  WakeRuleService({
    required this._rules,
    required this._wakes,
    required this._queue,
    required this._ports,
    required this._eventBus,
    PipelineCronScheduler? scheduler,
    this._clock = DateTime.now,
    this._timerFactory = Timer.new,
    String Function()? newId,
  }) : _scheduler = scheduler ?? PipelineCronScheduler(),
       _newId = newId ?? _defaultId;

  final WakeRuleRepository _rules;
  final WakeRepository _wakes;
  final WakeQueueService _queue;
  final WakeRulePorts _ports;
  final DomainEventBus _eventBus;
  final PipelineCronScheduler _scheduler;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _timerFactory;
  final String Function() _newId;
  final List<StreamSubscription<Object?>> _subs = [];
  final Map<String, _Gathered> _gathered = {};

  /// The write of each rule's watch wake in progress: one at a time per
  /// rule, so a burst written during a live run folds into the last one.
  final Map<String, Future<void>> _watchWrites = {};
  bool _started = false;

  static const _uuid = Uuid();
  static String _defaultId() => _uuid.v4();

  /// The `stateReason` prefix of every wake the service settles itself; its
  /// own settled handler ignores them.
  static const String ownReasonPrefix = 'rule_';

  /// Subscribes to run settlements, goals, member removals and the watched
  /// events, registers the guard and the settled handler, and gives every
  /// active time rule its pending wake. Call once, after the wake queue is
  /// built.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _queue
      ..registerGuard(this)
      ..registerSettledHandler(_settledWake)
      ..lineageRootOfRuns = _lineageRootOfRuns;
    _subs
      ..add(_eventBus.on<AgentRunSettled>().listen(_guarded(_runSettled)))
      ..add(_eventBus.on<GoalSettled>().listen(_guarded(_goalSettled)))
      ..add(
        _eventBus.on<WorkspaceMemberRemoved>().listen(_guarded(_memberRemoved)),
      );
    _subscribeWatches();
    await rearmAll();
  }

  /// Gives every active time rule its pending wake (the boot scan).
  Future<void> rearmAll() => _rearmAll();

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) =>
      _admit(wake, now);

  /// Unsubscribes and drops gathered watch events.
  Future<void> stop() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    await Future.wait([..._watchWrites.values]);
    for (final g in _gathered.values) {
      g.timer?.cancel();
    }
    _gathered.clear();
  }

  void Function(T) _guarded<T>(Future<void> Function(T) handler) =>
      (event) => unawaited(
        handler(event).catchError((Object e, StackTrace st) {
          CcInfraLog.error('WakeRuleService: ${T.toString()}', e, st);
        }),
      );

  // ------------------------------------------------------------- limits

  /// The workspace's limits ([wakeRuleLimitsSettingKey]).
  Future<WakeRuleLimits> limitsFor(String workspaceId) async =>
      WakeRuleLimits.fromSetting(
        await _ports.readSetting(workspaceId, wakeRuleLimitsSettingKey),
      );

  /// Replaces the workspace's limits. Refuses an unknown default zone.
  Future<WakeRuleLimits> setLimits(
    String workspaceId,
    WakeRuleLimits limits,
  ) async {
    await _requireWorkspace(workspaceId);
    if (!_ports.isKnownZone(limits.defaultTimeZone)) {
      throw ValidationException(
        '"${limits.defaultTimeZone}" is not an IANA time zone.',
        code: WakeRuleRefusals.invalidWhen,
      );
    }
    await _ports.writeSetting(
      workspaceId,
      wakeRuleLimitsSettingKey,
      jsonEncode(limits.toJson()),
    );
    return limits;
  }

  // ------------------------------------------------------------- create

  /// Creates a rule. Throws [WorkspaceMismatchException] for a workspace,
  /// conversation or agent outside the workspace, and [ValidationException]
  /// with a [WakeRuleRefusals] code for a refusal.
  Future<WakeRule> create(WakeRuleRequest request) async {
    final ws = request.workspaceId;
    await _requireWorkspace(ws);
    final spaceId = await _ports.conversationSpace(ws, request.conversationId);
    if (spaceId == null) {
      throw WorkspaceMismatchException(
        'Conversation ${request.conversationId} is not in workspace $ws',
      );
    }
    if (!await _ports.agentInWorkspace(ws, request.agentId)) {
      throw WorkspaceMismatchException(
        'Agent ${request.agentId} is not in workspace $ws',
      );
    }
    final limits = await limitsFor(ws);
    final now = _clock().toUtc();
    final trigger = _readTrigger(request, limits, now);
    // Against now as a slot: `in:1m` from 12:07:00.5 is the 12:08:00 slot.
    if (trigger is OnceAt &&
        trigger.at.difference(wakeSlotOf(now)) < Every.minInterval) {
      throw _refuse(
        WakeRuleRefusals.tooSoon,
        'A one-off is at least ${Every.minInterval.inSeconds} seconds ahead '
        '(in:1m or later).',
      );
    }
    final note = request.note.trim();
    if (note.length > WakeRule.maxNoteLength) {
      throw _refuse(
        WakeRuleRefusals.noteTooLong,
        'The note is ${note.length} characters; at most '
        '${WakeRule.maxNoteLength}.',
      );
    }
    final agentMade = request.origin == WakeRuleOrigin.agent;
    final watch = trigger is OnEvent;
    final repeating = trigger.repeats && !watch;
    if (agentMade &&
        repeating &&
        request.maxRuns == null &&
        request.expiresIn == null) {
      throw _refuse(
        WakeRuleRefusals.expiryRequired,
        'A repeating wake needs max_runs or expires_in (it ends after 7 days '
        'at most unless a person extends it).',
      );
    }
    final maxRuns =
        request.maxRuns ??
        (watch
            ? WakeRuleBounds.watchDefaultMaxRuns
            : agentMade && repeating
            ? WakeRuleBounds.agentDefaultMaxRuns
            : null);
    if (maxRuns != null &&
        (maxRuns < 1 || maxRuns > WakeRuleBounds.maxRunsCeiling)) {
      throw _refuse(
        WakeRuleRefusals.limitOutOfRange,
        'max_runs is 1 to ${WakeRuleBounds.maxRunsCeiling}.',
      );
    }
    final costCap = request.costCapMicros ?? limits.costCapMicros;
    if (costCap < 1 || costCap > WakeRuleLimits.maxCostCapMicros) {
      throw _refuse(
        WakeRuleRefusals.limitOutOfRange,
        'The cost cap is above 0 and at most '
        '${_usd(WakeRuleLimits.maxCostCapMicros)}.',
      );
    }
    final goalId = request.createdByRunId == null
        ? null
        : await _ports.goalOfRun(ws, request.createdByRunId!);
    // A rule an agent makes in a run an agent's rule (or a wake of its
    // lineage) started joins that lineage: the root's expiry, the root's
    // caps. A run a person's rule started is a person's run: no lineage.
    final lineage = agentMade && goalId == null && request.createdByRunId != null
        ? await _lineageOfRun(ws, request.createdByRunId!)
        : null;
    if (lineage != null) {
      await _requireLineageOpen(lineage, trigger, now);
    }
    final ownExpiry = _expiryFor(trigger, request, now);
    final expiresAt =
        lineage != null && lineage.root.expiresAt.isBefore(ownExpiry)
        ? lineage.root.expiresAt
        : ownExpiry;
    final requestedBy = request.origin == WakeRuleOrigin.person
        ? (request.requestedByUserId ?? request.createdByUserId)
        : request.requestedByUserId;
    if (trigger is OnEvent) {
      await _requireWatchable(
        ws,
        spaceId: spaceId,
        agentId: request.agentId,
        userId: requestedBy,
        trigger: trigger,
      );
    }
    final whenBusy =
        request.whenBusy ?? (watch ? WakeWhenBusy.queue : WakeWhenBusy.skip);
    final firstAt = request.fireNow ? now : _firstSlot(trigger, now);
    final first = firstAt == null ? null : wakeSlotOf(firstAt);
    final rule = WakeRule(
      id: _newId(),
      workspaceId: ws,
      spaceId: spaceId,
      conversationId: request.conversationId,
      agentId: request.agentId,
      trigger: trigger,
      note: note,
      deliver: request.deliver,
      whenBusy: whenBusy,
      maxRuns: maxRuns,
      costCapMicros: costCap,
      expiresAt: expiresAt,
      nextFireAt: watch ? null : first,
      goalId: goalId,
      rootRuleId: lineage?.root.id,
      origin: request.origin,
      createdByRunId: request.createdByRunId,
      createdByUserId: request.createdByUserId,
      requestedByUserId: requestedBy,
      createdAt: now,
      updatedAt: now,
    );
    final refused = await _rules.insertWithinLimits(
      rule,
      perConversation: limits.perConversation,
      perAgent: limits.perAgent,
      perWorkspace: limits.perWorkspace,
      lineage: lineage == null
          ? null
          : (
              rootRuleId: lineage.root.id,
              maxRuns: _lineageRunCapOf(lineage.root),
              costCapMicros: lineage.root.costCapMicros,
            ),
    );
    if (refused == WakeRuleLimit.lineage) {
      await _lineageSpent(lineage!);
    }
    if (refused != null) {
      final (scope, cap) = switch (refused) {
        WakeRuleLimit.conversation => (
          'in this conversation',
          limits.perConversation,
        ),
        WakeRuleLimit.agent => ('in this workspace', limits.perAgent),
        WakeRuleLimit.workspace || WakeRuleLimit.lineage => (
          'across the workspace',
          limits.perWorkspace,
        ),
      };
      throw _refuse(
        WakeRuleRefusals.limitReached,
        refused == WakeRuleLimit.workspace
            ? 'The workspace already has $cap wake rules $scope; cancel one '
                  'first.'
            : 'This agent already has $cap wake rules $scope; cancel one '
                  'first.',
      );
    }
    if (first != null && !watch) {
      await _armSlot(rule, first);
    }
    return rule;
  }

  WakeTrigger _readTrigger(
    WakeRuleRequest request,
    WakeRuleLimits limits,
    DateTime now,
  ) {
    final zone = (request.timeZone?.trim().isNotEmpty ?? false)
        ? request.timeZone!.trim()
        : limits.defaultTimeZone;
    final clock = request.clock;
    if (clock != null) {
      return OnceAt(_nextWallClock(clock, zone, now));
    }
    final when = request.when;
    if (when == null) {
      throw _refuse(WakeRuleRefusals.invalidWhen, wakeWhenGrammar);
    }
    return switch (parseWakeWhen(
      when,
      now: now,
      timeZone: zone,
      isKnownZone: _ports.isKnownZone,
    )) {
      WakeWhenTrigger(:final trigger) => trigger,
      WakeWhenNext() => const SelfPaced(),
      WakeWhenTooShort(:final interval) => throw _refuse(
        WakeRuleRefusals.intervalTooShort,
        'every:${formatWakeDuration(interval)} is under the 60-second '
        'minimum.',
      ),
      WakeWhenInvalid(:final message) => throw _refuse(
        WakeRuleRefusals.invalidWhen,
        message,
      ),
    };
  }

  /// The next instant whose wall clock in [zone] reads [clock] (after
  /// [now]).
  DateTime _nextWallClock(
    ({int hour, int minute}) clock,
    String zone,
    DateTime now,
  ) {
    if (!_ports.isKnownZone(zone)) {
      throw _refuse(
        WakeRuleRefusals.invalidWhen,
        '"$zone" is not an IANA time zone.',
      );
    }
    final spec = _CronSpec('${clock.minute} ${clock.hour} * * *', zone);
    final at = _scheduler.nextSlotAfter(spec, now);
    if (at == null) {
      throw _refuse(WakeRuleRefusals.invalidWhen, 'That time never comes.');
    }
    return at;
  }

  DateTime _expiryFor(WakeTrigger trigger, WakeRuleRequest r, DateTime now) {
    final person = r.origin == WakeRuleOrigin.person;
    final max = person
        ? WakeRuleBounds.personMaxExpiry
        : WakeRuleBounds.agentMaxExpiry;
    if (trigger is OnceAt) {
      if (trigger.at.difference(now) > max) {
        throw _refuse(
          WakeRuleRefusals.expiryTooLong,
          'A one-off may be set at most ${max.inDays} days ahead.',
        );
      }
      return trigger.at.add(WakeRuleBounds.oneOffGrace);
    }
    final asked = r.expiresIn;
    if (asked != null && (asked > max || asked <= Duration.zero)) {
      throw _refuse(
        WakeRuleRefusals.expiryTooLong,
        'expires_in is at most ${max.inDays} days.',
      );
    }
    return now.add(
      asked ??
          (person
              ? WakeRuleBounds.personDefaultExpiry
              : WakeRuleBounds.agentDefaultExpiry),
    );
  }

  DateTime? _firstSlot(WakeTrigger trigger, DateTime now) => switch (trigger) {
    OnceAt(:final at) => at,
    Every() || Cron() => _scheduler.nextSlotAfter(_specOf(trigger), now),
    SelfPaced() => now,
    OnEvent() => null,
  };

  Future<void> _requireWatchable(
    String ws, {
    required String spaceId,
    required String agentId,
    required String? userId,
    required OnEvent trigger,
  }) async {
    final access = _ports.watchAccess;
    if (OnEvent.isPullRequest(trigger.eventKind)) {
      final refusal = await access.prWatchRefusal(
        workspaceId: ws,
        spaceId: spaceId,
        userId: userId,
        target: trigger.pullRequest,
      );
      if (refusal != null) {
        throw _refuse(refusal.kind, refusal.message);
      }
      return;
    }
    final ok = switch (trigger.eventKind) {
      WakeEventKind.ticket => await access.ticketWatchable(
        workspaceId: ws,
        agentId: agentId,
        ticketId: trigger.targetId!,
      ),
      WakeEventKind.pipelineRun => await access.pipelineRunWatchable(
        workspaceId: ws,
        spaceId: spaceId,
        userId: userId,
        runId: trigger.targetId!,
      ),
      _ => true,
    };
    if (!ok) {
      throw _refuse(
        WakeRuleRefusals.watchRefused,
        trigger.eventKind == WakeEventKind.ticket
            ? 'No ticket ${trigger.targetId} that you delegated or were '
                  'assigned is in this workspace.'
            : 'No pipeline run ${trigger.targetId} of this space is in this '
                  'workspace.',
      );
    }
  }

  // ------------------------------------------------------------- changes

  /// A rule's changes from a person or an operation: [note], [whenBusy],
  /// [maxRuns] (pass [clearMaxRuns] to drop the cap), [costCapMicros], and
  /// [expiresAt] (within the maker's maximum from the rule's creation).
  /// Throws [NotFoundException] for an unknown id and [ValidationException]
  /// for an ended rule or a value out of range.
  Future<WakeRule> update(
    String workspaceId,
    String id, {
    String? note,
    WakeWhenBusy? whenBusy,
    int? maxRuns,
    bool clearMaxRuns = false,
    int? costCapMicros,
    DateTime? expiresAt,
    required String? editedByUserId,
  }) async {
    final rule = await require(workspaceId, id);
    if (!rule.isActive && rule.status != WakeRuleStatus.paused) {
      throw _refuse(WakeRuleRefusals.ruleEnded, 'This wake rule has ended.');
    }
    final now = _clock().toUtc();
    if (note != null || whenBusy != null) {
      final text = (note ?? rule.note).trim();
      if (text.length > WakeRule.maxNoteLength) {
        throw _refuse(
          WakeRuleRefusals.noteTooLong,
          'The note is ${text.length} characters; at most '
          '${WakeRule.maxNoteLength}.',
        );
      }
      await _rules.setTerms(
        workspaceId,
        id: id,
        note: text,
        whenBusy: whenBusy ?? rule.whenBusy,
        // The note becomes the person's words only when they change it.
        noteEditedByUserId: text == rule.note ? null : editedByUserId,
        now: now,
      );
    }
    if (maxRuns != null ||
        clearMaxRuns ||
        costCapMicros != null ||
        expiresAt != null) {
      final runs = clearMaxRuns ? null : (maxRuns ?? rule.maxRuns);
      if (runs != null && (runs < 1 || runs > WakeRuleBounds.maxRunsCeiling)) {
        throw _refuse(
          WakeRuleRefusals.limitOutOfRange,
          'max_runs is 1 to ${WakeRuleBounds.maxRunsCeiling}.',
        );
      }
      final cap = costCapMicros ?? rule.costCapMicros;
      if (cap < 1 || cap > WakeRuleLimits.maxCostCapMicros) {
        throw _refuse(
          WakeRuleRefusals.limitOutOfRange,
          'The cost cap is above 0 and at most '
          '${_usd(WakeRuleLimits.maxCostCapMicros)}.',
        );
      }
      final until = expiresAt?.toUtc() ?? rule.expiresAt;
      final rootId = rule.rootRuleId;
      if (rootId != null && until.isAfter(rule.expiresAt)) {
        final root = await _rules.getById(workspaceId, rootId);
        if (root == null || until.isAfter(root.expiresAt)) {
          throw _refuse(
            WakeRuleRefusals.expiryTooLong,
            'This wake belongs to the chain that started with wake $rootId '
            'and ends with it; extend $rootId instead.',
          );
        }
      }
      final max = rule.origin == WakeRuleOrigin.person
          ? WakeRuleBounds.personMaxExpiry
          : WakeRuleBounds.agentMaxExpiry;
      if (!until.isAfter(now) || until.difference(rule.createdAt) > max) {
        throw _refuse(
          WakeRuleRefusals.expiryTooLong,
          'The expiry is in the future and at most ${max.inDays} days after '
          'the rule was created.',
        );
      }
      await _rules.setLimits(
        workspaceId,
        id: id,
        expiresAt: until,
        maxRuns: runs,
        costCapMicros: cap,
        now: now,
      );
    }
    // The guard reads `when_busy` at each fire; the next wake carries the
    // new expiry.
    return require(workspaceId, id);
  }

  /// Pauses an active rule: its pending wake is cancelled. When [pausedBy]
  /// is not the person the rule acts for (or the rule acts for nobody), one
  /// row in its conversation names who paused it. False when it was not
  /// active.
  Future<bool> pause(
    String workspaceId,
    String id, {
    required String pausedBy,
  }) async {
    final rule = await require(workspaceId, id);
    final moved = await _rules.transition(
      workspaceId,
      id: id,
      from: {WakeRuleStatus.active},
      to: WakeRuleStatus.paused,
      endReason: null,
      now: _clock().toUtc(),
    );
    if (moved) {
      _gathered.remove(id)?.timer?.cancel();
      await _queue.cancelWhere(
        workspaceId,
        ruleId: id,
        reason: '${ownReasonPrefix}paused',
      );
      if (rule.requestedByUserId != pausedBy) {
        try {
          await _ports.postRow(
            workspaceId: workspaceId,
            spaceId: rule.spaceId,
            conversationId: rule.conversationId,
            content: wakeRulePausedRowText(rule, pausedBy),
            metadata: {
              'kind': wakeRulePausedRowKind,
              'ruleId': rule.id,
              'agentId': rule.agentId,
              'pausedByUserId': pausedBy,
            },
          );
        } on Object catch (e) {
          CcInfraLog.warning('WakeRuleService: paused row failed: $e');
        }
      }
    }
    return moved;
  }

  /// Resumes a paused rule from its next slot after now. False when it was
  /// not paused.
  Future<bool> resume(String workspaceId, String id) async {
    final rule = await require(workspaceId, id);
    final now = _clock().toUtc();
    if (rule.expiredAt(now) && rule.status == WakeRuleStatus.paused) {
      await _rules.transition(
        workspaceId,
        id: id,
        from: {WakeRuleStatus.paused},
        to: WakeRuleStatus.active,
        endReason: null,
        now: now,
      );
      await end(workspaceId, id, WakeRuleEndReason.expired);
      return true;
    }
    final moved = await _rules.transition(
      workspaceId,
      id: id,
      from: {WakeRuleStatus.paused},
      to: WakeRuleStatus.active,
      endReason: null,
      now: now,
    );
    if (moved && !rule.isWatch) {
      final next = switch (rule.trigger) {
        OnceAt(:final at) => at.isAfter(now) ? at : wakeSlotOf(now),
        SelfPaced() => wakeSlotOf(now.add(_delayOf(rule))),
        _ => _slotAfter(rule, now),
      };
      if (next == null) {
        await end(workspaceId, id, WakeRuleEndReason.expired);
        return true;
      }
      await _rules.setNext(
        workspaceId,
        id: id,
        nextFireAt: next,
        nextDelaySeconds: rule.nextDelaySeconds,
        now: now,
      );
      final armed = await _rules.getById(workspaceId, id);
      if (armed != null) {
        await _armSlot(armed, next);
      }
    }
    return moved;
  }

  /// A person's delete: ends a rule that has not ended (`cancelled`) and
  /// removes the row of one that has. False when there is no such rule.
  Future<bool> delete(String workspaceId, String id) async {
    final rule = await require(workspaceId, id);
    if (rule.status == WakeRuleStatus.ended) {
      return _rules.delete(workspaceId, id);
    }
    return end(workspaceId, id, WakeRuleEndReason.cancelled);
  }

  /// Sets the delay before the next run of the self-paced rule [id]
  /// (`wake_me(when: "next")` inside a run it started). Clamped to 1 minute
  /// to 1 hour. Returns the delay set.
  Future<Duration> setNextDelay(
    String workspaceId,
    String id,
    Duration delay,
  ) async {
    final rule = await require(workspaceId, id);
    if (rule.trigger is! SelfPaced || !rule.isActive) {
      throw _refuse(
        WakeRuleRefusals.nextOutsideLoop,
        'next sets the delay of an active self-paced loop only.',
      );
    }
    final clamped = delay < SelfPaced.minDelay
        ? SelfPaced.minDelay
        : delay > SelfPaced.maxDelay
        ? SelfPaced.maxDelay
        : delay;
    await _rules.setNext(
      workspaceId,
      id: id,
      nextFireAt: rule.nextFireAt,
      nextDelaySeconds: clamped.inSeconds,
      now: _clock().toUtc(),
    );
    return clamped;
  }

  /// Ends the rule [id] with [reason]: moves it to `ended`, cancels its
  /// pending wake, posts one row and publishes [WakeRuleEnded]; a lineage's
  /// root takes its lineage with it ([_endLineageOf]). False when it had
  /// already ended.
  Future<bool> end(
    String workspaceId,
    String id,
    WakeRuleEndReason reason,
  ) async {
    final now = _clock().toUtc();
    final moved = await _rules.transition(
      workspaceId,
      id: id,
      from: {WakeRuleStatus.active, WakeRuleStatus.paused},
      to: WakeRuleStatus.ended,
      endReason: reason,
      now: now,
    );
    if (!moved) {
      return false;
    }
    _gathered.remove(id)?.timer?.cancel();
    await _queue.cancelWhere(
      workspaceId,
      ruleId: id,
      reason: '${ownReasonPrefix}ended',
    );
    final rule = await _rules.getById(workspaceId, id);
    if (rule == null) {
      return true;
    }
    try {
      await _ports.postRow(
        workspaceId: workspaceId,
        spaceId: rule.spaceId,
        conversationId: rule.conversationId,
        content: wakeRuleEndedRowText(rule, reason),
        metadata: {
          'kind': wakeRuleEndedRowKind,
          'ruleId': rule.id,
          'endReason': reason.wire,
          'agentId': rule.agentId,
        },
      );
    } on Object catch (e) {
      CcInfraLog.warning('WakeRuleService: ended row failed: $e');
    }
    _eventBus.publish(
      WakeRuleEnded(
        ruleId: rule.id,
        workspaceId: workspaceId,
        spaceId: rule.spaceId,
        conversationId: rule.conversationId,
        agentId: rule.agentId,
        reason: reason,
        requestedByUserId: rule.requestedByUserId,
        occurredAt: now,
      ),
    );
    await _endLineageOf(rule, reason);
    return true;
  }

  // ------------------------------------------------------------- reads

  /// The rule [id] in [workspaceId]. Throws [NotFoundException].
  Future<WakeRule> require(String workspaceId, String id) async {
    await _requireWorkspace(workspaceId);
    final rule = await _rules.getById(workspaceId, id);
    if (rule == null) {
      throw NotFoundException('No wake rule $id in this workspace');
    }
    return rule;
  }

  /// The rules that have not ended which [agentId] holds in
  /// [conversationId] (schedules, loops and watches).
  Future<List<WakeRule>> openRulesOf(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async => [
    for (final r in await _rules.listForConversation(
      workspaceId,
      conversationId,
      statuses: {WakeRuleStatus.active, WakeRuleStatus.paused},
    ))
      if (r.agentId == agentId) r,
  ];

  /// The self-paced rule whose wake started a run (the run's [wakeIds]),
  /// or null.
  Future<WakeRule?> loopOfRun(String workspaceId, List<String> wakeIds) async {
    for (final id in wakeIds) {
      final wake = await _wakes.getById(workspaceId, id);
      final ruleId = wake?.detail.ruleId;
      if (ruleId == null) {
        continue;
      }
      final rule = await _rules.getById(workspaceId, ruleId);
      if (rule != null && rule.trigger is SelfPaced && rule.isActive) {
        return rule;
      }
    }
    return null;
  }

  /// When the rule fires next as the agent would read it: the next slot, or
  /// null for a watch (it fires when its event happens).
  DateTime? nextFireOf(WakeRule rule) => rule.isWatch ? null : rule.nextFireAt;

  /// Where [rule]'s lineage stands (its root, the runs it has left, when it
  /// ends), or null for a rule in none.
  Future<WakeLineageStatus?> lineageStatus(WakeRule rule) async {
    final rootId = rule.rootRuleId;
    if (rootId == null) {
      return null;
    }
    final root = await _rules.getById(rule.workspaceId, rootId);
    if (root == null) {
      return null;
    }
    final spent = await _rules.lineageTotals(rule.workspaceId, rootId);
    final left = _lineageRunCapOf(root) - spent.runs;
    return (
      rootRuleId: rootId,
      runsLeft: left < 0 ? 0 : left,
      endsAt: root.expiresAt,
    );
  }

  /// How many fire times [nextFires] and [previewCron] give at most.
  static const int previewCount = 3;

  /// The longest cron expression [previewCron] reads.
  static const int maxPreviewExpressionLength = 200;

  /// The longest zone name [previewCron] reads.
  static const int maxPreviewZoneLength = 64;

  /// The next fire times of a cron [rule] that has not ended (UTC, at most
  /// [previewCount]), from the server's clock with the scheduler the rule
  /// fires with: only slots it can still fire, so none at or after its
  /// expiry and no more than the runs it (and its lineage) has left. Empty
  /// for every other rule.
  Future<List<DateTime>> nextFires(WakeRule rule) async {
    if (rule.trigger is! Cron || rule.status == WakeRuleStatus.ended) {
      return const [];
    }
    var left = previewCount;
    final own = rule.maxRuns;
    if (own != null && own - rule.runCount < left) {
      left = own - rule.runCount;
    }
    final chain = await _lineageRunsLeft(rule);
    if (chain != null && chain < left) {
      left = chain;
    }
    return _slotsAfter(
      rule,
      _clock().toUtc(),
      count: left,
      before: rule.expiresAt.toUtc(),
    );
  }

  /// The next fire times (UTC, at most [previewCount]) of a draft cron
  /// [expression] in [timeZone] (empty: the workspace's zone), from the
  /// server's clock, for the New schedule dialog, and whether the server's
  /// zone database knows [timeZone] (true when it is empty; false for one
  /// over [maxPreviewZoneLength]). No times for an empty expression (a zone
  /// asked about alone), one that does not parse, never fires or is over
  /// [maxPreviewExpressionLength], or an unknown zone. Throws
  /// [WorkspaceMismatchException] for a workspace not registered.
  Future<WakeCronPreview> previewCron(
    String workspaceId, {
    required String expression,
    required String timeZone,
  }) async {
    await _requireWorkspace(workspaceId);
    final expr = expression.trim();
    final asked = timeZone.trim();
    final zoneKnown =
        asked.isEmpty ||
        (asked.length <= maxPreviewZoneLength && _ports.isKnownZone(asked));
    if (!zoneKnown ||
        expr.isEmpty ||
        expr.length > maxPreviewExpressionLength) {
      return (nextFires: const <DateTime>[], zoneKnown: zoneKnown);
    }
    final zone = asked.isEmpty
        ? (await limitsFor(workspaceId)).defaultTimeZone
        : asked;
    final spec = _CronSpec(expr, zone);
    if (spec.cronSchedule == null || !_ports.isKnownZone(zone)) {
      return (nextFires: const <DateTime>[], zoneKnown: zoneKnown);
    }
    return (
      nextFires: _slotsAfter(spec, _clock().toUtc(), count: previewCount),
      zoneKnown: zoneKnown,
    );
  }

  List<DateTime> _slotsAfter(
    ScheduleSpec spec,
    DateTime after, {
    required int count,
    DateTime? before,
  }) {
    final out = <DateTime>[];
    var cursor = after;
    while (out.length < count) {
      final next = _scheduler.nextSlotAfter(spec, cursor);
      if (next == null ||
          !next.isAfter(cursor) ||
          (before != null && !next.isBefore(before))) {
        break;
      }
      out.add(next);
      cursor = next;
    }
    return out;
  }

  /// The most rows a page of [history] has.
  static const int historyPageSize = 50;

  /// [rule]'s wakes, newest first, a page of [historyPageSize] after
  /// [cursor] (a page's `nextCursor`), each with the run it started (none
  /// for a wake that was skipped, cancelled or is still waiting). A watch's
  /// wake folded into a later one is left out. Reads [rule]'s own wakes
  /// only (its conversation, its id). Throws [ValidationException] for a
  /// cursor this method did not give.
  Future<WakeRuleHistoryPage> history(WakeRule rule, {String? cursor}) async {
    final before = cursor == null ? null : _historyCursorOf(cursor);
    final ws = rule.workspaceId;
    final raw = await _wakes.listForRule(
      ws,
      conversationId: rule.conversationId,
      ruleId: rule.id,
      limit: historyPageSize,
      before: before,
    );
    final rows = <({Wake wake, WakeRuleRunFacts? run})>[];
    for (final wake in raw) {
      if (wake.workspaceId != ws ||
          wake.detail.ruleId != rule.id ||
          wake.stateReason == '${ownReasonPrefix}folded') {
        continue;
      }
      final runId = wake.deliveredRunId;
      rows.add((
        wake: wake,
        run: runId == null ? null : await _ports.runFacts(ws, runId),
      ));
    }
    final last = raw.length < historyPageSize ? null : raw.last;
    return (
      wakes: rows,
      nextCursor: last == null
          ? null
          : '${last.createdAt.toUtc().toIso8601String()}|${last.id}',
    );
  }

  static ({DateTime createdAt, String id}) _historyCursorOf(String cursor) {
    final cut = cursor.indexOf('|');
    final at = cut <= 0 ? null : DateTime.tryParse(cursor.substring(0, cut));
    final id = cut < 0 ? '' : cursor.substring(cut + 1);
    if (at == null || id.isEmpty) {
      throw const ValidationException(
        'cursor: not one a page of this rule gave',
      );
    }
    return (createdAt: at.toUtc(), id: id);
  }

  // ------------------------------------------------------------- helpers

  Future<void> _requireWorkspace(String workspaceId) async {
    if (!await _ports.workspaceActive(workspaceId)) {
      throw WorkspaceMismatchException(
        'Workspace $workspaceId is not registered',
      );
    }
  }

  static ValidationException _refuse(String kind, String message) =>
      ValidationException(message, code: kind);

  static String _usd(int micros) =>
      '${(micros / 1000000).toStringAsFixed(2)} USD';

  _CronSpec _specOf(WakeTrigger trigger) => switch (trigger) {
    Every(:final interval) => _CronSpec.every(interval),
    Cron(:final expression, :final timeZone) => _CronSpec(expression, timeZone),
    _ => throw StateError('$trigger has no slots'),
  };

  static Duration _delayOf(WakeRule rule) => switch (rule.nextDelaySeconds) {
    final int s => Duration(seconds: s),
    null => SelfPaced.defaultDelay,
  };
}

/// The `kind` of the row a rule's end posts.
const String wakeRuleEndedRowKind = 'wake_rule_ended';

/// The row a rule's end posts: which rule, and why it ended.
String wakeRuleEndedRowText(WakeRule rule, WakeRuleEndReason reason) {
  final why = switch (reason) {
    WakeRuleEndReason.fired => 'it fired',
    WakeRuleEndReason.expired => 'it expired',
    WakeRuleEndReason.runCap when rule.rootRuleId != null =>
      'its chain of wakes used its runs',
    WakeRuleEndReason.runCap =>
      'it used its ${rule.maxRuns ?? rule.runCount} runs',
    WakeRuleEndReason.costCap when rule.rootRuleId != null =>
      'its chain of wakes reached its cost cap',
    WakeRuleEndReason.costCap => 'it reached its cost cap',
    WakeRuleEndReason.goalEnded => 'its goal ended',
    WakeRuleEndReason.cancelled => 'it was cancelled',
    WakeRuleEndReason.memberRemoved => 'its person left the workspace',
    WakeRuleEndReason.invalidRow => 'its stored row could not be read',
  };
  return 'Wake rule ended ($why): ${formatWakeWhen(rule.trigger)} · '
      '"${wakeRuleNoteGist(rule.note)}"';
}

/// The `kind` of the row a pause by someone other than the rule's person
/// posts.
const String wakeRulePausedRowKind = 'wake_rule_paused';

/// The row a pause by someone other than the rule's person posts: which
/// rule, and who paused it (a user id; the clients show the name).
String wakeRulePausedRowText(WakeRule rule, String pausedBy) =>
    'Wake rule paused by user $pausedBy: ${formatWakeWhen(rule.trigger)} · '
    '"${wakeRuleNoteGist(rule.note)}"';

/// The first line of a note, cut to 80 characters, for a row or a list.
String wakeRuleNoteGist(String note) {
  final line = note.trim().split('\n').first.trim();
  return line.length <= 80 ? line : '${line.substring(0, 79)}…';
}

/// A schedule with only the slot facts, for arithmetic before a rule exists.
class _CronSpec implements ScheduleSpec {
  _CronSpec(String expression, this.timezone)
    : cronSchedule = CronSchedule.tryParse(expression),
      intervalSeconds = null;

  _CronSpec.every(Duration interval)
    : intervalSeconds = interval.inSeconds,
      cronSchedule = null,
      timezone = null;

  @override
  final int? intervalSeconds;

  @override
  final CronSchedule? cronSchedule;

  @override
  final String? timezone;
}
