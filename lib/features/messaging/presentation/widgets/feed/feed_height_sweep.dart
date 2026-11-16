import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Bound on the already-measured memo; past it the memo starts over (the
/// height cache, not this, is the durable record).
const int _kMaxRemembered = 20000;

/// One row the [FeedHeightSweep] should measure.
class SweepJob {
  /// Creates a job measuring row [key] at [width] for content [revision].
  const SweepJob({
    required this.key,
    required this.revision,
    required this.width,
    this.payload,
  });

  /// Globally unique row key (see `FeedHeightCache`).
  final String key;

  /// Content revision the measurement is for.
  final int revision;

  /// Column width to measure at.
  final double width;

  /// Whatever the measure callback needs to do its work (the message, the
  /// segment); opaque to the sweep.
  final Object? payload;
}

/// Idle-time slicer that measures feed rows in the background.
///
/// Each slice runs from a short timer ([sliceGap]) and only when the
/// scheduler is idle: no frame scheduled or in progress and no animation
/// ticking. A busy scheduler pushes the slice back by another gap. It then
/// works through the queue until its stopwatch passes [sliceBudget]. At most
/// one timer is ever pending.
///
/// Not [SchedulerBinding.scheduleTask]: an idle-priority task queued while an
/// animation runs makes the scheduler re-arm a zero-delay timer on every
/// event-loop turn until the animation ends — a busy loop in the app, and a
/// hang under fake time, where that time never gets to advance.
///
/// A job already measured by this sweep (same key and revision, width within
/// half a pixel) is skipped when it is scheduled again; [resetMeasured]
/// forgets those.
class FeedHeightSweep {
  /// Creates a sweep that calls `measure` for each job and reports a non-null
  /// result through `onMeasured`, working in slices of [sliceBudget] on
  /// `binding` (the [SchedulerBinding] instance when null).
  FeedHeightSweep({
    required this._measure,
    required this._onMeasured,
    this.sliceBudget = const Duration(milliseconds: 4),
    this.sliceGap = const Duration(milliseconds: 16),
    this._binding,
  });

  /// Delay before each slice, and before re-checking a busy scheduler.
  final Duration sliceGap;

  /// Wall-clock budget of one slice. A slice always processes at least one
  /// job, then stops as soon as the elapsed time exceeds this.
  final Duration sliceBudget;

  final double? Function(SweepJob job) _measure;
  final void Function(SweepJob job, double extent) _onMeasured;
  final SchedulerBinding? _binding;

  /// Pending jobs, nearest first; [_cursor] is the next one to run.
  List<SweepJob> _queue = const [];
  int _cursor = 0;

  /// Key → (revision, width) of every job this sweep has run.
  final Map<String, (int, double)> _done = <String, (int, double)>{};

  bool _paused = false;
  bool _disposed = false;
  Timer? _timer;
  int _slicesRun = 0;

  /// Number of slices that did work. Test seam: one `pump` in a widget test
  /// runs the whole chain of idle tasks, so slicing is only observable here.
  @visibleForTesting
  int get debugSlicesRun => _slicesRun;

  /// Whether the sweep has nothing to do right now: the queue is drained, the
  /// sweep is paused, or it was disposed.
  ///
  /// A paused sweep with jobs queued reports idle — no work will start until
  /// [resume].
  bool get isIdle => _disposed || _paused || _cursor >= _queue.length;

  /// Replaces the pending queue with [jobsNearestFirst].
  ///
  /// Jobs this sweep already measured at the same revision and width are
  /// dropped. Starts a slice unless one is pending or the sweep is paused.
  void schedule(List<SweepJob> jobsNearestFirst) {
    if (_disposed) {
      return;
    }
    _queue = [
      for (final job in jobsNearestFirst)
        if (!_alreadyMeasured(job)) job,
    ];
    _cursor = 0;
    _ensureTask();
  }

  /// Stops new slices from starting. The queue is kept.
  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Lets slices run again after [pause].
  void resume() {
    if (_disposed || !_paused) {
      return;
    }
    _paused = false;
    _ensureTask();
  }

  /// Forgets which jobs were measured, so scheduling them again re-runs them
  /// (after a theme or font change, say).
  void resetMeasured() => _done.clear();

  /// Cancels the sweep and its pending timer; later calls do nothing.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _queue = const [];
    _cursor = 0;
    _done.clear();
  }

  bool _alreadyMeasured(SweepJob job) {
    final done = _done[job.key];
    return done != null &&
        done.$1 == job.revision &&
        (done.$2 - job.width).abs() <= 0.5;
  }

  void _ensureTask() {
    if (_timer != null || _paused || _disposed || _cursor >= _queue.length) {
      return;
    }
    _timer = Timer(sliceGap, _onTimer);
  }

  void _onTimer() {
    _timer = null;
    final binding = _binding ?? SchedulerBinding.instance;
    if (binding.transientCallbackCount > 0 ||
        binding.hasScheduledFrame ||
        binding.schedulerPhase != SchedulerPhase.idle) {
      _ensureTask();
      return;
    }
    _runSlice();
  }

  void _runSlice() {
    if (_disposed || _paused || _cursor >= _queue.length) {
      return;
    }
    _slicesRun++;
    final budget = sliceBudget.inMicroseconds;
    final stopwatch = Stopwatch()..start();
    while (_cursor < _queue.length) {
      final job = _queue[_cursor++];
      if (!_alreadyMeasured(job)) {
        _runJob(job);
        if (_disposed) {
          return;
        }
      }
      if (_paused || stopwatch.elapsedMicroseconds > budget) {
        break;
      }
    }
    _ensureTask();
  }

  void _runJob(SweepJob job) {
    try {
      final extent = _measure(job);
      // A null result is "not measurable yet" (content still loading): left
      // out of the memo so the next schedule retries it.
      if (extent == null) {
        return;
      }
      if (_done.length >= _kMaxRemembered) {
        _done.clear();
      }
      _done[job.key] = (job.revision, job.width);
      _onMeasured(job, extent);
    } on Object catch (error, stack) {
      // One row that cannot be measured must not stall the rest of the sweep.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'feed',
          context: ErrorDescription('measuring feed row ${job.key}'),
        ),
      );
    }
  }
}
