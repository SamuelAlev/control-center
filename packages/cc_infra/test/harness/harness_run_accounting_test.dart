import 'dart:async';

import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/llm_call_record_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/harness/harness_run_accounting.dart';
import 'package:test/test.dart';

class _Provider implements LlmProviderPort {
  _Provider(this.replies);
  final List<List<LlmEvent>> replies;
  @override
  String get displayName => 'scripted';
  @override
  String get defaultModel => 'model';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) => Stream.fromIterable(replies.removeAt(0));
}

class _Calls extends LlmCallRecordRepository {
  final rows = <LlmCallRecord>[];
  Completer<void>? gate;
  @override
  Future<void> upsert(String workspaceId, LlmCallRecord record) async {
    await gate?.future;
    rows.add(record);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runs implements AgentRunLogRepository {
  final own = <String, RunCost>{};
  final children = <String, int>{};
  @override
  Future<void> updateCost(
    String workspaceId,
    String runId,
    RunCost cost,
  ) async {
    own[runId] = cost;
  }

  @override
  Future<void> addChildCostMicros(
    String workspaceId,
    String runId,
    int delta,
  ) async {
    children.update(runId, (value) => value + delta, ifAbsent: () => delta);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<LlmEvent> _success(int input) => [
  LlmUsage(inputTokens: input),
  LlmDone(
    stopReason: LlmStopReason.endTurn,
    usage: LlmUsage(inputTokens: input),
  ),
];

void main() {
  final epoch = DateTime.utc(2026);
  HarnessRunAccounting accounting(
    String id, {
    HarnessRunAccounting? parent,
    _Runs? runs,
    _Calls? calls,
    ModelCost? Function(String, String)? price,
  }) => HarnessRunAccounting(
    runId: id,
    workspaceId: 'workspace',
    runStartedAt: epoch,
    parent: parent,
    repository: calls,
    runLogRepository: runs,
    priceLookup: price ?? (_, _) => const ModelCost(input: 1),
  );

  Future<void> request(
    LlmProviderPort provider,
    LlmCallPurpose purpose, {
    String? callId,
  }) async {
    await provider
        .complete(
          messages: [HarnessMessage.user('work')],
          config: LlmCompleteConfig(purpose: purpose, callId: callId),
        )
        .drain<void>();
  }

  test(
    'auxiliary and failed retry usage is priced once below cent precision',
    () async {
      final calls = _Calls();
      final runs = _Runs();
      final owner = accounting('root', calls: calls, runs: runs);
      final provider = owner.observe(
        _Provider([
          _success(901),
          [
            const LlmUsage(inputTokens: 3),
            const LlmError('retry', retryable: true),
          ],
          _success(17),
        ]),
        providerId: 'provider',
      );
      await request(provider, LlmCallPurpose.compaction);
      await request(provider, LlmCallPurpose.main, callId: 'turn');
      await request(provider, LlmCallPurpose.main, callId: 'turn');
      final records = owner.ledger.records.toList();
      owner.onProviderCall(records.last);
      await owner.flush();
      expect(records.map((r) => r.attempt), [1, 1, 2]);
      expect(records.map((r) => r.outcome), [
        ProviderCallOutcome.success,
        ProviderCallOutcome.failure,
        ProviderCallOutcome.success,
      ]);
      expect(owner.cost().inputTokens, 921);
      expect(owner.cost().costMicros, 921);
      expect(owner.subtreeCostMicros, 921);
      expect(calls.rows.map((r) => r.costMicros), [901, 3, 17]);
      expect(runs.own['root']!.costMicros, 921);
    },
  );

  test(
    'fallback targets rebind to children without charging parent own usage',
    () async {
      final runs = _Runs();
      final root = accounting('root', runs: runs);
      final child = accounting('child', parent: root, runs: runs);
      final grandchild = accounting('grandchild', parent: child);
      final chain = root.observe(
        FallbackProvider([
          FallbackEntry(
            providerId: 'first',
            model: 'model',
            build: () => _Provider([
              [
                const LlmUsage(inputTokens: 2),
                const LlmError('quota', code: 'insufficient_quota'),
              ],
            ]),
          ),
          FallbackEntry(
            providerId: 'second',
            model: 'model',
            build: () => _Provider([_success(7), _success(11)]),
          ),
        ]),
        providerId: 'first',
      );
      final childProvider = child.observe(chain, providerId: 'first');
      await request(childProvider, LlmCallPurpose.subagent);
      final nested = grandchild.observe(childProvider, providerId: 'second');
      await request(nested, LlmCallPurpose.subagent);
      await grandchild.flush();
      await child.flush();
      await root.flush();
      expect(root.cost().inputTokens, 0);
      expect(child.cost().inputTokens, 9);
      expect(grandchild.cost().inputTokens, 11);
      expect(root.subtreeCostMicros, 20);
      expect(child.subtreeCostMicros, 20);
      expect(runs.children, {'root': 20, 'child': 11});
      expect(child.ledger.records.map((r) => r.providerId), [
        'first',
        'second',
      ]);
      expect(root.ledger.records, isEmpty);
    },
  );

  test('missing usage and unknown model price remain unpriced', () async {
    final owner = accounting(
      'root',
      price: (_, model) => model == 'known' ? const ModelCost(input: 1) : null,
    );
    final missingUsage = owner.observe(
      _Provider([
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]),
      providerId: 'p',
    );
    await missingUsage
        .complete(
          messages: const [],
          config: const LlmCompleteConfig(model: 'known'),
        )
        .drain<void>();
    await request(
      owner.observe(_Provider([_success(4)]), providerId: 'p'),
      LlmCallPurpose.advisor,
    );
    expect(owner.ledger.records.map((r) => r.costMicros), [null, null]);
    expect(owner.unpricedCalls, 2);
    expect(owner.cost().inputTokens, 4);
  });

  test(
    'an unknown zero-rate catalog entry never prices a call as free',
    () async {
      final owner = accounting('root', price: (_, _) => const ModelCost());
      await request(
        owner.observe(_Provider([_success(4)]), providerId: 'p'),
        LlmCallPurpose.main,
      );
      expect(owner.ledger.records.single.costMicros, isNull);
      expect(owner.unpricedCalls, 1);
      expect(owner.cost().costBasis, CostBasis.unknown);
    },
  );

  test('flush waits for queued records and cost persistence', () async {
    final calls = _Calls()..gate = Completer<void>();
    final runs = _Runs();
    final owner = accounting('root', calls: calls, runs: runs);
    await request(
      owner.observe(_Provider([_success(5)]), providerId: 'p'),
      LlmCallPurpose.sideRequest,
    );
    var flushed = false;
    final pending = owner.flush().then((_) => flushed = true);
    await Future<void>.delayed(Duration.zero);
    expect(flushed, isFalse);
    expect(runs.own, isEmpty);
    calls.gate!.complete();
    await pending;
    expect(calls.rows.single.costMicros, 5);
    expect(runs.own['root']!.costMicros, 5);
  });

  test('accounting lineage refuses a different workspace', () {
    final parent = accounting('root');
    expect(
      () => HarnessRunAccounting(
        runId: 'child',
        workspaceId: 'foreign',
        runStartedAt: epoch,
        parent: parent,
        priceLookup: (_, _) => null,
      ),
      throwsA(isA<WorkspaceMismatchException>()),
    );
  });
}
