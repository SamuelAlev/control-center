import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/fallback_provider.dart';
import 'package:test/test.dart';

class _ScriptProvider implements LlmProviderPort {
  _ScriptProvider(this.name, this.events);
  final String name;
  final List<LlmEvent> events;
  int calls = 0;

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
    yield* Stream.fromIterable(events);
  }
}

void main() {
  test('advances to the next target on a non-retryable error', () async {
    final bad = _ScriptProvider('bad', const [
      LlmError('unauthorized', code: 'authentication_error'),
      LlmDone(),
    ]);
    final good = _ScriptProvider('good', const [LlmTextDelta('hi'), LlmDone()]);
    var fellBack = false;
    final fb = FallbackProvider([
      FallbackEntry(providerId: 'a', model: 'm', build: () => bad),
      FallbackEntry(providerId: 'b', model: 'm', build: () => good),
    ], onFallback: (from, to, reason) => fellBack = true);
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

  test('retryable error is surfaced (loop retries same target)', () async {
    final p = _ScriptProvider('p', const [
      LlmError('rate', code: 'rate_limit_error', retryable: true),
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
    // Retryable → surfaced, did NOT advance to 'other'.
    expect(events.whereType<LlmError>().single.retryable, isTrue);
    expect(other.calls, 0);
  });
}
