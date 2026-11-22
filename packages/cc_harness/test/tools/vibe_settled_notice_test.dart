import 'package:cc_harness/loop.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// A `/vibe` worker's result reaches the director's aside lane on its own
/// when nobody blocks on it (`vibe_wait`) and it was not killed, tagged with
/// its source and cut to [vibeNoticeMaxResult] characters.
void main() {
  late SteeringQueue lane;
  late VibeRoster roster;

  setUp(() {
    lane = SteeringQueue();
    // What the dispatch session wires.
    roster = VibeRoster(
      onSettled: (worker) => lane.pushAside(
        vibeSettledNotice(worker, nonce: 'n0nce1'),
        source: 'vibe:${worker.id}',
      ),
    );
  });

  VibeWorker start() => roster.add(
    label: 'audit',
    tier: VibeTier.values.first,
    brief: 'Audit the indexes.',
    now: DateTime.utc(2026, 11, 19),
  );

  test('a settled worker nobody waits on is pushed into the aside lane', () {
    final worker = start();
    roster.settle(worker.id, result: 'Three unused indexes.', isError: false);
    final pushed = lane.drainAside().single;
    expect(pushed.source, 'vibe:${worker.id}');
    expect(pushed.channel, SteeringChannel.aside);
    expect(pushed.content, contains('Background worker ${worker.id} "audit"'));
    expect(
      pushed.content,
      contains('<wake-data id="n0nce1">Three unused indexes.</wake-data'),
    );
    expect(lane.hasFollowUp, isFalse);
    expect(lane.hasSteering, isFalse);
  });

  test('a worker a vibe_wait blocks on is returned there, not pushed', () {
    final worker = start()..waiters = 1;
    roster.settle(worker.id, result: 'done', isError: false);
    expect(lane.isEmpty, isTrue);
  });

  test('a killed worker is not pushed', () {
    final worker = start();
    roster.kill(worker.id);
    roster.settle(worker.id, result: 'partial', isError: true);
    expect(lane.isEmpty, isTrue);
  });

  test('a long result is cut to 2000 characters with the way to the rest', () {
    final worker = start();
    roster.settle(worker.id, result: 'x' * 5000, isError: false);
    final content = lane.drainAside().single.content;
    expect(vibeNoticeMaxResult, 2000);
    expect(content, contains('${'x' * 1999}…'));
    expect(content, isNot(contains('x' * 2000)));
    expect(content, contains('vibe_wait({worker_id: "${worker.id}"})'));
  });
}
