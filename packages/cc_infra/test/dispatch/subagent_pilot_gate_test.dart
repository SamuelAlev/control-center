import 'dart:async';

import 'package:cc_infra/src/dispatch/subagent_pilot_gate.dart';
import 'package:test/test.dart';

void main() {
  group('SubagentPilotGate', () {
    test('the first child of a shape pilots at once; a sibling waits for it '
        'to start streaming', () async {
      final gate = SubagentPilotGate();
      final never = Completer<void>().future;
      final releasePilot = await gate.enter('explore|p|m', abandoned: never);
      expect(gate.isPiloting('explore|p|m'), isTrue);

      var siblingIn = false;
      final sibling = gate
          .enter('explore|p|m', abandoned: never)
          .then((_) => siblingIn = true);
      await Future<void>.delayed(Duration.zero);
      expect(siblingIn, isFalse, reason: 'held until the pilot streams');

      releasePilot();
      await sibling;
      expect(siblingIn, isTrue);
      expect(gate.isPiloting('explore|p|m'), isFalse);
    });

    test('another shape never waits on this one', () async {
      final gate = SubagentPilotGate();
      final never = Completer<void>().future;
      await gate.enter('a', abandoned: never);
      await gate.enter('b', abandoned: never);
      expect(gate.isPiloting('a'), isTrue);
      expect(gate.isPiloting('b'), isTrue);
    });

    test(
      'a slow pilot costs the sibling a cache hit, never the fan-out',
      () async {
        final gate = SubagentPilotGate(
          maxWait: const Duration(milliseconds: 50),
        );
        final never = Completer<void>().future;
        await gate.enter('k', abandoned: never);
        final waited = Stopwatch()..start();
        await gate.enter('k', abandoned: never);
        expect(
          waited.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 40)),
        );
        expect(
          gate.isPiloting('k'),
          isTrue,
          reason: 'the pilot still holds it',
        );
      },
    );

    test('a cancelled sibling stops waiting', () async {
      final gate = SubagentPilotGate();
      await gate.enter('k', abandoned: Completer<void>().future);
      final cancelled = Completer<void>();
      final sibling = gate.enter('k', abandoned: cancelled.future);
      cancelled.complete();
      await sibling;
      expect(gate.isPiloting('k'), isTrue, reason: 'the pilot still holds it');
    });

    test('release is idempotent, a sibling release is a no-op, and a new '
        'pilot can take the shape afterwards', () async {
      final gate = SubagentPilotGate();
      final never = Completer<void>().future;
      final first = await gate.enter('k', abandoned: never);
      first();
      first();
      expect(gate.isPiloting('k'), isFalse);

      final second = await gate.enter('k', abandoned: never);
      expect(gate.isPiloting('k'), isTrue);
      first();
      expect(gate.isPiloting('k'), isTrue, reason: 'a stale release is inert');

      final sibling = gate.enter('k', abandoned: never);
      second();
      final siblingRelease = await sibling;
      siblingRelease();
      expect(gate.isPiloting('k'), isFalse);
    });
  });
}
