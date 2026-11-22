import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// [RpcWakeRuleScheduleRepository] over an in-process JSON-RPC host: the
/// `wakeRules.*` op names, the args (always the workspace), the wire
/// decoding (a row the client cannot read is dropped), and the limits.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcWakeRuleScheduleRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcWakeRuleScheduleRepository(client);
  });

  tearDown(() async => client.close());

  Map<String, dynamic> wire({String id = 'r-1', String status = 'active'}) => {
    'id': id,
    'workspace_id': 'ws-1',
    'space_id': 'sp-1',
    'conversation_id': 'conv-1',
    'agent_id': 'agent-1',
    'owner_user_id': 'u-1',
    'created_by_user_id': 'u-1',
    'origin': 'person',
    'trigger': 'cron:0 9 * * 1-5',
    'trigger_kind': 'cron',
    'tz': 'Europe/Berlin',
    'note': 'Summarize the night.',
    'deliver': 'run',
    'when_busy': 'skip',
    'next_fire_at': '2026-11-20T08:00:00.000Z',
    'run_count': 3,
    'max_runs': 20,
    'skip_count': 1,
    'cost_micros': 1200000,
    'cost_cap_micros': 50000000,
    'status': status,
    'expires_at': '2026-12-19T12:00:00.000Z',
    'created_at': '2026-11-19T12:00:00.000Z',
    'updated_at': '2026-11-19T12:00:00.000Z',
    'can_change': true,
  };

  test(
    'watchForWorkspace decodes each rule and drops an unreadable one',
    () async {
      host.snapshotFor('wakeRules.watchForWorkspace', {
        'rules': [wire(), wire(id: 'r-bad', status: 'not_a_status')],
      });
      final rule = (await repo.watchForWorkspace('ws-1').first).single;
      expect(rule.id, 'r-1');
      expect(rule.origin, WakeRuleOrigin.person);
      expect(rule.trigger, 'cron:0 9 * * 1-5');
      expect(rule.timeZone, 'Europe/Berlin');
      expect(rule.nextFireAt, DateTime.utc(2026, 11, 20, 8));
      expect(rule.runCount, 3);
      expect(rule.maxRuns, 20);
      expect(rule.skipCount, 1);
      expect(rule.costMicros, 1200000);
      expect(rule.status, WakeRuleStatus.active);
      expect(rule.endReason, isNull);
      expect(rule.ownerUserId, 'u-1');
      expect(rule.canChange, isTrue);
      expect(host.lastSubscribe!.args, {'workspace_id': 'ws-1'});
    },
  );

  test('a chained rule carries its chain and whose words its note is', () async {
    host.snapshotFor('wakeRules.watchForWorkspace', {
      'rules': [
        {
          ...wire(),
          'origin': 'agent',
          'note_author': 'person',
          'note_edited_by_user_id': 'u-2',
          'root_rule_id': 'r-root',
          'lineage_runs_left': 7,
          'lineage_ends_at': '2026-12-01T00:00:00.000Z',
        },
        {...wire(id: 'r-2'), 'origin': 'agent'},
      ],
    });
    final rules = await repo.watchForWorkspace('ws-1').first;
    expect(rules.first.noteAuthor, WakeRuleOrigin.person);
    expect(rules.first.noteEditedByUserId, 'u-2');
    expect(rules.first.rootRuleId, 'r-root');
    expect(rules.first.lineageRunsLeft, 7);
    expect(rules.first.lineageEndsAt, DateTime.utc(2026, 12));
    // No `note_author`: the note is its creator's.
    expect(rules.last.noteAuthor, WakeRuleOrigin.agent);
    expect(rules.last.rootRuleId, isNull);
    expect(rules.last.lineageRunsLeft, isNull);
  });

  test('watchForConversation names the conversation', () async {
    host.snapshotFor('wakeRules.watchForConversation', {
      'rules': [wire()],
    });
    expect(
      await repo.watchForConversation('ws-1', 'conv-1').first,
      hasLength(1),
    );
    expect(host.lastSubscribe!.args, {
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
    });
  });

  test('create, update and the controls call their ops', () async {
    host.callResults['wakeRules.create'] = {'rule': wire()};
    host.callResults['wakeRules.update'] = {'rule': wire()};
    host.callResults['wakeRules.pause'] = {'paused': true};
    host.callResults['wakeRules.resume'] = {'resumed': false};
    host.callResults['wakeRules.delete'] = {'deleted': true};
    final created = await repo.create(
      'ws-1',
      WakeRuleDraft(
        conversationId: 'conv-1',
        agentId: 'agent-1',
        note: 'Summarize the night.',
        hour: 9,
        minute: 0,
        timeZone: 'Europe/Berlin',
        expiresIn: '30d',
      ),
    );
    expect(created.id, 'r-1');
    expect(host.lastCall('wakeRules.create')!.args, {
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
      'agent_id': 'agent-1',
      'note': 'Summarize the night.',
      'hour': 9,
      'minute': 0,
      'tz': 'Europe/Berlin',
      'expires_in': '30d',
      'deliver': 'run',
    });
    await repo.update(
      'ws-1',
      'r-1',
      note: 'New note',
      clearMaxRuns: true,
      expiresAt: DateTime.utc(2027),
    );
    expect(host.lastCall('wakeRules.update')!.args, {
      'workspace_id': 'ws-1',
      'rule_id': 'r-1',
      'note': 'New note',
      'clear_max_runs': true,
      'expires_at': '2027-01-01T00:00:00.000Z',
    });
    expect(await repo.pause('ws-1', 'r-1'), isTrue);
    expect(await repo.resume('ws-1', 'r-1'), isFalse);
    expect(await repo.delete('ws-1', 'r-1'), isTrue);
    expect(host.lastCall('wakeRules.delete')!.args, {
      'workspace_id': 'ws-1',
      'rule_id': 'r-1',
    });
  });

  test('listRuns sends the rule and cursor and decodes each wake with its '
      'run; an unreadable row is dropped', () async {
    host.callResults['wakeRules.listRuns'] = {
      'rule_id': 'r-1',
      'wakes': [
        {
          'id': 'w-3',
          'reason': 'watch',
          'state': 'delivered',
          'state_reason': null,
          'slot': null,
          'event_kind': 'environment',
          'status': 'exited',
          'subject': 'environment preview',
          'item': 'tests',
          'exit_code': 1,
          'events': 2,
          'due_at': '2026-11-20T09:00:00.000Z',
          'created_at': '2026-11-20T09:00:00.000Z',
          'settled_at': '2026-11-20T09:00:03.000Z',
          'run': {
            'id': 'run-3',
            'status': 'running',
            'end_reason': null,
            'cost_micros': 0,
            'started_at': '2026-11-20T09:00:03.000Z',
            'ended_at': null,
          },
        },
        {
          'id': 'w-2',
          'reason': 'schedule',
          'state': 'skipped',
          'state_reason': 'rule_busy',
          'slot': '2026-11-20T08:40:00.000Z',
          'due_at': '2026-11-20T08:40:00.000Z',
          'created_at': '2026-11-20T08:20:00.000Z',
          'settled_at': '2026-11-20T08:40:01.000Z',
          'run': null,
        },
        {
          'id': 'w-1',
          'reason': 'schedule',
          'state': 'delivered',
          'slot': '2026-11-20T08:20:00.000Z',
          'due_at': '2026-11-20T08:20:00.000Z',
          'created_at': '2026-11-20T08:00:00.000Z',
          'settled_at': '2026-11-20T08:20:01.000Z',
          'run': {
            'id': 'run-1',
            'status': 'completed',
            'end_reason': 'completed',
            'cost_micros': 120000,
            'started_at': '2026-11-20T08:20:01.000Z',
            'ended_at': '2026-11-20T08:24:00.000Z',
          },
        },
        {'id': '', 'reason': 'schedule', 'state': 'delivered'},
      ],
      'next_cursor': '2026-11-20T08:00:00.000Z|w-1',
    };
    final page = await repo.listRuns('ws-1', 'r-1', cursor: 'c-0');
    expect(host.lastCall('wakeRules.listRuns')!.args, {
      'workspace_id': 'ws-1',
      'rule_id': 'r-1',
      'cursor': 'c-0',
    });
    expect([for (final w in page.wakes) w.wakeId], ['w-3', 'w-2', 'w-1']);
    expect(page.nextCursor, '2026-11-20T08:00:00.000Z|w-1');
    final live = page.wakes[0];
    expect(live.eventKind, 'environment');
    expect(live.exitCode, 1);
    expect(live.events, 2);
    expect(live.run!.isLive, isTrue);
    expect(page.wakes[1].run, isNull);
    expect(page.wakes[1].stateReason, 'rule_busy');
    expect(page.wakes[1].slot, DateTime.utc(2026, 11, 20, 8, 40));
    final done = page.wakes[2].run!;
    expect(done.costMicros, 120000);
    expect(done.endReason, 'completed');
    expect(done.endedAt!.isUtc, isTrue);
    await repo.listRuns('ws-1', 'r-1');
    expect(host.lastCall('wakeRules.listRuns')!.args, {
      'workspace_id': 'ws-1',
      'rule_id': 'r-1',
    });
  });

  test("a rule's next fires decode as UTC instants; absent reads as none",
      () async {
    host.snapshotFor('wakeRules.watchForWorkspace', {
      'rules': [
        {
          ...wire(),
          'next_fires': ['2026-11-21T08:00:00.000Z', '2026-11-22T08:00:00.000Z'],
        },
        wire(id: 'r-2'),
      ],
    });
    final rules = await repo.watchForWorkspace('ws-1').first;
    expect(rules.first.nextFires, [
      DateTime.utc(2026, 11, 21, 8),
      DateTime.utc(2026, 11, 22, 8),
    ]);
    expect(rules.last.nextFires, isEmpty);
  });

  test("previewCron sends the draft and decodes the times and the zone's "
      'verdict', () async {
    host.callResults['wakeRules.previewCron'] = {
      'next_fires': ['2026-11-21T08:00:00.000Z'],
      'zone_known': true,
    };
    final preview = await repo.previewCron(
      'ws-1',
      expression: '0 9 * * *',
      timeZone: 'Europe/Berlin',
    );
    expect(host.lastCall('wakeRules.previewCron')!.args, {
      'workspace_id': 'ws-1',
      'expression': '0 9 * * *',
      'time_zone': 'Europe/Berlin',
    });
    expect(preview.nextFires, [DateTime.utc(2026, 11, 21, 8)]);
    expect(preview.zoneKnown, isTrue);
    host.callResults['wakeRules.previewCron'] = {
      'next_fires': <String>[],
      'zone_known': false,
    };
    final zoneOnly = await repo.previewCron(
      'ws-1',
      expression: '',
      timeZone: 'Europe/Berln',
    );
    expect(zoneOnly.nextFires, isEmpty);
    expect(zoneOnly.zoneKnown, isFalse);
  });

  test('a draft gives either when or a clock', () {
    expect(
      () => WakeRuleDraft(conversationId: 'c', agentId: 'a', note: 'n'),
      throwsArgumentError,
    );
    expect(
      () => WakeRuleDraft(
        conversationId: 'c',
        agentId: 'a',
        note: 'n',
        when: 'in:1h',
        hour: 9,
        minute: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => WakeRuleDraft(
        conversationId: 'c',
        agentId: 'a',
        note: 'n',
        hour: 24,
        minute: 0,
      ),
      throwsArgumentError,
    );
  });

  test('limits read and write the workspace setting', () async {
    host.callResults['wakeRules.getLimits'] = {
      'limits': WakeRuleLimits().toJson(),
    };
    host.callResults['wakeRules.setLimits'] = {
      'limits': {...WakeRuleLimits().toJson(), 'per_conversation': 20},
    };
    expect(await repo.limits('ws-1'), WakeRuleLimits());
    final set = await repo.setLimits(
      'ws-1',
      WakeRuleLimits(perConversation: 20),
    );
    expect(set.perConversation, 20);
    expect(
      host.lastCall('wakeRules.setLimits')!.args['limits'],
      WakeRuleLimits(perConversation: 20).toJson(),
    );
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        // Immediately push the scripted snapshot for this query (if any).
        final snapshot = snapshots[query];
        if (snapshot != null) {
          space.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {'op': op, 'data': callResults[op] ?? const {}});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
