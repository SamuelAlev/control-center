import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcription_port.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/meetings/meeting_echo_filter.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Audio channel a [MeetingRecordingService.ingest] frame belongs to. Mirrors
/// [MeetingSpeaker]: `me` is the local microphone, `them` is the captured
/// system / meeting audio (browser screenshare).
enum RecordingChannel {
  /// The local user's microphone (`getUserMedia`).
  me,

  /// The shared system / meeting audio (`getDisplayMedia`).
  them;

  /// Parses a wire channel tag, rejecting anything unrecognized.
  static RecordingChannel parse(String value) =>
      RecordingChannel.values.firstWhere(
        (c) => c.name == value,
        orElse: () =>
            throw ArgumentError.value(value, 'channel', 'unknown audio channel'),
      );

  /// The transcript speaker channel this audio channel maps onto.
  MeetingSpeaker get speaker =>
      this == RecordingChannel.me ? MeetingSpeaker.me : MeetingSpeaker.them;
}

/// Host-side meeting recorder driven by streamed PCM16 over RPC.
///
/// A thin client (the web app) captures the microphone + system audio in the
/// browser, downsamples to 16 kHz mono PCM16, and pushes the frames to the host
/// via `meeting.startRecording` → `meeting.ingestAudio` → `meeting.stopRecording`.
/// This service runs the *same* windowed transcription + echo-dedup the desktop
/// recorder runs (the desktop `MeetingRecorderController` is the reference), but
/// with the audio arriving over the wire instead of from native capture: it
/// owns one [_RecordingSession] per `(workspaceId, meetingId)`, feeds each
/// channel through a [MeetingTranscriptionService] gated by RMS, dedups mic echo
/// against the system channel via [MeetingEchoFilter], and appends the resulting
/// [MeetingSegment]s — which a connected client watches live through
/// `meeting.watchSegments`. On stop it marks the meeting `processing` and
/// publishes [MeetingRecordingStopped], which the built-in `meeting_summary`
/// pipeline picks up to augment the notes (the `MeetingSummaryReconciler`
/// finalizes it to `done`).
///
/// Sessions are keyed by `(workspaceId, meetingId)`; [ingest] / [stop] for a
/// meeting with no open session in the caller's workspace throw — a foreign
/// meeting is never reachable (the workspace binding is the boundary).
///
/// **Concurrent recordings are supported.** One server holds many live sessions
/// at once — two clients (e.g. desktop + web) each recording their own meeting,
/// or the same operator recording several — because every [start] mints a fresh
/// id and gets its own session, transcription channels, echo filter, and WAV
/// sinks. The single shared [SpeechTranscriber] serializes decodes across all
/// sessions (one worker isolate) but never blocks: each channel buffers its
/// audio while a decode is in flight, so concurrent meetings interleave rather
/// than starve. Isolation is covered by `meeting_recording_concurrency_test`.
class MeetingRecordingService {
  /// Creates a [MeetingRecordingService].
  ///
  /// [transcriber] is the shared speech recognizer (one worker isolate); every
  /// session's per-channel [MeetingTranscriptionService] decodes through it, so
  /// decodes serialize across channels and meetings — fine for the low
  /// concurrency a single host sees.
  MeetingRecordingService({
    required MeetingRepository repository,
    required SpeechTranscriber transcriber,
    required DomainEventBus eventBus,
    required CcPaths paths,
  })  : _repository = repository,
        _transcriber = transcriber,
        _eventBus = eventBus,
        _paths = paths;

  final MeetingRepository _repository;
  final SpeechTranscriber _transcriber;
  final DomainEventBus _eventBus;

  /// Resolves the on-disk meeting audio directory (`<dataDir>/meetings/<id>/`)
  /// where each session retains its per-channel WAVs for diarization + playback.
  final CcPaths _paths;

  static const Uuid _uuid = Uuid();
  final Map<String, _RecordingSession> _sessions = {};

  String _key(String workspaceId, String meetingId) =>
      '$workspaceId/$meetingId';

  /// Begins a recording: mints a meeting id, creates the [Meeting] row (status
  /// `recording`) in [workspaceId], opens a transcription session, and returns
  /// the new meeting id (the client uses it for `ingestAudio` / `stopRecording`
  /// and `meeting.watchSegments`). [mode] is a [MeetingMode] name (`remote` /
  /// `inPerson`); an unknown value falls back to remote.
  ///
  /// The server mints the id (rather than trusting a client value) so a client
  /// can never collide with — and clobber, via `upsert`'s insert-or-replace — a
  /// meeting in another workspace; the new id is unique and owned by
  /// [workspaceId] from creation.
  Future<String> start({
    required String workspaceId,
    required String title,
    required String mode,
  }) async {
    final meetingId = _uuid.v4();
    final trimmed = title.trim();
    final now = DateTime.now();

    // Retain the streamed PCM as per-channel WAVs (`me.wav` / `them.wav`) under
    // the meeting's audio dir, and record that dir as `audioPath`. This is what
    // unlocks the host's offline `meeting_summary` steps — diarization (reads
    // `them.wav`/`me.wav`) and playback assembly (mixes them into `mixed.wav`) —
    // for audio that arrives over RPC rather than from native desktop capture.
    // Retention is best-effort: a filesystem failure disables it (audioPath stays
    // null, those steps skip) but never blocks transcription.
    WavStreamWriter? meWav;
    WavStreamWriter? themWav;
    String? audioPath;
    try {
      final dir = await _paths.meetingAudioDir(meetingId);
      meWav = await WavStreamWriter.create(p.join(dir.path, 'me.wav'));
      themWav = await WavStreamWriter.create(p.join(dir.path, 'them.wav'));
      audioPath = dir.path;
    } on Object catch (e) {
      CcInfraLog.warning(
        'MeetingRecordingService: audio retention disabled for $meetingId: $e',
      );
      await meWav?.close();
      await themWav?.close();
      meWav = null;
      themWav = null;
      audioPath = null;
    }

    await _repository.upsert(
      Meeting(
        id: meetingId,
        workspaceId: workspaceId,
        title: trimmed.isEmpty ? 'New meeting' : trimmed,
        status: MeetingStatus.recording,
        mode: MeetingMode.fromStorage(mode),
        // A user-supplied title is "custom" so the summarizer won't rename it;
        // an empty title leaves the door open for a content-derived title.
        titleIsCustom: trimmed.isNotEmpty,
        audioPath: audioPath,
        createdAt: now,
        updatedAt: now,
        startedAt: now,
      ),
    );
    final session = _RecordingSession(
      workspaceId: workspaceId,
      meetingId: meetingId,
      repository: _repository,
      transcription: MeetingTranscriptionService(_transcriber),
      meWav: meWav,
      themWav: themWav,
    )..start();
    _sessions[_key(workspaceId, meetingId)] = session;
    return meetingId;
  }

  /// Feeds one PCM16 (16 kHz mono) [pcm] frame on [channel] into the open
  /// session for [meetingId] in [workspaceId]. [seq] is the client's per-channel
  /// sequence number (currently used only for gap diagnostics — frames are
  /// appended in arrival order, and the client awaits each call so arrival order
  /// equals capture order). Throws when no session is open (a foreign or
  /// already-stopped meeting).
  Future<void> ingest({
    required String workspaceId,
    required String meetingId,
    required String channel,
    required int seq,
    required Uint8List pcm,
  }) async {
    final session = _sessions[_key(workspaceId, meetingId)];
    if (session == null) {
      throw StateError(
        'No active recording for meeting $meetingId in this workspace.',
      );
    }
    session.ingest(RecordingChannel.parse(channel), seq, pcm);
  }

  /// Stops the recording: drains transcription + the echo filter, marks the
  /// meeting `processing`, and publishes [MeetingRecordingStopped] so the
  /// summary pipeline runs (or finalizes straight to `done` when nothing was
  /// transcribed). Throws when no session is open.
  Future<void> stop({
    required String workspaceId,
    required String meetingId,
    String? summaryInstructions,
  }) async {
    final session = _sessions.remove(_key(workspaceId, meetingId));
    if (session == null) {
      throw StateError(
        'No active recording for meeting $meetingId in this workspace.',
      );
    }
    await session.drainAndClose();

    final meeting = await _repository.getById(workspaceId, meetingId);
    if (meeting == null) {
      return;
    }
    final now = DateTime.now();
    await _repository.upsert(
      meeting.copyWith(
        status: MeetingStatus.processing,
        endedAt: now,
        updatedAt: now,
        summaryInstructions: summaryInstructions,
      ),
    );

    final segments = await _repository.getSegments(workspaceId, meetingId);
    final transcript = formatMeetingTranscript(segments);
    if (transcript.isEmpty) {
      // Nothing transcribed — finalize directly (no summary run to fire).
      await _repository.upsert(
        meeting.copyWith(
          status: MeetingStatus.done,
          endedAt: now,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }
    _eventBus.publish(
      MeetingRecordingStopped(
        workspaceId: workspaceId,
        meetingId: meetingId,
        title: meeting.title,
        userNotes: meeting.userNotes,
        transcript: transcript,
        occurredAt: DateTime.now(),
        summaryInstructions: summaryInstructions,
      ),
    );
  }

  /// Whether a recording session is open for [meetingId] in [workspaceId].
  bool isRecording(String workspaceId, String meetingId) =>
      _sessions.containsKey(_key(workspaceId, meetingId));

  /// Tears down every open session without finalizing (server shutdown). The
  /// stranded meetings are recovered by the `MeetingSummaryReconciler`'s startup
  /// sweep on next boot.
  Future<void> dispose() async {
    final open = _sessions.values.toList();
    _sessions.clear();
    for (final s in open) {
      await s.abort();
    }
  }
}

/// One live recording: two channel streams on a shared clock, transcribed and
/// echo-deduped into [MeetingSegment]s. Mirrors the desktop recorder's capture
/// loop (`_offerWindow` / `_persistSegment`) minus native audio I/O.
class _RecordingSession {
  _RecordingSession({
    required this.workspaceId,
    required this.meetingId,
    required MeetingRepository repository,
    required MeetingTranscriptionPort transcription,
    WavStreamWriter? meWav,
    WavStreamWriter? themWav,
  })  : _repository = repository,
        _transcription = transcription,
        _meWav = meWav,
        _themWav = themWav;

  /// System-channel peak (normalized 0–1) above which the remote is considered
  /// actively playing — fed to [MeetingEchoFilter.noteSystemActivity] so a
  /// concurrent "me" window is held longer as possible bleed. Matches the
  /// desktop recorder's `_systemActivityThreshold`.
  static const double _systemActivityThreshold = 0.03;
  static const Uuid _uuid = Uuid();

  final String workspaceId;
  final String meetingId;
  final MeetingRepository _repository;
  final MeetingTranscriptionPort _transcription;

  /// Per-channel WAV sinks the streamed PCM is mirrored into for retention
  /// (null when retention is disabled — see [MeetingRecordingService.start]).
  /// `me.wav` holds the (echo-cancelled) microphone; `them.wav` the system /
  /// meeting audio. The transcription stream and these files receive the exact
  /// same frames in the same order, so the WAV timeline aligns with the segment
  /// offsets the diarization step maps speakers onto.
  final WavStreamWriter? _meWav;
  final WavStreamWriter? _themWav;

  /// Single clock shared by both channels — the only timeline on which a "me"
  /// and "them" window are comparable (their per-channel byte offsets are not).
  final Stopwatch _clock = Stopwatch();
  final StreamController<Uint8List> _me = StreamController<Uint8List>();
  final StreamController<Uint8List> _them = StreamController<Uint8List>();
  late final MeetingEchoFilter _echo;
  StreamSubscription<TranscribedWindow>? _meTx;
  StreamSubscription<TranscribedWindow>? _themTx;
  final Completer<void> _meDone = Completer<void>();
  final Completer<void> _themDone = Completer<void>();

  /// In-flight segment appends, so [drainAndClose] can wait for them before the
  /// transcript is read (the echo filter commits "them" windows fire-and-forget).
  final Set<Future<void>> _inflight = {};
  bool _closed = false;

  void start() {
    _clock.start();
    _echo = MeetingEchoFilter(onAccepted: _persist);
    _meTx = _transcription.transcribe(_me.stream).listen(
      (w) => _offer(MeetingSpeaker.me, w),
      onError: (Object e, StackTrace s) => CcInfraLog.warning(
        'MeetingRecordingSession: me transcription error: $e',
      ),
      onDone: () {
        if (!_meDone.isCompleted) {
          _meDone.complete();
        }
      },
    );
    _themTx = _transcription.transcribe(_them.stream).listen(
      (w) => _offer(MeetingSpeaker.them, w),
      onError: (Object e, StackTrace s) => CcInfraLog.warning(
        'MeetingRecordingSession: them transcription error: $e',
      ),
      onDone: () {
        if (!_themDone.isCompleted) {
          _themDone.complete();
        }
      },
    );
  }

  void ingest(RecordingChannel channel, int seq, Uint8List pcm) {
    if (_closed || pcm.isEmpty) {
      return;
    }
    if (channel == RecordingChannel.them) {
      if (_peak(pcm) >= _systemActivityThreshold) {
        _echo.noteSystemActivity(_clock.elapsedMilliseconds);
      }
      _themWav?.add(pcm);
      if (!_them.isClosed) {
        _them.add(pcm);
      }
    } else {
      _meWav?.add(pcm);
      if (!_me.isClosed) {
        _me.add(pcm);
      }
    }
  }

  void _offer(MeetingSpeaker speaker, TranscribedWindow window) {
    _echo.add(
      EchoCandidate(
        speaker: speaker,
        window: window,
        emitMs: _clock.elapsedMilliseconds,
      ),
    );
  }

  Future<void> _persist(MeetingSpeaker speaker, TranscribedWindow window) {
    final future = _repository.appendSegment(
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
    _inflight.add(future);
    return future.whenComplete(() => _inflight.remove(future));
  }

  /// Closes both channel streams (so each [MeetingTranscriptionService] flushes
  /// its final window), drains the echo filter's held "me" windows, and waits
  /// for every append to land before returning — so the caller reads a complete
  /// transcript.
  Future<void> drainAndClose() async {
    _closed = true;
    await _me.close();
    await _them.close();
    await Future.wait([_meDone.future, _themDone.future]);
    await _meTx?.cancel();
    await _themTx?.cancel();
    await _echo.drain();
    // Let any fire-and-forget "them" commits enroll, then await all appends.
    await Future<void>.delayed(Duration.zero);
    if (_inflight.isNotEmpty) {
      await Future.wait(_inflight.toList());
    }
    // Finalize the retained WAVs (patches their size headers) so the offline
    // diarization + playback-assembly steps read complete files.
    await _meWav?.close();
    await _themWav?.close();
    _clock.stop();
  }

  /// Hard teardown without finalizing (server shutdown).
  Future<void> abort() async {
    _closed = true;
    _echo.dispose();
    await _meTx?.cancel();
    await _themTx?.cancel();
    if (!_me.isClosed) {
      await _me.close();
    }
    if (!_them.isClosed) {
      await _them.close();
    }
    // Close the WAVs so the partial recording is still a valid (size-patched)
    // file the startup reconciler / a later re-run can read.
    await _meWav?.close();
    await _themWav?.close();
    _clock.stop();
  }

  /// Normalized peak amplitude (0–1) of a PCM16 little-endian frame.
  static double _peak(Uint8List pcm) {
    final view = ByteData.sublistView(pcm);
    final samples = pcm.lengthInBytes ~/ 2;
    var peak = 0;
    for (var i = 0; i < samples; i++) {
      final s = view.getInt16(i * 2, Endian.little).abs();
      if (s > peak) {
        peak = s;
      }
    }
    return peak / 32768.0;
  }
}
