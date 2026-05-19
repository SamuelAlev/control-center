import 'dart:async';

import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_signal_collector_bindings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How often the detection controller samples its collectors.
const Duration _kPollInterval = Duration(seconds: 6);

/// What the detection UI should show right now.
class MeetingDetectionUiState {
  /// Creates a [MeetingDetectionUiState].
  const MeetingDetectionUiState({
    this.candidate,
    this.showPrompt = false,
    this.suggestAutoStop = false,
  });

  /// The "record this meeting?" prompt's candidate (when [showPrompt]).
  final MeetingCandidate? candidate;

  /// Whether to surface the record prompt.
  final bool showPrompt;

  /// Whether to suggest stopping a running recording (the meeting looks over).
  final bool suggestAutoStop;

  /// The idle state — nothing to show.
  static const MeetingDetectionUiState idle = MeetingDetectionUiState();

  /// Copy with overrides.
  MeetingDetectionUiState copyWith({
    MeetingCandidate? candidate,
    bool? showPrompt,
    bool? suggestAutoStop,
  }) =>
      MeetingDetectionUiState(
        candidate: candidate ?? this.candidate,
        showPrompt: showPrompt ?? this.showPrompt,
        suggestAutoStop: suggestAutoStop ?? this.suggestAutoStop,
      );
}

/// Drives automatic meeting detection: polls the signal collectors, fuses them
/// into a [MeetingCandidate], runs the [MeetingDetectionStateMachine], and
/// exposes a [MeetingDetectionUiState] the shell/meetings UI renders as a
/// record prompt / auto-stop suggestion.
///
/// Kept alive for the app's lifetime (see the alive provider, wired in
/// `main.dart`). Rebuilds — restarting detection — when the enabled toggle
/// flips. Recording start/stop is tracked off the recorder so manually-started
/// recordings still get auto-stop handling.
class MeetingDetectionController extends Notifier<MeetingDetectionUiState> {
  MeetingDetectionStateMachine? _machine;
  bool _wasRecording = false;

  @override
  MeetingDetectionUiState build() {
    final enabled = ref.watch(meetingAutoDetectEnabledProvider);
    if (!enabled) {
      return MeetingDetectionUiState.idle;
    }
    final machine = MeetingDetectionStateMachine();
    _machine = machine;

    // Mirror the recorder lifecycle into the machine so auto-stop works even
    // for recordings the user started manually.
    _wasRecording = ref.read(meetingRecorderControllerProvider).isRecording;
    if (_wasRecording) {
      machine.accept();
    }
    ref.listen<bool>(
      meetingRecorderControllerProvider.select((s) => s.isRecording),
      (_, isRecording) {
        if (isRecording && !_wasRecording) {
          machine.accept();
        } else if (!isRecording && _wasRecording) {
          machine.stopped();
          state = MeetingDetectionUiState.idle;
        }
        _wasRecording = isRecording;
      },
    );

    final timer = Timer.periodic(_kPollInterval, (_) => _tick());
    ref.onDispose(timer.cancel);

    // Kick off an immediate sweep so detection doesn't wait a full interval.
    unawaited(_tick());
    return MeetingDetectionUiState.idle;
  }

  Future<void> _tick() async {
    final machine = _machine;
    if (machine == null) {
      return;
    }
    final now = DateTime.now();
    final collector = ref.read(meetingSignalCollectorProvider);
    final signals = await collector.sample(now);
    // While recording, ongoing transcription is itself proof the meeting is
    // live — fold it in so the no-signal auto-stop gap only opens once speech
    // has genuinely stopped, not just because no external collector matched
    // (in-person meetings, browser calls, unrecognised conferencing apps).
    final activity = _recordingActivitySignal();
    final candidate = resolveMeetingCandidate(
      activity == null ? signals : [...signals, activity],
      now: now,
    );
    final action = machine.update(candidate: candidate, now: now);
    switch (action) {
      case MeetingDetectionAction.showPrompt:
        state = MeetingDetectionUiState(candidate: candidate, showPrompt: true);
      case MeetingDetectionAction.hidePrompt:
        state = MeetingDetectionUiState.idle;
      case MeetingDetectionAction.suggestAutoStop:
        state = state.copyWith(suggestAutoStop: true);
      case MeetingDetectionAction.none:
        break;
    }
  }

  /// A meeting-present signal derived from the recorder: while a recording is
  /// in progress, the time of the last committed transcript window. Returns null
  /// when not recording or before the first window. The pure resolver's
  /// freshness gate decides whether it is still recent enough to count, so a
  /// long pause naturally lets the signal lapse (and the auto-stop gap reopen).
  MeetingSignal? _recordingActivitySignal() {
    final recorder = ref.read(meetingRecorderControllerProvider);
    if (!recorder.isRecording || recorder.paused) {
      return null;
    }
    final last = recorder.lastSegmentAt;
    if (last == null) {
      return null;
    }
    return MeetingSignal(
      kind: MeetingSignalKind.activeRecording,
      active: true,
      at: last,
    );
  }

  /// The user accepted the prompt — a recording is starting.
  void accept() {
    _machine?.accept();
    state = MeetingDetectionUiState.idle;
  }

  /// The user dismissed the prompt — suppress this candidate until it clears.
  void dismiss() {
    _machine?.dismiss(state.candidate?.label);
    state = MeetingDetectionUiState.idle;
  }

  /// Acknowledge the auto-stop suggestion (whether or not the user stopped).
  void clearAutoStop() {
    state = state.copyWith(suggestAutoStop: false);
  }
}

/// The automatic meeting-detection controller.
final meetingDetectionControllerProvider =
    NotifierProvider<MeetingDetectionController, MeetingDetectionUiState>(
  MeetingDetectionController.new,
);
