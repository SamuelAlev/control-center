import 'package:cc_domain/core/domain/events/digest_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_infra/cc_infra.dart' show TimezoneZoneConverter;
import 'package:cc_server_core/src/unattended/waiting_digest.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 11, 19);

AgentGoalRun _goal(
  String id, {
  GoalHold? hold = GoalHold.needsReview,
  AgentGoalStatus status = AgentGoalStatus.paused,
  String? person = 'u-1',
  String spaceId = 'sp-1',
}) => AgentGoalRun(
  id: id,
  workspaceId: 'ws-1',
  spaceId: spaceId,
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Keep the changelog current',
  status: status,
  costCapMicros: 50000000,
  hold: hold,
  requestedByUserId: person,
  createdAt: _t0,
  updatedAt: _t0,
);

ImprovementProposal _proposal(String id, {String? goalId}) =>
    ImprovementProposal(
      id: id,
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      spaceId: 'sp-1',
      goalId: goalId,
      kind: ImprovementKind.memoryFact,
      scope: ImprovementScope.agent,
      operation: ImprovementOperation.add,
      change: 'Run the migrations before the tests.',
      expected: 'No failed first test run.',
      createdAt: _t0,
      expiresAt: _t0.add(ImprovementProposal.lifetime),
    );

class _World {
  _World(this.async, {Map<String, String>? settings})
    : settings = settings ?? {};

  final FakeAsync async;
  final Map<String, String> settings;
  final bus = DomainEventBus();
  final published = <WaitingDigest>[];
  String zone = 'UTC';
  Map<GoalHold, List<AgentGoalRun>> goals = {};
  List<HeldWakeView> wakes = [];
  List<ImprovementProposal> proposals = [];
  Map<String, List<PendingRequestDigestView>> requests = {};
  Set<(String, String)> unreadable = {};
  Set<String> gone = {};
  late WaitingDigestService service;

  /// The fake clock starts at [start] (UTC).
  DateTime start = _t0;
  DateTime now() => start.add(async.elapsed);

  WaitingDigestService begin() {
    bus.on<WaitingDigest>().listen(published.add);
    final zones = TimezoneZoneConverter.instance;
    return service = WaitingDigestService(
      eventBus: bus,
      scheduler: zones.scheduler(),
      toLocal: zones.toLocal,
      now: now,
      ports: WaitingDigestPorts(
        workspaceIds: () async => {'ws-1', ...requests.keys}.toList(),
        readSetting: (ws, key) async => settings['$ws/$key'],
        writeSetting: (ws, key, value) async => settings['$ws/$key'] = value,
        timeZoneOf: (_) async => zone,
        heldGoals: (_, hold) async => goals[hold] ?? const [],
        heldWakes: (ws) async => ws == 'ws-1' ? wakes : const [],
        pendingProposals: (ws) async => ws == 'ws-1' ? proposals : const [],
        pendingRequests: (ws) async => requests[ws] ?? const [],
        goalById: (_, id) async {
          for (final list in goals.values) {
            for (final g in list) {
              if (g.id == id) {
                return g;
              }
            }
          }
          return null;
        },
        admins: (_) async => ['admin-1'],
        isMember: (_, user) async => !gone.contains(user),
        canReadSpace: (_, user, space) async =>
            !unreadable.contains((user, space)),
        stopping: () => false,
      ),
    )..start();
  }
}

void main() {
  test(
    'sent once at 09:00, only for what waits, to the person it acts for',
    () {
      fakeAsync((async) {
        final w = _World(async)..start = _t0.add(const Duration(hours: 8));
        w.goals = {
          GoalHold.needsReview: [_goal('goal-1')],
          GoalHold.person: [
            _goal(
              'goal-2',
              hold: GoalHold.person,
              status: AgentGoalStatus.active,
            ),
          ],
        };
        w.wakes = [
          (
            id: 'wake-1',
            spaceId: 'sp-1',
            conversationId: 'conv-1',
            agentId: 'agent-1',
            requestedByUserId: null,
            summary: 'nightly sweep',
          ),
        ];
        w.proposals = [_proposal('imp-1', goalId: 'goal-1')];
        w.begin();
        async.elapse(const Duration(minutes: 59));
        expect(w.published, isEmpty, reason: 'not before the hour');
        async.elapse(const Duration(minutes: 2));
        expect(w.published, hasLength(2));
        final mine = w.published.firstWhere((d) => d.forUserId == 'u-1');
        expect(mine.day, '2026-11-19');
        expect(mine.items.map((i) => (i.type, i.id)), [
          (WaitingDigestItemType.goalReview, 'goal-1'),
          (WaitingDigestItemType.goalPerson, 'goal-2'),
          (WaitingDigestItemType.improvement, 'imp-1'),
        ]);
        final admins = w.published.firstWhere((d) => d.forUserId == 'admin-1');
        expect(admins.items.single.type, WaitingDigestItemType.heldWake);

        // Ticking on through the day sends nothing more.
        async.elapse(const Duration(hours: 10));
        expect(w.published, hasLength(2));
        // The next day's hour sends again.
        async.elapse(const Duration(hours: 14));
        expect(w.published, hasLength(4));
        expect(w.published.last.day, '2026-11-20');
        w.service.dispose();
      });
    },
  );

  test("a schedule run's pending approval is in its person's digest, with "
      'its deadline, and nobody else\'s; a bot run\'s goes to the admins; '
      'a goal already listed is not listed twice; each workspace lists its '
      'own', () {
    fakeAsync((async) {
      final w = _World(async)
        ..start = _t0.add(const Duration(hours: 9, minutes: 30));
      final deadline = _t0.add(const Duration(days: 3));
      PendingRequestDigestView request(
        String id, {
        String? person,
        String? goalId,
      }) => (
        id: id,
        summary: 'Run the migration outside the sandbox',
        agentId: 'agent-1',
        requestedByUserId: person,
        goalId: goalId,
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        deadline: deadline,
      );
      w.goals = {
        GoalHold.person: [
          _goal(
            'goal-1',
            hold: GoalHold.person,
            status: AgentGoalStatus.active,
          ),
        ],
      };
      w.requests = {
        'ws-1': [
          request('cf-schedule', person: 'u-1'),
          request('cf-bot'),
          request('cf-goal', person: 'u-1', goalId: 'goal-1'),
        ],
        'ws-2': [request('cf-other', person: 'u-2')],
      };
      w.begin();
      final ws1 = w.service.runFor('ws-1');
      async.flushMicrotasks();
      List<WaitingDigest>? sent;
      ws1.then((d) => sent = d);
      async.flushMicrotasks();
      final mine = sent!.singleWhere((d) => d.forUserId == 'u-1');
      expect(
        [for (final i in mine.items) (i.type, i.id)],
        [
          (WaitingDigestItemType.goalPerson, 'goal-1'),
          (WaitingDigestItemType.request, 'cf-schedule'),
        ],
      );
      final item = mine.items.last;
      expect(item.expiresAt, deadline);
      expect(item.conversationId, 'conv-1');
      final admin = sent!.singleWhere((d) => d.forUserId == 'admin-1');
      expect([for (final i in admin.items) i.id], ['cf-bot']);
      expect(sent!.where((d) => d.forUserId == 'u-2'), isEmpty);

      List<WaitingDigest>? other;
      w.service.runFor('ws-2').then((d) => other = d);
      async.flushMicrotasks();
      expect(other!.single.forUserId, 'u-2');
      expect([for (final i in other!.single.items) i.id], ['cf-other']);
      expect(other!.single.workspaceId, 'ws-2');
    });
  });

  test('nothing waits: nothing is sent, and the day is still spent', () {
    fakeAsync((async) {
      final w = _World(async)..start = _t0.add(const Duration(hours: 9));
      w.begin();
      async.elapse(const Duration(minutes: 2));
      expect(w.published, isEmpty);
      expect(
        w.settings['ws-1/${WaitingDigestService.daySettingKey}'],
        '2026-11-19',
      );
      // Something that starts waiting at 11:00 waits for tomorrow.
      w.goals = {
        GoalHold.needsReview: [_goal('goal-1')],
      };
      async.elapse(const Duration(hours: 2));
      expect(w.published, isEmpty);
      w.service.dispose();
    });
  });

  test('a restart never sends the day twice; a server down at the hour sends '
      'late', () {
    fakeAsync((async) {
      final settings = <String, String>{};
      final first = _World(async, settings: settings)
        ..start = _t0.add(const Duration(hours: 9));
      first.goals = {
        GoalHold.needsReview: [_goal('goal-1')],
      };
      first.begin();
      async.elapse(const Duration(minutes: 2));
      expect(first.published, hasLength(1));
      first.service.dispose();

      final second = _World(async, settings: settings)
        ..start = _t0.add(const Duration(hours: 9));
      second.goals = first.goals;
      second.begin();
      async.elapse(const Duration(minutes: 30));
      expect(second.published, isEmpty);
      second.service.dispose();

      // Down over the next day's hour: back at 14:00, it sends.
      final third = _World(async, settings: settings)
        ..start = _t0.add(const Duration(days: 1, hours: 14));
      third.goals = first.goals;
      third.begin();
      async.elapse(const Duration(minutes: 2));
      expect(third.published.single.day, '2026-11-20');
      third.service.dispose();
    });
  });

  test('the hour is the workspace setting, in the workspace zone', () {
    fakeAsync((async) {
      final w = _World(
        async,
        settings: {'ws-1/$unattendedPolicySettingKey': '{"digest_hour": 7}'},
      );
      // 07:00 in Tokyo is 22:00 UTC the day before.
      w
        ..zone = 'Asia/Tokyo'
        ..start = _t0.add(const Duration(hours: 21, minutes: 30));
      w.goals = {
        GoalHold.needsReview: [_goal('goal-1')],
      };
      w.begin();
      async.elapse(const Duration(minutes: 29));
      expect(w.published, isEmpty);
      async.elapse(const Duration(minutes: 2));
      expect(w.published.single.day, '2026-11-20');
      w.service.dispose();
    });
  });

  test('a person sees only what they may read; closed goals are left out', () {
    fakeAsync((async) {
      final w = _World(async)..start = _t0.add(const Duration(hours: 9));
      w.goals = {
        GoalHold.needsReview: [
          _goal('goal-1'),
          _goal('goal-2', spaceId: 'sp-secret'),
          _goal('goal-3', status: AgentGoalStatus.completed),
        ],
      };
      w.unreadable = {('u-1', 'sp-secret')};
      w.begin();
      async.elapse(const Duration(minutes: 2));
      expect(w.published.single.items.map((i) => i.id), ['goal-1']);
      w.service.dispose();
    });
  });

  test('what acted for a person who left the workspace goes to the admins', () {
    fakeAsync((async) {
      final w = _World(async)..start = _t0.add(const Duration(hours: 9));
      w.goals = {
        GoalHold.needsReview: [_goal('goal-1')],
      };
      w.proposals = [_proposal('prop-1', goalId: 'goal-1')];
      w.gone = {'u-1'};
      w.begin();
      async.elapse(const Duration(minutes: 2));
      final digest = w.published.single;
      expect(digest.forUserId, 'admin-1');
      expect(digest.items.map((i) => i.id), ['goal-1', 'prop-1']);
      w.service.dispose();
    });
  });
}
