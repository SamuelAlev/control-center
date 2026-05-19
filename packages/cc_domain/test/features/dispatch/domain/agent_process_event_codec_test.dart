import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:test/test.dart';

void main() {
  group('AgentProcessEventCodec done events', () {
    test('a plain DoneEvent round-trips with no outcome field on the wire', () {
      final wire = AgentProcessEventCodec.toWire(DoneEvent());

      expect(wire['kind'], 'done');
      expect(wire.containsKey('outcome'), isFalse);

      final back = AgentProcessEventCodec.fromWire(wire);
      expect(back, isA<DoneEvent>());
      expect((back as DoneEvent).outcome, isNull);
    });

    test(
      'a DoneEvent carrying maxTurns survives the fleet wire round-trip',
      () {
        final wire = AgentProcessEventCodec.toWire(
          DoneEvent(outcome: TurnOutcome.maxTurns),
        );

        expect(wire['outcome'], 'max_turns');

        final back = AgentProcessEventCodec.fromWire(wire);
        expect((back as DoneEvent).outcome, TurnOutcome.maxTurns);
      },
    );

    test('an unknown outcome wire value degrades to a plain completion', () {
      final back = AgentProcessEventCodec.fromWire(<String, dynamic>{
        'kind': 'done',
        'outcome': 'bogus',
      });

      expect((back as DoneEvent).outcome, isNull);
    });
  });
}
