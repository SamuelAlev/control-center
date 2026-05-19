// VM-only meeting providers (server/desktop-execution half of
// `meeting_providers.dart`).
//
// Meeting RECORDING + post-processing is a desktop capability: native AEC
// (cc_natives), the windowed Whisper transcription service (cc_infra/cc_natives),
// the coverage repairer, and the Dao-backed summary reconciler. None of it
// exists on a web thin client, so these providers/helpers live here — used by
// the desktop bootstrap and the (desktop-only) meeting recorder controller,
// never reached from the web graph. The web-safe meeting UI providers (meeting
// / segment / action-item / decision streams over RPC, playback state, audio
// clip loader) stay in `meeting_providers.dart`.
library;

import 'package:cc_domain/features/meetings/domain/services/meeting_transcription_port.dart';
import 'package:cc_domain/features/meetings/domain/services/mic_echo_canceller.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/src/meetings/meeting_summary_reconciler.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/meetings/data/services/aec_mic_filter.dart';
import 'package:control_center/features/meetings/data/services/meeting_coverage_repairer.dart';
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

/// Finalizes meetings when their `meeting_summary` pipeline run ends without
/// the agent persisting notes (the safety net for stuck `processing`).
final meetingSummaryReconcilerProvider =
    Provider<MeetingSummaryReconciler>((ref) {
  return MeetingSummaryReconciler(
    eventBus: ref.watch(domainEventBusProvider),
    // Server-side reconciler: own the DB directly (dao*), NOT the active-
    // workspace-bound RPC path — this finalizes runs across workspaces.
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
    meetingRepository: ref.watch(meetingRepositoryProvider),
  );
});

/// Post-meeting transcript coverage repair (#13) — re-decodes speech the live
/// rolling-window transcriber missed, run from the recorder at stop.
final meetingCoverageRepairerProvider = Provider<MeetingCoverageRepairer>((ref) {
  return MeetingCoverageRepairer(ref.watch(meetingRepositoryProvider));
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

/// Creates a [MeetingTranscriptionPort] from a ready [transcriber].
///
/// Callers must resolve and null-check the transcriber first (the recorder
/// fails with "voice model not installed" before reaching here), so this always
/// returns a live service. Returns the domain port so the recorder controller
/// (presentation) never names the data-layer implementation.
///
/// When [vadModelPath] is non-null the per-channel speech gate uses Silero VAD
/// **AND** the RMS energy floor; otherwise it is the RMS gate alone.
///
/// Silero is energy-agnostic — on its own it would re-decode the quiet far-end
/// echo residual that AEC3 attenuates but doesn't fully remove (which the energy
/// gate used to drop), bleeding the remote speakers into the "me" transcript.
/// Pairing it with the RMS floor keeps Silero's anti-hallucination benefit while
/// still gating out that residual.
MeetingTranscriptionPort meetingTranscriptionService(
  SpeechTranscriber transcriber, {
  String? vadModelPath,
}) {
  return MeetingTranscriptionService(
    transcriber,
    detectorFactory: vadModelPath == null
        ? null
        : () => AndSpeechActivityDetector([
              SileroVadDetector.create(modelPath: vadModelPath),
              const RmsSpeechActivityDetector(),
            ]),
  );
}

/// Builds the meeting recorder's signal-level mic echo canceller, returning the
/// domain [MicEchoCanceller] port so the recorder controller never names the
/// data-layer implementation. A null [processor] (no native AEC) yields an
/// identity passthrough; the cross-platform text echo filter remains the
/// backstop either way.
MicEchoCanceller makeMicEchoCanceller({
  AecEngine? processor,
  int Function()? clockNow,
  void Function(String message)? log,
}) {
  return AecMicFilter(processor: processor, clockNow: clockNow, log: log);
}
