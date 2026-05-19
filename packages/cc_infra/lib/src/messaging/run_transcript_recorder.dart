import 'dart:async';

import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';

/// Opens per-run transcript recordings.
///
/// A subagent run has no space message of its own, so its activity has nowhere
/// to live: the child loop's events used to be flattened into debug strings on
/// the parent's stream and dropped from transcripts. A recording folds those
/// events into real segments, streams them live under the CHILD run id (the same
/// [ActiveStreamRegistry] a parent turn uses, so the existing relay and client
/// renderers work unchanged) and throttle-flushes them for replay.
class RunTranscriptRecorder {
  /// Creates a [RunTranscriptRecorder].
  ///
  /// [repo] is optional: without it a run still streams live but nothing is
  /// persisted, so reopening it later shows "no activity recorded".
  RunTranscriptRecorder({
    required ActiveStreamRegistry registry,
    RunTranscriptRepository? repo,
    void Function(String message)? onWarn,
  }) : _registry = registry,
       _repo = repo,
       _onWarn = onWarn;

  final ActiveStreamRegistry _registry;
  final RunTranscriptRepository? _repo;
  final void Function(String message)? _onWarn;

  /// Opens a recording for [runId].
  ///
  /// Returns null when [workspaceId] is empty: an unscoped run could be neither
  /// persisted nor served without breaking the workspace-isolation invariant, so
  /// it is not recorded at all rather than recorded unreachably.
  RunTranscriptRecording? begin({
    required String runId,
    required String workspaceId,
    required DateTime startedAt,
  }) {
    if (runId.isEmpty || workspaceId.isEmpty) {
      _onWarn?.call(
        'run transcript not recorded for run "$runId": no workspace to scope it '
        'to (its activity tab will read as unrecorded)',
      );
      return null;
    }
    return RunTranscriptRecording._(
      runId: runId,
      workspaceId: workspaceId,
      startedAt: startedAt,
      registry: _registry,
      repo: _repo,
      onWarn: _onWarn,
    );
  }
}

/// One run's in-flight transcript recording. Created by
/// [RunTranscriptRecorder.begin].
class RunTranscriptRecording {
  RunTranscriptRecording._({
    required this.runId,
    required this.workspaceId,
    required this.startedAt,
    required ActiveStreamRegistry registry,
    required RunTranscriptRepository? repo,
    void Function(String message)? onWarn,
  }) : _registry = registry,
       _repo = repo,
       _onWarn = onWarn {
    _folder = TranscriptFolder(
      onUpdate: (update, {required structural}) {
        _registry.apply(runId, update);
        _markDirty(structural: structural);
      },
    );
    // Register synchronously so a subscription opened the instant the run row
    // appears finds a live stream rather than an empty replay.
    _registry.register(runId);
  }

  /// The run being recorded.
  final String runId;

  /// Owning workspace — the isolation boundary for the persisted row.
  final String workspaceId;

  /// When the recording started.
  final DateTime startedAt;

  final ActiveStreamRegistry _registry;
  final RunTranscriptRepository? _repo;
  final void Function(String message)? _onWarn;
  late final TranscriptFolder _folder;

  Timer? _flushTimer;
  bool _dirty = false;
  DateTime? _dirtySince;
  bool _finished = false;

  /// The segments folded so far, fully materialized.
  List<TranscriptSegment> get segments => _folder.snapshot();

  /// Folds one event into the run's transcript.
  ///
  /// Ignores [UsageEvent] / [DebugEvent] / [DoneEvent] the same way a space
  /// turn does — cost is accounted on the run log, diagnostics live in the
  /// NDJSON log and completion is signalled by [finish].
  void add(AgentProcessEvent event) {
    if (_finished) {
      return;
    }
    _folder.add(event);
  }

  /// Closes the recording: drains open segments, marks still-running tools
  /// interrupted, reports the terminal frame, writes the final row and releases
  /// the live stream.
  ///
  /// Idempotent and safe to call from a `finally` — a cancelled or crashed run
  /// must still leave a readable transcript.
  Future<void> finish(TurnOutcome outcome) async {
    if (_finished) {
      return;
    }
    _finished = true;
    _flushTimer?.cancel();
    _flushTimer = null;

    final now = DateTime.now();
    _folder.closeOpenText(now);
    _folder.interruptRunningTools(now);

    await _write(now: now, outcome: outcome, complete: true);

    _registry.apply(runId, TurnFinished(_folder.length - 1, outcome));
    await _registry.unregister(runId);
  }

  void _markDirty({required bool structural}) {
    _dirty = true;
    final now = DateTime.now();
    _dirtySince ??= now;
    if (structural) {
      // Max-latency guard: a tool-heavy run re-arms the trailing debounce
      // continuously; force a flush once staleness exceeds the bound.
      if (now.difference(_dirtySince!) >= kStructuralFlushMaxLatency) {
        _flushTimer?.cancel();
        _flushTimer = null;
        unawaited(_flush());
        return;
      }
      _flushTimer?.cancel();
      _flushTimer = Timer(kStructuralFlushDelay, () {
        _flushTimer = null;
        unawaited(_flush());
      });
    } else {
      _flushTimer ??= Timer(kDeltaFlushInterval, () {
        _flushTimer = null;
        unawaited(_flush());
      });
    }
  }

  Future<void> _flush() async {
    if (!_dirty || _finished) {
      return;
    }
    await _write(now: DateTime.now(), complete: false);
  }

  Future<void> _write({
    required DateTime now,
    required bool complete,
    TurnOutcome? outcome,
  }) async {
    final repo = _repo;
    if (repo == null) {
      _dirty = false;
      _dirtySince = null;
      return;
    }
    _dirty = false;
    _dirtySince = null;
    try {
      await repo.upsert(
        runId: runId,
        workspaceId: workspaceId,
        segmentsJson: _folder.encodeForFlush(),
        transcriptChars: _folder.transcriptChars,
        startedAt: startedAt,
        updatedAt: now,
        outcome: outcome,
        complete: complete,
      );
    } catch (e) {
      // Never fail the run over a transcript write — but never swallow it
      // either. A failed write means the run streams live and then reads as
      // "no activity recorded" once the tab is reopened, which is invisible
      // without this line.
      _onWarn?.call(
        'failed to persist transcript for run "$runId" '
        '(complete: $complete): $e',
      );
    }
  }
}
