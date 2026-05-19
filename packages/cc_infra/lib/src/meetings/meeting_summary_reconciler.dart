import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Keeps meetings from getting stuck in a non-terminal state.
///
/// A meeting is non-terminal while `recording` (capture in progress) or
/// `processing` (the `meeting_summary` pipeline is augmenting its notes). Both
/// can be stranded by a crash, an app kill, or a stopped pipeline, and the UI
/// shows the same "transcribing & summarizing" tag for each — so a stranded
/// meeting reads as "stuck forever". This reconciler drives every meeting to a
/// terminal state.
///
/// It is also the meeting's single `processing → done` finalizer: none of the
/// `meeting_summary` persist steps flip the meeting to `done` themselves (so a
/// single parallel-step failure can't strand a half-written meeting that's
/// already marked done). Instead, on the run's terminal event
/// (PipelineRunCompleted, Failed, OR Cancelled) it checks the meeting and, if
/// still `processing`, finalizes it to `done` — falling back to the raw
/// transcript as the notes when the agent produced none, so the recording is
/// never lost.
///
/// A startup sweep ([_reconcileStale]) catches meetings stranded by a previous
/// session:
/// - `recording`: no capture survives an app restart, so the recording was
///   interrupted before `stop()` ran. Recovered exactly as a graceful stop
///   would — summarize a real transcript, else finalize to `done`.
/// - `processing`: finalized to `done` unless a summary run is still active (a
///   live run finalizes it via its terminal event instead).
///
/// Pure Dart (logs through [CcInfraLog]): runs in the desktop in-process host
/// and in the headless `cc_server`, which both own the meeting + pipeline-run
/// DAOs directly.
class MeetingSummaryReconciler {
  /// Creates a [MeetingSummaryReconciler].
  MeetingSummaryReconciler({
    required this.eventBus,
    required this.runRepository,
    required this.meetingRepository,
  });

  /// The template id whose runs this reconciler reacts to.
  static const String templateId = 'meeting_summary';

  /// Bus carrying [PipelineRunCompleted] / [PipelineRunFailed].
  final DomainEventBus eventBus;

  /// Used to recover the run's trigger payload (the meeting id).
  final PipelineRunRepository runRepository;

  /// The meeting store to finalize.
  final MeetingRepository meetingRepository;

  StreamSubscription<DomainEvent>? _sub;

  /// Starts listening, and sweeps any meetings stranded in a non-terminal state
  /// by a previous session (a crash mid-recording, or a summary run that never
  /// started / never finalized — e.g. a disabled trigger/template, an app crash
  /// mid-summary, or a stopped pipeline).
  void start() {
    _sub = eventBus.on<DomainEvent>().listen(_onEvent);
    unawaited(_reconcileStale());
  }

  /// One-shot startup sweep over every non-terminal meeting (see
  /// [MeetingRepository.getUnfinalized]):
  /// - `recording`: no capture survives an app restart, so the recording was
  ///   interrupted before `stop()` ran — recover it like a graceful stop.
  /// - `processing`: finalize unless a summary run is still active (an active
  ///   run finalizes it on its terminal event instead). Mirrors the per-run
  ///   path's transcript fallback.
  Future<void> _reconcileStale() async {
    try {
      final stuck = await meetingRepository.getUnfinalized();
      for (final meeting in stuck) {
        switch (meeting.status) {
          case MeetingStatus.recording:
            await _recoverStrandedRecording(meeting);
          case MeetingStatus.processing:
            final active = await runRepository.activeForDedupKey(
              templateId: templateId,
              workspaceId: meeting.workspaceId,
              dedupKey: meeting.id,
            );
            if (active != null) {
              continue; // A live run will finalize it via _onEvent.
            }
            await _finalize(meeting);
          case MeetingStatus.done:
          case MeetingStatus.failed:
            break; // Terminal — not returned by getUnfinalized; defensive.
        }
      }
    } on Object catch (e, st) {
      CcInfraLog.error(
        'MeetingSummaryReconciler: startup reconcile failed',
        e,
        st,
      );
    }
  }

  /// Recovers a meeting stranded in `recording` by a crash/kill before `stop()`
  /// ran. Mirrors `MeetingRecorderController.stop()`: with a real transcript,
  /// move it to `processing` and re-announce [MeetingRecordingStopped] so the
  /// summary pipeline runs (the reconciler then finalizes it normally); with
  /// nothing captured, finalize straight to `done`. Sets `endedAt` if it was
  /// never recorded (the crash skipped it).
  Future<void> _recoverStrandedRecording(Meeting meeting) async {
    final segments =
        await meetingRepository.getSegments(meeting.workspaceId, meeting.id);
    final transcript = formatMeetingTranscript(segments);
    final now = DateTime.now();

    if (transcript.isEmpty) {
      await meetingRepository.upsert(
        meeting.copyWith(
          status: MeetingStatus.done,
          endedAt: meeting.endedAt ?? now,
          updatedAt: now,
        ),
      );
      return;
    }

    await meetingRepository.upsert(
      meeting.copyWith(
        status: MeetingStatus.processing,
        endedAt: meeting.endedAt ?? now,
        updatedAt: now,
      ),
    );
    eventBus.publish(
      MeetingRecordingStopped(
        workspaceId: meeting.workspaceId,
        meetingId: meeting.id,
        title: meeting.title,
        userNotes: meeting.userNotes,
        transcript: transcript,
        occurredAt: now,
        // Reproduce the template snapshotted when the meeting was recorded.
        summaryInstructions: meeting.summaryInstructions,
      ),
    );
  }

  Future<void> _onEvent(DomainEvent event) async {
    final String runId;
    if (event is PipelineRunCompleted) {
      if (event.templateId != templateId) {
        return;
      }
      runId = event.pipelineRunId;
    } else if (event is PipelineRunFailed) {
      if (event.templateId != templateId) {
        return;
      }
      runId = event.pipelineRunId;
    } else if (event is PipelineRunCancelled) {
      if (event.templateId != templateId) {
        return;
      }
      runId = event.pipelineRunId;
    } else {
      return;
    }

    try {
      final run = await runRepository.getRun(runId);
      if (run == null) {
        return;
      }
      final meetingId = run.triggerPayload?['meetingId'] as String?;
      if (meetingId == null) {
        return;
      }
      final meeting = await meetingRepository.getById(run.workspaceId, meetingId);
      if (meeting == null || meeting.status != MeetingStatus.processing) {
        // Already finalized (the saveNotes step ran), or gone.
        return;
      }
      await _finalize(meeting);
    } on Object catch (e, st) {
      CcInfraLog.error('MeetingSummaryReconciler: reconcile failed', e, st);
    }
  }

  /// Finalizes a stuck-`processing` [meeting] to `done`, keeping the transcript
  /// as the notes fallback when the agent never produced enhanced notes (so the
  /// recording is never lost). `copyWith(enhancedNotes: null)` leaves existing
  /// notes untouched.
  Future<void> _finalize(Meeting meeting) async {
    String? fallback;
    if (!meeting.isEnhanced) {
      final segments =
          await meetingRepository.getSegments(meeting.workspaceId, meeting.id);
      final transcript = formatMeetingTranscript(segments);
      fallback = transcript.isEmpty ? null : transcript;
    }
    final finalized = meeting.copyWith(
      status: MeetingStatus.done,
      enhancedNotes: fallback,
      updatedAt: DateTime.now(),
    );
    await meetingRepository.upsert(finalized);
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
