import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 11, 19, 12);

/// The rule service surface the command handler uses; the service itself is
/// tested in `test/dispatch/wake_rule_service_test.dart`.
class _Service implements WakeRuleService {
  final requests = <WakeRuleRequest>[];
  Object? error;

  @override
  Future<WakeRule> create(WakeRuleRequest request) async {
    requests.add(request);
    final e = error;
    if (e != null) {
      throw e;
    }
    return WakeRule(
      id: 'rule-1',
      workspaceId: request.workspaceId,
      spaceId: 'sp-1',
      conversationId: request.conversationId,
      agentId: request.agentId,
      trigger: switch (request.when) {
        'next' => const SelfPaced(),
        final String w when w.startsWith('in:') => OnceAt(
          _t0.add(const Duration(hours: 2)),
        ),
        _ => Every(const Duration(minutes: 30)),
      },
      note: request.note,
      costCapMicros: request.costCapMicros ?? 50000000,
      maxRuns: request.maxRuns,
      expiresAt: _t0.add(const Duration(days: 30)),
      nextFireAt: _t0,
      origin: request.origin,
      requestedByUserId: request.requestedByUserId,
      createdAt: _t0,
      updatedAt: _t0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Service service;
  late List<
    ({String conversationId, String content, Map<String, Object?> meta})
  >
  rows;
  late PersonGoalCommand handler;
  late List<String> goals;

  setUp(() {
    service = _Service();
    rows = [];
    goals = [];
    handler = personCommands(
      goals:
          ({
            required String workspaceId,
            required String spaceId,
            required String agentId,
            required String prompt,
            required String requestedByUserId,
            String? conversationId,
          }) async {
            goals.add(prompt);
            return 'run-goal';
          },
      refine:
          ({
            required String workspaceId,
            required String spaceId,
            required String agentId,
            required String prompt,
            required String requestedByUserId,
            String? conversationId,
          }) async {
            goals.add('refine: $prompt');
            return null;
          },
      wakeRules: wakeRuleCommands(
        service: () => service,
        standingConversation: (ws, space) async => 'conv-standing',
        conversationSpace: (ws, conv) async =>
            conv == 'conv-other' ? 'sp-other' : 'sp-1',
        postRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async => rows.add((
              conversationId: conversationId,
              content: content,
              meta: metadata,
            )),
      ),
    );
  });

  Future<String?> run(String prompt, {String? conversationId = 'conv-1'}) =>
      handler(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        agentId: 'agent-1',
        prompt: prompt,
        requestedByUserId: 'user-1',
        conversationId: conversationId,
      );

  test('only /goal, /refine, /loop and /schedule are person commands', () {
    expect(isPersonCommand('/goal ship it'), isTrue);
    expect(isPersonCommand('/refine'), isTrue);
    expect(isPersonCommand('/loop check the deploy'), isTrue);
    expect(isPersonCommand('/schedule in 2h look again'), isTrue);
    expect(isPersonCommand('please /loop this'), isFalse);
    expect(isPersonCommand('/looper x'), isFalse);
  });

  test('/goal still reaches the goal handler', () async {
    expect(await run('/goal ship it'), 'run-goal');
    expect(goals, ['/goal ship it']);
    expect(service.requests, isEmpty);
  });

  test('/loop makes a person rule that fires now and posts one row', () async {
    expect(await run('/loop every 30m --max 5 check the deploy'), isNull);
    final request = service.requests.single;
    expect(request.when, 'every:30m');
    expect(request.note, 'check the deploy');
    expect(request.maxRuns, 5);
    expect(request.origin, WakeRuleOrigin.person);
    expect(request.requestedByUserId, 'user-1');
    expect(request.createdByUserId, 'user-1');
    expect(request.fireNow, isTrue);
    final row = rows.single;
    expect(row.conversationId, 'conv-1');
    expect(row.meta['kind'], wakeRuleCreatedRowKind);
    expect(row.meta['ruleId'], 'rule-1');
    expect(
      row.content,
      'Loop set, every:30m · next run 2026-11-19 12:00 UTC · at most 5 '
      'runs · ends 2026-12-19 12:00 UTC · budget 50.00 USD: "check the '
      'deploy"',
    );
  });

  test('/schedule waits for its time; no conversation means the '
      "space's standing one", () async {
    await run('/schedule in 2h look at the logs', conversationId: null);
    final request = service.requests.single;
    expect(request.when, startsWith('in:'));
    expect(request.fireNow, isFalse);
    expect(request.conversationId, 'conv-standing');
    expect(rows.single.content, startsWith('Scheduled, '));
  });

  test('an unreadable command and a refused rule are refusals with their '
      'kind, and post nothing', () async {
    await expectLater(
      run('/schedule whenever'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          WakeRuleRefusals.invalidWhen,
        ),
      ),
    );
    service.error = const ValidationException(
      'This conversation has 10 open wake rules.',
      code: WakeRuleRefusals.limitReached,
    );
    await expectLater(
      run('/loop every 30m x'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          WakeRuleRefusals.limitReached,
        ),
      ),
    );
    expect(rows, isEmpty);
  });

  test('a conversation of another space is refused before the rule', () async {
    await expectLater(
      run('/loop every 30m x', conversationId: 'conv-other'),
      throwsA(isA<ValidationException>()),
    );
    expect(service.requests, isEmpty);
    expect(rows, isEmpty);
  });
}
