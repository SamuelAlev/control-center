import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show JsonRpcRequest, NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_infra/cc_infra.dart'
    show WakeLineageStatus, WakeRuleRequest, WakeRuleService;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/wake_tools.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 19, 12);

WakeRule _rule(
  String id, {
  WakeTrigger? trigger,
  String agentId = 'agent-1',
  String conversationId = 'conv-1',
  DateTime? nextFireAt,
  WakeRuleStatus status = WakeRuleStatus.active,
  WakeRuleEndReason? endReason,
  int? maxRuns,
  WakeRuleOrigin origin = WakeRuleOrigin.agent,
  String? requestedByUserId = 'u-1',
  String? rootRuleId,
}) => WakeRule(
  id: id,
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: conversationId,
  agentId: agentId,
  trigger: trigger ?? Every(const Duration(minutes: 30)),
  note: 'Check the deploy.\nThen the logs.',
  costCapMicros: 50000000,
  expiresAt: _now.add(const Duration(days: 7)),
  nextFireAt: nextFireAt ?? _now.add(const Duration(minutes: 30)),
  maxRuns: maxRuns,
  origin: origin,
  requestedByUserId: requestedByUserId,
  rootRuleId: rootRuleId,
  status: status,
  endReason: endReason,
  createdAt: _now,
  updatedAt: _now,
);

/// The service's surface the tools use; the service itself is tested in
/// cc_infra.
class _Service implements WakeRuleService {
  final requests = <WakeRuleRequest>[];
  final rules = <String, WakeRule>{};
  final ended = <String>[];
  Object? createError;
  WakeRule? loop;
  Duration? delaySet;

  /// The lineage each rule id belongs to.
  final chains = <String, WakeLineageStatus>{};

  @override
  Future<WakeRule> create(WakeRuleRequest request) async {
    requests.add(request);
    final error = createError;
    if (error != null) {
      throw error;
    }
    final rule = _rule(
      'rule-${requests.length}',
      trigger: switch (request.when) {
        'on:pr_checks' => OnEvent(WakeEventKind.prChecks),
        'on:pr_checks:acme/shop-ui#12' => OnEvent(
          WakeEventKind.prChecks,
          targetId: 'acme/shop-ui#12',
        ),
        _ => Every(const Duration(minutes: 30)),
      },
      maxRuns: request.maxRuns,
    );
    rules[rule.id] = rule;
    return rule;
  }

  @override
  DateTime? nextFireOf(WakeRule rule) => rule.isWatch ? null : rule.nextFireAt;

  @override
  Future<WakeLineageStatus?> lineageStatus(WakeRule rule) async =>
      chains[rule.id];

  @override
  Future<WakeRule?> loopOfRun(String workspaceId, List<String> wakeIds) async =>
      wakeIds.contains('wake-loop') ? loop : null;

  @override
  Future<Duration> setNextDelay(
    String workspaceId,
    String id,
    Duration delay,
  ) async => delaySet = delay;

  @override
  Future<List<WakeRule>> openRulesOf(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async => [
    for (final r in rules.values)
      if (r.conversationId == conversationId &&
          r.agentId == agentId &&
          r.status != WakeRuleStatus.ended)
        r,
  ];

  @override
  Future<WakeRule> require(String workspaceId, String id) async =>
      (workspaceId == 'ws-1' ? rules[id] : null) ??
      (throw const NotFoundException('Wake rule not found'));

  @override
  Future<bool> end(
    String workspaceId,
    String id,
    WakeRuleEndReason reason,
  ) async {
    final rule = rules[id];
    if (rule == null || rule.status == WakeRuleStatus.ended) {
      return false;
    }
    ended.add(id);
    rules[id] = rule.copyWith(status: WakeRuleStatus.ended, endReason: reason);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runs implements AgentRunLogRepository {
  final runs = <String, AgentRunLog>{};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      runs[id]?.workspaceId == workspaceId ? runs[id] : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentRunLog _run(String id, {String? requester, List<String>? wakeIds}) =>
    AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      startedAt: _now,
      status: RunStatus.running,
      requestedByUserId: requester,
      wakeIds: wakeIds ?? const [],
    );

class _Wakes implements WakeRepository {
  final rows = <Wake>[];

  @override
  Future<Wake?> getById(String workspaceId, String id) async {
    for (final w in rows) {
      if (w.workspaceId == workspaceId && w.id == id) {
        return w;
      }
    }
    return null;
  }

  @override
  Future<List<Wake>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeState>? states,
  }) async => [
    for (final w in rows)
      if (w.workspaceId == workspaceId &&
          w.conversationId == conversationId &&
          (states == null || states.contains(w.state)))
        w,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Asks implements PeerAskRepository {
  final rows = <PeerAsk>[];
  final calls = <(String?, String?)>[];

  @override
  Future<List<PeerAsk>> listPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) async {
    calls.add((askerAgentId, askerConversationId));
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Wake _wake(
  String id, {
  String agentId = 'agent-1',
  String? ruleId,
  WakeReason? reason,
}) => Wake(
  id: id,
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: agentId,
  reason:
      reason ??
      (ruleId == null ? WakeReason.peerMessage : WakeReason.schedule),
  payload: 'note',
  detail: WakeDetail(ruleId: ruleId),
  dedupKey: id,
  notBefore: _now.add(const Duration(minutes: 5)),
  createdAt: _now,
);

const _args = {
  'workspace_id': 'ws-1',
  'agent_id': 'agent-1',
  'conversation_id': 'conv-1',
};

const _scope = McpCallScope(
  workspaceId: 'ws-1',
  agentId: 'agent-1',
  conversationId: 'conv-1',
  attested: true,
  runLogId: 'run-1',
);

Map<String, dynamic> _decode(CallResult result) =>
    jsonDecode(result.content.single.text) as Map<String, dynamic>;

/// Every key a note names inside braces (`{a, b: [{c}]}` → a, b, c).
Set<String> _noteKeys(String note) => {
  for (final m in RegExp(r'[{,]\s*([a-z_]+)').allMatches(note)) m.group(1)!,
};

Set<String> _keysOf(Object? json) => switch (json) {
  final Map<String, dynamic> map => {
    ...map.keys,
    for (final v in map.values) ..._keysOf(v),
  },
  final List<dynamic> list => {for (final v in list) ..._keysOf(v)},
  _ => const {},
};

void main() {
  late _Service service;
  late _Runs runs;
  late _Wakes wakes;
  late _Asks asks;
  Duration? ttl;
  // Whether the calling run has `repl`; the scopes it was asked about.
  var repl = false;
  final asked = <McpCallScope>[];

  setUp(() {
    repl = false;
    asked.clear();
    service = _Service();
    runs = _Runs()
      ..runs['run-1'] = _run('run-1', requester: 'u-1')
      ..runs['run-loop'] = _run('run-loop', wakeIds: ['wake-loop']);
    wakes = _Wakes();
    asks = _Asks();
    ttl = const Duration(hours: 1);
  });

  WakeMeTool wakeMe() => WakeMeTool(
    service: service,
    runs: runs,
    cacheTtl: (_, _) => ttl,
    hasRepl: (scope) {
      asked.add(scope);
      return repl;
    },
    now: () => _now,
  );

  group('wake_me', () {
    test('declares its identity, script use, description and note', () {
      final tool = wakeMe();
      expect(tool.name, 'wake_me');
      expect(tool.scriptCallable, isTrue);
      expect(tool.forcedScopeKeys, {'agent_id', 'conversation_id'});
      expect(tool.requiredScopeKeys, {'agent_id', 'conversation_id'});
      expect(tool.requiresRunGrant, isTrue);
      expect(
        tool.description,
        'Arrange to be woken later instead of sleeping or polling: at a '
        'time, on an interval, at your own pace, or when something happens '
        "(a pull request's checks, a review, a merge, an environment, a "
        'ticket, a pipeline run).',
      );
      expect(
        tool.resultNote,
        'JSON {rule_id, when, fires_at, expires_at, max_runs, cancel, '
        'cache_warm, reference, watching, chain}: fires_at is null for a '
        'watch; cache_warm is present when the prompt cache lifetime is '
        'known; reference is on the first result of a run; a cron also gives '
        'its tz; watching (a pull request watch) says which pull request it '
        'hears; chain (a wake set in a run another wake started) is {root, '
        "runs_left, ends_at}: the chain shares its first wake's end and "
        'runs. With when "next": {rule_id, next_delay_seconds, cancel}.',
      );
    });

    test('the reference starts with the section 17 text, verbatim', () {
      expect(
        wakeMeReference,
        startsWith(
          'Arrange to be woken in this conversation later, then end your '
          'turn. Use it in place of sleeping, polling or re-running a '
          'command to see whether something changed. `when`: `in:20m`, '
          '`at:<ISO time>`, `every:30m`, `cron:0 9 * * 1-5`, `next` (in a '
          'loop: you choose the delay each time), or an event: '
          '`on:pr_checks`, `on:pr_review`, `on:pr_merged`, '
          '`on:environment`, `on:ticket:<id>`, `on:pipeline_run:<id>`. '
          'Prefer an event to a timer when one fits. `note`: what your '
          'future self needs: what you were waiting for, what to check '
          'first, what to do next. It comes back to you as your own note. A '
          'repeating wake needs `max_runs` or `expires_in`, and ends after 7 '
          'days unless a person extends it. The result says when it fires '
          'and whether the prompt cache will still be warm then. A wake '
          'inside the cache window is cheap; one after it re-reads the '
          'conversation. You are woken without asking when an agent you '
          'asked or delegated to finishes.',
        ),
      );
      expect(wakeMeReference, contains('Grammar: '));
      expect(wakeMeReference, contains('Busy: '));
    });

    test('creates the rule for the run and returns every key its note '
        'names; the reference comes once per run', () async {
      final tool = wakeMe();
      final first = await tool.callForRun({
        ..._args,
        'when': 'every:30m',
        'note': 'Check the deploy.',
        'max_runs': 5,
        'expires_in': '2d',
        'when_busy': 'queue',
      }, _scope);
      expect(first.isError, isFalse);
      final body = _decode(first);
      // A watch and a chain add their keys (the tests below).
      expect(
        _noteKeys(tool.resultNote.substring(0, tool.resultNote.indexOf('With')))
            .difference(_keysOf(body))
            .difference({'watching', 'chain', 'root', 'runs_left', 'ends_at'}),
        isEmpty,
      );
      expect(body.containsKey('chain'), isFalse);
      expect(body.containsKey('watching'), isFalse);
      expect(body['rule_id'], 'rule-1');
      expect(body['when'], 'every:30m');
      expect(body['fires_at'], '2026-11-19T12:30:00.000Z');
      expect(body['max_runs'], 5);
      expect(body['cancel'], 'cancel_wake(id: "rule-1")');
      expect(asked.single, _scope);
      expect(body['cache_warm'], isTrue);
      expect(body['reference'], wakeMeReference);
      final request = service.requests.single;
      expect(request.origin, WakeRuleOrigin.agent);
      expect(request.createdByRunId, 'run-1');
      expect(request.requestedByUserId, 'u-1');
      expect(request.expiresIn, const Duration(days: 2));
      expect(request.whenBusy, WakeWhenBusy.queue);
      expect(request.deliver, WakeDeliver.run);

      ttl = const Duration(minutes: 5);
      final second = _decode(
        await tool.callForRun({
          ..._args,
          'when': 'every:30m',
          'note': 'Again.',
          'max_runs': 2,
        }, _scope),
      );
      expect(second.containsKey('reference'), isFalse);
      expect(second['cache_warm'], isFalse);
    });

    test('a watch has no fire time; an unknown cache lifetime says '
        'nothing', () async {
      ttl = null;
      final body = _decode(
        await wakeMe().callForRun({
          ..._args,
          'when': 'on:pr_checks',
          'note': 'CI.',
        }, _scope),
      );
      expect(body['fires_at'], isNull);
      expect(body.containsKey('cache_warm'), isFalse);
      expect(body['when'], 'on:pr_checks');
      // Nothing to watch yet is allowed, and the result says so.
      expect(
        body['watching'],
        "this space's pull request: one opened from its branch, or one it "
        'reviews. If none is open yet, the watch waits for one.',
      );
      final named = _decode(
        await wakeMe().callForRun({
          ..._args,
          'when': 'on:pr_checks:acme/shop-ui#12',
          'note': 'CI.',
        }, _scope),
      );
      expect(named['watching'], 'pull request acme/shop-ui#12 only.');
    });

    test('a wake set in a run another wake started shows its chain', () async {
      service.chains['rule-1'] = (
        rootRuleId: 'r-root',
        runsLeft: 7,
        endsAt: DateTime.utc(2026, 11, 26, 12),
      );
      final body = _decode(
        await wakeMe().callForRun({
          ..._args,
          'when': 'in:20m',
          'note': 'again',
        }, _scope),
      );
      expect(body['chain'], {
        'root': 'r-root',
        'runs_left': 7,
        'ends_at': '2026-11-26T12:00:00.000Z',
      });
    });

    test('a refusal carries its kind and the reference', () async {
      service.createError = const ValidationException(
        'every: must be 60 s or more apart.',
        code: WakeRuleRefusals.intervalTooShort,
      );
      final result = await wakeMe().callForRun({
        ..._args,
        'when': 'every:10s',
        'note': 'x',
      }, _scope);
      expect(result.isError, isTrue);
      expect(result.structured, {'kind': 'wake_interval_too_short'});
      expect(result.content.single.text, contains(wakeMeReference));
      final bad = await wakeMe().callForRun({
        ..._args,
        'when': 'every:30m',
        'note': 'x',
        'expires_in': 'soon',
      }, _scope);
      expect(bad.structured, {'kind': WakeRuleRefusals.invalidWhen});
    });

    test('"next" sets the delay of the loop that started this run, and '
        'is refused anywhere else', () async {
      service.loop = _rule('loop-1', trigger: const SelfPaced());
      const loopScope = McpCallScope(
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        attested: true,
        runLogId: 'run-loop',
      );
      final tool = wakeMe();
      final ok = await tool.callForRun({
        ..._args,
        'when': 'next',
        'delay': '20m',
      }, loopScope);
      expect(_decode(ok), {
        'rule_id': 'loop-1',
        'next_delay_seconds': 1200,
        'cancel': 'cancel_wake(id: "loop-1")',
      });
      expect(service.delaySet, const Duration(minutes: 20));
      final outside = await tool.callForRun({
        ..._args,
        'when': 'next',
        'delay': '20m',
      }, _scope);
      expect(outside.structured, {'kind': WakeRuleRefusals.nextOutsideLoop});
      expect(service.requests, isEmpty);
    });

    test('a model-supplied identity is overwritten by the run scope', () async {
      final dispatcher = McpToolDispatcher(
        registry: McpToolRegistry([wakeMe()]),
      );
      await dispatcher.handleScopedRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: {
            'name': 'wake_me',
            'arguments': {
              'workspace_id': 'ws-1',
              'agent_id': 'agent-other',
              'conversation_id': 'conv-other',
              'when': 'in:20m',
              'note': 'x',
            },
          },
          id: 1,
        ),
        scope: _scope,
      );
      final request = service.requests.single;
      expect(request.agentId, 'agent-1');
      expect(request.conversationId, 'conv-1');
      expect(request.createdByRunId, 'run-1');
    });
  });

  group('list_wakes', () {
    test('lists own rules, pending wakes and asks as rows; filters by '
        'type; names every key its note names', () async {
      service.rules['r-1'] = _rule('r-1', maxRuns: 4, rootRuleId: 'r-root');
      service.chains['r-1'] = (
        rootRuleId: 'r-root',
        runsLeft: 3,
        endsAt: DateTime.utc(2026, 11, 26, 12),
      );
      service.rules['r-other'] = _rule('r-other', agentId: 'agent-2');
      wakes.rows
        ..add(_wake('w-1'))
        ..add(_wake('w-2', agentId: 'agent-2'));
      asks.rows.add(
        PeerAsk(
          id: 'ask-1',
          workspaceId: 'ws-1',
          kind: PeerAskKind.ask,
          mode: PeerAskMode.background,
          askerAgentId: 'agent-1',
          askerConversationId: 'conv-1',
          askerSpaceId: 'sp-1',
          recipientAgentId: 'agent-3',
          questionHash: 'h',
          status: PeerAskStatus.pending,
          createdAt: _now,
          expiresAt: _now.add(const Duration(days: 1)),
        ),
      );
      final tool = ListWakesTool(
        service: service,
        wakes: wakes,
        asks: asks,
        runs: runs,
      );
      expect(tool.name, 'list_wakes');
      expect(tool.scriptCallable, isTrue);
      expect(
        tool.resultNote,
        'JSON {rows: [{type, id, when, fires_at, status, runs, max_runs, '
        'expires_at, what, can_cancel, chain}]}: type is "rule", "wake" or '
        '"ask"; can_cancel is true for what you made yourself; chain is '
        '{root, runs_left, ends_at} for a rule in a chain of wakes (null for '
        'others); pass type to list one kind.',
      );
      final body = _decode(await tool.callForRun(_args, _scope));
      expect(_noteKeys(tool.resultNote).difference(_keysOf(body)), isEmpty);
      final rows = (body['rows'] as List).cast<Map<String, dynamic>>();
      expect(
        [for (final r in rows) '${r['type']}:${r['id']}'],
        ['rule:r-1', 'wake:w-1', 'ask:ask-1'],
      );
      expect(rows.first['what'], 'Check the deploy.');
      expect(rows.first['max_runs'], 4);
      expect(rows.first['expires_at'], '2026-11-26T12:00:00.000Z');
      expect([for (final r in rows) r['can_cancel']], [true, false, false]);
      expect(rows.first['chain'], {
        'root': 'r-root',
        'runs_left': 3,
        'ends_at': '2026-11-26T12:00:00.000Z',
      });
      expect(asks.calls.single, ('agent-1', 'conv-1'));
      final only = _decode(
        await tool.callForRun({..._args, 'type': 'wake'}, _scope),
      );
      expect(((only['rows'] as List).single as Map)['id'], 'w-1');
    });
  });

  test('a run with repl is told to cancel from a script: cancel_wake is in '
      'no mode\'s direct set', () async {
    for (final mode in Mode.values) {
      expect(
        {
          ...ModeToolPolicy.directNamesFor(mode),
          ...profileFor(mode).pinnedVerbs,
        },
        isNot(contains('cancel_wake')),
        reason: '$mode',
      );
    }
    repl = true;
    final body = _decode(
      await wakeMe().callForRun({..._args, 'when': 'in:30m'}, _scope),
    );
    expect(body['cancel'], 'await tools.cancel_wake({id: "rule-1"})');
  });

  group('cancel_wake', () {
    test('ends an own rule; again is a success that says it ended', () async {
      service.rules['r-1'] = _rule('r-1');
      final tool = CancelWakeTool(service: service, wakes: wakes, runs: runs);
      expect(tool.name, 'cancel_wake');
      expect(tool.scriptCallable, isTrue);
      expect(tool.requiresRunGrant, isTrue);
      expect(
        tool.resultNote,
        'JSON {id, type, cancelled, status}: cancelled is false when it had '
        'already settled; status then says how.',
      );
      final first = _decode(
        await tool.callForRun({..._args, 'id': 'r-1'}, _scope),
      );
      expect(_noteKeys(tool.resultNote).difference(_keysOf(first)), isEmpty);
      expect(first, {
        'id': 'r-1',
        'type': 'rule',
        'cancelled': true,
        'status': 'cancelled',
      });
      final again = _decode(
        await tool.callForRun({..._args, 'id': 'r-1'}, _scope),
      );
      expect(again['cancelled'], isFalse);
      expect(again['status'], 'ended (cancelled)');
      expect(service.ended, ['r-1']);
    });

    test("a rule's pending wake id cancels its rule; a wake no rule of its "
        'own wrote is not found', () async {
      service.rules['r-1'] = _rule('r-1');
      wakes.rows
        ..add(_wake('w-rule', ruleId: 'r-1'))
        ..add(_wake('w-peer'))
        ..add(_wake('w-recovery', reason: WakeReason.recovery))
        ..add(_wake('w-goal', reason: WakeReason.goalContinuation))
        ..add(_wake('w-limit', reason: WakeReason.limitReset));
      final tool = CancelWakeTool(service: service, wakes: wakes, runs: runs);
      final viaWake = _decode(
        await tool.callForRun({..._args, 'id': 'w-rule'}, _scope),
      );
      expect(viaWake['id'], 'r-1');
      expect(viaWake['type'], 'rule');
      for (final id in ['w-peer', 'w-recovery', 'w-goal', 'w-limit']) {
        final result = await tool.callForRun({..._args, 'id': id}, _scope);
        expect(result.structured, {'kind': 'wake_not_found'}, reason: id);
      }
      expect(service.ended, ['r-1']);
    });

    test("a person's rule, and a rule made for another person or by a bot "
        'run, are not found', () async {
      service.rules['r-person'] = _rule(
        'r-person',
        origin: WakeRuleOrigin.person,
      );
      service.rules['r-u2'] = _rule('r-u2', requestedByUserId: 'u-2');
      service.rules['r-bot'] = _rule('r-bot', requestedByUserId: null);
      wakes.rows.add(_wake('w-person', ruleId: 'r-person'));
      final tool = CancelWakeTool(service: service, wakes: wakes, runs: runs);
      for (final id in ['r-person', 'w-person', 'r-u2', 'r-bot']) {
        final result = await tool.callForRun({..._args, 'id': id}, _scope);
        expect(result.structured, {'kind': 'wake_not_found'}, reason: id);
      }
      // The bot's own run may cancel the bot's rule.
      final bot = _decode(
        await tool.callForRun(
          {..._args, 'id': 'r-bot'},
          const McpCallScope(
            workspaceId: 'ws-1',
            agentId: 'agent-1',
            conversationId: 'conv-1',
            attested: true,
            runLogId: 'run-loop',
          ),
        ),
      );
      expect(bot['cancelled'], isTrue);
      expect(service.ended, ['r-bot']);
    });

    test(
      "another agent's rule or wake, and an unknown id, are not found",
      () async {
        service.rules['r-other'] = _rule('r-other', agentId: 'agent-2');
        service.rules['r-conv'] = _rule('r-conv', conversationId: 'conv-2');
        wakes.rows.add(_wake('w-other', agentId: 'agent-2'));
        final tool = CancelWakeTool(
          service: service,
          wakes: wakes,
          runs: runs,
        );
        for (final id in ['r-other', 'r-conv', 'w-other', 'nope']) {
          final result = await tool.callForRun({..._args, 'id': id}, _scope);
          expect(result.isError, isTrue, reason: id);
          expect(result.structured, {'kind': 'wake_not_found'}, reason: id);
        }
        expect(service.ended, isEmpty);
      },
    );
  });
}
