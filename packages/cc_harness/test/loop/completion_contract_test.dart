import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// The regression suite for the plan-mode silent-success bug: a run that
/// researched for many turns, announced its plan in prose, then stopped without
/// ever calling `submit_plan` — and was reported as `completed`.
void main() {
  const runner = AgentLoopRunner();

  const planContract = CompletionContract(
    id: 'plan.submitted',
    requiredToolNames: {'submit_plan'},
    nudge: 'You have not called `submit_plan`. Call it now.',
    unmetSummary: 'Ended without submitting a plan.',
  );

  test('unmet contract nudges exactly once, then ends contractUnmet', () async {
    // Turn 1 researches, turn 2 narrates "let me write the plan now" and stops.
    // After the nudge the model stops again without delivering.
    final provider = _Scripted([
      [_toolCall('read'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('Now let me write the plan.'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'plan the thing',
          tools: [_ReadTool('read'), _SubmitPlanTool()],
          provider: provider,
          config: const AgentLoopConfig(contract: planContract),
        )
        .toList();

    final notices = events
        .whereType<LoopNotice>()
        .where((n) => n.message.contains('plan.submitted'))
        .toList();
    expect(notices, hasLength(1), reason: 'exactly one nudge, never a loop');

    final done = events.whereType<LoopDone>().single;
    expect(done.reason, LoopDoneReason.contractUnmet);
    expect(done.unmetContractId, 'plan.submitted');
  });

  test(
    'a successful required call satisfies the contract with no nudge',
    () async {
      final provider = _Scripted([
        [
          _toolCall('submit_plan'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('Submitted.'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'plan the thing',
            tools: [_ReadTool('read'), _SubmitPlanTool()],
            provider: provider,
            config: const AgentLoopConfig(contract: planContract),
          )
          .toList();

      expect(
        events.whereType<LoopNotice>().where(
          (n) => n.message.contains('plan.submitted'),
        ),
        isEmpty,
      );
      final done = events.whereType<LoopDone>().single;
      expect(done.reason, LoopDoneReason.completed);
      expect(done.unmetContractId, isNull);
    },
  );

  test('a required call that errors does NOT satisfy the contract', () async {
    // The real failure path: `submit_plan` returns graph-validation violations,
    // the model gives up instead of fixing them. Nothing was delivered.
    final provider = _Scripted([
      [
        _toolCall('submit_plan'),
        const LlmDone(stopReason: LlmStopReason.toolUse),
      ],
      [
        const LlmTextDelta('That did not work; giving up.'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'plan the thing',
          tools: [_SubmitPlanTool(fails: true)],
          provider: provider,
          config: const AgentLoopConfig(contract: planContract),
        )
        .toList();

    expect(
      events.whereType<LoopNotice>().where(
        (n) => n.message.contains('plan.submitted'),
      ),
      hasLength(1),
    );
    expect(
      events.whereType<LoopDone>().single.reason,
      LoopDoneReason.contractUnmet,
    );
  });

  test('a queued follow-up is consumed BEFORE the contract nudge', () async {
    // Real user steering outranks the reminder.
    final steering = SteeringQueue()..pushFollowUp('also check the tests');
    final provider = _Scripted([
      [
        const LlmTextDelta('done thinking'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'plan the thing',
          tools: [_SubmitPlanTool()],
          provider: provider,
          config: AgentLoopConfig(
            contract: planContract,
            steering: steering,
            maxTurns: 4,
          ),
        )
        .toList();

    final order = events
        .whereType<LoopNotice>()
        .map((n) => n.message)
        .where((m) => m.contains('Follow-up') || m.contains('plan.submitted'))
        .toList();
    expect(order.first, contains('Follow-up'));
    expect(order.any((m) => m.contains('plan.submitted')), isTrue);
  });

  test('a probe can satisfy the contract without an observed call', () async {
    final provider = _Scripted([
      [
        const LlmTextDelta('the plan already exists'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'plan the thing',
          tools: [_SubmitPlanTool()],
          provider: provider,
          config: AgentLoopConfig(
            contract: CompletionContract(
              id: 'plan.submitted',
              requiredToolNames: const {'submit_plan'},
              nudge: 'nudge',
              unmetSummary: 'unmet',
              probe: () async => true,
            ),
          ),
        )
        .toList();
    expect(
      events.whereType<LoopDone>().single.reason,
      LoopDoneReason.completed,
    );
  });

  test(
    'a throwing probe is treated as unsatisfied, never as an error',
    () async {
      final provider = _Scripted([
        [
          const LlmTextDelta('stopping'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'plan the thing',
            tools: [_SubmitPlanTool()],
            provider: provider,
            config: AgentLoopConfig(
              contract: CompletionContract(
                id: 'plan.submitted',
                requiredToolNames: const {},
                nudge: 'nudge',
                unmetSummary: 'unmet',
                probe: () async => throw StateError('boom'),
              ),
              maxTurns: 3,
            ),
          )
          .toList();
      expect(events.whereType<LoopError>(), isEmpty);
      expect(
        events.whereType<LoopDone>().single.reason,
        LoopDoneReason.contractUnmet,
      );
    },
  );

  test('maxTurns keeps its reason but reports the unmet contract', () async {
    final provider = _Scripted([
      [_toolCall('read'), const LlmDone(stopReason: LlmStopReason.toolUse)],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'plan the thing',
          tools: [_ReadTool('read'), _SubmitPlanTool()],
          provider: provider,
          config: const AgentLoopConfig(contract: planContract, maxTurns: 2),
        )
        .toList();
    final done = events.whereType<LoopDone>().single;
    expect(done.reason, LoopDoneReason.maxTurns);
    expect(done.unmetContractId, 'plan.submitted');
  });

  test(
    'no contract → the event stream is unchanged (replay compatibility)',
    () async {
      // Recorded sessions predate contracts. With `contract: null` the loop must
      // emit exactly what it always did, or every stored cassette breaks.
      List<LlmEvent> textTurn() => const [
        LlmTextDelta('answer'),
        LlmDone(stopReason: LlmStopReason.endTurn),
      ];
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: const [],
            provider: _Scripted([textTurn()]),
            config: const AgentLoopConfig(),
          )
          .toList();
      expect(events.whereType<LoopNotice>(), isEmpty);
      final done = events.whereType<LoopDone>().single;
      expect(done.reason, LoopDoneReason.completed);
      expect(done.unmetContractId, isNull);
    },
  );

  group('ContractLedger', () {
    test('is inert without a contract', () {
      final ledger = ContractLedger(null);
      expect(ledger.isActive, isFalse);
      expect(ledger.satisfied, isFalse);
      ledger.recordToolResult('submit_plan', isError: false);
      expect(ledger.satisfied, isFalse);
    });

    test('an empty verb set with no probe is inactive', () {
      const contract = CompletionContract(
        id: 'x',
        requiredToolNames: {},
        nudge: 'n',
        unmetSummary: 'u',
      );
      expect(contract.isActive, isFalse);
      expect(ContractLedger(contract).isActive, isFalse);
    });

    test('nudges are bounded by maxNudges', () {
      final ledger = ContractLedger(planContract);
      expect(ledger.canNudge, isTrue);
      ledger.takeNudge();
      expect(ledger.canNudge, isFalse);
      expect(ledger.nudgesIssued, 1);
    });

    test('an unrelated tool never satisfies the contract', () {
      final ledger = ContractLedger(planContract)
        ..recordToolResult('read', isError: false);
      expect(ledger.satisfied, isFalse);
    });
  });

  group('ToolGateDecision', () {
    test('a reasonless denial renders the legacy message', () {
      expect(const ToolGateDecision.deny().deniedMessage, 'Denied by user.');
    });

    test('a reasoned denial carries reason and remediation', () {
      const d = ToolGateDecision.deny(
        reason: 'orchestrate mode denies vendorSyncWrite',
        remediation: 'Call `propose_orchestration`.',
      );
      expect(d.deniedMessage, contains('orchestrate mode denies'));
      expect(d.deniedMessage, contains('propose_orchestration'));
    });

    test('allow carries no reason', () {
      expect(const ToolGateDecision.allow().allowed, isTrue);
    });
  });
}

LlmToolUseDelta _toolCall(String name) =>
    LlmToolUseDelta(id: 'call-$name', name: name, argumentsJson: '{}');

/// Replays one scripted list of events per `complete()` call; repeats the last.
class _Scripted implements LlmProviderPort {
  _Scripted(this.script);
  final List<List<LlmEvent>> script;
  int calls = 0;

  @override
  String get displayName => 'Scripted';
  @override
  String get defaultModel => 'mock';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final i = calls < script.length ? calls : script.length - 1;
    calls++;
    yield* Stream.fromIterable(script[i]);
  }
}

class _ReadTool extends HarnessTool {
  _ReadTool(this._name);
  final String _name;

  @override
  String get name => _name;
  @override
  String get description => 'reads';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('$_name ok');
}

/// Stands in for the bridged `submit_plan` MCP tool: read-tier (so it survives
/// the read-only tool filter) and effect-free (so no guard gates it).
class _SubmitPlanTool extends HarnessTool {
  _SubmitPlanTool({this.fails = false});

  /// When true, returns graph violations instead of accepting the plan.
  final bool fails;

  @override
  String get name => 'submit_plan';
  @override
  String get description => 'submits a typed plan';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => fails
      ? HarnessToolResult.error('Plan violations: node "b" depends on "z".')
      : HarnessToolResult.success('{"plan_id":"p1","revision":1}');
}
