import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:test/test.dart';

void main() {
  // ---- usage events ----

  group('AgentProcessEventCodec usage events', () {
    test('a fully attributed usage report round-trips intact', () {
      final event = UsageEvent(
        usage: const RunUsage(
          inputTokens: 1200,
          outputTokens: 340,
          thoughtTokens: 88,
          cachedReadTokens: 900,
          cachedWriteTokens: 150,
          estimatedCostCents: 7,
          costMicros: 71234,
          costBasis: CostBasis.subscription,
        ),
        durationMs: 4321,
        purpose: LlmCallPurpose.compaction,
        provider: 'anthropic',
        modelId: 'claude-sonnet-4-5',
        attempt: 2,
        requestId: 'req_abc',
        scope: UsageScope.runCumulative,
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      final wire = AgentProcessEventCodec.toWire(event);
      expect(wire['kind'], 'usage');

      final back = AgentProcessEventCodec.fromWire(wire);
      expect(back, isA<UsageEvent>());
      final decoded = back as UsageEvent;

      // Compared field by field: AgentProcessEvent.== only looks at the type
      // discriminant and the primary content string, so it cannot witness any
      // of the payload below.
      expect(decoded.usage.inputTokens, 1200);
      expect(decoded.usage.outputTokens, 340);
      expect(decoded.usage.thoughtTokens, 88);
      expect(decoded.usage.cachedReadTokens, 900);
      expect(decoded.usage.cachedWriteTokens, 150);
      expect(decoded.usage.estimatedCostCents, 7);
      expect(decoded.usage.costMicros, 71234);
      expect(decoded.usage.costBasis, CostBasis.subscription);
      expect(decoded.durationMs, 4321);
      expect(decoded.purpose, LlmCallPurpose.compaction);
      expect(decoded.provider, 'anthropic');
      expect(decoded.modelId, 'claude-sonnet-4-5');
      expect(decoded.attempt, 2);
      expect(decoded.requestId, 'req_abc');
      expect(decoded.scope, UsageScope.runCumulative);
      expect(decoded.timestamp, DateTime.utc(2026, 1, 2, 3, 4, 5));

      // Provenance and exact precision are the point of the extra fields: the
      // wire must spell them out rather than drop them.
      expect(wire['costBasis'], 'subscription');
      expect(wire['costMicros'], 71234);
      expect(wire['purpose'], 'compaction');
      expect(wire['scope'], 'run_cumulative');
      expect(wire['attempt'], 2);
    });

    test('a bare usage report keeps the historical wire shape', () {
      final wire = AgentProcessEventCodec.toWire(
        UsageEvent(usage: const RunUsage(inputTokens: 5)),
      );

      // The token axes a pre-attribution reader knows are still emitted.
      expect(wire['kind'], 'usage');
      expect(wire['inputTokens'], 5);
      expect(wire['outputTokens'], 0);
      expect(wire['thoughtTokens'], 0);
      expect(wire['cachedReadTokens'], 0);
      expect(wire['cachedWriteTokens'], 0);
      expect(wire['estimatedCostCents'], 0);
      // Optional attribution stays absent rather than being fabricated.
      expect(wire.containsKey('durationMs'), isFalse);
      expect(wire.containsKey('provider'), isFalse);
      expect(wire.containsKey('modelId'), isFalse);
      expect(wire.containsKey('attempt'), isFalse);
      expect(wire.containsKey('requestId'), isFalse);

      final decoded = AgentProcessEventCodec.fromWire(wire) as UsageEvent;
      expect(decoded.usage.inputTokens, 5);
      expect(decoded.scope, UsageScope.request);
      expect(decoded.purpose, LlmCallPurpose.main);
      expect(decoded.usage.costBasis, CostBasis.estimated);
      expect(decoded.durationMs, isNull);
      expect(decoded.provider, isNull);
      expect(decoded.modelId, isNull);
      expect(decoded.attempt, isNull);
      expect(decoded.requestId, isNull);
    });
  });

  // ---- stage timing events ----

  group('AgentProcessEventCodec stage timing events', () {
    test('an observed boundary survives the fleet wire round-trip', () {
      final event = StageTimingEvent(
        stage: RunStage.firstResponseByte,
        offsetMs: 250,
        source: RunTimingSource.transport,
        durationMs: 40,
        provider: 'anthropic',
        modelId: 'claude-sonnet-4-5',
        timestamp: DateTime.utc(2026, 2, 3, 4, 5, 6),
      );

      final wire = AgentProcessEventCodec.toWire(event);
      expect(wire['kind'], 'stageTiming');
      expect(wire['stage'], 'first_response_byte');
      expect(wire['source'], 'transport');

      final decoded = AgentProcessEventCodec.fromWire(wire);
      expect(decoded, isA<StageTimingEvent>());
      final timing = decoded as StageTimingEvent;

      expect(timing.stage, RunStage.firstResponseByte);
      expect(timing.offsetMs, 250);
      expect(timing.source, RunTimingSource.transport);
      expect(timing.durationMs, 40);
      expect(timing.provider, 'anthropic');
      expect(timing.modelId, 'claude-sonnet-4-5');
      expect(timing.timestamp, DateTime.utc(2026, 2, 3, 4, 5, 6));
    });

    test('an unrecognized stage is never fabricated into a boundary', () {
      final decoded = AgentProcessEventCodec.fromWire(<String, dynamic>{
        'kind': 'stageTiming',
        'stage': 'something_unknown',
        'offsetMs': 12,
        'source': 'transport',
      });

      // Inventing a `submitted` (or any other) stage here would corrupt every
      // percentile it entered, so the codec must degrade to a debug marker.
      expect(decoded, isNot(isA<StageTimingEvent>()));
      expect(decoded, isA<DebugEvent>());
      expect((decoded as DebugEvent).content, contains('something_unknown'));
    });

    test('the stageTiming event type label round-trips', () {
      expect(AgentProcessEventType.stageTiming.name, 'stage_timing');
      expect(
        AgentProcessEventTypeExtension.fromString('stage_timing'),
        AgentProcessEventType.stageTiming,
      );
    });
  });
}
