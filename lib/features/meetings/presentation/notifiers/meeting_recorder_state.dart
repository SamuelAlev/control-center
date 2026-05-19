/// High-level state of the meeting recorder.
enum MeetingRecorderStatus {
  /// Not recording.
  idle,

  /// Capturing audio and transcribing live.
  recording,

  /// The last start/stop failed.
  error,
}

/// Immutable state for the meeting recorder controller.
class MeetingRecorderState {
  /// Creates a [MeetingRecorderState].
  const MeetingRecorderState({
    this.status = MeetingRecorderStatus.idle,
    this.meetingId,
    this.startedAt,
    this.error,
    this.paused = false,
    this.pausedTotal = Duration.zero,
    this.pausedSince,
    this.inputLevel = 0,
    this.micWarning = false,
    this.lastSegmentAt,
  });

  /// A recording state for [meetingId] started at [startedAt].
  factory MeetingRecorderState.recording(String meetingId, DateTime startedAt) {
    return MeetingRecorderState(
      status: MeetingRecorderStatus.recording,
      meetingId: meetingId,
      startedAt: startedAt,
    );
  }

  /// An error state.
  factory MeetingRecorderState.failed(String message) {
    return MeetingRecorderState(
      status: MeetingRecorderStatus.error,
      error: message,
    );
  }

  /// The idle state.
  static const MeetingRecorderState idle = MeetingRecorderState();

  /// Current status.
  final MeetingRecorderStatus status;

  /// The id of the meeting being recorded/processed, if any.
  final String? meetingId;

  /// When the current recording began.
  final DateTime? startedAt;

  /// The last error message, when [status] is [MeetingRecorderStatus.error].
  final String? error;

  /// Whether the recording is currently paused. While paused, incoming
  /// transcription windows are dropped and the elapsed timer is frozen.
  final bool paused;

  /// Total time spent paused before the current pause segment.
  final Duration pausedTotal;

  /// When the current pause began (null when not paused).
  final DateTime? pausedSince;

  /// Smoothed live microphone input level in 0..1 (real RMS), for the meter.
  final double inputLevel;

  /// Whether the mic appears silent/dead while the remote is actively talking
  /// — surfaced as a "mic may be muted" warning during the recording.
  final bool micWarning;

  /// When the recorder last committed a transcript window (either channel), or
  /// null if nothing has been transcribed yet this recording. Auto-detection
  /// reads this so the "meeting looks over" auto-stop suggestion is suppressed
  /// while speech is still being transcribed (see `MeetingDetectionController`).
  final DateTime? lastSegmentAt;

  /// Whether a recording is in progress.
  bool get isRecording => status == MeetingRecorderStatus.recording;

  /// Whether the recorder is free to start a new recording.
  bool get isIdle =>
      status == MeetingRecorderStatus.idle ||
      status == MeetingRecorderStatus.error;

  /// The active (un-paused) recording duration as of [now].
  Duration elapsedAt(DateTime now) {
    final start = startedAt;
    if (start == null) {
      return Duration.zero;
    }
    final raw = now.difference(start);
    final activePause =
        pausedSince != null ? now.difference(pausedSince!) : Duration.zero;
    final elapsed = raw - pausedTotal - activePause;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Returns a copy with the given overrides.
  MeetingRecorderState copyWith({
    MeetingRecorderStatus? status,
    String? meetingId,
    DateTime? startedAt,
    String? error,
    bool? paused,
    Duration? pausedTotal,
    DateTime? pausedSince,
    bool clearPausedSince = false,
    double? inputLevel,
    bool? micWarning,
    DateTime? lastSegmentAt,
  }) {
    return MeetingRecorderState(
      status: status ?? this.status,
      meetingId: meetingId ?? this.meetingId,
      startedAt: startedAt ?? this.startedAt,
      error: error ?? this.error,
      paused: paused ?? this.paused,
      pausedTotal: pausedTotal ?? this.pausedTotal,
      pausedSince: clearPausedSince ? null : (pausedSince ?? this.pausedSince),
      inputLevel: inputLevel ?? this.inputLevel,
      micWarning: micWarning ?? this.micWarning,
      lastSegmentAt: lastSegmentAt ?? this.lastSegmentAt,
    );
  }
}
