import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart' show MeetingRepository;
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_state.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Web-inert meeting recorder.
///
/// Live recording captures native audio + transcribes on-device (cc_natives /
/// the speech models) — a desktop-only capability with no browser equivalent.
/// On web this controller NEVER records: [start] surfaces an honest "recording
/// runs on the desktop/host" error, [stop] / [togglePause] / [cancelProcessing]
/// / [resummarize] are inert, and the state stays idle.
///
/// The pure DATA edits the meeting detail UI drives through this controller —
/// notes, title, and the manual action-item / decision CRUD — are NOT recording
/// and DO work: they route through the RPC-backed [MeetingRepository] (the
/// `meeting.*` ops), so a connected web client can still edit a finished
/// meeting's notes and structured output. Mirrors the desktop controller's
/// public surface so the shared meeting screens compile and behave identically
/// for everything except capture.
class MeetingRecorderController extends Notifier<MeetingRecorderState> {
  static const _uuid = Uuid();

  /// Sort-order base for user-added rows, matching the desktop controller so a
  /// re-run keeps manual rows after agent-extracted ones.
  static const _manualSortBase = 1000000;

  /// Throttle (ms) on input-level state pushes so the meter is smooth without
  /// rebuilding the recorder UI on every audio frame (~8 Hz).
  static const _levelPushIntervalMs = 125;

  MeetingAudioCapturePort? _capture;
  String? _meetingId;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Uint8List>? _systemSub;

  // Per-channel sequence + serial send chain: each ingest awaits the previous
  // on the same channel so frames reach the host in capture order (the client
  // applies natural backpressure rather than racing concurrent RPC calls).
  int _micSeq = 0;
  int _systemSeq = 0;
  Future<void> _micChain = Future<void>.value();
  Future<void> _systemChain = Future<void>.value();
  int _lastLevelPushMs = 0;

  @override
  MeetingRecorderState build() => MeetingRecorderState.idle;

  /// Starts a web recording: captures the mic + system (screenshare) audio in
  /// the browser and streams 16 kHz PCM16 to the host, which transcribes and
  /// appends segments this client watches via `meeting.watchSegments`.
  ///
  /// Recording REQUIRES system audio (the meeting audio): the capture port
  /// refuses to start — surfaced here as an error — when the screenshare yields
  /// no audio track (e.g. Safari/Firefox, or full-screen sharing on macOS).
  Future<void> start({
    String? title,
    String? sourceId,
    MeetingMode mode = MeetingMode.remote,
  }) async {
    if (state.isRecording) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      state = MeetingRecorderState.failed(
        'Select a workspace before recording.',
      );
      return;
    }
    final control = ref.read(meetingRecordingControlProvider);

    // 1) Browser capture first — fail before creating a host meeting if the mic
    // is denied or no system audio is shared.
    final capture = ref.read(meetingAudioCaptureFactoryProvider)();
    try {
      await capture.start();
    } on MeetingCaptureException catch (e) {
      await capture.stop();
      state = MeetingRecorderState.failed(e.message);
      return;
    } catch (e) {
      await capture.stop();
      state = MeetingRecorderState.failed('Could not start audio capture: $e');
      return;
    }

    // 2) Open the host recording session (server mints the meeting id).
    final String meetingId;
    try {
      meetingId = await control.startRecording(
        title: (title ?? '').trim(),
        mode: mode.name,
      );
    } catch (e) {
      await capture.stop();
      state = MeetingRecorderState.failed(
        'Could not start recording on the host: $e',
      );
      return;
    }

    // 3) Stream both channels to the host.
    _capture = capture;
    _meetingId = meetingId;
    _micSeq = 0;
    _systemSeq = 0;
    _micChain = Future<void>.value();
    _systemChain = Future<void>.value();
    _lastLevelPushMs = 0;
    _micSub = capture.micStream.listen(
      (pcm) => _ingest(control, meetingId, isMic: true, pcm: pcm),
    );
    _systemSub = capture.systemStream.listen(
      (pcm) => _ingest(control, meetingId, isMic: false, pcm: pcm),
    );
    state = MeetingRecorderState.recording(meetingId, DateTime.now());
  }

  /// Stops capture, drains pending sends, and tells the host to finalize
  /// (which fires the summary pipeline). Returns the recorder to idle.
  Future<void> stop() async {
    if (!state.isRecording) {
      return;
    }
    final meetingId = _meetingId;
    await _micSub?.cancel();
    await _systemSub?.cancel();
    _micSub = null;
    _systemSub = null;
    await _capture?.stop();
    _capture = null;
    // Let any in-flight ingests land before the host drains the transcript.
    await _micChain.catchError((_) {});
    await _systemChain.catchError((_) {});
    if (meetingId != null) {
      try {
        await ref
            .read(meetingRecordingControlProvider)
            .stopRecording(meetingId: meetingId);
      } catch (e) {
        AppLog.w('MeetingRecorder', 'stopRecording failed: $e');
      }
    }
    _meetingId = null;
    state = MeetingRecorderState.idle;
  }

  /// Toggles pause. While paused, captured frames are dropped (not sent to the
  /// host) and the elapsed timer is frozen — mirroring the desktop recorder.
  void togglePause() {
    if (!state.isRecording) {
      return;
    }
    if (state.paused) {
      final pausedSince = state.pausedSince;
      final added = pausedSince != null
          ? DateTime.now().difference(pausedSince)
          : Duration.zero;
      state = state.copyWith(
        paused: false,
        pausedTotal: state.pausedTotal + added,
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

  /// Sends one captured [pcm] frame to the host on the mic (`me`) or system
  /// (`them`) channel, serialized per channel. Dropped while paused. Mic frames
  /// also drive the input-level meter.
  void _ingest(
    MeetingRecordingControlPort control,
    String meetingId, {
    required bool isMic,
    required Uint8List pcm,
  }) {
    if (state.paused || state.meetingId != meetingId) {
      return;
    }
    if (isMic) {
      _pushLevel(pcm);
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

  /// Pushes a throttled, normalized RMS level (0–1) from a mic [pcm] frame.
  void _pushLevel(Uint8List pcm) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLevelPushMs < _levelPushIntervalMs) {
      return;
    }
    _lastLevelPushMs = now;
    if (state.isRecording && !state.paused) {
      state = state.copyWith(inputLevel: _rms(pcm));
    }
  }

  /// Normalized RMS (0–1) of a PCM16 little-endian frame.
  static double _rms(Uint8List pcm) {
    final view = ByteData.sublistView(pcm);
    final samples = pcm.lengthInBytes ~/ 2;
    if (samples == 0) {
      return 0;
    }
    var sumSq = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += s * s;
    }
    final rms = (sumSq / samples) > 0 ? _sqrt(sumSq / samples) : 0.0;
    return rms > 1.0 ? 1.0 : rms;
  }

  static double _sqrt(double x) {
    // Avoid importing dart:math for one call site.
    var guess = x;
    for (var i = 0; i < 8; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Inert: summarization runs on the desktop host's pipeline engine.
  Future<void> resummarize(String meetingId) async {}

  /// Inert: summarization runs on the desktop host's pipeline engine.
  Future<void> cancelProcessing(String meetingId) async {}

  // ---- Data edits (served over RPC) ----

  /// Persists the user's notes for [meetingId] over RPC.
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

  /// Adds a user-authored action item to [meetingId] over RPC.
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
    await ref.read(meetingRepositoryProvider).addActionItem(
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

  /// Edits an action item's [content] + [owner] over RPC.
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

  /// Deletes action item [id] over RPC.
  Future<void> deleteActionItem(String id) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref.read(meetingRepositoryProvider).deleteActionItem(workspaceId, id);
  }

  /// Adds a user-authored decision to [meetingId] over RPC.
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
    await ref.read(meetingRepositoryProvider).addDecision(
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

  /// Edits a decision's [content] over RPC.
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

  /// Deletes decision [id] over RPC.
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
}

/// Controls the active meeting recording. On web this is the inert variant —
/// recording is device-only; the data edits route over RPC.
final meetingRecorderControllerProvider =
    NotifierProvider<MeetingRecorderController, MeetingRecorderState>(
  MeetingRecorderController.new,
);
