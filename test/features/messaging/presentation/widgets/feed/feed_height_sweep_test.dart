import 'package:control_center/features/messaging/presentation/widgets/feed/feed_height_sweep.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

List<SweepJob> _jobs(int count, {String prefix = 'row', int revision = 0}) => [
  for (var i = 0; i < count; i++)
    SweepJob(key: '$prefix:$i', revision: revision, width: 400, payload: i),
];

/// Spins for [duration] of real time: `Stopwatch` is not faked in widget
/// tests, so this is what a slow measurement costs the slice.
void _busy(Duration duration) {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < duration) {}
}

/// Pumps until [sweep] has drained (bounded, so a stuck sweep fails rather
/// than hangs).
///
/// Every pump passes a slice gap: slices run from timers, and a bare `pump()`
/// does not advance the fake clock, so it never fires them.
Future<void> _drain(WidgetTester tester, FeedHeightSweep sweep) async {
  for (var i = 0; i < 200 && !sweep.isIdle; i++) {
    await tester.pump(_gap);
  }
  expect(sweep.isIdle, isTrue);
}

const Duration _gap = Duration(milliseconds: 16);

void main() {
  testWidgets('holds back while an animation ticks, without spinning', (
    tester,
  ) async {
    // Regression: an idle-priority scheduler task queued during an animation
    // re-armed a zero-delay timer forever under fake time (a permalink's
    // ensureVisible animation hung the feed tests).
    final measured = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        measured.add(job.key);
        return 1;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);
    final ticker = Ticker((_) {})..start();
    addTearDown(ticker.dispose);

    sweep.schedule(_jobs(3));
    for (var i = 0; i < 10; i++) {
      await tester.pump(_gap);
    }
    expect(measured, isEmpty);

    ticker.stop();
    await _drain(tester, sweep);
    expect(measured, ['row:0', 'row:1', 'row:2']);
  });

  testWidgets('slices stop at the budget and resume in a later task', (
    tester,
  ) async {
    final sliceOfJob = <int>[];
    late final FeedHeightSweep sweep;
    sweep = FeedHeightSweep(
      sliceBudget: const Duration(milliseconds: 4),
      measure: (job) {
        sliceOfJob.add(sweep.debugSlicesRun);
        _busy(const Duration(milliseconds: 1));
        return 10;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(40));
    // Nothing runs synchronously: the work waits for an idle slice.
    expect(sliceOfJob, isEmpty);
    expect(sweep.isIdle, isFalse);

    await _drain(tester, sweep);

    expect(sliceOfJob, hasLength(40));
    // Each job costs at least 1ms of a 4ms budget, and a slice checks the
    // clock after every job: no slice can run more than five.
    final perSlice = <int, int>{};
    for (final slice in sliceOfJob) {
      perSlice[slice] = (perSlice[slice] ?? 0) + 1;
    }
    expect(perSlice.values.every((n) => n >= 1 && n <= 5), isTrue);
    expect(sweep.debugSlicesRun, greaterThanOrEqualTo(8));
    expect(sweep.debugSlicesRun, perSlice.length);
  });

  testWidgets('cheap work fits in one slice, nearest first', (tester) async {
    final measured = <String>[];
    final reported = <String, double>{};
    final sweep = FeedHeightSweep(
      measure: (job) {
        measured.add(job.key);
        return (job.payload! as int) * 10.0;
      },
      onMeasured: (job, extent) => reported[job.key] = extent,
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(3));
    await _drain(tester, sweep);

    expect(sweep.debugSlicesRun, 1);
    expect(measured, ['row:0', 'row:1', 'row:2']);
    expect(reported, {'row:0': 0.0, 'row:1': 10.0, 'row:2': 20.0});
  });

  testWidgets('schedule replaces the pending queue', (tester) async {
    final measured = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        measured.add(job.key);
        return 1;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);

    sweep
      ..schedule(_jobs(10, prefix: 'old'))
      ..schedule(_jobs(3, prefix: 'new'));
    await _drain(tester, sweep);

    expect(measured, ['new:0', 'new:1', 'new:2']);
  });

  testWidgets('skips jobs already measured at the same revision and width', (
    tester,
  ) async {
    final measured = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        measured.add('${job.key}@${job.revision}/${job.width}');
        return 1;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(2));
    await _drain(tester, sweep);
    expect(measured, ['row:0@0/400.0', 'row:1@0/400.0']);

    measured.clear();
    sweep.schedule([
      ..._jobs(2),
      const SweepJob(key: 'row:0', revision: 0, width: 400.4),
    ]);
    expect(sweep.isIdle, isTrue);
    await _drain(tester, sweep);
    expect(measured, isEmpty);

    // A new revision or a real width change is new work.
    sweep.schedule([
      const SweepJob(key: 'row:0', revision: 1, width: 400),
      const SweepJob(key: 'row:1', revision: 0, width: 320),
    ]);
    await _drain(tester, sweep);
    expect(measured, ['row:0@1/400.0', 'row:1@0/320.0']);

    // Forgetting the memo re-runs everything.
    measured.clear();
    sweep
      ..resetMeasured()
      ..schedule(_jobs(1));
    await _drain(tester, sweep);
    expect(measured, ['row:0@0/400.0']);
  });

  testWidgets('a null measurement is skipped and retried next schedule', (
    tester,
  ) async {
    var ready = false;
    var calls = 0;
    final reported = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        calls++;
        return ready ? 5 : null;
      },
      onMeasured: (job, extent) => reported.add(job.key),
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(2));
    await _drain(tester, sweep);
    expect(calls, 2);
    expect(reported, isEmpty);

    ready = true;
    sweep.schedule(_jobs(2));
    await _drain(tester, sweep);
    expect(calls, 4);
    expect(reported, ['row:0', 'row:1']);
  });

  testWidgets('pause holds the queue until resume', (tester) async {
    final measured = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        measured.add(job.key);
        return 1;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);

    sweep
      ..schedule(_jobs(4))
      ..pause();
    expect(sweep.isIdle, isTrue);
    for (var i = 0; i < 5; i++) {
      await tester.pump(_gap);
    }
    expect(measured, isEmpty);

    sweep.resume();
    expect(sweep.isIdle, isFalse);
    await _drain(tester, sweep);
    expect(measured, ['row:0', 'row:1', 'row:2', 'row:3']);
  });

  testWidgets('pausing mid-slice stops after the current job', (tester) async {
    final measured = <String>[];
    late final FeedHeightSweep sweep;
    sweep = FeedHeightSweep(
      measure: (job) {
        measured.add(job.key);
        if (job.key == 'row:1') {
          sweep.pause();
        }
        return 1;
      },
      onMeasured: (job, extent) {},
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(4));
    for (var i = 0; i < 5; i++) {
      await tester.pump(_gap);
    }
    expect(measured, ['row:0', 'row:1']);

    sweep.resume();
    await _drain(tester, sweep);
    expect(measured, ['row:0', 'row:1', 'row:2', 'row:3']);
  });

  testWidgets('dispose with a task pending is a safe no-op', (tester) async {
    var calls = 0;
    final sweep = FeedHeightSweep(
      measure: (job) {
        calls++;
        return 1;
      },
      onMeasured: (job, extent) {},
    );

    sweep
      ..schedule(_jobs(5))
      ..dispose();
    for (var i = 0; i < 5; i++) {
      await tester.pump(_gap);
    }

    expect(calls, 0);
    expect(tester.takeException(), isNull);
    expect(sweep.isIdle, isTrue);

    // Calls after dispose do nothing.
    sweep
      ..schedule(_jobs(2))
      ..resume();
    await tester.pump(_gap);
    expect(calls, 0);
  });

  testWidgets('dispose from inside a measurement ends the slice', (
    tester,
  ) async {
    final reported = <String>[];
    late final FeedHeightSweep sweep;
    sweep = FeedHeightSweep(
      measure: (job) {
        if (job.key == 'row:1') {
          sweep.dispose();
        }
        return 1;
      },
      onMeasured: (job, extent) => reported.add(job.key),
    );

    sweep.schedule(_jobs(4));
    for (var i = 0; i < 5; i++) {
      await tester.pump(_gap);
    }

    // row:1's result still lands (it was measured before the sweep saw the
    // dispose); nothing after it runs.
    expect(reported, ['row:0', 'row:1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a throwing measurement is reported and the sweep continues', (
    tester,
  ) async {
    final reported = <String>[];
    final sweep = FeedHeightSweep(
      measure: (job) {
        if (job.key == 'row:1') {
          throw StateError('boom');
        }
        return 1;
      },
      onMeasured: (job, extent) => reported.add(job.key),
    );
    addTearDown(sweep.dispose);

    sweep.schedule(_jobs(3));
    await _drain(tester, sweep);

    expect(reported, ['row:0', 'row:2']);
    // Reported through FlutterError, which the test binding captures.
    expect(tester.takeException(), isA<StateError>());
  });
}
