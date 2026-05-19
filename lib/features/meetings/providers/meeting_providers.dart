import 'package:control_center/core/infrastructure/audio/aec/aec_processor.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/data/services/meeting_summary_reconciler.dart';
import 'package:control_center/features/meetings/data/services/meeting_transcription_service.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Factory for a fresh native AEC processor. WebRTC AEC3's handle is stateful,
/// so one is created per recording and disposed at stop. Returns null when the
/// native AEC library is unavailable (Windows/Linux until built, or a load
/// failure) — the recorder then passes the mic through unchanged and the text
/// `MeetingEchoFilter` remains the echo defense.
final aecProcessorFactoryProvider = Provider<AecProcessor? Function()>((ref) {
  return () =>
      AecProcessor.tryCreate(explicitPaths: aecFfiDylibCandidatePaths());
});

/// Streams all meetings for a workspace, newest first.
final meetingsProvider =
    StreamProvider.family<List<Meeting>, String>((ref, workspaceId) {
  return ref.watch(meetingRepositoryProvider).watchByWorkspace(workspaceId);
});

/// Identifies a single meeting within a workspace.
typedef MeetingRef = ({String workspaceId, String meetingId});

/// Streams a single meeting reactively (derived from the workspace stream,
/// since the repository exposes a reactive list but a one-shot get-by-id).
final meetingDetailProvider =
    StreamProvider.family<Meeting?, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchByWorkspace(args.workspaceId)
      .map((meetings) {
    for (final m in meetings) {
      if (m.id == args.meetingId) {
        return m;
      }
    }
    return null;
  });
});

/// Streams transcript segments for a meeting, oldest first.
final meetingSegmentsProvider =
    StreamProvider.family<List<MeetingSegment>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchSegments(args.workspaceId, args.meetingId);
});

/// Streams a meeting's diarized speakers (DB-backed). Populated by the
/// `meeting.diarize` pipeline step; empty until/unless diarization has run.
final meetingSpeakersProvider =
    StreamProvider.family<List<MeetingSpeakerLabel>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchSpeakers(args.workspaceId, args.meetingId);
});

/// Streams a meeting's action items (DB-backed, in the agent's order).
final meetingActionItemsProvider =
    StreamProvider.family<List<MeetingActionItem>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchActionItems(args.workspaceId, args.meetingId);
});

/// Streams a meeting's decisions (DB-backed, in the agent's order).
final meetingDecisionsProvider =
    StreamProvider.family<List<MeetingDecision>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchDecisions(args.workspaceId, args.meetingId);
});

/// Streams per-meeting action-item counts (total + done) for a workspace,
/// keyed by meeting id. Powers the list signal pills + the stats strip.
final meetingActionItemStatsProvider = StreamProvider.family<
    Map<String, MeetingActionItemStats>, String>((ref, workspaceId) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchActionItemStats(workspaceId);
});

/// Streams per-meeting decision counts for a workspace, keyed by meeting id.
final meetingDecisionCountsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, workspaceId) {
  return ref.watch(meetingRepositoryProvider).watchDecisionCounts(workspaceId);
});

/// Finalizes meetings when their `meeting_summary` pipeline run ends without
/// the agent persisting notes (the safety net for stuck `processing`).
final meetingSummaryReconcilerProvider =
    Provider<MeetingSummaryReconciler>((ref) {
  return MeetingSummaryReconciler(
    eventBus: ref.watch(domainEventBusProvider),
    runRepository: ref.watch(pipelineRunRepositoryProvider),
    meetingRepository: ref.watch(meetingRepositoryProvider),
  );
});

/// Keep-alive notifier that starts the [MeetingSummaryReconciler].
class MeetingSummaryReconcilerNotifier extends Notifier<void> {
  @override
  void build() {
    final reconciler = ref.watch(meetingSummaryReconcilerProvider);
    reconciler.start();
    ref.onDispose(reconciler.dispose);
  }
}

/// Keeps the meeting-summary reconciler alive across the app lifetime.
final meetingSummaryReconcilerAliveProvider =
    NotifierProvider<MeetingSummaryReconcilerNotifier, void>(
  MeetingSummaryReconcilerNotifier.new,
);

/// Creates a [MeetingTranscriptionService] from a ready [transcriber].
///
/// Callers must resolve and null-check the transcriber first (the recorder
/// fails with "voice model not installed" before reaching here), so this always
/// returns a live service.
MeetingTranscriptionService meetingTranscriptionService(
  SpeechTranscriber transcriber,
) {
  return MeetingTranscriptionService(transcriber);
}
