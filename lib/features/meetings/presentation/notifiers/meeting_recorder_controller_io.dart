import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/system_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_mic_health.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:cc_domain/features/meetings/domain/services/mic_echo_canceller.dart';
import 'package:cc_natives/cc_natives.dart' show AecEngine, AecProcessor;
import 'package:control_center/core/infrastructure/power/background_activity_guard.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/di/server_providers.dart'
    show systemAudioCapturePortProvider;
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/providers/meeting_server_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_template_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Desktop meeting recorder — a NATIVE-capture thin client over RPC.
///
/// The desktop opens no database: it captures the microphone + system-output
/// audio natively (a capability the headless `cc_server` cannot reach), but the
/// transcription, echo de-duplication, persistence, and summary pipeline all run
/// on the connected `cc_server`. So this controller is the desktop sibling of the
/// web recorder (`meeting_recorder_controller_web.dart`): it streams 16 kHz mono
/// PCM16 frames for the `me` (mic) and `them` (system) channels to the host via
/// [MeetingRecordingControlPort] (`meeting.startRecording` → `ingestAudio` →
/// `stopRecording`), and the host appends segments this client watches over
/// `meeting.watchSegments`. The data edits the meeting screens drive (notes,
/// title, action-item / decision CRUD) route through the RPC-backed
/// `MeetingRepository` — never the DB-backed `dao*` one.
///
/// The desktop keeps two native niceties the host can't do for it, both pure
/// stream/state work with no database: signal-level acoustic echo cancellation
/// (the host only runs the cross-platform text echo filter) and the live
/// input-level meter + dead-mic warning. App Nap is held off for the recording
/// so capture delivery never stalls while the user is in their meeting app.
class MeetingRecorderController extends Notifier<MeetingRecorderState> {
  static const _uuid = Uuid();

  // All OS audio processing is OFF. On macOS, enabling EITHER `echoCancel` or
  // `autoGain` switches the mic to Voice Processing I/O (AUVoiceIO), and in this
  // record_macos build VPIO is fatal here: it (a) produced a dead mic — every
  // window logged "peak 0%" — and (b) reconfigured and ducked the output device
  // the system-audio process tap clocks, so the tap emitted 0 frames. Both
  // capture channels went dead. So echo cancellation is NOT done at the audio
  // source: the signal-level AEC below (when the native library is available)
  // subtracts the system loopback from the mic, and the host's cross-platform
  // text echo filter is the backstop on every platform.
  static const _micConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  /// Normalized peak (0–1) above which a frame counts as audio activity. Used to
  /// keep `lastSegmentAt` fresh for auto-detection — with transcription now
  /// host-side the client no longer commits segments, so raw audio level is the
  /// "speech is still happening" proxy.
  static const _activityThreshold = 0.02;

  /// Minimum gap (ms) between `lastSegmentAt` bumps, so the activity proxy does
  /// not rebuild the recorder UI on every audio chunk.
  static const _activityBumpIntervalMs = 500;

  /// Sort-order base for user-added action items / decisions — reserved high so
  /// user rows sort after the agent-extracted ones even after a re-run.
  static const _manualSortBase = 1000000;

  AudioRecorder? _mic;
  SystemAudioCapturePort? _system;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Uint8List>? _systemSub;

  // Per-channel sequence + serial send chain: each ingest awaits the previous on
  // the same channel so frames reach the host in capture order (the client
  // applies natural backpressure rather than racing concurrent RPC calls).
  int _micSeq = 0;
  int _systemSeq = 0;
  Future<void> _micChain = Future<void>.value();
  Future<void> _systemChain = Future<void>.value();

  /// Single clock shared by both channels — the only timeline on which a `me`
  /// and a `them` frame are comparable. The signal-level AEC cross-correlates the
  /// two streams against it to auto-measure this session's loopback↔mic delay.
  Stopwatch? _clock;

  /// Signal-level acoustic echo canceller (remote mode only): subtracts the
  /// system loopback (far-end reference) from the mic before it is streamed, so
  /// the remote's speaker bleed never reaches the host transcriber. A no-op
  /// passthrough when the native AEC library is unavailable.
  MicEchoCanceller? _aec;

  /// Live mic/system statistics — drives the input-level meter + dead-mic
  /// warning.
  final MeetingMicHealthTracker _micHealth = MeetingMicHealthTracker();

  /// Throttles input-level pushes (~8 Hz) so the meter is smooth.
  int _lastLevelPushMs = 0;

  /// Throttles `lastSegmentAt` activity bumps.
  int _lastSegmentBumpMs = 0;

  /// Held for the recording so the OS does not throttle the app (macOS App Nap)
  /// while its window is unfocused — otherwise captured audio buffers and only
  /// streams in a burst when focus returns. Captured at start so teardown can
  /// release it without touching `ref` during disposal.
  BackgroundActivityGuard? _activityGuard;

  String? _workspaceId;
  String? _meetingId;

  @override
  MeetingRecorderState build() {
    ref.onDispose(() {
      unawaited(_teardownCaptures());
    });
    return MeetingRecorderState.idle;
  }

  /// Starts a new recording. [sourceId] selects the system-audio source
  /// (null = the full system mixdown). [mode] selects remote (mic + system
  /// capture) vs in-person (mic only).
  ///
  /// Capture starts natively first (so a denied mic / system permission fails
  /// before a host meeting is created), then the host session is opened (the
  /// server mints the meeting id), then both channels stream to the host.
  Future<void> start({
    String? title,
    String? sourceId,
    MeetingMode mode = MeetingMode.remote,
  }) async {
    if (!state.isIdle) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      state = MeetingRecorderState.failed('No active workspace.');
      return;
    }
    final control = ref.read(meetingRecordingControlProvider);

    try {
      // Microphone ("me").
      final mic = AudioRecorder();
      if (!await mic.hasPermission()) {
        state = MeetingRecorderState.failed('Microphone permission denied.');
        await mic.dispose();
        return;
      }

      // System output ("them") — only in remote mode. In-person meetings use a
      // single shared mic, so there is no system channel to capture.
      final captureSystem = mode == MeetingMode.remote;
      SystemAudioCapturePort? system;
      if (captureSystem) {
        final s = ref.read(systemAudioCapturePortProvider);
        if (!await s.requestPermission()) {
          state = MeetingRecorderState.failed(
            'System-audio capture permission denied.',
          );
          await mic.dispose();
          return;
        }
        system = s;
      }

      // Open the host recording session (the server mints the meeting id). Fails
      // loudly when the connected server has no ASR model installed (the
      // `meeting.*` recording ops are absent) rather than recording into a void.
      final String meetingId;
      try {
        meetingId = await control.startRecording(
          title: (title ?? '').trim(),
          mode: mode.name,
        );
      } catch (e) {
        await mic.dispose();
        state = MeetingRecorderState.failed(
          'Could not start recording on the host: $e',
        );
        return;
      }

      _workspaceId = workspaceId;
      _meetingId = meetingId;
      _mic = mic;
      _system = system;
      _micSeq = 0;
      _systemSeq = 0;
      _micChain = Future<void>.value();
      _systemChain = Future<void>.value();
      _lastLevelPushMs = 0;
      _lastSegmentBumpMs = 0;
      _micHealth.reset();

      // Keep the app fully active for the whole recording (macOS App Nap would
      // otherwise stall capture delivery while we are unfocused).
      _activityGuard = ref.read(backgroundActivityGuardProvider);
      unawaited(_activityGuard?.begin('Recording and transcribing a meeting'));

      // Shared clock for the signal-level AEC cross-correlation.
      final clock = Stopwatch()..start();
      _clock = clock;

      // Signal-level AEC, remote mode only (needs the loopback as far-end
      // reference). A null engine → identity passthrough; the host text echo
      // filter remains the backstop.
      final AecEngine? aecEngine =
          captureSystem ? ref.read(aecProcessorFactoryProvider)() : null;
      _aec = makeMicEchoCanceller(
        processor: aecEngine,
        clockNow: () => clock.elapsedMilliseconds,
        log: (m) => AppLog.i('MeetingCapture', m),
      );
      AppLog.i(
        'MeetingCapture',
        aecEngine is AecProcessor
            ? 'AEC enabled (AEC3 ${aecEngine.version})'
            : 'AEC unavailable — host echo filter only',
      );

      // mic → log/health on the RAW input (so dead-mic detection sees the true
      // signal) → AEC clean → stream the cleaned mic as `me`.
      final micRaw = _logFrames(await mic.startStream(_micConfig), 'mic/me');
      final micClean = _aec?.cleanMic(micRaw) ?? micRaw;
      _micSub = micClean.listen(
        (pcm) => _ingest(control, meetingId, channel: 'me', pcm: pcm),
        onError: (Object e, StackTrace s) =>
            AppLog.w('MeetingRecorder', 'mic stream error: $e'),
      );

      if (captureSystem && system != null) {
        // loopback → log/health + AEC far-end reference (re-emitted unchanged
        // for `them`) → stream as `them`.
        final systemRaw = _logFrames(
          system.capture(sourceId: sourceId),
          'system/them',
          isSystem: true,
        );
        final systemStream = _aec?.referenceTap(systemRaw) ?? systemRaw;
        _systemSub = systemStream.listen(
          (pcm) => _ingest(control, meetingId, channel: 'them', pcm: pcm),
          onError: (Object e, StackTrace s) =>
              AppLog.w('MeetingRecorder', 'system stream error: $e'),
        );
      }

      state = MeetingRecorderState.recording(meetingId, DateTime.now());
    } catch (e, s) {
      AppLog.e('MeetingRecorder', 'start failed: $e', e, s);
      await _teardownCaptures();
      // Discard the half-opened host session + its empty meeting row so a failed
      // start doesn't leave a stranded `recording` meeting. Best-effort.
      final strandedId = _meetingId;
      final strandedWorkspaceId = _workspaceId;
      if (strandedId != null) {
        try {
          await control.stopRecording(meetingId: strandedId);
        } on Object catch (_) {}
        if (strandedWorkspaceId != null) {
          try {
            await ref
                .read(meetingRepositoryProvider)
                .delete(strandedWorkspaceId, strandedId);
          } on Object catch (_) {}
        }
      }
      _meetingId = null;
      _workspaceId = null;
      state = MeetingRecorderState.failed('Failed to start recording: $e');
    }
  }

  /// Stops capture, drains pending sends, and tells the host to finalize (which
  /// fires the `meeting_summary` pipeline). Returns the recorder to idle.
  ///
  /// The active meeting-note template's instructions are pinned onto the stop so
  /// a later "Re-run summary" reproduces this template even if the user switches
  /// it afterwards — summarization itself runs entirely host-side.
  Future<void> stop() async {
    if (!state.isRecording) {
      return;
    }
    final meetingId = _meetingId;
    await _teardownCaptures();
    // Let any in-flight ingests land before the host drains the transcript.
    await _micChain.catchError((Object _) {});
    await _systemChain.catchError((Object _) {});
    if (meetingId != null) {
      try {
        await ref.read(meetingRecordingControlProvider).stopRecording(
              meetingId: meetingId,
              summaryInstructions:
                  ref.read(activeMeetingTemplateProvider).instructions,
            );
      } catch (e) {
        AppLog.w('MeetingRecorder', 'stopRecording failed: $e');
      }
    }
    _meetingId = null;
    _workspaceId = null;
    state = MeetingRecorderState.idle;
  }

  /// Toggles pause on the active recording. While paused, captured frames are
  /// dropped (not sent to the host) and the elapsed timer is frozen.
  void togglePause() {
    if (!state.isRecording) {
      return;
    }
    if (state.paused) {
      final since = state.pausedSince;
      final extra =
          since != null ? DateTime.now().difference(since) : Duration.zero;
      state = state.copyWith(
        paused: false,
        pausedTotal: state.pausedTotal + extra,
        clearPausedSince: true,
      );
    } else {
      state = state.copyWith(
        paused: true,
        pausedSince: DateTime.now(),
        inputLevel: 0,
      );
    }
  }

  /// Re-runs the `meeting_summary` pipeline for a finished meeting from its
  /// CURRENT notes + transcript — the manual "Re-run summary" path. Drives the
  /// host's pipeline engine over RPC; its `meeting.saveNotes` step finalizes the
  /// meeting (the recorder no longer writes the meeting row — the host owns
  /// recorder writes).
  Future<void> resummarize(String meetingId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    final meeting = await repo.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    final segments = await repo.getSegments(workspaceId, meetingId);
    final transcript = formatMeetingTranscript(segments);
    if (transcript.isEmpty) {
      return;
    }

    // A summary run for this meeting may already be in flight (the automatic run
    // from stop(), or a prior re-run). If so, do nothing: re-triggering would
    // dedup to null.
    final active =
        await ref.read(pipelineRunRepositoryProvider).activeForDedupKey(
              templateId: 'meeting_summary',
              workspaceId: workspaceId,
              dedupKey: meetingId,
            );
    if (active != null) {
      return;
    }

    await ref.read(pipelineEngineProvider).start(
      'meeting_summary',
      workspaceId: workspaceId,
      triggerEventType: 'manual',
      triggerPayload: {
        'workspaceId': workspaceId,
        'meetingId': meetingId,
        'title': meeting.title,
        'userNotes': meeting.userNotes,
        'transcript': transcript,
        // Reproduce the template captured when the meeting was recorded; fall
        // back to the current active template for meetings recorded before the
        // snapshot existed (null summaryInstructions).
        'summaryInstructions': meeting.summaryInstructions ??
            ref.read(activeMeetingTemplateProvider).instructions,
      },
      dedupKey: meetingId,
    );
  }

  /// Cancels the in-flight `meeting_summary` run for [meetingId] — the manual
  /// "Stop" affordance on a processing meeting. Cancelling emits
  /// `PipelineRunCancelled`, which the host's `MeetingSummaryReconciler` turns
  /// into a `done` finalize (keeping the transcript as the fallback). When no run
  /// is live (already terminal / stranded) the host's startup reconciler is the
  /// backstop — the desktop no longer writes the meeting row directly.
  Future<void> cancelProcessing(String meetingId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final meeting =
        await ref.read(meetingRepositoryProvider).getById(workspaceId, meetingId);
    if (meeting == null || meeting.status != MeetingStatus.processing) {
      return;
    }
    final active =
        await ref.read(pipelineRunRepositoryProvider).activeForDedupKey(
              templateId: 'meeting_summary',
              workspaceId: workspaceId,
              dedupKey: meetingId,
            );
    if (active != null) {
      await ref.read(pipelineEngineProvider).cancel(active.id);
    }
  }

  /// Persists the user's live notes for [meetingId] over RPC.
  Future<void> updateNotes(String meetingId, String notes) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).updateNotes(
          workspaceId: workspaceId,
          meetingId: meetingId,
          notes: notes,
        );
  }

  /// Persists an edited [title] for [meetingId] over RPC.
  Future<void> updateTitle(String meetingId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).updateTitle(
          workspaceId: workspaceId,
          meetingId: meetingId,
          title: trimmed,
        );
  }

  /// Adds a user-authored action item to [meetingId] (marked `isManual`, so a
  /// later "Re-run summary" won't wipe it).
  Future<void> addActionItem(
    String meetingId, {
    required String content,
    String? owner,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    // Confirm the meeting belongs to this workspace before inserting (getById is
    // workspace-scoped, so a foreign id yields null).
    final meeting = await repo.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    await repo.addActionItem(
      MeetingActionItem(
        id: _uuid.v4(),
        meetingId: meetingId,
        workspaceId: workspaceId,
        content: text,
        owner: _nullIfBlank(owner),
        sortOrder: _manualSortBase,
        isManual: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Edits an action item's [content] + [owner]. Marks it `isManual` so a re-run
  /// won't overwrite the edit.
  Future<void> updateActionItem(
    String id, {
    required String content,
    String? owner,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).updateActionItem(
          workspaceId: workspaceId,
          id: id,
          content: text,
          owner: _nullIfBlank(owner),
        );
  }

  /// Deletes the action item [id].
  Future<void> deleteActionItem(String id) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).deleteActionItem(workspaceId, id);
  }

  /// Adds a user-authored decision to [meetingId] (marked `isManual`).
  Future<void> addDecision(
    String meetingId, {
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    final meeting = await repo.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    await repo.addDecision(
      MeetingDecision(
        id: _uuid.v4(),
        meetingId: meetingId,
        workspaceId: workspaceId,
        content: text,
        sortOrder: _manualSortBase,
        isManual: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Edits a decision's [content]. Marks it `isManual` so a re-run won't
  /// overwrite the edit.
  Future<void> updateDecision(
    String id, {
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).updateDecision(
          workspaceId: workspaceId,
          id: id,
          content: text,
        );
  }

  /// Deletes the decision [id].
  Future<void> deleteDecision(String id) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).deleteDecision(workspaceId, id);
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Sends one captured [pcm] frame to the host on [channel] (`me` = mic,
  /// `them` = system), serialized per channel. Dropped while paused or after the
  /// recording moved on.
  void _ingest(
    MeetingRecordingControlPort control,
    String meetingId, {
    required String channel,
    required Uint8List pcm,
  }) {
    if (state.paused || state.meetingId != meetingId) {
      return;
    }
    if (channel == 'me') {
      final seq = _micSeq++;
      _micChain = _micChain.then((_) {
        return control.ingestAudio(
          meetingId: meetingId,
          channel: 'me',
          seq: seq,
          pcm: pcm,
        );
      }).catchError((Object e) {
        AppLog.w('MeetingRecorder', 'mic ingest failed: $e');
      });
    } else {
      final seq = _systemSeq++;
      _systemChain = _systemChain.then((_) {
        return control.ingestAudio(
          meetingId: meetingId,
          channel: 'them',
          seq: seq,
          pcm: pcm,
        );
      }).catchError((Object e) {
        AppLog.w('MeetingRecorder', 'system ingest failed: $e');
      });
    }
  }

  /// Diagnostic passthrough: logs frame count + peak per [channel] ~every 2s of
  /// audio, feeds the mic-health tracker, pushes the throttled input-level meter
  /// (mic only), and keeps `lastSegmentAt` fresh from audio activity (the proxy
  /// for live transcription now that segments are committed host-side).
  Stream<Uint8List> _logFrames(
    Stream<Uint8List> source,
    String channel, {
    bool isSystem = false,
  }) {
    var frames = 0;
    var bytes = 0;
    var peak = 0;
    return source.map((chunk) {
      frames++;
      bytes += chunk.length;
      final view = ByteData.sublistView(chunk);
      var chunkPeak = 0;
      for (var i = 0; i + 1 < chunk.length; i += 32) {
        final s = view.getInt16(i, Endian.little).abs();
        if (s > chunkPeak) {
          chunkPeak = s;
        }
      }
      if (chunkPeak > peak) {
        peak = chunkPeak;
      }
      final nowMs = _clock?.elapsedMilliseconds ?? 0;
      final rms = MeetingMicHealthTracker.rmsOfPcm16(chunk);
      if (isSystem) {
        _micHealth.noteSystem(rms, nowMs);
      } else {
        _micHealth.noteMic(rms, nowMs);
      }

      // Audio-activity proxy: either channel showing speech-level audio keeps
      // the meeting "present" so auto-detection doesn't suggest auto-stop.
      if (state.isRecording &&
          !state.paused &&
          chunkPeak / 32768.0 > _activityThreshold &&
          nowMs - _lastSegmentBumpMs >= _activityBumpIntervalMs) {
        _lastSegmentBumpMs = nowMs;
        state = state.copyWith(lastSegmentAt: DateTime.now());
      }

      // Mic input-level meter + dead-mic warning (mic channel only, ~8 Hz).
      if (!isSystem && nowMs - _lastLevelPushMs >= 120) {
        _lastLevelPushMs = nowMs;
        final warning = _micHealth.micSilentWhileActive;
        if (state.isRecording &&
            (warning != state.micWarning ||
                (_micHealth.level - state.inputLevel).abs() > 0.02)) {
          state = state.copyWith(
            inputLevel: state.paused ? 0 : _micHealth.level,
            micWarning: warning,
          );
        }
      }

      if (bytes >= 16000 * 2 * 2) {
        // ~2s @ 16 kHz mono PCM16.
        AppLog.i(
          'MeetingCapture',
          '$channel: $frames frames / $bytes bytes, '
              'peak ${(peak / 32768 * 100).round()}%',
        );
        frames = 0;
        bytes = 0;
        peak = 0;
      }
      return chunk;
    });
  }

  /// Tears down the capture streams + native handles. Safe on the dispose path
  /// (uses the captured guard, not `ref`).
  Future<void> _teardownCaptures() async {
    final guard = _activityGuard;
    _activityGuard = null;
    unawaited(guard?.end());
    await _micSub?.cancel();
    _micSub = null;
    await _systemSub?.cancel();
    _systemSub = null;
    // Dispose the AEC after the capture subscriptions are cancelled (which cancel
    // its eager source subscriptions), so no block is in flight when the native
    // handle is freed.
    final aec = _aec;
    _aec = null;
    await aec?.dispose();
    _clock?.stop();
    _clock = null;
    try {
      await _mic?.stop();
    } catch (_) {}
    await _mic?.dispose();
    _mic = null;
    try {
      await _system?.stop();
    } catch (_) {}
    _system = null;
  }
}

/// Controls the active meeting recording.
final meetingRecorderControllerProvider =
    NotifierProvider<MeetingRecorderController, MeetingRecorderState>(
  MeetingRecorderController.new,
);
