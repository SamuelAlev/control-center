import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/fallback_provider.dart';
import 'package:test/test.dart';

class _ScriptProvider implements LlmProviderPort {
  _ScriptProvider(this.name, this.events);
  final String name;
  final List<LlmEvent> events;
  int calls = 0;
  LlmCompleteConfig? lastConfig;

  @override
  String get displayName => name;
  @override
  String get defaultModel => 'm';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    calls++;
    lastConfig = config;
    yield* Stream.fromIterable(events);
  }
}

/// A provider whose native-deferral capability depends on the model it is asked
/// about, mirroring `AnthropicProvider`.
class _ModelGatedProvider extends _ScriptProvider
    implements LlmDeferredToolSupport {
  _ModelGatedProvider(super.name, super.events);

  @override
  bool supportsDeferredTools({String? model}) => model == 'new-model';
}

void main() {
  test('advances to the next target on a non-retryable error', () async {
    final bad = _ScriptProvider('bad', const [
      LlmError('unauthorized', code: 'authentication_error'),
      LlmDone(),
    ]);
    final good = _ScriptProvider('good', const [LlmTextDelta('hi'), LlmDone()]);
    var fellBack = false;
    final fb = FallbackProvider(
      [
        FallbackEntry(providerId: 'a', model: 'm', build: () => bad),
        FallbackEntry(providerId: 'b', model: 'm', build: () => good),
      ],
      onFallback: (from, to, reason, {fromCredentialId, capacity = false}) =>
          fellBack = true,
    );
    final events = await fb
        .complete(messages: [HarnessMessage.user('x')])
        .toList();
    expect(fellBack, isTrue);
    expect(events.whereType<LlmTextDelta>().single.text, 'hi');
    expect(fb.lastServedProviderId, 'b');
    expect(good.calls, 1);
  });

  test('is sticky: a later call starts at the last working target', () async {
    final bad = _ScriptProvider('bad', const [
      LlmError('quota', code: 'quota_exceeded'),
      LlmDone(),
    ]);
    final good = _ScriptProvider('good', const [LlmTextDelta('ok'), LlmDone()]);
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => bad),
      FallbackEntry(providerId: 'b', model: 'm', build: () => good),
    ]);
    await fb.complete(messages: [HarnessMessage.user('1')]).toList();
    await fb.complete(messages: [HarnessMessage.user('2')]).toList();
    expect(bad.calls, 1); // not retried after it failed once
    expect(good.calls, 2);
  });

  test('surfaces a terminal error when every target fails', () async {
    final e1 = _ScriptProvider('e1', const [
      LlmError('no', code: 'authentication_error'),
      LlmDone(),
    ]);
    final e2 = _ScriptProvider('e2', const [
      LlmError('no2', code: 'authentication_error'),
      LlmDone(),
    ]);
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => e1),
      FallbackEntry(providerId: 'b', model: 'm', build: () => e2),
    ]);
    final events = await fb
        .complete(messages: [HarnessMessage.user('x')])
        .toList();
    expect(events.whereType<LlmError>(), isNotEmpty);
  });

  test('retryable non-capacity error is surfaced (loop retries)', () async {
    final p = _ScriptProvider('p', const [
      LlmError('connection reset', retryable: true),
      LlmDone(),
    ]);
    final other = _ScriptProvider('o', const [LlmTextDelta('x'), LlmDone()]);
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => p),
      FallbackEntry(providerId: 'b', model: 'm', build: () => other),
    ]);
    final events = await fb
        .complete(messages: [HarnessMessage.user('x')])
        .toList();
    // A network-level failure says nothing about the next credential's
    // headroom — surfaced for the loop's backoff, NOT rotated.
    expect(events.whereType<LlmError>().single.retryable, isTrue);
    expect(other.calls, 0);
  });

  test(
    'rotates on a retryable rate-limit when a next credential exists',
    () async {
      final limited = _ScriptProvider('limited', const [
        LlmError('rate limited', code: 'rate_limit_error', retryable: true),
        LlmDone(),
      ]);
      final good = _ScriptProvider('good', const [
        LlmTextDelta('ok'),
        LlmDone(),
      ]);
      String? fallbackReason;
      final fb = FallbackProvider(
        [
          FallbackEntry(providerId: 'a', model: 'm', build: () => limited),
          FallbackEntry(providerId: 'a', model: 'm', build: () => good),
        ],
        onFallback: (from, to, reason, {fromCredentialId, capacity = false}) =>
            fallbackReason = reason,
      );
      final events = await fb
          .complete(messages: [HarnessMessage.user('x')])
          .toList();
      // The exhausted credential fails over immediately instead of burning the
      // loop's backoff budget on a key with no headroom.
      expect(fallbackReason, 'rate_limit_error');
      expect(events.whereType<LlmError>(), isEmpty);
      expect(events.whereType<LlmTextDelta>().single.text, 'ok');
      expect(good.calls, 1);
    },
  );

  test('fails over on a spent-balance 400 (credit exhaustion)', () async {
    // Anthropic frames exhausted prepaid credit as 400 invalid_request_error —
    // a request-level code that must not mask the target-specific cause.
    final spent = _ScriptProvider('spent', const [
      LlmError(
        'Anthropic API error 400: {"error":{"type":"invalid_request_error",'
        '"message":"Your credit balance is too low to access the Anthropic '
        'API."}}',
        code: 'invalid_request_error',
      ),
      LlmDone(),
    ]);
    final good = _ScriptProvider('good', const [LlmTextDelta('ok'), LlmDone()]);
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => spent),
      FallbackEntry(providerId: 'a', model: 'm', build: () => good),
    ]);
    final events = await fb
        .complete(messages: [HarnessMessage.user('x')])
        .toList();
    expect(events.whereType<LlmError>(), isEmpty);
    expect(events.whereType<LlmTextDelta>().single.text, 'ok');
  });

  test('does not rotate once output has streamed', () async {
    final partial = _ScriptProvider('partial', const [
      LlmTextDelta('half'),
      LlmError('rate', code: 'rate_limit_error', retryable: true),
      LlmDone(),
    ]);
    final other = _ScriptProvider('other', const [
      LlmTextDelta('x'),
      LlmDone(),
    ]);
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => partial),
      FallbackEntry(providerId: 'a', model: 'm', build: () => other),
    ]);
    final events = await fb
        .complete(messages: [HarnessMessage.user('x')])
        .toList();
    // Rotating mid-turn would replay/corrupt the partial assistant output —
    // the retryable error surfaces instead and the loop retries this target.
    expect(events.whereType<LlmTextDelta>().single.text, 'half');
    expect(events.whereType<LlmError>().single.retryable, isTrue);
    expect(other.calls, 0);
  });

  test(
    'an exhausted chain surfaces the error and the retry re-walks it',
    () async {
      final e1 = _ScriptProvider('e1', const [
        LlmError('rate', code: 'http_429', retryable: true),
        LlmDone(),
      ]);
      final e2 = _ScriptProvider('e2', const [
        LlmError('rate', code: 'http_429', retryable: true),
        LlmDone(),
      ]);
      final fb = FallbackProvider([
        FallbackEntry(providerId: 'a', model: 'm', build: () => e1),
        FallbackEntry(providerId: 'b', model: 'm', build: () => e2),
      ]);
      final events = await fb
          .complete(messages: [HarnessMessage.user('x')])
          .toList();
      // Both targets capacity-limited: the retryable error surfaces for the
      // loop's backoff.
      expect(events.whereType<LlmError>().single.retryable, isTrue);
      expect(e1.calls, 1);
      expect(e2.calls, 1);
      // The loop's backoff retry starts from the PRIMARY again — the delay may
      // have cleared its window — rather than hammering only the last target.
      await fb.complete(messages: [HarnessMessage.user('y')]).toList();
      expect(e1.calls, 2);
    },
  );

  group('per-entry model and accounting', () {
    test('asks each target for its OWN model, not the primary', () async {
      final spent = _ScriptProvider('spent', const [
        LlmError('Invalid API key', code: 'authentication_error'),
        LlmDone(),
      ]);
      final crossProvider = _ScriptProvider('cross', const [
        LlmTextDelta('ok'),
        LlmDone(),
      ]);
      final fb = FallbackProvider([
        FallbackEntry(
          providerId: 'anthropic',
          model: 'claude-opus-4-8',
          build: () => spent,
        ),
        FallbackEntry(
          providerId: 'openai',
          model: 'gpt-x',
          build: () => crossProvider,
        ),
      ]);

      await fb
          .complete(
            messages: [HarnessMessage.user('x')],
            config: const LlmCompleteConfig(model: 'claude-opus-4-8'),
          )
          .toList();

      expect(spent.lastConfig?.model, 'claude-opus-4-8');
      expect(
        crossProvider.lastConfig?.model,
        'gpt-x',
        reason: 'forwarding the primary model to the fallback target would 404',
      );
      // Everything else is carried through untouched.
      expect(
        crossProvider.lastConfig?.maxTokens,
        const LlmCompleteConfig().maxTokens,
      );
    });

    test(
      'an entry that declares no model keeps the provider default',
      () async {
        final provider = _ScriptProvider('p', const [
          LlmTextDelta('ok'),
          LlmDone(),
        ]);
        final fb = FallbackProvider([
          FallbackEntry(providerId: 'a', model: '', build: () => provider),
        ]);
        await fb
            .complete(
              messages: [HarnessMessage.user('x')],
              config: const LlmCompleteConfig(model: 'caller-model'),
            )
            .toList();
        expect(provider.lastConfig?.model, 'm');
        expect(fb.defaultModel, 'm');
      },
    );

    test('accounts each physical attempt to the target that ran it', () async {
      final ledger = ProviderCallLedger(runId: 'run-1');
      final primary = _ScriptProvider('primary', const [
        LlmError('bad key', code: 'authentication_error'),
        LlmDone(),
      ]);
      final secondary = _ScriptProvider('secondary', const [
        LlmTextDelta('ok'),
        LlmUsage(inputTokens: 30, outputTokens: 4),
        LlmDone(stopReason: LlmStopReason.endTurn),
      ]);
      final fb = FallbackProvider([
        FallbackEntry(
          providerId: 'anthropic',
          model: 'claude-opus-4-8',
          build: () => ObservedLlmProvider(
            primary,
            observer: ledger,
            identity: ledger.identity,
            runId: 'run-1',
          ),
        ),
        FallbackEntry(
          providerId: 'openai',
          model: 'gpt-x',
          build: () => ObservedLlmProvider(
            secondary,
            observer: ledger,
            identity: ledger.identity,
            runId: 'run-1',
          ),
        ),
      ]);

      await fb
          .complete(
            messages: [HarnessMessage.user('x')],
            config: const LlmCompleteConfig(
              model: 'claude-opus-4-8',
              callId: 'turn-1',
              purpose: LlmCallPurpose.main,
            ),
          )
          .toList();

      expect(
        ledger.records,
        hasLength(2),
        reason: 'the failed target is spend too — one record per physical call',
      );
      expect(ledger.duplicatesIgnored, 0);
      expect(ledger.records.map((r) => r.model), [
        'claude-opus-4-8',
        'gpt-x',
      ], reason: 'each record names the model its target was asked for');
      expect(ledger.records.map((r) => r.providerId), ['primary', 'secondary']);
      expect(ledger.records.first.outcome, ProviderCallOutcome.failure);
      expect(ledger.records.last.outcome, ProviderCallOutcome.success);
      expect(ledger.total.inputTokens, 30);
      expect(ledger.billableTokens, 34);
    });

    test('deferral capability is refused when ANY target cannot defer', () {
      final newTarget = _ModelGatedProvider('new', const [LlmDone()]);
      final oldTarget = _ModelGatedProvider('old', const [LlmDone()]);
      final incapable = _ScriptProvider('plain', const [LlmDone()]);

      final bothNew = FallbackProvider([
        FallbackEntry(
          providerId: 'a',
          model: 'new-model',
          build: () => newTarget,
        ),
        FallbackEntry(
          providerId: 'b',
          model: 'new-model',
          build: () => oldTarget,
        ),
      ]);
      expect(
        providerSupportsDeferredTools(bothNew, model: 'new-model'),
        isTrue,
      );

      final mixedModel = FallbackProvider([
        FallbackEntry(
          providerId: 'a',
          model: 'new-model',
          build: () => newTarget,
        ),
        FallbackEntry(
          providerId: 'b',
          model: 'old-model',
          build: () => oldTarget,
        ),
      ]);
      expect(
        providerSupportsDeferredTools(mixedModel, model: 'new-model'),
        isFalse,
        reason:
            'the second entry is checked with ITS OWN model, not the '
            'caller\'s primary — deferring here would break the failover',
      );

      final mixedProvider = FallbackProvider([
        FallbackEntry(
          providerId: 'a',
          model: 'new-model',
          build: () => newTarget,
        ),
        FallbackEntry(
          providerId: 'b',
          model: 'new-model',
          build: () => incapable,
        ),
      ]);
      expect(
        providerSupportsDeferredTools(mixedProvider, model: 'new-model'),
        isFalse,
        reason: 'a target with no native deferral must veto the whole chain',
      );
    });
  });
}
