import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_infra/src/evaluation/provider_call_budget_guard.dart';
import 'package:test/test.dart';

class _Provider implements LlmProviderPort {
  int calls = 0;

  @override
  String get defaultModel => 'gpt-5.6-terra';

  @override
  String get displayName => 'No-network fixture';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    calls++;
    yield const LlmUsage(inputTokens: 1000, outputTokens: 100);
    yield const LlmDone();
  }
}

void main() {
  const messages = <HarnessMessage>[];

  test(
    'subscription threshold allows first call to overshoot, blocks second',
    () async {
      final delegate = _Provider();
      var spentMicros = 0;
      final guarded = ProviderCallBudgetGuard(
        delegate,
        canBegin: () => spentMicros < 1000000,
      );
      expect(await guarded.complete(messages: messages).toList(), hasLength(2));
      spentMicros = 1500000; // Accounted first physical call overshot USD 1.
      final denied = await guarded.complete(messages: messages).toList();
      expect(
        denied.first,
        isA<LlmError>().having(
          (error) => error.code,
          'reason',
          'evaluation_budget_exhausted',
        ),
      );
      expect(delegate.calls, 1);
    },
  );

  test('unknown observed cost halts all later physical requests', () async {
    final delegate = _Provider();
    var costUnknown = false;
    final guarded = ProviderCallBudgetGuard(
      delegate,
      canBegin: () => !costUnknown,
    );
    await guarded.complete(messages: messages).drain<void>();
    costUnknown = true; // Missing usage or unpriceable outcome.
    await guarded.complete(messages: messages).drain<void>();
    expect(delegate.calls, 1);
  });

  test('paid API key still reserves worst-case before each request', () async {
    final delegate = _Provider();
    var spentMicros = 0;
    const budgetMicros = 10000000;
    const maxCallMicros = 9500000;
    final guarded = ProviderCallBudgetGuard(
      delegate,
      canBegin: () => spentMicros + maxCallMicros <= budgetMicros,
    );
    await guarded.complete(messages: messages).drain<void>();
    spentMicros = 600000; // Less than budget, but insufficient for next call.
    await guarded.complete(messages: messages).drain<void>();
    expect(delegate.calls, 1);
  });
}
