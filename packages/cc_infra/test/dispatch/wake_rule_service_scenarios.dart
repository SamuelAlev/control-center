import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/environment_events.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_pr_watch_events.dart';
import 'package:cc_infra/src/dispatch/peer_wakes.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/ticket_settled_wakes.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/dispatch/wake_rule_service.dart';
import 'package:cc_infra/src/pipelines/timezone_zone_converter.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart' show FakeWakeRunLedger;

class _Timer implements Timer {
  _Timer(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

/// A Claude Code run of agent-1 in conv-1 whose turn ended while its
/// background task runs: live, and held only for that wait.
class _HeldRun implements SteeringSessionView, BackgroundHoldView {
  int yields = 0;

  @override
  String? get workspaceId => 'ws-1';
  @override
  String? get conversationId => 'conv-1';
  @override
  String? get agentId => 'agent-1';
  @override
  String? get runLogId => 'live-run';
  @override
  String? get requestedByUserId => 'user-1';
  @override
  bool get readOnly => false;
  @override
  bool get freshHistory => false;
  @override
  bool acceptsSteering = true;
  @override
  bool get heldForBackgroundOnly => true;

  @override
  void yieldBackgroundHold() {
    yields++;
    acceptsSteering = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Access implements WakeWatchAccess {
  /// `ws/space/owner/name` the space exposes, polled, its person may read.
  final Set<String> prs = {'ws-1/sp-1/acme/shop-ui'};
  final Set<String> tickets = {'ws-1/agent-1/T-1'};

  /// `ws/space/run`: a pipeline run and the space it belongs to.
  final Set<String> runs = {'ws-1/sp-1/R-1'};

  /// `ws/run` a person may read wherever the run belongs.
  final Set<String> readableRuns = {};

  bool _exposes(String ws, String space, String owner, String name) =>
      prs.contains('$ws/$space/$owner/$name');

  @override
  Future<WakeWatchRefusal?> prWatchRefusal({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
  }) async {
    final ok = target == null
        ? prs.any((k) => k.startsWith('$workspaceId/$spaceId/'))
        : _exposes(workspaceId, spaceId, target.owner, target.name);
    return ok
        ? null
        : (kind: WakeRuleRefusals.watchTargetUnreadable, message: 'unread');
  }

  /// The space's own pull request: head branch `space/<space>`.
  @override
  Future<bool> prWatched({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required WakePullRequestRef? target,
    required String repoOwner,
    required String repoName,
    required int number,
    required String headRef,
  }) async =>
      _exposes(workspaceId, spaceId, repoOwner, repoName) &&
      (target?.names(repoOwner, repoName, number) ??
          headRef == 'space/$spaceId');

  @override
  Future<bool> ticketWatchable({
    required String workspaceId,
    required String agentId,
    required String ticketId,
  }) async => tickets.contains('$workspaceId/$agentId/$ticketId');

  @override
  Future<bool> pipelineRunWatchable({
    required String workspaceId,
    required String spaceId,
    required String? userId,
    required String runId,
  }) async =>
      runs.contains('$workspaceId/$spaceId/$runId') ||
      (userId != null &&
          runs.any(
            (k) => k.startsWith('$workspaceId/') && k.endsWith('/$runId'),
          ) &&
          readableRuns.contains('$workspaceId/$runId'));
}

/// The two stores a scenario runs on: the in-memory fakes here, the real
/// repositories over in-memory workspace databases in `cc_server_core`
/// (`wake_rule_service_persistence_test.dart`). Workspaces `ws-1` (agents
/// `agent-1`, `agent-2`; `conv-1` in `sp-1`, `conv-2` in `sp-2`; goal
/// `goal-1` in `conv-1`) and `ws-2` (`agent-1`; `conv-9` in `sp-9`).
abstract class WakeRuleStores {
  /// The wakes.
  WakeRepository get wakes;

  /// The rules.
  WakeRuleRepository get rules;

  /// Every wake of [workspaceId].
  Future<List<Wake>> all(String workspaceId);

  /// Closes what [wakes] and [rules] hold open.
  Future<void> close();
}

/// Opens the stores for one test; [clock] is the test's clock.
typedef OpenWakeRuleStores =
    Future<WakeRuleStores> Function(DateTime Function() clock);

/// The rule service's scenarios on the stores [open] gives.
void wakeRuleServiceScenarios(OpenWakeRuleStores open) {
  late WakeRuleStores stores;
  late WakeRepository wakes;
  late WakeRuleRepository rules;
  late DomainEventBus bus;
  late DateTime now;
  late WakeQueueService queue;
  late WakeRuleService service;
  late List<WakeDispatchRequest> dispatched;
  // Runs inside the dispatch port, before the queue records the delivery.
  Future<void> Function(WakeDispatchRequest run, String runId)? onDispatch;
  late List<
    ({
      String workspaceId,
      String spaceId,
      String conversationId,
      String content,
      Map<String, Object?> metadata,
    })
  >
  rows;
  late List<_Timer> timers;
  late bool busy;
  // Live runs the queue sees (a run held for its background tasks).
  late List<SteeringSessionView> live;
  late Set<String> members;
  late Map<String, String> settings;
  late Map<String, String> goalOfRun;
  // The wakes each dispatched run carried, by run id.
  late Map<String, List<String>> runWakes;
  late Map<String, WakeRuleRunFacts> runFacts;
  // The run whose tool call started each run by a direct dispatch (the run
  // log's `started_by_run_id`).
  late Map<String, String> startedBy;
  late Map<String, bool> goalEnded;
  late _Access access;
  late List<WakeRuleEnded> ended;
  late List<MessageReceived> notified;
  var runSeq = 0;
  var idSeq = 0;
  final zones = TimezoneZoneConverter.instance;

  Agent agent(String id) => Agent(
    id: id,
    name: 'Builder',
    title: 't',
    agentMdPath: '/tmp/$id.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(const []),
    createdAt: DateTime.utc(2026),
    lifecycleStatus: AgentLifecycleStatus.active,
  );

  /// Builds the queue and the service over the stores, as a server boot
  /// does.
  Future<void> boot() async {
    Future<void> postRow({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String content,
      required Map<String, Object?> metadata,
    }) async => rows.add((
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: content,
      metadata: metadata,
    ));
    queue = WakeQueueService(
      wakes: wakes,
      runLedger: FakeWakeRunLedger(),
      eventBus: bus,
      clock: () => now,
      timerFactory: _Timer.new,
      nonce: () => 'nonce1',
      newId: () => 'q-${idSeq++}',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => ws == 'ws-1' || ws == 'ws-2',
        conversationSpace: (ws, conv) async => switch ((ws, conv)) {
          ('ws-1', 'conv-1') => 'sp-1',
          ('ws-1', 'conv-2') => 'sp-2',
          ('ws-2', 'conv-9') => 'sp-9',
          _ => null,
        },
        agent: (ws, id) async => ws == 'ws-1' ? agent(id) : null,
        isMember: (ws, user) async => members.contains(user),
        takenOver: (ws, space) async => false,
        budgetBlocked: (ws, agentId) async => false,
        liveSessions: (conv) => [
          for (final s in live)
            if (s.conversationId == conv) s,
        ],
        hasLiveRun: (ws, conv, agentId) async => busy,
        dispatch: (run) async {
          dispatched.add(run);
          final runId = 'run-${++runSeq}';
          runWakes[runId] = run.wakeContext.wakeIds;
          await onDispatch?.call(run, runId);
          return runId;
        },
        postSystemRow: postRow,
      ),
    );
    await queue.start();
    service = WakeRuleService(
      rules: rules,
      wakes: wakes,
      queue: queue,
      eventBus: bus,
      scheduler: zones.scheduler(),
      clock: () => now,
      timerFactory: (delay, cb) {
        final t = _Timer(delay, cb);
        timers.add(t);
        return t;
      },
      newId: () => 'rule-${idSeq++}',
      ports: WakeRulePorts(
        workspaceActive: (ws) async => ws == 'ws-1' || ws == 'ws-2',
        conversationSpace: (ws, conv) async => switch ((ws, conv)) {
          ('ws-1', 'conv-1') => 'sp-1',
          ('ws-1', 'conv-2') => 'sp-2',
          ('ws-2', 'conv-9') => 'sp-9',
          _ => null,
        },
        agentInWorkspace: (ws, id) async =>
            ws == 'ws-1' && (id == 'agent-1' || id == 'agent-2'),
        // As the server wires it: a run held only for its background tasks
        // is not busy.
        agentBusy: queue.agentBusy,
        agentName: (ws, id) async => ws == 'ws-1' ? 'Builder $id' : null,
        postRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async {
              await postRow(
                workspaceId: workspaceId,
                spaceId: spaceId,
                conversationId: conversationId,
                content: content,
                metadata: metadata,
              );
              return 'msg-${rows.length}';
            },
        readSetting: (ws, key) async => settings['$ws/$key'],
        writeSetting: (ws, key, value) async => settings['$ws/$key'] = value,
        isKnownZone: zones.isKnown,
        goalOfRun: (ws, runId) async => goalOfRun[runId],
        runWakeIds: (ws, runId) async => runWakes[runId] ?? const [],
        goalTerminal: (ws, goalId) async => goalEnded[goalId],
        watchAccess: access,
        runProvider: (ws, runId) async => 'anthropic',
        runFacts: (ws, runId) async => ws == 'ws-1' ? runFacts[runId] : null,
        startedByRun: (ws, runId) async =>
            ws == 'ws-1' ? startedBy[runId] : null,
      ),
    );
    await service.start();
  }

  setUp(() async {
    stores = await open(() => now);
    wakes = stores.wakes;
    rules = stores.rules;
    bus = DomainEventBus();
    now = DateTime.utc(2026, 5, 1, 12, 7);
    dispatched = [];
    onDispatch = null;
    rows = [];
    timers = [];
    busy = false;
    live = [];
    members = {'user-1', 'user-2'};
    settings = {};
    goalOfRun = {};
    runWakes = {};
    runFacts = {};
    startedBy = {};
    goalEnded = {};
    access = _Access();
    ended = [];
    notified = [];
    runSeq = 0;
    idSeq = 0;
    bus.on<WakeRuleEnded>().listen(ended.add);
    bus.on<MessageReceived>().listen(notified.add);
    await boot();
  });

  tearDown(() async {
    await service.stop();
    await queue.stop();
    bus.dispose();
    await stores.close();
  });

  Future<void> advance(Duration by) async {
    now = now.add(by);
    await queue.tick();
    await pumpEventQueue();
  }

  Future<void> settle(
    String runId, {
    List<String> wakeIds = const [],
    int costMicros = 0,
    RunEndReason endReason = RunEndReason.completed,
    DateTime? limitResetsAt,
    WakeReason? wakeReason,
  }) async {
    bus.publish(
      AgentRunSettled(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        runId: runId,
        status: RunStatus.completed,
        endReason: endReason,
        costMicros: costMicros,
        limitResetsAt: limitResetsAt,
        wakeIds: wakeIds,
        requestedByUserId: null,
        wakeReason: wakeReason,
        occurredAt: now,
      ),
    );
    await pumpEventQueue();
  }

  WakeRuleRequest agentRequest(
    String when, {
    int? maxRuns,
    Duration? expiresIn,
    String conversationId = 'conv-1',
    String workspaceId = 'ws-1',
    String agentId = 'agent-1',
    WakeWhenBusy? whenBusy,
    WakeDeliver deliver = WakeDeliver.run,
    String? createdByRunId = 'run-0',
    String? requestedByUserId,
    String? timeZone,
    int? costCapMicros,
  }) => WakeRuleRequest(
    workspaceId: workspaceId,
    conversationId: conversationId,
    agentId: agentId,
    when: when,
    note: 'check the deploy',
    origin: WakeRuleOrigin.agent,
    maxRuns: maxRuns,
    expiresIn: expiresIn,
    whenBusy: whenBusy,
    deliver: deliver,
    createdByRunId: createdByRunId,
    requestedByUserId: requestedByUserId,
    timeZone: timeZone,
    costCapMicros: costCapMicros,
  );

  Future<List<Wake>> pending(String ruleId, {String ws = 'ws-1'}) async => [
    for (final w in await stores.all(ws))
      if (w.detail.ruleId == ruleId && w.state == WakeState.pending) w,
  ];

  Future<WakeRule> ruleOf(String id, {String ws = 'ws-1'}) async =>
      (await rules.getById(ws, id))!;

  Matcher refusedWith(String kind) =>
      throwsA(isA<ValidationException>().having((e) => e.code, 'code', kind));

  group('creation limits', () {
    test('an interval under 60 seconds is refused', () {
      expect(
        service.create(agentRequest('every:30s', maxRuns: 3)),
        refusedWith(WakeRuleRefusals.intervalTooShort),
      );
    });

    test('an agent\'s repeating rule needs max_runs or expires_in', () async {
      expect(
        service.create(agentRequest('every:20m')),
        refusedWith(WakeRuleRefusals.expiryRequired),
      );
      final capped = await service.create(
        agentRequest('every:20m', maxRuns: 3),
      );
      expect(capped.maxRuns, 3);
      expect(capped.expiresAt, now.add(const Duration(days: 7)));
      final timed = await service.create(
        agentRequest('every:20m', expiresIn: const Duration(days: 2)),
      );
      expect(timed.maxRuns, WakeRuleBounds.agentDefaultMaxRuns);
      expect(timed.expiresAt, now.add(const Duration(days: 2)));
    });

    test('an expiry past the maker\'s maximum is refused', () {
      expect(
        service.create(
          agentRequest('every:1h', expiresIn: const Duration(days: 31)),
        ),
        refusedWith(WakeRuleRefusals.expiryTooLong),
      );
      expect(
        service.create(agentRequest('in:31d')),
        refusedWith(WakeRuleRefusals.expiryTooLong),
      );
    });

    test('each count cap refuses with its own message', () async {
      settings['ws-1/$wakeRuleLimitsSettingKey'] =
          '{"per_conversation": 2, "per_agent": 3, "per_workspace": 4}';
      await service.create(agentRequest('in:1h'));
      await service.create(agentRequest('in:2h'));
      await expectLater(
        service.create(agentRequest('in:3h')),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', WakeRuleRefusals.limitReached)
              .having((e) => e.message, 'message', contains('conversation')),
        ),
      );
      await service.create(agentRequest('in:3h', conversationId: 'conv-2'));
      await expectLater(
        service.create(agentRequest('in:4h', conversationId: 'conv-2')),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', WakeRuleRefusals.limitReached)
              .having(
                (e) => e.message,
                'message',
                contains('in this workspace'),
              ),
        ),
      );
      await service.create(agentRequest('in:4h', agentId: 'agent-2'));
      await expectLater(
        service.create(agentRequest('in:5h', agentId: 'agent-2')),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', WakeRuleRefusals.limitReached)
              .having((e) => e.message, 'message', contains('across')),
        ),
      );
    });

    test(
      'a time rule gets exactly one pending wake at its first slot',
      () async {
        final rule = await service.create(
          agentRequest('every:20m', maxRuns: 5),
        );
        final waiting = await pending(rule.id);
        expect(waiting, hasLength(1));
        expect(waiting.single.notBefore, DateTime.utc(2026, 5, 1, 12, 20));
        expect(
          waiting.single.dedupKey,
          'rule:${rule.id}:2026-05-01T12:20:00.000Z',
        );
        expect(waiting.single.reason, WakeReason.schedule);
        expect(waiting.single.runOptions?.costCapMicros, 5000000);
        expect(waiting.single.detail.fields[WakeFields.origin], 'agent');
      },
    );
  });

  group('firing', () {
    test('a one-off fires once and ends', () async {
      final rule = await service.create(agentRequest('in:10m'));
      await advance(const Duration(minutes: 10, seconds: 3));
      expect(dispatched, hasLength(1));
      final after = await ruleOf(rule.id);
      expect(after.status, WakeRuleStatus.ended);
      expect(after.endReason, WakeRuleEndReason.fired);
      expect(after.runCount, 1);
      expect(await pending(rule.id), isEmpty);
      expect(ended.single.reason, WakeRuleEndReason.fired);
      expect(
        rows.where((r) => r.metadata['kind'] == wakeRuleEndedRowKind),
        hasLength(1),
      );
      await advance(const Duration(hours: 1));
      expect(dispatched, hasLength(1));
    });

    test('a repeating rule writes its next slot after each fire', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 2));
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, hasLength(1));
      final next = (await pending(rule.id)).single;
      expect(next.notBefore, DateTime.utc(2026, 5, 1, 12, 40));
      expect(next.detail.fields[WakeFields.run], 2);
      await advance(const Duration(minutes: 20));
      expect(dispatched, hasLength(2));
      final after = await ruleOf(rule.id);
      expect(after.endReason, WakeRuleEndReason.runCap);
      expect(await pending(rule.id), isEmpty);
    });

    test('busy with when_busy skip: no run, one skip, the next slot', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      busy = true;
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, isEmpty);
      final after = await ruleOf(rule.id);
      expect(after.skipCount, 1);
      expect(after.runCount, 0);
      expect(
        (await pending(rule.id)).single.notBefore,
        DateTime.utc(2026, 5, 1, 12, 40),
      );
      // Quiet: no "not delivered" row for a busy loop.
      expect(rows.where((r) => r.metadata['kind'] == 'wake_skipped'), isEmpty);
    });

    test('busy only with a run held for its background tasks, when_busy '
        'skip: the run yields and the wake is delivered once it settles, no '
        'skip', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      final held = _HeldRun();
      live.add(held);
      busy = true;
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, isEmpty);
      expect(held.yields, 1);
      expect((await ruleOf(rule.id)).skipCount, 0);
      live.clear();
      busy = false;
      await settle('live-run');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(after.skipCount, 0);
    });

    test('busy with when_busy queue: the wake waits for the run', () async {
      final rule = await service.create(
        agentRequest('every:20m', maxRuns: 5, whenBusy: WakeWhenBusy.queue),
      );
      busy = true;
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, isEmpty);
      expect((await ruleOf(rule.id)).skipCount, 0);
      busy = false;
      await settle('live-run');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await ruleOf(rule.id)).runCount, 1);
    });

    test('late inside the grace still fires', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      // 12:20 slot, grace 10 minutes: at 12:28 it still fires.
      await advance(const Duration(minutes: 21));
      expect(dispatched, hasLength(1));
      expect((await ruleOf(rule.id)).skipCount, 0);
    });

    test('late past the grace is one skip and the next future slot, '
        'however many slots were missed', () async {
      final rule = await service.create(agentRequest('every:1m', maxRuns: 500));
      // The server is down for three hours: 180 slots pass.
      now = now.add(const Duration(hours: 3));
      await service.rearmAll();
      await queue.tick();
      await pumpEventQueue();
      await queue.tick();
      await pumpEventQueue();
      expect(dispatched, isEmpty);
      final after = await ruleOf(rule.id);
      expect(after.skipCount, 1);
      expect(after.runCount, 0);
      final next = (await pending(rule.id)).single.notBefore;
      expect(next.isAfter(now), isTrue);
      expect(
        next.difference(now),
        lessThanOrEqualTo(const Duration(minutes: 1)),
      );
    });

    test('restart recovery: re-arming twice writes no second wake', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await service.rearmAll();
      await service.rearmAll();
      expect(await pending(rule.id), hasLength(1));
      // The rule moved on but its next wake was never written (a crash
      // between the two writes): the scan writes it once.
      await advance(const Duration(minutes: 13, seconds: 3));
      final next = (await pending(rule.id)).single;
      await wakes.cancel('ws-1', ids: [next.id], reason: 'rule_test', now: now);
      await service.rearmAll();
      // The cancelled wake's key cannot be reused: the scan moves on.
      await service.rearmAll();
      final open = await pending(rule.id);
      expect(open.length, lessThanOrEqualTo(1));
      expect(dispatched, hasLength(1));
    });

    test('a slot whose wake settled before the rule moved on moves on at '
        'boot', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      final first = (await pending(rule.id)).single;
      await wakes.markDelivered('ws-1', ids: [first.id], runId: 'r', now: now);
      await service.rearmAll();
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(
        (await pending(rule.id)).single.notBefore,
        DateTime.utc(2026, 5, 1, 12, 40),
      );
    });

    test(
      'deliver: notify posts the note, tells the person, starts no run',
      () async {
        final rule = await service.create(
          agentRequest(
            'in:5m',
            deliver: WakeDeliver.notify,
            requestedByUserId: 'user-1',
          ),
        );
        await advance(const Duration(minutes: 5, seconds: 3));
        expect(dispatched, isEmpty);
        // The agent's words, attributed to it and quoted: never the
        // server's own sentence.
        final row = rows
            .where((r) => r.metadata['kind'] == 'wake_rule_note')
            .single;
        expect(
          row.content,
          'Builder agent-1 left a note for at:2026-05-01T12:12:00.000Z, in '
          'its own words:\n\n> check the deploy',
        );
        expect(row.metadata['noteAuthor'], 'agent');
        final told = notified.single;
        expect(told.mentions.single.wire, 'user:user-1');
        expect(told.senderName, 'Builder agent-1');
        expect(told.isAgentMessage, isTrue);
        expect(told.contentPreview, '"check the deploy"');
        expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.fired);
      },
    );

    test("a note a person changed is theirs: a person's reminder", () async {
      final rule = await service.create(
        agentRequest(
          'in:5m',
          deliver: WakeDeliver.notify,
          requestedByUserId: 'user-1',
        ),
      );
      final edited = await service.update(
        'ws-1',
        rule.id,
        note: 'ship the fix\nthen tell the team',
        editedByUserId: 'user-1',
      );
      expect(edited.noteEditedByUserId, 'user-1');
      // A change of busy behaviour alone keeps the author.
      final again = await service.update(
        'ws-1',
        rule.id,
        whenBusy: WakeWhenBusy.queue,
        editedByUserId: 'user-2',
      );
      expect(again.noteEditedByUserId, 'user-1');
      await advance(const Duration(minutes: 5, seconds: 3));
      final row = rows
          .where((r) => r.metadata['kind'] == 'wake_rule_note')
          .single;
      expect(
        row.content,
        'A reminder a person set for at:2026-05-01T12:12:00.000Z:\n\n'
        '> ship the fix\n> then tell the team',
      );
      expect(row.metadata['noteAuthorUserId'], 'user-1');
      expect(notified.single.isAgentMessage, isFalse);
      expect(notified.single.senderName, 'Schedule');
    });
  });

  group('loops and cost', () {
    test(
      'a self-paced loop fires at its chosen delay, else after 20 minutes',
      () async {
        final rule = await service.create(
          const WakeRuleRequest(
            workspaceId: 'ws-1',
            conversationId: 'conv-1',
            agentId: 'agent-1',
            when: 'next',
            note: 'keep the build green',
            origin: WakeRuleOrigin.person,
            createdByUserId: 'user-1',
            fireNow: true,
          ),
        );
        expect(rule.requestedByUserId, 'user-1');
        await advance(const Duration(seconds: 3));
        expect(dispatched, hasLength(1));
        final firstWake = dispatched.single.wakeContext.wakeIds;
        // The agent picks 5 minutes for the next run.
        expect(
          await service.setNextDelay(
            'ws-1',
            rule.id,
            const Duration(minutes: 5),
          ),
          const Duration(minutes: 5),
        );
        await settle('run-1', wakeIds: firstWake);
        expect(
          (await pending(rule.id)).single.notBefore,
          now.add(const Duration(minutes: 5)),
        );
        await advance(const Duration(minutes: 5, seconds: 3));
        expect(dispatched, hasLength(2));
        // Without a choice the delay is 20 minutes.
        await settle('run-2', wakeIds: dispatched.last.wakeContext.wakeIds);
        expect(
          (await pending(rule.id)).single.notBefore,
          now.add(const Duration(minutes: 20)),
        );
      },
    );

    test('a delay is clamped to 1 minute .. 1 hour', () async {
      final rule = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'next',
          note: 'n',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
        ),
      );
      expect(
        await service.setNextDelay('ws-1', rule.id, const Duration(seconds: 5)),
        const Duration(minutes: 1),
      );
      expect(
        await service.setNextDelay('ws-1', rule.id, const Duration(hours: 5)),
        const Duration(hours: 1),
      );
    });

    test('the cost cap ends the rule', () async {
      final rule = await service.create(
        agentRequest('every:20m', maxRuns: 9, costCapMicros: 3000000),
      );
      await advance(const Duration(minutes: 13, seconds: 3));
      final run = dispatched.single;
      expect(run.costCapMicros, 3000000);
      await settle(
        'run-1',
        wakeIds: run.wakeContext.wakeIds,
        costMicros: 3200000,
      );
      final after = await ruleOf(rule.id);
      expect(after.costMicros, 3200000);
      expect(after.endReason, WakeRuleEndReason.costCap);
      expect(await pending(rule.id), isEmpty);
    });
  });

  group('a provider usage limit', () {
    Future<List<Wake>> limitWakes() async => [
      for (final w in await stores.all('ws-1'))
        if (w.reason == WakeReason.limitReset) w,
    ];
    Future<List<Wake>> slotWakes(String ruleId) async => [
      for (final w in await pending(ruleId))
        if (w.reason == WakeReason.schedule) w,
    ];

    test('a rule\'s run parks until the reset plus 30 seconds and the next '
        'slot waits for the limit wake', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await slotWakes(rule.id)).single.notBefore, DateTime.utc(2026, 5, 1, 12, 40));
      final reset = now.add(const Duration(hours: 1));
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
        limitResetsAt: reset,
      );
      final parked = (await limitWakes()).single;
      expect(parked.dedupKey, 'limit:run-1');
      expect(parked.detail.ruleId, rule.id);
      expect(parked.detail.sourceRunId, 'run-1');
      expect(parked.payload, 'check the deploy');
      expect(parked.notBefore, reset.add(const Duration(seconds: 30)));
      expect(parked.detail.fields[WakeFields.provider], 'anthropic');
      expect(parked.runOptions?.costCapMicros, isNotNull);
      // The next slot is withheld: no slot wake, no next fire time.
      expect(await slotWakes(rule.id), isEmpty);
      expect((await ruleOf(rule.id)).nextFireAt, isNull);
      await advance(const Duration(minutes: 30));
      expect(dispatched, hasLength(1));
      await advance(const Duration(minutes: 30, seconds: 29));
      expect(dispatched, hasLength(1));
      await advance(const Duration(seconds: 1));
      expect(dispatched, hasLength(2));
      expect(dispatched.last.wakeContext.wakeReason, WakeReason.limitReset);
      expect(dispatched.last.costCapMicros, isNotNull);
      // Delivered: the rule's next slot is written, after now.
      final next = (await ruleOf(rule.id)).nextFireAt;
      expect(next, isNotNull);
      expect(next!.isAfter(now), isTrue);
      expect((await slotWakes(rule.id)).single.notBefore, next);
      expect((await ruleOf(rule.id)).runCount, 1);
      // The resumed run's cost is the rule's.
      await settle(
        'run-2',
        wakeIds: dispatched.last.wakeContext.wakeIds,
        costMicros: 1000,
      );
      expect((await ruleOf(rule.id)).costMicros, 1000);
    });

    test('with no reported reset the rule moves on as before', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await advance(const Duration(minutes: 13, seconds: 3));
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
      );
      expect(await limitWakes(), isEmpty);
      expect(await slotWakes(rule.id), hasLength(1));
    });

    test('a cancelled limit wake writes the next slot', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await advance(const Duration(minutes: 13, seconds: 3));
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
        limitResetsAt: now.add(const Duration(hours: 2)),
      );
      expect(await slotWakes(rule.id), isEmpty);
      expect(
        await queue.cancel(
          'ws-1',
          (await limitWakes()).single.id,
          reason: 'cancelled_by_person',
        ),
        isTrue,
      );
      await pumpEventQueue();
      expect(await slotWakes(rule.id), hasLength(1));
      expect((await ruleOf(rule.id)).nextFireAt, isNotNull);
    });

    test('pausing a parked rule drops its limit wake', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await advance(const Duration(minutes: 13, seconds: 3));
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
        limitResetsAt: now.add(const Duration(hours: 2)),
      );
      await service.pause('ws-1', rule.id, pausedBy: 'user-1');
      await pumpEventQueue();
      expect((await limitWakes()).single.state, WakeState.cancelled);
      expect(await slotWakes(rule.id), isEmpty);
    });

    test('a parked rule whose expiry passes is ended as expired, and its '
        'park never runs', () async {
      // An hourly rule that expires in 3 hours, parked at a reset 2 days
      // away.
      final rule = await service.create(
        agentRequest('every:1h', expiresIn: const Duration(hours: 3)),
      );
      await advance(const Duration(minutes: 53, seconds: 3));
      expect(dispatched, hasLength(1));
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
        limitResetsAt: now.add(const Duration(days: 2)),
      );
      final parked = (await limitWakes()).single;
      expect(parked.expiresAt, (await ruleOf(rule.id)).expiresAt);
      await advance(const Duration(hours: 3));
      await advance(WakeQueueService.maintenanceEvery);
      expect((await ruleOf(rule.id)).status, WakeRuleStatus.ended);
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.expired);
      expect((await limitWakes()).single.state.isSettled, isTrue);
      await advance(const Duration(days: 2, minutes: 1));
      expect(dispatched, hasLength(1));
    });

    test('a park whose lineage another rule spent meanwhile is skipped and '
        'ends its rule', () async {
      // The root allows two runs in its lineage.
      final root = await service.create(agentRequest('every:20m', maxRuns: 2));
      await advance(const Duration(minutes: 13, seconds: 3));
      expect(dispatched, hasLength(1));
      // Its run makes a one-off in the lineage, then hits the limit.
      final child = await service.create(
        agentRequest('in:5m', createdByRunId: 'run-1'),
      );
      expect(child.rootRuleId, root.id);
      await settle(
        'run-1',
        wakeIds: dispatched.single.wakeContext.wakeIds,
        endReason: RunEndReason.usageLimit,
        limitResetsAt: now.add(const Duration(hours: 1)),
      );
      // The one-off spends the lineage's second run.
      await advance(const Duration(minutes: 5, seconds: 1));
      expect(dispatched, hasLength(2));
      await settle('run-2', wakeIds: dispatched.last.wakeContext.wakeIds);
      await advance(const Duration(hours: 1));
      expect(dispatched, hasLength(2));
      expect((await ruleOf(root.id)).status, WakeRuleStatus.ended);
      expect((await ruleOf(root.id)).endReason, WakeRuleEndReason.runCap);
    });
  });

  group('endings', () {
    test('a goal-bound rule ends with its goal', () async {
      goalOfRun['run-g'] = 'goal-1';
      goalEnded['goal-1'] = false;
      final rule = await service.create(
        agentRequest('every:20m', maxRuns: 5, createdByRunId: 'run-g'),
      );
      expect(rule.goalId, 'goal-1');
      bus.publish(
        GoalSettled(
          goalId: 'goal-1',
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          status: AgentGoalStatus.completed,
          hold: null,
          summary: null,
          requestedByUserId: null,
          occurredAt: now,
        ),
      );
      await pumpEventQueue();
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.goalEnded);
      expect(await pending(rule.id), isEmpty);
    });

    test('member removal ends that person\'s rules', () async {
      final mine = await service.create(
        agentRequest('every:20m', maxRuns: 5, requestedByUserId: 'user-1'),
      );
      final theirs = await service.create(
        agentRequest('every:20m', maxRuns: 5, requestedByUserId: 'user-2'),
      );
      bus.publish(
        WorkspaceMemberRemoved(
          workspaceId: 'ws-1',
          userId: 'user-1',
          occurredAt: now,
        ),
      );
      await pumpEventQueue();
      expect(
        (await ruleOf(mine.id)).endReason,
        WakeRuleEndReason.memberRemoved,
      );
      expect(await pending(mine.id), isEmpty);
      expect((await ruleOf(theirs.id)).isActive, isTrue);
      expect(await pending(theirs.id), hasLength(1));
    });

    test('pause cancels the wake; resume re-arms from the next slot', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      expect(
        await service.pause('ws-1', rule.id, pausedBy: 'user-1'),
        isTrue,
      );
      expect(await pending(rule.id), isEmpty);
      now = now.add(const Duration(hours: 1));
      expect(await service.resume('ws-1', rule.id), isTrue);
      expect(
        (await pending(rule.id)).single.notBefore,
        DateTime.utc(2026, 5, 1, 13, 20),
      );
    });

    test('delete ends a rule, then removes the ended row', () async {
      final rule = await service.create(agentRequest('in:1h'));
      expect(await service.delete('ws-1', rule.id), isTrue);
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.cancelled);
      expect(await service.delete('ws-1', rule.id), isTrue);
      expect(await rules.getById('ws-1', rule.id), isNull);
    });
  });

  group('time zones', () {
    test(
      'a cron rule keeps its wall-clock hour across both DST changes',
      () async {
        now = DateTime.utc(2026, 3, 28, 9);
        final spring = await service.create(
          agentRequest('cron:0 9 * * *', maxRuns: 5, timeZone: 'Europe/Berlin'),
        );
        // 09:00 CET on the 28th has passed; 09:00 CEST on the 29th is 07:00Z.
        expect(spring.nextFireAt, DateTime.utc(2026, 3, 29, 7));
        now = DateTime.utc(2026, 10, 24, 8);
        final autumn = await service.create(
          agentRequest('cron:0 9 * * *', maxRuns: 5, timeZone: 'Europe/Berlin'),
        );
        // 09:00 CEST on the 24th has passed; 09:00 CET on the 25th is 08:00Z.
        expect(autumn.nextFireAt, DateTime.utc(2026, 10, 25, 8));
      },
    );

    test('the workspace\'s default zone applies when none is named', () async {
      settings['ws-1/$wakeRuleLimitsSettingKey'] =
          '{"default_time_zone": "America/New_York"}';
      now = DateTime.utc(2026, 7, 1, 12);
      final rule = await service.create(
        agentRequest('cron:0 9 * * *', maxRuns: 2),
      );
      expect(rule.trigger, Cron('0 9 * * *', 'America/New_York'));
      // 12:00Z is 08:00 EDT, so 09:00 EDT today (13:00Z) is next.
      expect(rule.nextFireAt, DateTime.utc(2026, 7, 1, 13));
    });

    test('the default zone\'s slot is tomorrow once today\'s has passed '
        '(the case that isolates the zone arithmetic)', () async {
      settings['ws-1/$wakeRuleLimitsSettingKey'] =
          '{"default_time_zone": "America/New_York"}';
      // 13:30Z is 09:30 EDT: 09:00 EDT today is gone.
      now = DateTime.utc(2026, 7, 1, 13, 30);
      final rule = await service.create(
        agentRequest('cron:0 9 * * *', maxRuns: 2),
      );
      expect(rule.nextFireAt, DateTime.utc(2026, 7, 2, 13));
    });

    test('setLimits refuses an unknown default zone', () {
      expect(
        service.setLimits('ws-1', WakeRuleLimits(defaultTimeZone: 'Mars/Base')),
        refusedWith(WakeRuleRefusals.invalidWhen),
      );
    });
  });

  group('watches', () {
    Map<String, dynamic> pr({
      String checks = 'pending',
      String head = 'space/sp-1',
      String author = 'builder-bot[bot]',
      String sha = 'a1',
      String decision = 'none',
      int comments = 0,
    }) => {
      'title': 'Add cart',
      'head_ref': head,
      'head_sha': sha,
      'author': {'login': author},
      'checks_status': checks,
      'review_decision': decision,
      'comments_count': comments,
    };

    // The poller's comparison of two snapshots of one pull request: the real
    // detection, published on the bus.
    Future<void> poll(
      Map<String, dynamic> before,
      Map<String, dynamic> after, {
      String ws = 'ws-1',
      String owner = 'acme',
      int number = 12,
      ({String name, String? url})? failing,
    }) async {
      await publishPrWatchEdges(
        bus: bus,
        workspaceId: ws,
        repoOwner: owner,
        repoName: 'shop-ui',
        prNumber: number,
        before: before,
        after: after,
        now: now,
        firstFailingCheck: () async => failing,
      );
      await pumpEventQueue();
    }

    Future<void> fireTimers() async {
      for (final t in [...timers]) {
        if (!t.cancelled) {
          t.callback();
        }
      }
      await pumpEventQueue();
    }

    Future<List<Wake>> watchWakes(String ruleId) async => [
      for (final w in await stores.all('ws-1'))
        if (w.detail.ruleId == ruleId && w.reason == WakeReason.watch) w,
    ];

    test('checks that pass the first time fire once', () async {
      final rule = await service.create(agentRequest('on:pr_checks'));
      await poll(pr(), pr());
      expect(timers, isEmpty);
      await poll(pr(), pr(checks: 'passing'));
      await poll(pr(checks: 'passing'), pr(checks: 'passing'));
      await fireTimers();
      final written = (await watchWakes(rule.id)).single;
      expect(written.detail.status, 'passing');
      expect(written.detail.fields[WakeFields.events], 1);
      expect(wakeHeadline(written), contains('checks on acme/shop-ui#12'));
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await ruleOf(rule.id)).runCount, 1);
    });

    test('failing checks fire with the failed check named', () async {
      final rule = await service.create(agentRequest('on:pr_checks'));
      await poll(
        pr(),
        pr(checks: 'failing'),
        failing: (name: 'lint', url: 'https://ci.example/1'),
      );
      await fireTimers();
      final written = (await watchWakes(rule.id)).single;
      expect(written.detail.status, 'failing');
      expect(written.detail.fields[WakeFields.item], 'lint');
      expect(written.payload, contains('Failed checks: lint'));
      expect(written.payload, contains('https://ci.example/1'));
    });

    test('a re-run that finishes again fires again', () async {
      final rule = await service.create(agentRequest('on:pr_checks'));
      await poll(pr(), pr(checks: 'failing'));
      await fireTimers();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      await settle('run-1', wakeIds: dispatched.single.wakeContext.wakeIds);
      now = now.add(const Duration(minutes: 10));
      await poll(pr(checks: 'failing'), pr());
      await poll(pr(), pr(checks: 'passing'));
      await fireTimers();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(2));
      expect(
        [for (final w in await watchWakes(rule.id)) w.detail.status],
        containsAll(['failing', 'passing']),
      );
    });

    test('a burst of edges becomes one wake with the latest state', () async {
      final rule = await service.create(agentRequest('on:pr_checks'));
      await poll(pr(), pr(checks: 'failing'));
      now = now.add(const Duration(seconds: 10));
      await poll(pr(checks: 'failing'), pr(checks: 'passing'));
      now = now.add(const Duration(seconds: 10));
      await poll(pr(checks: 'passing'), pr(checks: 'passing', sha: 'b2'));
      final live = timers.where((t) => !t.cancelled).toList();
      expect(live, hasLength(1));
      expect(live.single.delay, const Duration(seconds: 30));
      await fireTimers();
      final written = (await watchWakes(rule.id)).single;
      expect(written.detail.status, 'passing');
      expect(written.detail.fields[WakeFields.events], 3);
      expect(written.dedupKey, startsWith('rule:${rule.id}:'));
    });

    test(
      'a burst never waits longer than five minutes after its first event',
      () async {
        await service.create(agentRequest('on:pr_checks'));
        await poll(pr(), pr(checks: 'failing'));
        now = now.add(const Duration(minutes: 4, seconds: 50));
        await poll(pr(checks: 'failing'), pr(checks: 'passing'));
        final live = timers.where((t) => !t.cancelled).single;
        expect(live.delay, const Duration(seconds: 10));
      },
    );

    test("a pull request the App's bot opened fires a bot rule's watch; "
        "another member's pull request in the repository does not and "
        'uses no run', () async {
      final rule = await service.create(agentRequest('on:pr_checks'));
      expect(rule.requestedByUserId, isNull);
      await poll(
        pr(head: 'feature/alice', author: 'alice'),
        pr(head: 'feature/alice', author: 'alice', checks: 'failing'),
        number: 30,
      );
      expect(timers, isEmpty);
      await poll(pr(), pr(checks: 'passing'));
      await fireTimers();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(
        (await watchWakes(rule.id)).single.detail.fields[WakeFields.subject],
        'acme/shop-ui#12',
      );
    });

    test('a watch that names a pull request hears only that one; one in a '
        'repository the space does not expose is refused', () async {
      final rule = await service.create(
        agentRequest('on:pr_checks:acme/shop-ui#40'),
      );
      expect(formatWakeWhen(rule.trigger), 'on:pr_checks:acme/shop-ui#40');
      await poll(pr(), pr(checks: 'passing'));
      expect(timers, isEmpty);
      await poll(
        pr(head: 'feature/alice', author: 'alice'),
        pr(head: 'feature/alice', author: 'alice', checks: 'passing'),
        number: 40,
      );
      expect(timers.where((t) => !t.cancelled), hasLength(1));
      expect(
        service.create(agentRequest('on:pr_checks:other/repo#1')),
        refusedWith(WakeRuleRefusals.watchTargetUnreadable),
      );
      expect(
        service.create(agentRequest('on:pr_merged:acme/shop-ui#x')),
        refusedWith(WakeRuleRefusals.invalidWhen),
      );
    });

    test('a named pull request\'s merge fires once and ends the watch', () async {
      final rule = await service.create(
        agentRequest('on:pr_merged:acme/shop-ui#12'),
      );
      bus.publish(
        prWatchClosed(
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'shop-ui',
          prNumber: 12,
          last: pr(checks: 'passing'),
          merged: true,
          now: now,
        ),
      );
      await pumpEventQueue();
      await fireTimers();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await watchWakes(rule.id)).single.detail.status, 'merged');
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.fired);
    });

    // An event is never dropped because of timing: one that comes while a
    // run of the agent is live waits in the queue and is delivered after
    // the run, once, with the count and the latest state.
    Future<void> envExit({int code = 1}) async {
      bus.publish(
        EnvironmentProcessExited(
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          environmentId: 'env-1',
          componentId: 'tests',
          exitCode: code,
          occurredAt: now,
        ),
      );
      await pumpEventQueue();
    }

    test('a comment during the agent\'s run is delivered after it', () async {
      final rule = await service.create(agentRequest('on:pr_review'));
      busy = true;
      await poll(pr(), pr(comments: 1));
      await fireTimers();
      timers.clear();
      await advance(const Duration(seconds: 3));
      expect(dispatched, isEmpty, reason: 'it waits for the live run');
      // The live run ends.
      busy = false;
      await settle('run-live');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await watchWakes(rule.id)).single.detail.status, 'commented');
      await advance(const Duration(minutes: 10));
      expect(dispatched, hasLength(1));
    });

    test('an exit during the run, and one shortly after a run of the rule, '
        'both wake the agent (an exit names no one who caused it)', () async {
      final rule = await service.create(agentRequest('on:environment'));
      busy = true;
      await envExit();
      await fireTimers();
      timers.clear();
      // The live run ends.
      busy = false;
      await settle('run-live');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      await settle('run-1', wakeIds: dispatched.single.wakeContext.wakeIds);
      // The rule's own run started a task; it exits 90 seconds after.
      now = now.add(const Duration(seconds: 90));
      await envExit(code: 0);
      await fireTimers();
      timers.clear();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(2));
      expect(
        [for (final w in await watchWakes(rule.id)) w.detail.status],
        ['exited', 'exited'],
      );
    });

    test('bursts during a long run are one wake with the latest state and '
        'the whole count', () async {
      final rule = await service.create(
        agentRequest('on:pr_review', whenBusy: WakeWhenBusy.skip),
      );
      busy = true;
      await poll(pr(), pr(comments: 1));
      await fireTimers();
      timers.clear();
      now = now.add(const Duration(hours: 1));
      await poll(pr(comments: 1), pr(comments: 3));
      await poll(pr(comments: 3), pr(comments: 3, decision: 'approved'));
      await fireTimers();
      timers.clear();
      await advance(const Duration(seconds: 3));
      expect(dispatched, isEmpty);
      final waiting = [
        for (final w in await watchWakes(rule.id))
          if (w.state == WakeState.pending) w,
      ];
      expect(waiting, hasLength(1));
      expect(waiting.single.detail.status, 'approved');
      expect(waiting.single.detail.fields[WakeFields.events], 3);
      // The live run ends.
      busy = false;
      await settle('run-live');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect(dispatched.single.wakeContext.wakeIds, [waiting.single.id]);
      expect((await ruleOf(rule.id)).runCount, 1);
    });

    test('no double delivery when an event comes during the debounce and '
        'the run ends', () async {
      final rule = await service.create(agentRequest('on:pr_review'));
      // Gathered while the agent is idle; a run starts before the quiet
      // period ends and another event comes.
      await poll(pr(), pr(comments: 1));
      busy = true;
      await poll(pr(comments: 1), pr(comments: 3));
      await fireTimers();
      timers.clear();
      await advance(const Duration(seconds: 3));
      expect(dispatched, isEmpty);
      busy = false;
      await settle('run-live');
      await advance(const Duration(seconds: 3));
      await fireTimers();
      await advance(const Duration(minutes: 10));
      expect(dispatched, hasLength(1));
      final written = await watchWakes(rule.id);
      expect(written, hasLength(1));
      expect(written.single.detail.fields[WakeFields.events], 2);
    });

    test('a restart in the middle of the run, then its end: delivered '
        'once', () async {
      final rule = await service.create(agentRequest('on:environment'));
      busy = true;
      await envExit();
      // No quiet period while the run is live: the wake is in the queue
      // before the restart, nothing is held in memory.
      await service.stop();
      await queue.stop();
      timers.clear();
      now = now.add(const Duration(minutes: 30));
      await boot();
      await advance(const Duration(seconds: 3));
      expect(dispatched, isEmpty);
      busy = false;
      await settle('run-live');
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await watchWakes(rule.id)).single.state, WakeState.delivered);
    });

    test('an environment of another space never fires', () async {
      await service.create(agentRequest('on:environment'));
      bus.publish(
        EnvironmentReady(
          workspaceId: 'ws-1',
          spaceId: 'sp-2',
          environmentId: 'env-2',
          occurredAt: now,
        ),
      );
      await pumpEventQueue();
      expect(timers, isEmpty);
    });

    test('a pipeline run watch: its own space, or a person who can read '
        'it; never another space\'s or workspace\'s', () async {
      access.runs.addAll({'ws-1/sp-2/R-2', 'ws-2/sp-9/R-9'});
      await expectLater(
        service.create(agentRequest('on:pipeline_run:R-2')),
        refusedWith(WakeRuleRefusals.watchRefused),
      );
      await expectLater(
        service.create(agentRequest('on:pipeline_run:R-9')),
        refusedWith(WakeRuleRefusals.watchRefused),
      );
      await expectLater(
        service.create(
          agentRequest('on:pipeline_run:R-2', requestedByUserId: 'user-1'),
        ),
        refusedWith(WakeRuleRefusals.watchRefused),
      );
      access.readableRuns.add('ws-1/R-2');
      final mine = await service.create(
        agentRequest('on:pipeline_run:R-2', requestedByUserId: 'user-1'),
      );
      final own = await service.create(agentRequest('on:pipeline_run:R-1'));
      // The person lost the run before it settled: no wake.
      access.readableRuns.clear();
      bus
        ..publish(
          PipelineRunCompleted(
            pipelineRunId: 'R-2',
            workspaceId: 'ws-1',
            templateId: 'tpl-1',
            occurredAt: now,
          ),
        )
        ..publish(
          PipelineRunCompleted(
            pipelineRunId: 'R-1',
            workspaceId: 'ws-1',
            templateId: 'tpl-1',
            occurredAt: now,
          ),
        );
      await pumpEventQueue();
      await fireTimers();
      expect(await watchWakes(mine.id), isEmpty);
      expect(await watchWakes(own.id), hasLength(1));
    });

    test('a ticket watch fires once for its ticket, then ends', () async {
      final rule = await service.create(agentRequest('on:ticket:T-1'));
      bus.publish(
        TicketCompleted(ticketId: 'T-2', workspaceId: 'ws-1', occurredAt: now),
      );
      await pumpEventQueue();
      expect(timers, isEmpty);
      bus.publish(
        TicketCompleted(ticketId: 'T-1', workspaceId: 'ws-1', occurredAt: now),
      );
      await pumpEventQueue();
      await fireTimers();
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.fired);
    });
  });

  group('isolation', () {
    test('a rule cannot target another workspace\'s conversation', () {
      expect(
        service.create(agentRequest('in:1h', conversationId: 'conv-9')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(
        service.create(
          agentRequest('in:1h', workspaceId: 'ws-2', conversationId: 'conv-9'),
        ),
        throwsA(isA<WorkspaceMismatchException>()),
        reason: 'agent-1 is not in ws-2',
      );
      expect(
        service.create(agentRequest('in:1h', workspaceId: 'ws-gone')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test(
      'a watch cannot subscribe to another workspace\'s ticket or run',
      () async {
        access.tickets.add('ws-2/agent-1/T-9');
        access.runs.add('ws-2/sp-9/R-9');
        expect(
          service.create(agentRequest('on:ticket:T-9')),
          refusedWith(WakeRuleRefusals.watchRefused),
        );
        expect(
          service.create(agentRequest('on:pipeline_run:R-9')),
          refusedWith(WakeRuleRefusals.watchRefused),
        );
        // A space exposing no readable repository has no pull request to
        // watch.
        expect(
          service.create(
            agentRequest('on:pr_checks', conversationId: 'conv-2'),
          ),
          refusedWith(WakeRuleRefusals.watchTargetUnreadable),
        );
      },
    );

    test('another workspace\'s event never reaches a watch', () async {
      await service.create(agentRequest('on:pr_checks'));
      await publishPrWatchEdges(
        bus: bus,
        workspaceId: 'ws-2',
        repoOwner: 'acme',
        repoName: 'shop-ui',
        prNumber: 12,
        before: const {'checks_status': 'pending', 'head_ref': 'space/sp-1'},
        after: const {'checks_status': 'failing', 'head_ref': 'space/sp-1'},
        now: now,
        firstFailingCheck: () async => null,
      );
      await pumpEventQueue();
      expect(timers, isEmpty);
    });

    test('another person\'s pause posts one row naming them; a second '
        'pause posts nothing', () async {
      final rule = await service.create(
        agentRequest('every:20m', maxRuns: 5, requestedByUserId: 'user-1'),
      );
      expect(
        await service.pause('ws-1', rule.id, pausedBy: 'user-2'),
        isTrue,
      );
      expect(
        await service.pause('ws-1', rule.id, pausedBy: 'user-2'),
        isFalse,
      );
      final paused = rows
          .where((r) => r.metadata['kind'] == wakeRulePausedRowKind)
          .toList();
      expect(paused, hasLength(1));
      expect(paused.single.workspaceId, 'ws-1');
      expect(paused.single.spaceId, 'sp-1');
      expect(paused.single.conversationId, 'conv-1');
      expect(paused.single.metadata, {
        'kind': wakeRulePausedRowKind,
        'ruleId': rule.id,
        'agentId': 'agent-1',
        'pausedByUserId': 'user-2',
      });
      expect(paused.single.content, contains('user-2'));
    });

    test('the owner\'s own pause posts no row', () async {
      final rule = await service.create(
        agentRequest('every:20m', maxRuns: 5, requestedByUserId: 'user-1'),
      );
      expect(
        await service.pause('ws-1', rule.id, pausedBy: 'user-1'),
        isTrue,
      );
      expect(
        rows.where((r) => r.metadata['kind'] == wakeRulePausedRowKind),
        isEmpty,
      );
    });

    test('a pause of a rule that acts for nobody names the person', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      expect(rule.requestedByUserId, isNull);
      await service.pause('ws-1', rule.id, pausedBy: 'user-2');
      expect(
        rows
            .where((r) => r.metadata['kind'] == wakeRulePausedRowKind)
            .single
            .metadata['pausedByUserId'],
        'user-2',
      );
    });

    test('a foreign workspace id finds no rule at any operation', () async {
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      for (final call in <Future<Object?> Function()>[
        () => service.require('ws-2', rule.id),
        () => service.pause('ws-2', rule.id, pausedBy: 'user-1'),
        () => service.resume('ws-2', rule.id),
        () => service.delete('ws-2', rule.id),
        () => service.update(
          'ws-2',
          rule.id,
          note: 'x',
          editedByUserId: 'user-1',
        ),
        () => service.setNextDelay('ws-2', rule.id, const Duration(minutes: 5)),
      ]) {
        await expectLater(call(), throwsA(isA<NotFoundException>()));
      }
      expect((await ruleOf(rule.id)).isActive, isTrue);
    });
  });
  group('slots as the row stores them', () {
    test('a one-off made from an instant with microseconds fires and ends '
        'fired', () async {
      now = DateTime.utc(2026, 5, 1, 12, 7, 0, 123, 456);
      final rule = await service.create(agentRequest('in:10m'));
      expect(rule.nextFireAt, DateTime.utc(2026, 5, 1, 12, 17));
      await advance(const Duration(minutes: 10, seconds: 1));
      expect(dispatched, hasLength(1));
      final after = await ruleOf(rule.id);
      expect(after.endReason, WakeRuleEndReason.fired);
      expect(after.runCount, 1);
      expect(after.expiresAt.isUtc, isTrue);
      expect(after.lastFiredAt!.isUtc, isTrue);
    });

    test('a repeating rule fires twice and advances its slot', () async {
      now = DateTime.utc(2026, 5, 1, 12, 7, 0, 987, 654);
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await advance(const Duration(minutes: 13, seconds: 1));
      expect(dispatched, hasLength(1));
      await advance(const Duration(minutes: 20));
      expect(dispatched, hasLength(2));
      final after = await ruleOf(rule.id);
      expect(after.runCount, 2);
      expect(after.skipCount, 0);
      expect(after.nextFireAt, DateTime.utc(2026, 5, 1, 13));
      final next = (await pending(rule.id)).single;
      expect(next.notBefore, DateTime.utc(2026, 5, 1, 13));
      expect(next.dedupKey, 'rule:${rule.id}:2026-05-01T13:00:00.000Z');
    });

    test("/loop's first run starts at once, then the next slot", () async {
      now = DateTime.utc(2026, 5, 1, 12, 7, 0, 500, 1);
      final rule = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'every:30m',
          note: 'check the deploy',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          fireNow: true,
        ),
      );
      expect(rule.nextFireAt, DateTime.utc(2026, 5, 1, 12, 7));
      // The queue's quiet window is two seconds.
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(after.nextFireAt, DateTime.utc(2026, 5, 1, 12, 30));
      await advance(const Duration(minutes: 23));
      expect(dispatched, hasLength(2));
    });

    test("a self-paced rule's next delay counts from a settle with "
        'microseconds', () async {
      now = DateTime.utc(2026, 5, 1, 12, 7, 0, 250, 750);
      final rule = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'next',
          note: 'keep the build green',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          fireNow: true,
        ),
      );
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      await service.setNextDelay('ws-1', rule.id, const Duration(minutes: 5));
      await settle('run-1', wakeIds: dispatched.single.wakeContext.wakeIds);
      final slot = DateTime.utc(2026, 5, 1, 12, 12, 3);
      expect((await ruleOf(rule.id)).nextFireAt, slot);
      expect((await pending(rule.id)).single.notBefore, slot);
      await advance(const Duration(minutes: 5));
      expect(dispatched, hasLength(2));
    });

    test('after a restart the re-arm arms the right slot once', () async {
      now = DateTime.utc(2026, 5, 1, 12, 7, 0, 1, 2);
      final rule = await service.create(agentRequest('every:20m', maxRuns: 5));
      await service.stop();
      await queue.stop();
      await boot();
      await service.rearmAll();
      final waiting = await pending(rule.id);
      expect(waiting, hasLength(1));
      expect(waiting.single.notBefore, DateTime.utc(2026, 5, 1, 12, 20));
      await advance(const Duration(minutes: 13));
      expect(dispatched, hasLength(1));
      expect((await pending(rule.id)).single.notBefore,
          DateTime.utc(2026, 5, 1, 12, 40));
      expect((await ruleOf(rule.id)).runCount, 1);
    });
  });
  group('a loop whose run settles before its delivery is recorded', () {
    test('the next slot is written once and the fire counts', () async {
      final rule = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'next',
          note: 'keep the build green',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          fireNow: true,
        ),
      );
      // The run fails at once: it settles inside the dispatch, before the
      // queue marks its wake delivered and calls the delivered handler.
      onDispatch = (run, runId) =>
          settle(runId, wakeIds: run.wakeContext.wakeIds);
      await advance(const Duration(seconds: 3));
      onDispatch = null;
      await pumpEventQueue(times: 100);
      expect(dispatched, hasLength(1));
      final slot = DateTime.utc(2026, 5, 1, 12, 27, 3);
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(after.nextFireAt, slot);
      expect((await pending(rule.id)).single.notBefore, slot);
      await advance(const Duration(minutes: 20));
      expect(dispatched, hasLength(2));
    });

    test('a restart while its run was live counts the fire once and goes on '
        'from now', () async {
      final rule = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'next',
          note: 'keep the build green',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          fireNow: true,
        ),
      );
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(1));
      expect((await ruleOf(rule.id)).runCount, 1);
      // The server stops under the run: no settle writes the next slot.
      await service.stop();
      await queue.stop();
      now = now.add(const Duration(minutes: 1));
      await boot();
      final after = await ruleOf(rule.id);
      expect(after.runCount, 1);
      expect(after.nextFireAt, DateTime.utc(2026, 5, 1, 12, 28, 3));
      expect(await pending(rule.id), hasLength(1));
    });
  });
  group('next fires', () {
    test("a cron rule's next fires land where it fires across a daylight "
        'saving change, from the server clock', () async {
      now = DateTime.utc(2026, 10, 31, 12);
      final rule = await service.create(
        agentRequest(
          'cron:0 9 * * *',
          maxRuns: 10,
          timeZone: 'America/New_York',
        ),
      );
      // 09:00 in New York is 13:00 UTC before November 1 and 14:00 after.
      expect(await service.nextFires(rule), [
        DateTime.utc(2026, 10, 31, 13),
        DateTime.utc(2026, 11, 1, 14),
        DateTime.utc(2026, 11, 2, 14),
      ]);
    });

    test('slots stop at the expiry and at the runs left; an ended or a '
        'non-cron rule has none', () async {
      now = DateTime.utc(2026, 11, 20, 12);
      final short = await service.create(
        agentRequest(
          'cron:0 9 * * *',
          expiresIn: const Duration(days: 2),
          timeZone: 'UTC',
        ),
      );
      expect(await service.nextFires(short), [
        DateTime.utc(2026, 11, 21, 9),
        DateTime.utc(2026, 11, 22, 9),
      ]);
      final capped = await service.create(
        agentRequest('cron:0 9 * * *', maxRuns: 2, timeZone: 'UTC'),
      );
      expect(await service.nextFires(capped), hasLength(2));
      expect(
        await service.nextFires(capped.copyWith(runCount: 1)),
        [DateTime.utc(2026, 11, 21, 9)],
      );
      await service.end('ws-1', capped.id, WakeRuleEndReason.cancelled);
      expect(await service.nextFires(await ruleOf(capped.id)), isEmpty);
      final every = await service.create(agentRequest('every:1h', maxRuns: 3));
      expect(await service.nextFires(every), isEmpty);
    });

    test('a draft previews from the server; a bad expression, an unknown '
        'zone or an over-long input gives none; the zone verdict comes '
        'along; another workspace is refused', () async {
      now = DateTime.utc(2026, 10, 31, 12);
      final ny = await service.previewCron(
        'ws-1',
        expression: '0 9 * * *',
        timeZone: 'America/New_York',
      );
      expect(ny.nextFires, [
        DateTime.utc(2026, 10, 31, 13),
        DateTime.utc(2026, 11, 1, 14),
        DateTime.utc(2026, 11, 2, 14),
      ]);
      expect(ny.zoneKnown, isTrue);
      // No zone: the workspace's, and known.
      final mine = await service.previewCron(
        'ws-1',
        expression: '0 9 * * *',
        timeZone: '',
      );
      expect(mine.nextFires, hasLength(3));
      expect(mine.zoneKnown, isTrue);
      // A zone asked about alone: no times, the verdict.
      for (final zone in ['Europe/Berlin', '']) {
        final alone = await service.previewCron(
          'ws-1',
          expression: '',
          timeZone: zone,
        );
        expect(alone.nextFires, isEmpty, reason: zone);
        expect(alone.zoneKnown, isTrue, reason: zone);
      }
      for (final (expression, zone, known) in [
        ('0 9 * * *', 'Mars/Base', false),
        ('', 'Europe/Berln', false),
        ('0 9 31 2 *', 'UTC', true),
        ('not a cron', 'UTC', true),
        ('0 9 * * *', 'A/${'b' * 80}', false),
        ('${'1,' * 120}1 9 * * *', 'UTC', true),
      ]) {
        final got = await service.previewCron(
          'ws-1',
          expression: expression,
          timeZone: zone,
        );
        expect(got.nextFires, isEmpty, reason: '$expression $zone');
        expect(got.zoneKnown, known, reason: '$expression $zone');
      }
      await expectLater(
        service.previewCron('ws-9', expression: '0 9 * * *', timeZone: 'UTC'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });
  });

  group('history', () {
    // A rule's past wake, written straight to the store. The rules are
    // watches: no slot of theirs waits in the queue.
    Future<Wake> past(
      WakeRule rule,
      int n, {
      WakeState state = WakeState.delivered,
      String? stateReason,
      String? runId,
      String? ruleId,
      String conversationId = 'conv-1',
      Duration age = Duration.zero,
    }) async {
      final at = DateTime.utc(2026, 5, 1, 10).add(age);
      final wake = Wake(
        id: 'w-${n.toString().padLeft(3, '0')}',
        workspaceId: 'ws-1',
        spaceId: conversationId == 'conv-1' ? 'sp-1' : 'sp-2',
        conversationId: conversationId,
        agentId: 'agent-1',
        reason: WakeReason.schedule,
        payload: 'check the deploy',
        detail: WakeDetail(ruleId: ruleId ?? rule.id, slot: at),
        dedupKey: 'past:$n',
        notBefore: at,
        state: state,
        stateReason: stateReason,
        deliveredRunId: runId,
        createdAt: at,
        settledAt: state == WakeState.pending ? null : at,
      );
      expect(await wakes.insertIfAbsent(wake), isTrue);
      return wake;
    }

    test('a rule with no wakes has an empty last page', () async {
      final rule = await service.create(agentRequest('on:environment'));
      final page = await service.history(rule);
      expect(page.wakes, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('newest first, 50 a page, the cursor goes on where the page ended '
        '(same-second rows by id), and nothing of another rule', () async {
      final rule = await service.create(agentRequest('on:environment'));
      final other = await service.create(agentRequest('on:pr_review'));
      // 60 wakes, two in each minute: the second of each pair shares the
      // first's createdAt.
      for (var n = 0; n < 60; n++) {
        await past(rule, n, age: Duration(minutes: n ~/ 2));
      }
      await past(rule, 900, ruleId: other.id, age: const Duration(hours: 9));
      await past(
        rule,
        901,
        conversationId: 'conv-2',
        age: const Duration(hours: 9),
      );
      final first = await service.history(rule);
      expect(first.wakes, hasLength(50));
      expect(first.wakes.first.wake.id, 'w-059');
      expect(first.wakes[1].wake.id, 'w-058');
      expect(first.wakes.last.wake.id, 'w-010');
      final second = await service.history(rule, cursor: first.nextCursor);
      expect([for (final r in second.wakes) r.wake.id], [
        for (var n = 9; n >= 0; n--) 'w-${n.toString().padLeft(3, '0')}',
      ]);
      expect(second.nextCursor, isNull);
      await expectLater(
        service.history(rule, cursor: 'garbage'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a delivered wake has its run, a live one too; a skipped one has '
        'none; a folded watch wake is left out', () async {
      final rule = await service.create(agentRequest('on:environment'));
      runFacts['run-done'] = (
        id: 'run-done',
        status: 'completed',
        endReason: 'completed',
        costMicros: 120000,
        startedAt: DateTime.utc(2026, 5, 1, 10),
        endedAt: DateTime.utc(2026, 5, 1, 10, 4),
      );
      runFacts['run-live'] = (
        id: 'run-live',
        status: 'running',
        endReason: null,
        costMicros: 0,
        startedAt: DateTime.utc(2026, 5, 1, 10, 40),
        endedAt: null,
      );
      await past(rule, 1, runId: 'run-done');
      await past(
        rule,
        2,
        state: WakeState.skipped,
        stateReason: 'rule_busy',
        age: const Duration(minutes: 20),
      );
      await past(rule, 3, runId: 'run-live', age: const Duration(minutes: 40));
      await past(
        rule,
        4,
        state: WakeState.cancelled,
        stateReason: 'rule_folded',
        age: const Duration(minutes: 41),
      );
      final page = await service.history(rule);
      expect([for (final r in page.wakes) r.wake.id], ['w-003', 'w-002', 'w-001']);
      expect(page.wakes[0].run!.endedAt, isNull);
      expect(page.wakes[0].run!.status, 'running');
      expect(page.wakes[1].run, isNull);
      expect(page.wakes[1].wake.stateReason, 'rule_busy');
      expect(page.wakes[2].run!.costMicros, 120000);
    });
  });

  group('chains of wakes', () {
    // Fires [rule]'s pending wake (advancing to it) and returns the run it
    // started.
    Future<String> fire(WakeRule rule) async {
      final wake = (await pending(rule.id)).single;
      final gap = wake.notBefore.difference(now);
      await advance(
        (gap.isNegative ? Duration.zero : gap) + const Duration(seconds: 3),
      );
      final runId = 'run-$runSeq';
      expect(runWakes[runId], contains(wake.id));
      return runId;
    }

    test('a one-off is at least 60 seconds ahead', () async {
      await expectLater(
        service.create(agentRequest('in:1s')),
        refusedWith(WakeRuleRefusals.tooSoon),
      );
      await expectLater(
        service.create(agentRequest('at:2026-05-01T12:07:30Z')),
        refusedWith(WakeRuleRefusals.tooSoon),
      );
      now = now.add(const Duration(milliseconds: 600));
      final rule = await service.create(agentRequest('in:1m'));
      expect(rule.nextFireAt, DateTime.utc(2026, 5, 1, 12, 8));
    });

    test("a rule made in a rule's run joins its lineage: the root's expiry, "
        "and its runs count toward the root's cap", () async {
      final r1 = await service.create(
        agentRequest(
          'every:20m',
          maxRuns: 3,
          expiresIn: const Duration(hours: 3),
        ),
      );
      expect(r1.rootRuleId, isNull);
      final run1 = await fire(r1);
      // A repeating rule made in R1's run ends when R1 does.
      final long = await service.create(
        agentRequest(
          'every:30m',
          expiresIn: const Duration(days: 7),
          createdByRunId: run1,
        ),
      );
      expect(long.rootRuleId, r1.id);
      expect(long.expiresAt, r1.expiresAt);
      await service.end('ws-1', long.id, WakeRuleEndReason.cancelled);
      final r2 = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect(r2.rootRuleId, r1.id);
      expect(r2.expiresAt.isAfter(r1.expiresAt), isFalse);
      expect(await service.lineageStatus(r2), (
        rootRuleId: r1.id,
        runsLeft: 2,
        endsAt: r1.expiresAt,
      ));
      expect(await service.lineageStatus(r1), isNull);
      await settle(run1, wakeIds: runWakes[run1]!);
      final run2 = await fire(r2);
      // A rule made in R2's run joins R1's lineage, not a new one.
      final r3 = await service.create(
        agentRequest('in:5m', createdByRunId: run2),
      );
      expect(r3.rootRuleId, r1.id);
      expect((await service.lineageStatus(r3))!.runsLeft, 1);
      await settle(run2, wakeIds: runWakes[run2]!);
      // R3's fire is the third run of the lineage, R1's cap: it ends as a
      // run cap, and R1 fires no more.
      final run3 = await fire(r3);
      await settle(run3, wakeIds: runWakes[run3]!);
      expect((await ruleOf(r3.id)).endReason, WakeRuleEndReason.runCap);
      // R1's 12:40 slot comes due: its lineage has no run left.
      await advance(const Duration(minutes: 10));
      expect(dispatched, hasLength(3));
      expect((await ruleOf(r1.id)).runCount, 1);
      expect((await ruleOf(r1.id)).endReason, WakeRuleEndReason.runCap);
      expect((await rules.lineageTotals('ws-1', r1.id)).runs, 3);
      await expectLater(
        service.create(agentRequest('in:5m', createdByRunId: run3)),
        refusedWith(WakeRuleRefusals.lineageEnded),
      );
    });

    test("the lineage's cost cap ends the rule whose run spent it", () async {
      final r1 = await service.create(
        agentRequest('in:5m', costCapMicros: 1000000),
      );
      final run1 = await fire(r1);
      final r2 = await service.create(
        agentRequest('every:20m', maxRuns: 9, createdByRunId: run1),
      );
      await settle(run1, wakeIds: runWakes[run1]!, costMicros: 700000);
      final run2 = await fire(r2);
      await settle(run2, wakeIds: runWakes[run2]!, costMicros: 300000);
      final after = await ruleOf(r2.id);
      expect(after.costMicros, 300000);
      expect(after.endReason, WakeRuleEndReason.costCap);
    });

    // A lineage travels with the work it starts: every wake a run in it
    // causes carries its root, whatever the path back to the agent.
    var seq = 0;
    Future<String> deliver(List<Wake> wakes) async {
      final before = runSeq;
      for (final wake in wakes) {
        expect(await queue.enqueue(wake), isTrue);
      }
      await advance(const Duration(seconds: 3));
      expect(runSeq, before + 1, reason: 'one run takes them');
      return 'run-$runSeq';
    }

    Wake peerMessage(String fromRunId, {String to = 'agent-2', PeerAsk? ask}) =>
        peerMessageWake(
          id: 'peer-${++seq}',
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          conversationId: 'conv-1',
          recipientAgentId: to,
          payload: 'status of the deploy?',
          messageId: 'm-$seq',
          chain: const ['agent-1'],
          now: now,
          senderAgentId: to == 'agent-2' ? 'agent-1' : 'agent-2',
          senderRunId: fromRunId,
          ask: ask,
        );

    PeerAsk askOf(String askerRunId) => PeerAsk(
      id: 'ask-${++seq}',
      workspaceId: 'ws-1',
      mode: PeerAskMode.background,
      askerAgentId: 'agent-1',
      askerRunId: askerRunId,
      askerConversationId: 'conv-1',
      askerSpaceId: 'sp-1',
      recipientAgentId: 'agent-2',
      recipientConversationId: 'conv-1',
      recipientSpaceId: 'sp-1',
      questionHash: 'h$seq',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
    );

    Future<Object?> carried(String wakeId) async =>
        (await wakes.getById('ws-1', wakeId))!.detail.fields[WakeFields
            .lineageRoot];

    test("the reviewer's path: a rule's run asks a peer in the background, "
        "the reply's run makes a rule: it is in the lineage, and refused "
        'once the lineage is spent', () async {
      final r1 = await service.create(agentRequest('every:20m', maxRuns: 2));
      final run1 = await fire(r1);
      final ask = askOf(run1);
      final question = peerMessage(run1, ask: ask);
      final runB = await deliver([question]);
      expect(await carried(question.id), r1.id);
      // The peer's own rule, made in the run the question started, joins.
      final peerRule = await service.create(
        agentRequest('in:5m', agentId: 'agent-2', createdByRunId: runB),
      );
      expect(peerRule.rootRuleId, r1.id);
      await service.end('ws-1', peerRule.id, WakeRuleEndReason.cancelled);
      final reply = peerReplyWake(
        ask: ask,
        status: 'answered',
        recipientName: 'Builder agent-2',
        now: now,
        payload: 'deployed',
        recipientRunId: runB,
      );
      final runA2 = await deliver([reply]);
      expect(await carried(reply.id), r1.id);
      final r2 = await service.create(
        agentRequest('in:5m', createdByRunId: runA2),
      );
      expect(r2.rootRuleId, r1.id);
      expect(r2.expiresAt.isAfter(r1.expiresAt), isFalse);
      await settle(run1, wakeIds: runWakes[run1]!);
      // R2's fire is the lineage's second run, R1's cap.
      final run2 = await fire(r2);
      await settle(run2, wakeIds: runWakes[run2]!);
      // An interim notice of a second ask, with no recipient run, still
      // continues R2's run: refused, not a fresh root.
      final late = peerReplyWake(
        ask: askOf(run2),
        status: 'expired',
        recipientName: 'Builder agent-2',
        now: now,
      );
      final runA3 = await deliver([late]);
      await expectLater(
        service.create(agentRequest('in:5m', createdByRunId: runA3)),
        refusedWith(WakeRuleRefusals.lineageEnded),
      );
      expect((await rules.lineageTotals('ws-1', r1.id)).runs, 2);
    });

    test("through a delegated ticket's completion", () async {
      final r1 = await service.create(agentRequest('in:5m'));
      final run1 = await fire(r1);
      final done = childCompletedWake(
        id: 'ticket-T-1-settled',
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        delegatorAgentId: 'agent-1',
        workerAgentId: 'agent-2',
        workerName: 'Builder agent-2',
        status: 'completed',
        dedupKey: 'ticket:T-1:settled',
        now: now,
        ticketId: 'T-1',
        // The worker's run was started by the ticket, not by a wake.
        workerRunId: 'run-worker',
        delegatingRunId: run1,
      );
      final run2 = await deliver([done]);
      expect(await carried(done.id), r1.id);
      final r2 = await service.create(
        agentRequest(
          'every:30m',
          expiresIn: const Duration(days: 7),
          createdByRunId: run2,
        ),
      );
      expect(r2.rootRuleId, r1.id);
      expect(r2.expiresAt, r1.expiresAt);
    });

    test("a person's message in between starts fresh, and a producer's own "
        'root is dropped', () async {
      final r1 = await service.create(agentRequest('in:5m'));
      final run1 = await fire(r1);
      final message = Wake(
        id: 'person-1',
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        reason: WakeReason.userMessage,
        payload: 'carry on',
        detail: WakeDetail(
          sourceRunId: run1,
          fields: {WakeFields.lineageRoot: r1.id},
        ),
        dedupKey: 'person-1',
        notBefore: now,
        requestedByUserId: 'user-1',
        createdAt: now,
      );
      final run2 = await deliver([message]);
      expect(await carried(message.id), isNull);
      final fresh = await service.create(
        agentRequest('in:5m', createdByRunId: run2),
      );
      expect(fresh.rootRuleId, isNull);
      // A peer's message from a run in no lineage that names a root itself
      // carries none.
      final forged = peerMessage('run-elsewhere', to: 'agent-1');
      final run3 = await deliver([
        forged.copyWith(
          detail: forged.detail.copyWith(
            fields: {...forged.detail.fields, WakeFields.lineageRoot: r1.id},
          ),
        ),
      ]);
      expect(await carried(forged.id), isNull);
      expect(
        (await service.create(agentRequest('in:5m', createdByRunId: run3)))
            .rootRuleId,
        isNull,
      );
    });

    test("a peer's runs cost the lineage: the root ends at its cost cap, a "
        "carried run's cap is what is left, and a carried wake after that "
        'is skipped as a budget block', () async {
      final r1 = await service.create(
        agentRequest('every:20m', maxRuns: 9, costCapMicros: 3000000),
      );
      final run1 = await fire(r1);
      await settle(run1, wakeIds: runWakes[run1]!, costMicros: 1000000);
      final ask = askOf(run1);
      final runB = await deliver([peerMessage(run1, ask: ask)]);
      expect(dispatched.last.costCapMicros, 2000000);
      await settle(
        runB,
        wakeIds: runWakes[runB]!,
        costMicros: 1500000,
        wakeReason: WakeReason.peerMessage,
      );
      expect((await ruleOf(r1.id)).costMicros, 2500000);
      expect((await rules.lineageTotals('ws-1', r1.id)).costMicros, 2500000);
      expect((await ruleOf(r1.id)).isActive, isTrue);
      final reply = peerReplyWake(
        ask: ask,
        status: 'answered',
        recipientName: 'Builder agent-2',
        now: now,
        payload: 'deployed',
        recipientRunId: runB,
      );
      final runA2 = await deliver([reply]);
      expect(dispatched.last.costCapMicros, 500000);
      await settle(
        runA2,
        wakeIds: runWakes[runA2]!,
        costMicros: 600000,
        wakeReason: WakeReason.peerReply,
      );
      final after = await ruleOf(r1.id);
      expect(after.endReason, WakeRuleEndReason.costCap);
      expect(await pending(r1.id), isEmpty);
      // The lineage is spent: the next message it carries starts nothing.
      final before = dispatched.length;
      final next = peerMessage(runA2);
      expect(await queue.enqueue(next), isTrue);
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(before));
      final skipped = (await wakes.getById('ws-1', next.id))!;
      expect(skipped.state, WakeState.skipped);
      expect(skipped.stateReason, WakeStateReasons.budgetBlocked);
      expect(
        rows.where(
          (r) =>
              r.metadata['wakeId'] == next.id &&
              r.metadata['wakeSkipKind'] == WakeStateReasons.budgetBlocked,
        ),
        hasLength(1),
      );
    });

    test('a carried wake after the lineage ended is skipped as a budget '
        'block', () async {
      final r1 = await service.create(
        agentRequest('in:5m', expiresIn: const Duration(hours: 1)),
      );
      final run1 = await fire(r1);
      await settle(run1, wakeIds: runWakes[run1]!);
      now = r1.expiresAt.add(const Duration(minutes: 1));
      final before = dispatched.length;
      final late = peerMessage(run1);
      expect(await queue.enqueue(late), isTrue);
      expect(await carried(late.id), r1.id);
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(before));
      expect(
        (await wakes.getById('ws-1', late.id))!.stateReason,
        WakeStateReasons.budgetBlocked,
      );
    });

    test("a person's rule and a goal's rule are not charged for runs their "
        'runs cause', () async {
      final mine = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'every:20m',
          note: 'standup',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          requestedByUserId: 'user-1',
          createdByRunId: null,
          costCapMicros: 1000000,
        ),
      );
      final runP = await fire(mine);
      await settle(runP, wakeIds: runWakes[runP]!);
      final runB = await deliver([peerMessage(runP)]);
      expect(dispatched.last.costCapMicros, isNull);
      await settle(
        runB,
        wakeIds: runWakes[runB]!,
        costMicros: 2000000,
        wakeReason: WakeReason.peerMessage,
      );
      expect((await ruleOf(mine.id)).costMicros, 0);
      expect((await ruleOf(mine.id)).isActive, isTrue);
      final r1 = await service.create(agentRequest('in:5m'));
      final run1 = await fire(r1);
      goalOfRun[run1] = 'goal-1';
      goalEnded['goal-1'] = false;
      final ofGoal = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect(ofGoal.goalId, 'goal-1');
      final runG = await fire(ofGoal);
      final runC = await deliver([peerMessage(runG)]);
      await settle(
        runC,
        wakeIds: runWakes[runC]!,
        costMicros: 2000000,
        wakeReason: WakeReason.peerMessage,
      );
      expect((await ruleOf(ofGoal.id)).costMicros, 0);
    });

    test("a rule's wake carries at most what its lineage has left", () async {
      final r1 = await service.create(
        agentRequest('every:20m', maxRuns: 9, costCapMicros: 10000000),
      );
      final run1 = await fire(r1);
      final r2 = await service.create(
        agentRequest('every:30m', maxRuns: 9, createdByRunId: run1),
      );
      expect((await pending(r2.id)).single.runOptions?.costCapMicros, 5000000);
      await settle(run1, wakeIds: runWakes[run1]!, costMicros: 7000000);
      // Armed now: the lineage's 3 dollars.
      final r3 = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect((await pending(r3.id)).single.runOptions?.costCapMicros, 3000000);
      // Armed before: lowered at admission.
      await fire(r3);
      expect(dispatched.last.costCapMicros, 3000000);
      await fire(r2);
      expect(dispatched.last.costCapMicros, 3000000);
    });

    test("a run an agent's assignment started (a team leader's) is in the "
        "assigning run's lineage and costs it; a person's assignment "
        'carries none', () async {
      final r1 = await service.create(
        agentRequest('every:20m', maxRuns: 9, costCapMicros: 3000000),
      );
      final run1 = await fire(r1);
      await settle(run1, wakeIds: runWakes[run1]!, costMicros: 1000000);
      startedBy['run-leader'] = run1;
      final leaderRule = await service.create(
        agentRequest('in:5m', agentId: 'agent-2', createdByRunId: 'run-leader'),
      );
      expect(leaderRule.rootRuleId, r1.id);
      await settle(
        'run-leader',
        costMicros: 500000,
        wakeReason: WakeReason.assignment,
      );
      expect((await ruleOf(r1.id)).costMicros, 1500000);
      // A wake the leader's run causes carries the lineage.
      final asked = peerMessage('run-leader', to: 'agent-1');
      expect(await queue.enqueue(asked), isTrue);
      expect(await carried(asked.id), r1.id);
      // Assigned by a person: the leader's run names no starter.
      final fresh = await service.create(
        agentRequest(
          'in:5m',
          agentId: 'agent-2',
          createdByRunId: 'run-person-assigned',
        ),
      );
      expect(fresh.rootRuleId, isNull);
      await settle(
        'run-person-assigned',
        costMicros: 900000,
        wakeReason: WakeReason.assignment,
      );
      expect((await ruleOf(r1.id)).costMicros, 1500000);
    });

    test("a schedule set in a reviewer's run that a chained run dispatched "
        'joins the chain and its cost is charged to the chain; a pipeline '
        "step's reviewer and a person's carry none", () async {
      final r1 = await service.create(
        agentRequest('every:20m', maxRuns: 9, costCapMicros: 5000000),
      );
      final run1 = await fire(r1);
      final r2 = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect(r2.rootRuleId, r1.id);
      final run2 = await fire(r2);
      await settle(run2, wakeIds: runWakes[run2]!, costMicros: 1000000);
      expect((await ruleOf(r2.id)).costMicros, 1000000);
      expect((await ruleOf(r1.id)).costMicros, 0);
      // `dispatch_reviewers` in the chained run: the reviewer's run log
      // names it.
      startedBy['run-reviewer'] = run2;
      final set = await service.create(
        agentRequest(
          'in:10m',
          agentId: 'agent-2',
          createdByRunId: 'run-reviewer',
        ),
      );
      expect(set.rootRuleId, r1.id);
      await settle(
        'run-reviewer',
        costMicros: 700000,
        wakeReason: WakeReason.assignment,
      );
      // A run no rule's own wake started: charged on the root's row.
      expect((await ruleOf(r1.id)).costMicros, 700000);
      // A pipeline step's reviewer and a person's name no starter.
      for (final (run, reason) in [
        ('run-step-reviewer', WakeReason.pipelineStep),
        ('run-person-reviewer', WakeReason.assignment),
      ]) {
        final own = await service.create(
          agentRequest('in:10m', agentId: 'agent-2', createdByRunId: run),
        );
        expect(own.rootRuleId, isNull, reason: run);
        await settle(run, costMicros: 900000, wakeReason: reason);
      }
      expect((await ruleOf(r1.id)).costMicros, 700000);
      expect((await ruleOf(r2.id)).costMicros, 1000000);
    });

    test("pausing a lineage's root pauses nothing else; deleting it ends "
        'the lineage: its rules end as cancelled, nothing joins it and its '
        'carried wakes are skipped', () async {
      final root = await service.create(
        agentRequest('every:20m', maxRuns: 9, requestedByUserId: 'user-1'),
      );
      final run1 = await fire(root);
      final child = await service.create(
        agentRequest(
          'every:30m',
          maxRuns: 9,
          createdByRunId: run1,
          requestedByUserId: 'user-1',
        ),
      );
      expect(child.rootRuleId, root.id);
      await settle(run1, wakeIds: runWakes[run1]!);
      expect(
        await service.pause('ws-1', root.id, pausedBy: 'user-1'),
        isTrue,
      );
      expect((await ruleOf(child.id)).isActive, isTrue);
      expect(await pending(child.id), hasLength(1));
      final joined = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect(joined.rootRuleId, root.id);
      final carriedWhilePaused = peerMessage(run1);
      final before = runSeq;
      await deliver([carriedWhilePaused]);
      expect(runSeq, before + 1);
      expect(await service.delete('ws-1', root.id), isTrue);
      for (final id in [child.id, joined.id]) {
        final after = await ruleOf(id);
        expect(after.status, WakeRuleStatus.ended);
        expect(after.endReason, WakeRuleEndReason.cancelled);
        expect(await pending(id), isEmpty);
        expect(
          rows.where(
            (r) =>
                r.metadata['kind'] == wakeRuleEndedRowKind &&
                r.metadata['ruleId'] == id &&
                r.metadata['endReason'] == 'cancelled',
          ),
          hasLength(1),
        );
        expect(ended.where((e) => e.ruleId == id), hasLength(1));
      }
      await expectLater(
        service.create(agentRequest('in:5m', createdByRunId: run1)),
        refusedWith(WakeRuleRefusals.lineageEnded),
      );
      final late = peerMessage(run1);
      final count = dispatched.length;
      expect(await queue.enqueue(late), isTrue);
      await advance(const Duration(seconds: 3));
      expect(dispatched, hasLength(count));
      expect(
        (await wakes.getById('ws-1', late.id))!.stateReason,
        WakeStateReasons.budgetBlocked,
      );
    });

    test('a run that two lineages reach is in the older one', () async {
      final older = await service.create(agentRequest('in:5m'));
      now = now.add(const Duration(seconds: 1));
      final newer = await service.create(
        agentRequest('in:10m', conversationId: 'conv-2'),
      );
      final runOld = await fire(older);
      final runNew = await fire(newer);
      final run = await deliver([
        peerMessage(runNew, to: 'agent-2'),
        peerMessage(runOld, to: 'agent-2'),
      ]);
      expect(runWakes[run], hasLength(2));
      final made = await service.create(
        agentRequest('in:5m', agentId: 'agent-2', createdByRunId: run),
      );
      expect(made.rootRuleId, older.id);
    });

    test('the 51st link of a chain of one-offs is refused, and the person '
        'is told once', () async {
      var rule = await service.create(
        agentRequest('in:3m', requestedByUserId: 'user-1'),
      );
      final root = rule.id;
      // Three minutes apart: under the queue's 30 runs an hour.
      for (var link = 1; link <= 50; link++) {
        final run = await fire(rule);
        await settle(run, wakeIds: runWakes[run]!);
        if (link == 50) {
          await expectLater(
            service.create(
              agentRequest(
                'in:3m',
                createdByRunId: run,
                requestedByUserId: 'user-1',
              ),
            ),
            refusedWith(WakeRuleRefusals.lineageEnded),
          );
          break;
        }
        rule = await service.create(
          agentRequest(
            'in:3m',
            createdByRunId: run,
            requestedByUserId: 'user-1',
          ),
        );
        expect(rule.rootRuleId, root);
      }
      expect((await rules.lineageTotals('ws-1', root)).runs, 50);
      expect((await ruleOf(rule.id)).endReason, WakeRuleEndReason.runCap);
      final runCapRows = rows.where(
        (r) =>
            r.metadata['kind'] == wakeRuleEndedRowKind &&
            r.metadata['endReason'] == 'run_cap',
      );
      expect(runCapRows, hasLength(1));
      expect(runCapRows.single.content, contains('its chain of wakes'));
    });

    test("a person's own rule starts no lineage: a rule set in its run is "
        "a new root; a goal's run makes none", () async {
      final r1 = await service.create(agentRequest('in:5m'));
      final run1 = await fire(r1);
      final mine = await service.create(
        WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'every:20m',
          note: 'standup',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          createdByRunId: run1,
        ),
      );
      expect(mine.rootRuleId, isNull);
      final runP = await fire(mine);
      final child = await service.create(
        agentRequest('in:5m', createdByRunId: runP),
      );
      expect(child.rootRuleId, isNull);
      expect(await service.lineageStatus(child), isNull);
      // A wake the person's run causes carries no root either.
      final asked = peerMessage(runP);
      await deliver([asked]);
      expect(await carried(asked.id), isNull);
      goalOfRun[run1] = 'goal-1';
      goalEnded['goal-1'] = false;
      final ofGoal = await service.create(
        agentRequest('in:5m', createdByRunId: run1),
      );
      expect(ofGoal.goalId, 'goal-1');
      expect(ofGoal.rootRuleId, isNull);
    });

    test("a person's uncapped hourly schedule runs past 50 runs, and its "
        "51st run's wake is accepted as its own root", () async {
      final mine = await service.create(
        const WakeRuleRequest(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          when: 'every:1h',
          note: 'triage CI',
          origin: WakeRuleOrigin.person,
          createdByUserId: 'user-1',
          requestedByUserId: 'user-1',
          createdByRunId: null,
        ),
      );
      expect(mine.maxRuns, isNull);
      late String run;
      for (var n = 1; n <= 51; n++) {
        run = await fire(mine);
        if (n < 51) {
          await settle(run, wakeIds: runWakes[run]!);
        }
      }
      final child = await service.create(
        agentRequest('in:5m', createdByRunId: run),
      );
      expect(child.rootRuleId, isNull);
      await settle(run, wakeIds: runWakes[run]!);
      final after = await ruleOf(mine.id);
      expect(after.status, WakeRuleStatus.active);
      expect(after.runCount, 51);
      expect(await service.lineageStatus(after), isNull);
    });

    test('a person extends a lineage only through its root', () async {
      final r1 = await service.create(
        agentRequest('every:20m', expiresIn: const Duration(hours: 2)),
      );
      final run1 = await fire(r1);
      final r2 = await service.create(
        agentRequest(
          'every:30m',
          expiresIn: const Duration(days: 1),
          createdByRunId: run1,
        ),
      );
      final later = r1.expiresAt.add(const Duration(days: 1));
      await expectLater(
        service.update(
          'ws-1',
          r2.id,
          expiresAt: later,
          editedByUserId: 'user-1',
        ),
        refusedWith(WakeRuleRefusals.expiryTooLong),
      );
      await service.update(
        'ws-1',
        r1.id,
        expiresAt: later,
        editedByUserId: 'user-1',
      );
      final extended = await service.update(
        'ws-1',
        r2.id,
        expiresAt: later,
        editedByUserId: 'user-1',
      );
      expect(extended.expiresAt, later);
      expect((await service.lineageStatus(r2))!.endsAt, later);
    });
  });
}
