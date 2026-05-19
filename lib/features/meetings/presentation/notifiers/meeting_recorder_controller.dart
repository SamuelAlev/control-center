import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/domain/events/meeting_events.dart';
import 'package:control_center/core/domain/ports/system_audio_capture_port.dart';
import 'package:control_center/core/infrastructure/audio/wav_io.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_providers.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/data/services/aec_mic_filter.dart';
import 'package:control_center/features/meetings/data/services/meeting_echo_filter.dart';
import 'package:control_center/features/meetings/data/services/meeting_transcription_service.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Controls a single meeting recording: starts the microphone + system-output
/// capture and transcribes both channels live into the DB (tagged me/them). On
/// stop it publishes [MeetingRecordingStopped], which the built-in
/// `meeting_summary` pipeline picks up to augment the user's notes — the
/// recorder itself stays decoupled from the summarization engine.
class MeetingRecorderController extends Notifier<MeetingRecorderState> {
  static const _uuid = Uuid();
  // All OS audio processing is OFF. On macOS, enabling EITHER `echoCancel` or
  // `autoGain` switches the mic to Voice Processing I/O (AUVoiceIO), and in this
  // record_macos build VPIO is fatal here: it (a) produced a dead mic — every
  // window logged "peak 0%" and Whisper saw only silence — and (b) reconfigured
  // and ducked the output device the system-audio process tap clocks, so the tap
  // emitted 0 frames ("io_no_output / bufferListNoCopy returned nil") and the
  // meeting playback was ducked system-wide. Both capture channels went dead.
  //
  // So echo de-duplication is NOT done at the audio source. The mic does pick up
  // the remote participants playing out of the speakers — that bleed is otherwise
  // transcribed as a degraded "me" duplicate of every "them" line — but the
  // cross-platform MeetingEchoFilter removes those duplicate "me" windows
  // downstream (text containment, no audio processing, works on every platform).
  // noiseSuppress stays off too (also VPIO/macOS-unsupported). Non-speech windows
  // are dropped by MeetingTranscriptionService.isNonSpeechArtifact.
  static const _micConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  /// Kill-switch for the cross-platform echo de-duplicator. Echo cancellation
  /// is NOT done at the audio source (macOS VPIO killed both capture channels —
  /// see [_micConfig]), so this filter is the sole mechanism that removes the
  /// duplicate "me" windows produced by speaker bleed, on every platform. Flip
  /// to false to restore direct, unfiltered persistence.
  static const _echoFilterEnabled = true;

  /// System-channel peak (normalized 0–1) above which the remote is considered
  /// to be actively playing. Fed to [MeetingEchoFilter.noteSystemActivity] so a
  /// concurrent "me" window can be flagged as possible bleed and held longer.
  /// The loopback is clean (it never captures the mic), so this cleanly
  /// separates remote speech (logged at 30–60%) from silence (~0%).
  static const _systemActivityThreshold = 0.03;

  AudioRecorder? _mic;
  SystemAudioCapturePort? _system;
  StreamSubscription<TranscribedWindow>? _micTx;
  StreamSubscription<TranscribedWindow>? _systemTx;

  /// Single clock shared by both channels — the only timeline on which a "me"
  /// window and a "them" window are comparable (their per-channel byte offsets
  /// are not). Started at recording start, stamped onto each emitted window.
  Stopwatch? _clock;
  MeetingEchoFilter? _echoFilter;

  /// Signal-level acoustic echo canceller (remote mode only). Subtracts the
  /// system loopback (far-end reference) from the mic before transcription so
  /// the remote's speaker bleed never reaches Whisper — independent of how it
  /// would have been transcribed. A no-op passthrough when the native AEC
  /// library is unavailable; [_echoFilter] remains the backstop either way.
  AecMicFilter? _aec;

  /// Per-channel WAV writers, created only when diarization models are
  /// installed (otherwise the retained audio would never be used). The offline
  /// diarization pipeline step reads these back after the recording stops.
  WavStreamWriter? _micWav;
  WavStreamWriter? _systemWav;

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
  /// capture) vs in-person (mic only); it decides what diarization later splits.
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
    final transcriber = await _resolveTranscriber();
    if (transcriber == null) {
      state = MeetingRecorderState.failed(
        'Voice model not installed — install it from Settings.',
      );
      return;
    }

    try {
      if (!transcriber.isReady) {
        await transcriber.initialize();
      }

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

      final repo = ref.read(meetingRepositoryProvider);
      final now = DateTime.now();
      final meetingId = _uuid.v4();

      // Retain per-channel audio only when diarization models are installed —
      // otherwise the WAVs would be written but never read. The offline
      // diarization pipeline step reads them back after the recording stops.
      final retainAudio = await _diarizationInstalled();
      String? audioDirPath;
      if (retainAudio) {
        final dir = await meetingAudioDir(meetingId);
        audioDirPath = dir.path;
        _micWav = await WavStreamWriter.create(p.join(dir.path, 'me.wav'));
        if (captureSystem) {
          _systemWav =
              await WavStreamWriter.create(p.join(dir.path, 'them.wav'));
        }
      }

      final meeting = Meeting(
        id: meetingId,
        workspaceId: workspaceId,
        title: title?.trim().isNotEmpty == true
            ? title!.trim()
            : _defaultTitle(now),
        status: MeetingStatus.recording,
        mode: mode,
        audioPath: audioDirPath,
        createdAt: now,
        updatedAt: now,
        startedAt: now,
      );
      await repo.upsert(meeting);

      _workspaceId = workspaceId;
      _meetingId = meetingId;
      _mic = mic;
      _system = system;

      // One transcription service drives both channels; each decode runs to
      // completion synchronously, so a single recognizer serializes safely.
      final transcription = meetingTranscriptionService(transcriber);

      // Shared clock + cross-channel echo filter. Both listeners stamp their
      // windows against this one clock and route through the filter, which
      // drops "me" windows that duplicate a near-contemporaneous "them" window.
      final clock = Stopwatch()..start();
      _clock = clock;
      _echoFilter = _echoFilterEnabled
          ? MeetingEchoFilter(onAccepted: _persistSegment)
          : null;

      // Signal-level AEC, remote mode only (needs the loopback as the far-end
      // reference). Null processor → identity passthrough; the recorder behaves
      // exactly as before and MeetingEchoFilter is the sole echo defense.
      final aecProcessor =
          captureSystem ? ref.read(aecProcessorFactoryProvider)() : null;
      _aec = AecMicFilter(
        processor: aecProcessor,
        // The shared recording clock — both capture listeners stamp against it,
        // so the AEC can cross-correlate the two streams to auto-measure the
        // loopback↔mic delay for this session's hardware.
        clockNow: () => clock.elapsedMilliseconds,
        log: (m) => AppLog.i('MeetingCapture', m),
      );
      AppLog.i(
        'MeetingCapture',
        aecProcessor != null
            ? 'AEC enabled (${aecProcessor.version})'
            : 'AEC unavailable — using text echo filter only',
      );

      // mic → log/tee RAW (me.wav stays unprocessed: diarization reads them.wav
      // in remote mode, and AEC no-ops in-person) → AEC clean → transcribe.
      final micRaw = _logFrames(
        await mic.startStream(_micConfig),
        'mic/me',
        sink: _micWav,
      );
      final micStream = _aec?.cleanMic(micRaw) ?? micRaw;
      _micTx = transcription.transcribe(micStream).listen(
            (w) {
              AppLog.i('MeetingCapture', 'me window: "${_snippet(w.text)}"');
              _offerWindow(MeetingSpeaker.me, w);
            },
            onError: (Object e, StackTrace s) =>
                AppLog.w('MeetingRecorder', 'mic transcription error: $e'),
          );

      if (captureSystem && system != null) {
        // loopback → log/tee + activity → AEC far-end reference (re-emitted
        // unchanged for "them") → transcribe.
        final systemRaw = _logFrames(
          system.capture(sourceId: sourceId),
          'system/them',
          sink: _systemWav,
          trackSystemActivity: true,
        );
        final systemStream = _aec?.referenceTap(systemRaw) ?? systemRaw;
        _systemTx = transcription.transcribe(systemStream).listen(
              (w) {
                AppLog.i('MeetingCapture', 'them window: "${_snippet(w.text)}"');
                _offerWindow(MeetingSpeaker.them, w);
              },
              onError: (Object e, StackTrace s) =>
                  AppLog.w('MeetingRecorder', 'system transcription error: $e'),
            );
      }

      state = MeetingRecorderState.recording(meetingId, now);
    } catch (e, s) {
      AppLog.e('MeetingRecorder', 'start failed: $e', e, s);
      await _teardownCaptures();
      // Drop the half-created meeting row so a failed start doesn't leave a
      // meeting stranded in `recording` (it has no transcript — nothing to
      // keep, and the startup reconciler would otherwise have to clean it up).
      final strandedId = _meetingId;
      final strandedWorkspaceId = _workspaceId;
      if (strandedId != null && strandedWorkspaceId != null) {
        try {
          await ref
              .read(meetingRepositoryProvider)
              .delete(strandedWorkspaceId, strandedId);
        } on Object catch (_) {
          // Best-effort cleanup; the reconciler is the backstop.
        }
      }
      _meetingId = null;
      _workspaceId = null;
      state = MeetingRecorderState.failed('Failed to start recording: $e');
    }
  }

  /// Stops the recording and announces it for summarization.
  ///
  /// Marks the meeting `processing` and publishes [MeetingRecordingStopped],
  /// which the built-in `meeting_summary` pipeline picks up via its event
  /// trigger to enhance the notes and persist action items + decisions. The
  /// meeting is finalized to `done` by the pipeline's `meeting.saveNotes` step,
  /// or by the MeetingSummaryReconciler if the run ends without it. The recorder
  /// itself returns to idle immediately — summarization is the pipeline's job.
  Future<void> stop() async {
    if (!state.isRecording) {
      return;
    }
    final workspaceId = _workspaceId;
    final meetingId = _meetingId;
    // Graceful: commit any held "me" windows (awaited) before reading segments.
    await _teardownCaptures(drainFilter: true);

    if (workspaceId == null || meetingId == null) {
      state = MeetingRecorderState.idle;
      return;
    }

    final repo = ref.read(meetingRepositoryProvider);
    try {
      final meeting = await repo.getById(workspaceId, meetingId);
      if (meeting == null) {
        return;
      }
      final now = DateTime.now();
      await repo.upsert(
        meeting.copyWith(
          status: MeetingStatus.processing,
          endedAt: now,
          updatedAt: now,
        ),
      );

      final segments = await repo.getSegments(workspaceId, meetingId);
      final transcript = formatMeetingTranscript(segments);
      if (transcript.isEmpty) {
        // Nothing was transcribed — finalize with whatever the user typed.
        await repo.upsert(
          meeting.copyWith(
            status: MeetingStatus.done,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        ref.read(domainEventBusProvider).publish(
              MeetingRecordingStopped(
                workspaceId: workspaceId,
                meetingId: meetingId,
                title: meeting.title,
                userNotes: meeting.userNotes,
                transcript: transcript,
                occurredAt: DateTime.now(),
              ),
            );
      }
    } catch (e, s) {
      AppLog.e('MeetingRecorder', 'stop failed: $e', e, s);
    } finally {
      state = MeetingRecorderState.idle;
      _workspaceId = null;
      _meetingId = null;
    }
  }

  /// Toggles pause on the active recording. While paused, the capture streams
  /// keep flowing but their transcribed windows are dropped, and the elapsed
  /// timer (derived from [MeetingRecorderState.elapsedAt]) is frozen.
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
      state = state.copyWith(paused: true, pausedSince: DateTime.now());
    }
  }

  /// Re-runs the `meeting_summary` pipeline for a finished meeting from its
  /// CURRENT notes + transcript — the manual "Re-run summary" path (e.g. after
  /// the user edits their personal notes). Marks the meeting `processing`; the
  /// pipeline finalizes it back to `done` (via the `meeting.saveNotes` step /
  /// MeetingSummaryReconciler).
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

    // A summary run for this meeting may already be in flight (the automatic
    // run from stop(), or a prior re-run). If so, do nothing: re-triggering
    // would dedup to null and we must NOT then flip the meeting to done — that
    // would defeat the reconciler's fallback if the active run later fails.
    final active = await ref.read(pipelineRunRepositoryProvider).activeForDedupKey(
          templateId: 'meeting_summary',
          workspaceId: workspaceId,
          dedupKey: meetingId,
        );
    if (active != null) {
      return;
    }

    await repo.upsert(
      meeting.copyWith(
        status: MeetingStatus.processing,
        updatedAt: DateTime.now(),
      ),
    );
    final run = await ref.read(pipelineEngineProvider).start(
      'meeting_summary',
      workspaceId: workspaceId,
      triggerEventType: 'manual',
      triggerPayload: {
        'workspaceId': workspaceId,
        'meetingId': meetingId,
        'title': meeting.title,
        'userNotes': meeting.userNotes,
        'transcript': transcript,
      },
      dedupKey: meetingId,
    );
    if (run == null) {
      // No active run AND start returned null → the template is genuinely
      // disabled/missing. Finalize with the transcript so it isn't stuck.
      await repo.upsert(
        meeting.copyWith(
          status: MeetingStatus.done,
          enhancedNotes: meeting.isEnhanced ? null : transcript,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Cancels the in-flight `meeting_summary` run for [meetingId] — the manual
  /// "Stop" affordance on a processing meeting. Killing the run emits
  /// `PipelineRunCancelled`, which the `MeetingSummaryReconciler` turns into a
  /// `done` finalize (keeping the transcript as the notes fallback, so the
  /// recording is never lost). When no run is live (already terminal / stranded)
  /// it finalizes the meeting directly, so the Stop button is never a silent
  /// no-op.
  Future<void> cancelProcessing(String meetingId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    final meeting = await repo.getById(workspaceId, meetingId);
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
      // The reconciler finalizes the meeting to `done` on PipelineRunCancelled.
      await ref.read(pipelineEngineProvider).cancel(active.id);
      return;
    }

    // No live run to kill (already terminal / stranded) — finalize directly so
    // the meeting leaves `processing` instead of waiting for the startup sweep.
    final segments = await repo.getSegments(workspaceId, meetingId);
    final transcript = formatMeetingTranscript(segments);
    await repo.upsert(
      meeting.copyWith(
        status: MeetingStatus.done,
        enhancedNotes: meeting.isEnhanced
            ? null
            : (transcript.isEmpty ? null : transcript),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Persists the user's live notes for [meetingId].
  Future<void> updateNotes(String meetingId, String notes) async {
    final repo = ref.read(meetingRepositoryProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final meeting = await repo.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    await repo.upsert(
      meeting.copyWith(userNotes: notes, updatedAt: DateTime.now()),
    );
  }

  /// Persists an edited [title] for [meetingId].
  Future<void> updateTitle(String meetingId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final meeting = await repo.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    await repo.upsert(
      meeting.copyWith(title: trimmed, updatedAt: DateTime.now()),
    );
  }

  /// Routes a transcribed window through the echo filter (stamping it on the
  /// shared clock), or persists it directly when the filter is disabled.
  void _offerWindow(MeetingSpeaker speaker, TranscribedWindow window) {
    final filter = _echoFilter;
    final clock = _clock;
    if (filter != null && clock != null) {
      filter.add(
        EchoCandidate(
          speaker: speaker,
          window: window,
          emitMs: clock.elapsedMilliseconds,
        ),
      );
    } else {
      unawaited(_persistSegment(speaker, window));
    }
  }

  Future<void> _persistSegment(
    MeetingSpeaker speaker,
    TranscribedWindow window,
  ) async {
    if (state.paused) {
      // Dropped on purpose: the user paused, so this window is not part of the
      // meeting record. This also covers an echo-filter-held "me" window whose
      // hold timer fires after a pause begins — correctly dropped.
      return;
    }
    final workspaceId = _workspaceId;
    final meetingId = _meetingId;
    if (workspaceId == null || meetingId == null) {
      return;
    }
    final repo = ref.read(meetingRepositoryProvider);
    await repo.appendSegment(
      MeetingSegment(
        id: _uuid.v4(),
        meetingId: meetingId,
        workspaceId: workspaceId,
        speaker: speaker,
        text: window.text,
        startMs: window.startMs,
        endMs: window.endMs,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Diagnostic passthrough: logs frame count + peak amplitude per [channel]
  /// roughly every 2s of audio. Lets us tell, from logs alone, whether the
  /// system-output tap is delivering real signal, silence, or nothing — the
  /// usual reason the "them" transcript stays empty (no/silent frames) versus
  /// the recognizer returning only non-speech tokens (logged in the service).
  Stream<Uint8List> _logFrames(
    Stream<Uint8List> source,
    String channel, {
    WavStreamWriter? sink,
    bool trackSystemActivity = false,
  }) {
    var frames = 0;
    var bytes = 0;
    var peak = 0;
    return source.map((chunk) {
      // Retain the raw audio (when enabled) for the offline diarization step.
      sink?.add(chunk);
      frames++;
      bytes += chunk.length;
      final view = ByteData.sublistView(chunk);
      // Sample every 16th frame — enough to gauge signal vs. silence cheaply.
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
      // Tell the echo filter when the remote is actually playing, so it knows a
      // concurrent "me" window may be speaker bleed and holds it longer.
      if (trackSystemActivity &&
          chunkPeak / 32768.0 > _systemActivityThreshold) {
        _echoFilter?.noteSystemActivity(_clock?.elapsedMilliseconds ?? 0);
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

  static String _snippet(String text) =>
      text.length <= 60 ? text : '${text.substring(0, 60)}…';

  static String _defaultTitle(DateTime when) {
    final y = when.year.toString().padLeft(4, '0');
    final mo = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    final h = when.hour.toString().padLeft(2, '0');
    final mi = when.minute.toString().padLeft(2, '0');
    return 'Meeting $y-$mo-$d $h:$mi';
  }

  /// Resolves the speech transcriber, waiting for the voice-model disk probe
  /// to settle first.
  ///
  /// [voiceModelStateProvider] starts in [VoiceModelStatus.unknown] and probes
  /// the disk asynchronously on first access; reading [speechTranscriberProvider]
  /// before that completes would wrongly report "not installed" even when the
  /// model is already on disk. Poll until the probe settles — it is just a few
  /// disk stats, so this returns almost immediately — with a generous timeout.
  Future<SpeechTranscriber?> _resolveTranscriber() async {
    var modelState = ref.read(voiceModelStateProvider);
    var tries = 0;
    while (modelState.status == VoiceModelStatus.unknown && tries < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      modelState = ref.read(voiceModelStateProvider);
      tries++;
    }
    return ref.read(speechTranscriberProvider);
  }

  /// Whether the diarization models are installed, waiting for the async disk
  /// probe to settle first.
  ///
  /// Mirrors [_resolveTranscriber]: [diarizationModelStateProvider] starts in
  /// [DiarizationModelStatus.unknown] and probes the disk asynchronously on
  /// first access. Reading `isInstalled` synchronously right after launch would
  /// wrongly report "not installed" even when the models are on disk — so the
  /// first recording of a session would skip audio retention and could never be
  /// diarized. Poll until the probe settles (a few disk stats — near-instant).
  Future<bool> _diarizationInstalled() async {
    var s = ref.read(diarizationModelStateProvider);
    var tries = 0;
    while (s.status == DiarizationModelStatus.unknown && tries < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      s = ref.read(diarizationModelStateProvider);
      tries++;
    }
    return s.isInstalled;
  }

  /// Tears down the capture streams. When [drainFilter] is true (graceful
  /// stop), the echo filter commits its held "me" windows — awaited, so the
  /// recording's tail is persisted before stop() reads segments back. Otherwise
  /// (error path / dispose) those held windows are dropped.
  Future<void> _teardownCaptures({bool drainFilter = false}) async {
    // Stop new windows arriving before draining the filter.
    await _micTx?.cancel();
    _micTx = null;
    await _systemTx?.cancel();
    _systemTx = null;
    final filter = _echoFilter;
    _echoFilter = null;
    if (filter != null) {
      if (drainFilter) {
        await filter.drain();
      } else {
        filter.dispose();
      }
    }
    // Dispose the AEC after the transcribe subscriptions are cancelled above
    // (which cancels its eager source subscriptions), so no block is in flight
    // when the native handle is freed.
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
    // Finalize the retained WAVs (patches their size headers) so the diarization
    // step can read complete files. Closing is safe even on the error path.
    try {
      await _micWav?.close();
    } catch (_) {}
    _micWav = null;
    try {
      await _systemWav?.close();
    } catch (_) {}
    _systemWav = null;
  }
}

/// Controls the active meeting recording.
final meetingRecorderControllerProvider =
    NotifierProvider<MeetingRecorderController, MeetingRecorderState>(
  MeetingRecorderController.new,
);
