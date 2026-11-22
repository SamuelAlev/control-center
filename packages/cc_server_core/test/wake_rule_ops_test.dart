import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        NotFoundException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        WakeCronPreview,
        WakeLineageStatus,
        WakeRuleHistoryPage,
        WakeRuleRequest,
        WakeRuleService;
import 'package:cc_server_core/src/catalog/wake_rule_ops.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 11, 19, 12);

WakeRule _rule(String id, String ws, {String? owner = 'user-1'}) => WakeRule(
  id: id,
  workspaceId: ws,
  spaceId: 'sp-$ws',
  conversationId: ws == 'ws-1' ? 'conv-1' : 'conv-2',
  agentId: 'agent-1',
  trigger: Every(const Duration(minutes: 30)),
  note: 'Check the deploy.',
  costCapMicros: 50000000,
  expiresAt: _t0.add(const Duration(days: 30)),
  nextFireAt: _t0.add(const Duration(minutes: 30)),
  origin: owner == null ? WakeRuleOrigin.agent : WakeRuleOrigin.person,
  requestedByUserId: owner,
  createdByUserId: owner,
  createdAt: _t0,
  updatedAt: _t0,
);

class _Rules implements WakeRuleRepository {
  final Map<String, Map<String, WakeRule>> byWs = {};

  void put(WakeRule r) => (byWs[r.workspaceId] ??= {})[r.id] = r;

  @override
  Future<WakeRule?> getById(String workspaceId, String id) async =>
      byWs[workspaceId]?[id];

  @override
  Stream<List<WakeRule>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value([
    for (final r in byWs[workspaceId]?.values ?? const <WakeRule>[])
      if (r.conversationId == conversationId) r,
  ]);

  @override
  Stream<List<WakeRule>> watchForWorkspace(String workspaceId) async* {
    // A store that wrongly mixed in another workspace's row.
    yield [...?byWs[workspaceId]?.values, ...?byWs['ws-2']?.values];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The service surface the ops use; its behaviour is tested in cc_infra.
class _Service implements WakeRuleService {
  _Service(this.rules);

  final _Rules rules;
  final calls = <String>[];
  final requests = <WakeRuleRequest>[];
  WakeRuleLimits limits = WakeRuleLimits();

  @override
  Future<WakeRule> create(WakeRuleRequest request) async {
    requests.add(request);
    final rule = _rule('new-1', request.workspaceId);
    rules.put(rule);
    return rule;
  }

  @override
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
    calls.add('update $id by $editedByUserId');
    final rule = rules.byWs[workspaceId]![id]!.copyWith(
      note: note,
      noteEditedByUserId: note == null ? null : editedByUserId,
    );
    rules.put(rule);
    return rule;
  }

  @override
  Future<bool> pause(
    String workspaceId,
    String id, {
    required String pausedBy,
  }) async {
    calls.add('pause $id by $pausedBy');
    return true;
  }

  @override
  Future<bool> resume(String workspaceId, String id) async {
    calls.add('resume $id');
    return true;
  }

  @override
  Future<bool> delete(String workspaceId, String id) async {
    calls.add('delete $id');
    return true;
  }

  @override
  Future<WakeRuleLimits> limitsFor(String workspaceId) async => limits;

  /// The next fires each rule id answers, and the drafts previewed.
  final fires = <String, List<DateTime>>{};
  final previews = <String>[];
  List<DateTime> preview = const [];

  @override
  Future<List<DateTime>> nextFires(WakeRule rule) async =>
      fires[rule.id] ?? const [];

  @override
  Future<WakeCronPreview> previewCron(
    String workspaceId, {
    required String expression,
    required String timeZone,
  }) async {
    previews.add('$workspaceId $expression@$timeZone');
    return (nextFires: preview, zoneKnown: timeZone != 'Mars/Base');
  }

  /// The history page each rule id answers, and the cursors asked for.
  final histories = <String, WakeRuleHistoryPage>{};
  final cursors = <String?>[];

  @override
  Future<WakeRuleHistoryPage> history(WakeRule rule, {String? cursor}) async {
    cursors.add(cursor);
    const WakeRuleHistoryPage empty = (wakes: [], nextCursor: null);
    return histories[rule.id] ?? empty;
  }

  /// The lineage each rule id belongs to.
  final chains = <String, WakeLineageStatus>{};

  @override
  Future<WakeLineageStatus?> lineageStatus(WakeRule rule) async =>
      chains[rule.id];

  @override
  Future<WakeRuleLimits> setLimits(
    String workspaceId,
    WakeRuleLimits limits,
  ) async => this.limits = limits;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => switch ((workspaceId, conversationId)) {
    ('ws-1', 'conv-1') || ('ws-2', 'conv-2') => Conversation(
      id: conversationId,
      workspaceId: workspaceId,
      spaceId: 'sp-$workspaceId',
      title: 't',
      createdAt: _t0,
      updatedAt: _t0,
    ),
    _ => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The `wakeRules.*` ops: workspace isolation at each op, the space gate,
/// who may change a rule, the person's identity on create, and the wire.
void main() {
  late _Rules rules;
  late _Service service;
  late List<RepoOp> ops;
  late List<WatchQuery> watches;
  late Set<String> unreadableSpaces;
  late Map<String, WorkspaceRole> roles;

  setUp(() {
    rules = _Rules()
      ..put(_rule('mine', 'ws-1'))
      ..put(_rule('theirs', 'ws-1', owner: 'user-2'))
      ..put(_rule('bot', 'ws-1', owner: null))
      ..put(_rule('foreign', 'ws-2'));
    service = _Service(rules);
    unreadableSpaces = {};
    roles = {'user-1': WorkspaceRole.member, 'admin': WorkspaceRole.admin};
    final pack = buildWakeRuleOps(
      service: () => service,
      rules: rules,
      conversations: _Conversations(),
      requireSpace: (ws, user, space) async {
        if (unreadableSpaces.contains(space)) {
          throw const ValidationException('space_access_denied');
        }
      },
      guardSpace: (ws, user, space, source) => source,
      roleOf: (ws, user) async => roles[user],
    );
    ops = pack.ops;
    watches = pack.watches;
  });

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> args, {
    String ws = 'ws-1',
    String user = 'user-1',
  }) async => Map<String, dynamic>.from(
    await ops
            .firstWhere((o) => o.name == name)
            .handler(
              RepoOpContext(
                args: args,
                workspaceId: ws,
                deviceId: 'device-1',
                userId: user,
                role: roles[user],
              ),
            )
        as Map,
  );

  Stream<Map<String, dynamic>> watch(
    String name,
    Map<String, dynamic> args, {
    String user = 'user-1',
  }) => watches
      .firstWhere((w) => w.name == name)
      .handler(
        WatchQueryContext(
          args: args,
          workspaceId: 'ws-1',
          deviceId: 'device-1',
          userId: user,
        ),
      );

  test('the pack: writes and reads open to members, limits to admins', () {
    expect(
      {for (final o in ops) o.name: o.kind},
      {
        'wakeRules.create': RepoOpKind.mutate,
        'wakeRules.update': RepoOpKind.mutate,
        'wakeRules.pause': RepoOpKind.mutate,
        'wakeRules.resume': RepoOpKind.mutate,
        'wakeRules.delete': RepoOpKind.mutate,
        'wakeRules.get': RepoOpKind.read,
        'wakeRules.listRuns': RepoOpKind.read,
        'wakeRules.previewCron': RepoOpKind.read,
        'wakeRules.getLimits': RepoOpKind.read,
        'wakeRules.setLimits': RepoOpKind.mutate,
      },
    );
    for (final o in ops) {
      expect(
        o.minRole,
        o.name == 'wakeRules.setLimits'
            ? WorkspaceRole.admin
            : WorkspaceRole.member,
        reason: o.name,
      );
    }
    expect(
      [for (final w in watches) w.name],
      ['wakeRules.watchForConversation', 'wakeRules.watchForWorkspace'],
    );
    for (final w in watches) {
      expect(w.minRole, WorkspaceRole.member);
    }
  });

  test('no service, no ops', () {
    final pack = buildWakeRuleOps(
      service: null,
      rules: null,
      conversations: _Conversations(),
      requireSpace: (_, _, _) async {},
      guardSpace: (_, _, _, s) => s,
      roleOf: (_, _) async => null,
    );
    expect(pack.ops, isEmpty);
    expect(pack.watches, isEmpty);
  });

  group('workspace isolation', () {
    test('a rule of another workspace is not found at any op', () async {
      for (final name in [
        'wakeRules.get',
        'wakeRules.listRuns',
        'wakeRules.update',
        'wakeRules.pause',
        'wakeRules.resume',
        'wakeRules.delete',
      ]) {
        await expectLater(
          call(name, {'rule_id': 'foreign'}),
          throwsA(isA<NotFoundException>()),
          reason: name,
        );
      }
      expect(service.calls, isEmpty);
    });

    test('a conversation of another workspace is refused', () async {
      await expectLater(
        call('wakeRules.create', {
          'conversation_id': 'conv-2',
          'agent_id': 'agent-1',
          'note': 'x',
          'when': 'in:1h',
        }),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        watch('wakeRules.watchForConversation', {
          'conversation_id': 'conv-2',
        }).first,
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(service.requests, isEmpty);
    });

    test(
      'the workspace watch drops foreign rows and unreadable spaces',
      () async {
        var rows =
            (await watch('wakeRules.watchForWorkspace', {}).first)['rules']
                as List;
        expect(
          [for (final r in rows) (r as Map)['id']],
          ['mine', 'theirs', 'bot'],
        );
        unreadableSpaces.add('sp-ws-1');
        rows =
            (await watch('wakeRules.watchForWorkspace', {}).first)['rules']
                as List;
        expect(rows, isEmpty);
      },
    );

    test('an unreadable space refuses every rule op', () async {
      unreadableSpaces.add('sp-ws-1');
      for (final name in [
        'wakeRules.get',
        'wakeRules.listRuns',
        'wakeRules.pause',
      ]) {
        await expectLater(
          call(name, {'rule_id': 'mine'}),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });

  group('who may change a rule', () {
    test("resume and terms are the rule's own person's", () async {
      for (final (name, args) in [
        ('wakeRules.resume', {'rule_id': 'theirs'}),
        ('wakeRules.update', {'rule_id': 'theirs', 'note': 'x'}),
      ]) {
        await expectLater(
          call(name, args),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              WakeRuleRefusals.notYours,
            ),
          ),
          reason: name,
        );
      }
      expect(await call('wakeRules.resume', {'rule_id': 'mine'}), {
        'resumed': true,
      });
    });

    test('pausing and deleting are open to every member', () async {
      expect(await call('wakeRules.pause', {'rule_id': 'theirs'}), {
        'paused': true,
      });
      expect(await call('wakeRules.delete', {'rule_id': 'theirs'}), {
        'deleted': true,
      });
      // The service names the pauser (its row when it is not the owner).
      expect(service.calls, ['pause theirs by user-1', 'delete theirs']);
    });

    test("a bot's rule is changed by an admin only", () async {
      await expectLater(
        call('wakeRules.resume', {'rule_id': 'bot'}),
        throwsA(isA<AuthException>()),
      );
      expect(
        await call('wakeRules.resume', {'rule_id': 'bot'}, user: 'admin'),
        {'resumed': true},
      );
    });

    test('the wire says whether the viewer may change each rule', () async {
      final mine = (await call('wakeRules.get', {'rule_id': 'mine'}))['rule'];
      final theirs = (await call('wakeRules.get', {
        'rule_id': 'theirs',
      }))['rule'];
      expect((mine as Map)['can_change'], isTrue);
      expect((theirs as Map)['can_change'], isFalse);
      final rows =
          (await watch(
                'wakeRules.watchForWorkspace',
                {},
                user: 'admin',
              ).first)['rules']
              as List;
      expect(
        {for (final r in rows) (r as Map)['id']: r['can_change']},
        {'mine': false, 'theirs': false, 'bot': true},
      );
    });
  });

  group('listRuns', () {
    Wake wake(
      String id, {
      WakeState state = WakeState.delivered,
      String? stateReason,
      String? runId,
    }) => Wake(
      id: id,
      workspaceId: 'ws-1',
      spaceId: 'sp-ws-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      reason: WakeReason.schedule,
      payload: 'Check the deploy.',
      detail: WakeDetail(
        ruleId: 'mine',
        slot: DateTime.parse('2026-11-19T13:00:00+01:00'),
      ),
      dedupKey: 'k-$id',
      notBefore: _t0,
      state: state,
      stateReason: stateReason,
      deliveredRunId: runId,
      createdAt: _t0,
      settledAt: state == WakeState.pending ? null : _t0,
    );

    test('a rule with no wakes is an empty last page', () async {
      final out = await call('wakeRules.listRuns', {'rule_id': 'mine'});
      expect(out, {'rule_id': 'mine', 'wakes': isEmpty, 'next_cursor': null});
      expect(service.cursors, [null]);
    });

    test('the page, its cursor, a skipped wake (no run) and a live run, '
        'every time UTC; the payload is not sent', () async {
      service.histories['mine'] = (
        wakes: [
          (
            wake: wake('w-2', runId: 'run-2'),
            run: (
              id: 'run-2',
              status: 'running',
              endReason: null,
              costMicros: 0,
              startedAt: DateTime.parse('2026-11-19T13:00:03+01:00'),
              endedAt: null,
            ),
          ),
          (
            wake: wake('w-1', state: WakeState.skipped, stateReason: 'busy'),
            run: null,
          ),
        ],
        nextCursor: 'next-1',
      );
      final out = await call('wakeRules.listRuns', {
        'rule_id': 'mine',
        'cursor': 'c-0',
      });
      expect(service.cursors, ['c-0']);
      expect(out['next_cursor'], 'next-1');
      final rows = (out['wakes'] as List).cast<Map<String, dynamic>>();
      expect(rows.first, {
        'id': 'w-2',
        'reason': 'schedule',
        'state': 'delivered',
        'state_reason': null,
        'slot': '2026-11-19T12:00:00.000Z',
        'event_kind': null,
        'status': null,
        'subject': null,
        'item': null,
        'exit_code': null,
        'events': null,
        'due_at': '2026-11-19T12:00:00.000Z',
        'created_at': '2026-11-19T12:00:00.000Z',
        'settled_at': '2026-11-19T12:00:00.000Z',
        'run': {
          'id': 'run-2',
          'status': 'running',
          'end_reason': null,
          'cost_micros': 0,
          'started_at': '2026-11-19T12:00:03.000Z',
          'ended_at': null,
        },
      });
      expect(rows[1]['run'], isNull);
      expect(rows[1]['state'], 'skipped');
      expect(rows[1]['state_reason'], 'busy');
    });

    test('a cursor that is not a string is refused', () async {
      await expectLater(
        call('wakeRules.listRuns', {'rule_id': 'mine', 'cursor': 3}),
        throwsA(isA<ValidationException>()),
      );
      expect(service.cursors, isEmpty);
    });
  });

  test('create acts for the caller and reads the clock form', () async {
    final out = await call('wakeRules.create', {
      'conversation_id': 'conv-1',
      'agent_id': 'agent-1',
      'note': 'Summarize the night.',
      'hour': 9,
      'minute': 0,
      'tz': 'Europe/Berlin',
      'expires_in': '30d',
      'fire_now': false,
    });
    final request = service.requests.single;
    expect(request.requestedByUserId, 'user-1');
    expect(request.createdByUserId, 'user-1');
    expect(request.origin, WakeRuleOrigin.person);
    expect(request.when, isNull);
    expect(request.clock, (hour: 9, minute: 0));
    expect(request.timeZone, 'Europe/Berlin');
    expect(request.expiresIn, const Duration(days: 30));
    expect((out['rule'] as Map)['owner_user_id'], 'user-1');
    await expectLater(
      call('wakeRules.create', {
        'conversation_id': 'conv-1',
        'agent_id': 'agent-1',
        'note': 'x',
        'hour': 25,
        'minute': 0,
      }),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          WakeRuleRefusals.invalidWhen,
        ),
      ),
    );
  });

  test('the wire names everything the Schedules screen shows', () async {
    final rule = (await call('wakeRules.get', {'rule_id': 'mine'}))['rule'];
    expect(
      (rule as Map).keys.toSet(),
      containsAll([
        'id',
        'owner_user_id',
        'agent_id',
        'conversation_id',
        'trigger',
        'next_fire_at',
        'run_count',
        'cost_micros',
        'cost_cap_micros',
        'status',
        'expires_at',
        'can_change',
      ]),
    );
    expect(rule['trigger'], 'every:30m');
    expect(rule['next_fire_at'], '2026-11-19T12:30:00.000Z');
    expect(rule['note_author'], 'person');
    expect(rule.containsKey('root_rule_id'), isFalse);
  });

  test('every time on the wire is UTC ISO 8601 with Z, even from local '
      'times', () {
    final local = DateTime(2026, 11, 19, 14, 20, 5);
    final wire = wakeRuleToWire(
      WakeRule(
        id: 'r-1',
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        trigger: Every(const Duration(minutes: 30)),
        note: 'x',
        costCapMicros: 1,
        expiresAt: local.add(const Duration(days: 1)),
        lastFiredAt: local,
        nextFireAt: local.add(const Duration(minutes: 30)),
        origin: WakeRuleOrigin.agent,
        rootRuleId: 'r-0',
        createdAt: local,
        updatedAt: local,
      ),
      canChange: false,
      lineage: (
        rootRuleId: 'r-0',
        runsLeft: 4,
        endsAt: local.add(const Duration(days: 2)),
      ),
      nextFires: [local.add(const Duration(hours: 1))],
    );
    expect(wire['next_fires'], [
      local.add(const Duration(hours: 1)).toUtc().toIso8601String(),
    ]);
    expect((wire['next_fires'] as List).single as String, endsWith('Z'));
    for (final key in [
      'expires_at',
      'last_fired_at',
      'next_fire_at',
      'created_at',
      'updated_at',
      'lineage_ends_at',
    ]) {
      expect(wire[key] as String, endsWith('Z'), reason: key);
    }
    expect(wire['last_fired_at'], local.toUtc().toIso8601String());
    expect(wire['root_rule_id'], 'r-0');
    expect(wire['lineage_runs_left'], 4);
    expect(wire['note_author'], 'agent');
  });

  test("a cron rule's next fires ride on its wire; a rule with none sends "
      'no field', () async {
    service.fires['mine'] = [DateTime.utc(2026, 11, 21, 8)];
    final mine = (await call('wakeRules.get', {'rule_id': 'mine'}))['rule'];
    expect((mine as Map)['next_fires'], ['2026-11-21T08:00:00.000Z']);
    final bot = (await call('wakeRules.get', {'rule_id': 'bot'}))['rule'];
    expect((bot as Map).containsKey('next_fires'), isFalse);
  });

  test("previewCron answers the service's times for the caller's "
      'workspace; a non-string is refused', () async {
    service.preview = [DateTime.parse('2026-11-21T09:00:00+01:00')];
    final out = await call('wakeRules.previewCron', {
      'expression': '0 9 * * *',
      'time_zone': 'Europe/Berlin',
    });
    expect(out, {
      'next_fires': ['2026-11-21T08:00:00.000Z'],
      'zone_known': true,
    });
    expect(service.previews, ['ws-1 0 9 * * *@Europe/Berlin']);
    await call('wakeRules.previewCron', {'expression': '0 9 * * *'}, ws: 'ws-2');
    expect(service.previews.last, 'ws-2 0 9 * * *@');
    // A zone asked about alone, with the server's verdict.
    final zoneOnly = await call('wakeRules.previewCron', {
      'time_zone': 'Mars/Base',
    });
    expect(zoneOnly['zone_known'], isFalse);
    expect(service.previews.last, 'ws-1 @Mars/Base');
    await expectLater(
      call('wakeRules.previewCron', {'expression': 9}),
      throwsA(isA<ValidationException>()),
    );
  });

  test("a person's note edit makes the note theirs on the wire", () async {
    final bot = (await call('wakeRules.get', {'rule_id': 'bot'}))['rule'];
    expect((bot as Map)['note_author'], 'agent');
    final out = await call('wakeRules.update', {
      'rule_id': 'bot',
      'note': 'Check the deploy, then the logs.',
    }, user: 'admin');
    expect(service.calls.last, 'update bot by admin');
    final rule = out['rule'] as Map;
    expect(rule['note_author'], 'person');
    expect(rule['note_edited_by_user_id'], 'admin');
  });

  test("a rule of a lineage shows the lineage's runs left and end", () async {
    service.chains['mine'] = (
      rootRuleId: 'r-root',
      runsLeft: 12,
      endsAt: DateTime.utc(2026, 11, 26, 12),
    );
    final rule = (await call('wakeRules.get', {'rule_id': 'mine'}))['rule'];
    expect((rule as Map)['lineage_runs_left'], 12);
    expect(rule['lineage_ends_at'], '2026-11-26T12:00:00.000Z');
  });

  test('setLimits merges onto the current limits and refuses a value out '
      'of range with its kind', () async {
    final out = await call('wakeRules.setLimits', {
      'limits': {'per_conversation': 20},
    }, user: 'admin');
    expect((out['limits'] as Map)['per_conversation'], 20);
    expect((out['limits'] as Map)['per_agent'], 50);
    await expectLater(
      call('wakeRules.setLimits', {
        'limits': {'per_conversation': 'many'},
      }, user: 'admin'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          WakeRuleRefusals.limitOutOfRange,
        ),
      ),
    );
  });
}
