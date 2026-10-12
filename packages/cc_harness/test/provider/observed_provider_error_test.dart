import 'dart:async';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

class _Source implements LlmProviderPort {
  _Source(this.stream);
  final Stream<LlmEvent>? stream;
  @override
  String get displayName => 'source';
  @override
  String get defaultModel => 'model';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) => stream ?? (throw StateError('synchronous provider failure'));
}

class _Calls implements ProviderCallObserver {
  final records = <ProviderCallRecord>[];
  @override
  void onProviderCall(ProviderCallRecord record) => records.add(record);
}

void main() {
  test('a terminal stream error releases its still-open source', () async {
    var cancelled = false;
    final raw = StreamController<LlmEvent>(onCancel: () => cancelled = true);
    final calls = _Calls();
    final provider = ObservedLlmProvider(_Source(raw.stream), observer: calls);
    try {
      final result = expectLater(
        provider.complete(messages: const []).drain<void>(),
        throwsStateError,
      );
      raw.add(const LlmUsage(inputTokens: 9));
      raw.addError(StateError('transport failed before source EOF'));
      await result;
      expect(cancelled, isTrue);
      expect(calls.records.single.usage.inputTokens, 9);
      expect(calls.records.single.outcome, ProviderCallOutcome.failure);
    } finally {
      await raw.close();
    }
  });

  test(
    'a synchronous launch failure ends the observed stream and is recorded',
    () async {
      final calls = _Calls();
      final provider = ObservedLlmProvider(_Source(null), observer: calls);
      await expectLater(
        provider.complete(messages: const []).drain<void>(),
        throwsStateError,
      );
      expect(calls.records.single.outcome, ProviderCallOutcome.failure);
      expect(calls.records.single.usageReported, isFalse);
    },
  );
}
