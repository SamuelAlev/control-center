import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:test/test.dart';

/// PRD 25 §6: a run's duration is its **active** time, not the wall-clock span.
/// Idle time between a stop and a restart (a failed→retried run, or an app
/// restart) must not inflate the duration. These tests drive the entity's
/// timing contract directly — construct → fold at a stop → resume → fold at
/// completion — mirroring exactly what `PipelineEngine` does through the
/// repository, without needing the engine's async plumbing.
void main() {
  group('PipelineRun active-time accounting (PRD 25 §6)', () {
    final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);

    PipelineRun runningAt(DateTime resumedAt, {int activeMs = 0}) =>
        PipelineRun(
          id: 'r1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: PipelineRunStatus.running,
          startedAt: t0,
          activeMs: activeMs,
          lastResumedAt: resumedAt,
        );

    test('a running run accrues live time since lastResumedAt', () {
      final run = runningAt(t0);
      expect(run.activeDurationAt(t0), Duration.zero);
      expect(
        run.activeDurationAt(t0.add(const Duration(seconds: 5))),
        const Duration(seconds: 5),
      );
    });

    test('the idle stop→restart gap is excluded from the active duration', () {
      // T0: the run starts running.
      var run = runningAt(t0);

      // Ran 5s, then stopped (failed). Fold the live segment into activeMs and
      // clear the resume mark — the engine's terminal-transition behaviour.
      final stopAt = t0.add(const Duration(seconds: 5));
      final foldedMs = run.activeDurationAt(stopAt).inMilliseconds;
      run = run.copyWith(
        status: PipelineRunStatus.failed,
        finishedAt: stopAt,
        activeMs: foldedMs,
        lastResumedAt: null,
      );
      expect(run.activeMs, 5000);
      expect(run.lastResumedAt, isNull);
      // Terminal: elapsing wall-clock does not grow the duration.
      expect(
        run.activeDurationAt(stopAt.add(const Duration(hours: 1))),
        const Duration(seconds: 5),
      );

      // Idle for 1h, then resumed (retry): activeMs is preserved, the clock
      // restarts from the resume instant.
      final resumeAt = stopAt.add(const Duration(hours: 1));
      run = run.copyWith(
        status: PipelineRunStatus.running,
        lastResumedAt: resumeAt,
      );

      // Ran 3s more. The live view is 5s + 3s = 8s — NOT 1h + 8s.
      final finishAt = resumeAt.add(const Duration(seconds: 3));
      expect(run.activeDurationAt(finishAt), const Duration(seconds: 8));
      expect(
        run.activeDurationAt(finishAt).inMinutes,
        lessThan(1),
        reason: 'the 1h idle gap must be excluded from the active duration',
      );

      // Complete: fold again, clear the resume mark.
      final finalMs = run.activeDurationAt(finishAt).inMilliseconds;
      run = run.copyWith(
        status: PipelineRunStatus.completed,
        finishedAt: finishAt,
        activeMs: finalMs,
        lastResumedAt: null,
      );
      expect(run.activeMs, 8000);
      expect(run.activeDurationAt(DateTime.now()), const Duration(seconds: 8));
    });

    test('copyWith is nullable-aware for lastResumedAt', () {
      final run = runningAt(t0, activeMs: 1000);
      // Omitted → the current value is preserved.
      expect(run.copyWith(activeMs: 2000).lastResumedAt, t0);
      // Passed explicitly as null → cleared.
      expect(run.copyWith(lastResumedAt: null).lastResumedAt, isNull);
    });

    test('a non-running run reports only its accumulated activeMs', () {
      final run = PipelineRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.suspended,
        startedAt: t0,
        activeMs: 4000,
        lastResumedAt: t0,
      );
      // status != running → the live segment is not added, even hours later.
      expect(
        run.activeDurationAt(t0.add(const Duration(hours: 2))),
        const Duration(seconds: 4),
      );
    });
  });
}
