/// Represents the current state of Focus Mode.
class FocusModeState {
  /// Creates a [FocusModeState].
  const FocusModeState({
    required this.active,
    this.sessionStartedAt,
    this.sessionDurationMinutes = 50,
    this.goal,
    this.compactMode = false,
    this.blockNotifications = true,
    this.pausedAt,
  });

  /// Whether focus mode is currently active.
  final bool active;

  /// When the current focus session was started.
  final DateTime? sessionStartedAt;

  /// Intended focus session length in minutes. Default 50.
  final int sessionDurationMinutes;

  /// Optional goal description shown in the compact floating bar.
  final String? goal;

  /// Whether the pill window is currently open (compact mode).
  final bool compactMode;

  /// Whether non-urgent notifications are muted during this session.
  final bool blockNotifications;

  /// Set when the session timer is paused; null when running.
  final DateTime? pausedAt;

  /// Whether the session is currently paused.
  bool get isPaused => pausedAt != null;

  /// Elapsed time since focus session start, accounting for pauses.
  Duration get elapsed {
    if (!active || sessionStartedAt == null) {
      return Duration.zero;
    }
    final now = pausedAt ?? DateTime.now();
    return now.difference(sessionStartedAt!);
  }

  /// Minutes remaining in the current session.
  int get minutesRemaining {
    final remaining = sessionDurationMinutes - elapsed.inMinutes;
    return remaining.clamp(0, sessionDurationMinutes);
  }

  /// Seconds remaining in the current session (full precision).
  int get secondsRemaining {
    final totalSecs = sessionDurationMinutes * 60;
    return (totalSecs - elapsed.inSeconds).clamp(0, totalSecs);
  }

  /// Fraction of session elapsed (0.0 = just started, 1.0 = ended).
  double get sessionProgress {
    final totalSecs = sessionDurationMinutes * 60;
    if (totalSecs == 0) {
      return 0;
    }
    return (elapsed.inSeconds / totalSecs).clamp(0.0, 1.0);
  }

  /// Whether the session timer is still within the planned duration.
  bool get withinSession =>
      active && elapsed.inMinutes < sessionDurationMinutes;

  /// Creates a copy with the specified fields replaced.
  FocusModeState copyWith({
    bool? active,
    DateTime? sessionStartedAt,
    int? sessionDurationMinutes,
    String? goal,
    bool? compactMode,
    bool? blockNotifications,
    DateTime? pausedAt,
    bool clearStartedAt = false,
    bool clearGoal = false,
    bool clearPausedAt = false,
  }) {
    return FocusModeState(
      active: active ?? this.active,
      sessionStartedAt:
          clearStartedAt ? null : (sessionStartedAt ?? this.sessionStartedAt),
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      goal: clearGoal ? null : (goal ?? this.goal),
      compactMode: compactMode ?? this.compactMode,
      blockNotifications: blockNotifications ?? this.blockNotifications,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusModeState &&
          active == other.active &&
          sessionStartedAt == other.sessionStartedAt &&
          sessionDurationMinutes == other.sessionDurationMinutes &&
          goal == other.goal &&
          compactMode == other.compactMode &&
          blockNotifications == other.blockNotifications &&
          pausedAt == other.pausedAt;

  @override
  int get hashCode => Object.hash(
    active,
    sessionStartedAt,
    sessionDurationMinutes,
    goal,
    compactMode,
    blockNotifications,
    pausedAt,
  );
}
