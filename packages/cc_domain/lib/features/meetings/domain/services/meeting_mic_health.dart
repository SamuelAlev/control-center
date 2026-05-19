import 'dart:math' as math;

/// Health verdict for the microphone capture during a meeting.
enum MicHealth {
  /// The mic is delivering audio (or there is nothing to compare against yet).
  ok,

  /// The remote side is clearly audible (system audio is active) but the mic
  /// has been silent / all-zero for a sustained window — a strong signal the
  /// mic is muted, dead, or grabbed by another app. Worth warning the user
  /// mid-call so they don't lose their own half of the conversation.
  silentWhileSystemActive,
}

/// Tracks live audio statistics for the mic ("me") and system ("them") channels
/// to (a) drive a real amplitude level meter and (b) detect a dead/muted mic
/// during a recording.
///
/// MeetingMicHealthTracker: a mic that stays silent while
/// the far end is plainly talking is almost always broken, not just a listening
/// pause. Pure (time is passed in) so it is deterministic and unit-testable.
class MeetingMicHealthTracker {
  /// Creates a tracker. Defaults are tuned for 16 kHz PCM16 normalized RMS.
  MeetingMicHealthTracker({
    this.micFloor = 0.01,
    this.systemFloor = 0.02,
    this.confirmMs = 3000,
    this.recentSystemWindowMs = 2000,
    this.levelSmoothing = 0.4,
  });

  /// Normalized RMS (0..1) above which the mic counts as carrying speech.
  final double micFloor;

  /// Normalized RMS above which the system channel counts as actively playing.
  final double systemFloor;

  /// How long the mic must stay below [micFloor] (while the system is active)
  /// before the mic is reported as silent — avoids flagging brief pauses.
  final int confirmMs;

  /// How recently the system must have been active for the silent-mic check to
  /// apply (so an old, long-finished remote turn doesn't keep the warning up).
  final int recentSystemWindowMs;

  /// EMA factor (0..1) for the reported [level]; higher = snappier.
  final double levelSmoothing;

  int? _lastTMs;
  int? _lastMicAboveFloorMs;
  int? _lastSystemActiveMs;
  int? _firstMicMs;
  double _level = 0;

  /// Smoothed mic level in 0..1, for an amplitude-driven meter.
  double get level => _level;

  /// Records a mic chunk's normalized [rms] stamped at shared-clock [tMs].
  void noteMic(double rms, int tMs) {
    _lastTMs = tMs;
    _firstMicMs ??= tMs;
    _level = _level + (rms.clamp(0.0, 1.0) - _level) * levelSmoothing;
    if (rms >= micFloor) {
      _lastMicAboveFloorMs = tMs;
    }
  }

  /// Records a system ("them") chunk's normalized [rms] stamped at [tMs].
  void noteSystem(double rms, int tMs) {
    if (tMs > (_lastTMs ?? 0)) {
      _lastTMs = tMs;
    }
    if (rms >= systemFloor) {
      _lastSystemActiveMs = tMs;
    }
  }

  /// The current mic-health verdict as of the latest stamped time.
  MicHealth get health {
    final now = _lastTMs;
    final systemActiveAt = _lastSystemActiveMs;
    if (now == null || systemActiveAt == null) {
      return MicHealth.ok;
    }
    final systemRecentlyActive = now - systemActiveAt <= recentSystemWindowMs;
    if (!systemRecentlyActive) {
      return MicHealth.ok;
    }
    // Silence is measured from the last time the mic rose above the floor, or
    // from the first mic sample if it has never risen above it.
    final since = _lastMicAboveFloorMs ?? _firstMicMs;
    if (since == null) {
      return MicHealth.ok;
    }
    final silentMs = now - since;
    return silentMs >= confirmMs
        ? MicHealth.silentWhileSystemActive
        : MicHealth.ok;
  }

  /// Whether the mic appears dead/muted while the remote is talking.
  bool get micSilentWhileActive => health == MicHealth.silentWhileSystemActive;

  /// Resets all state for a new recording.
  void reset() {
    _lastTMs = null;
    _lastMicAboveFloorMs = null;
    _lastSystemActiveMs = null;
    _firstMicMs = null;
    _level = 0;
  }

  /// Root-mean-square of one mono PCM16 buffer, normalized to 0..1. Shared so
  /// callers don't re-implement the same loop.
  static double rmsOfPcm16(List<int> bytes) {
    final n = bytes.length ~/ 2;
    if (n == 0) {
      return 0;
    }
    var sumSq = 0.0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      // Little-endian signed 16-bit.
      var s = bytes[i] | (bytes[i + 1] << 8);
      if (s >= 0x8000) {
        s -= 0x10000;
      }
      final v = s / 32768.0;
      sumSq += v * v;
    }
    return math.sqrt(sumSq / n);
  }
}
