/// A kind of observable signal that suggests a meeting is happening. The
/// SOURCES of these signals are OS-specific (macOS CoreAudio/EventKit, Windows
/// WASAPI sessions, Linux PipeWire, plus the cross-platform calendar), but the
/// fusion logic here is pure and platform-independent. MeetingCandidateResolver, whose detection logic ports verbatim while only the
/// collectors differ per OS.
enum MeetingSignalKind {
  /// A known conferencing app (Zoom / Meet / Teams / Webex / Slack huddle) is
  /// the frontmost / active process.
  conferencingApp,

  /// A browser tab is on a meeting URL (meet.google.com, zoom.us, teams, …).
  browserMeeting,

  /// A calendar event is scheduled to be happening right now.
  calendarEvent,

  /// The camera is in use.
  camera,

  /// The microphone is captured by another app.
  microphoneInUse,

  /// Sustained system audio output (someone is audibly talking).
  systemAudioActive,

  /// We are recording this meeting and still transcribing speech. The most
  /// direct possible evidence a meeting is live: it is observed only by the
  /// detection controller while a recording is in progress (stamped at the last
  /// time a transcript window was committed), and it exists precisely to stop
  /// the auto-stop suggestion from firing while people are still talking.
  activeRecording,
}

/// One observation of a [MeetingSignalKind] at a point in time.
class MeetingSignal {
  /// Creates a [MeetingSignal].
  const MeetingSignal({
    required this.kind,
    required this.active,
    required this.at,
    this.label,
  });

  /// Which signal this is.
  final MeetingSignalKind kind;

  /// Whether the signal is currently asserted.
  final bool active;

  /// When the observation was made (shared clock / wall clock).
  final DateTime at;

  /// Optional human label (app name, URL host, event title).
  final String? label;
}

/// A resolved likelihood that a meeting is underway.
class MeetingCandidate {
  /// Creates a [MeetingCandidate].
  const MeetingCandidate({
    required this.confidence,
    required this.primary,
    required this.since,
    this.label,
  });

  /// Fused confidence in `[0, 1]`.
  final double confidence;

  /// The strongest contributing signal kind.
  final MeetingSignalKind primary;

  /// The best human label among the active signals.
  final String? label;

  /// Earliest fresh-active observation time — when the candidate began.
  final DateTime since;
}

/// Tunable thresholds for detection + auto-stop.
class MeetingDetectionPolicy {
  /// Creates a [MeetingDetectionPolicy].
  const MeetingDetectionPolicy({
    this.freshness = const Duration(seconds: 20),
    this.minPresence = const Duration(seconds: 8),
    this.autoStopAfter = const Duration(seconds: 90),
    this.threshold = 0.6,
  });

  /// Signals older than this (relative to `now`) are ignored.
  final Duration freshness;

  /// A candidate must persist at least this long before a prompt is offered —
  /// debounces a brief blip (a notification sound, opening Zoom by accident).
  final Duration minPresence;

  /// While recording, this much time with no fresh candidate means the meeting
  /// has ended and an auto-stop should be suggested.
  final Duration autoStopAfter;

  /// Minimum fused confidence for a candidate to exist.
  final double threshold;
}

/// Per-kind base weights. A strong single signal (a conferencing app) is enough
/// on its own; weak signals (camera, audio) corroborate one another.
const Map<MeetingSignalKind, double> _kindWeight = {
  MeetingSignalKind.conferencingApp: 0.8,
  MeetingSignalKind.browserMeeting: 0.7,
  MeetingSignalKind.calendarEvent: 0.6,
  MeetingSignalKind.camera: 0.4,
  MeetingSignalKind.microphoneInUse: 0.35,
  MeetingSignalKind.systemAudioActive: 0.3,
  // Definitive on its own: if we are recording AND still transcribing speech,
  // the meeting is unambiguously live.
  MeetingSignalKind.activeRecording: 0.9,
};

/// Fuses recent [signals] into a [MeetingCandidate], or null when the evidence
/// is below [MeetingDetectionPolicy.threshold]. Pure + deterministic (time is
/// passed in) so the whole detection policy is unit-testable.
///
/// Confidence = the strongest active fresh signal's weight, plus a corroboration
/// bonus (+0.15 per additional distinct active kind), clamped to 1.0. The label
/// and primary come from the highest-weight active signal.
MeetingCandidate? resolveMeetingCandidate(
  Iterable<MeetingSignal> signals, {
  required DateTime now,
  MeetingDetectionPolicy policy = const MeetingDetectionPolicy(),
}) {
  // Keep the latest fresh observation per kind.
  final latest = <MeetingSignalKind, MeetingSignal>{};
  for (final s in signals) {
    if (!s.active) {
      continue;
    }
    if (now.difference(s.at) > policy.freshness || s.at.isAfter(now)) {
      continue;
    }
    final prev = latest[s.kind];
    if (prev == null || s.at.isAfter(prev.at)) {
      latest[s.kind] = s;
    }
  }
  if (latest.isEmpty) {
    return null;
  }

  MeetingSignalKind? best;
  var bestWeight = 0.0;
  for (final kind in latest.keys) {
    final w = _kindWeight[kind] ?? 0;
    if (w > bestWeight) {
      bestWeight = w;
      best = kind;
    }
  }
  if (best == null) {
    return null;
  }
  final corroboration = (latest.length - 1) * 0.15;
  final confidence = (bestWeight + corroboration).clamp(0.0, 1.0);
  if (confidence < policy.threshold) {
    return null;
  }
  final since = latest.values
      .map((s) => s.at)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return MeetingCandidate(
    confidence: confidence,
    primary: best,
    label: latest[best]?.label,
    since: since,
  );
}

/// Lifecycle state of the auto-detection prompt machine.
enum MeetingDetectionState {
  /// No candidate.
  idle,

  /// A candidate exists but has not yet persisted [MeetingDetectionPolicy.minPresence].
  watching,

  /// A prompt is being shown (candidate persisted long enough, not dismissed).
  prompting,

  /// The user accepted — a recording is in progress.
  recording,
}

/// Actions the host should take in response to an [MeetingDetectionStateMachine.update].
enum MeetingDetectionAction {
  /// Nothing to do.
  none,

  /// Show the "record this meeting?" prompt.
  showPrompt,

  /// Hide the prompt (the candidate vanished before the user answered).
  hidePrompt,

  /// Suggest stopping — the meeting appears to have ended.
  suggestAutoStop,
}

/// A pure, time-driven state machine that turns a stream of [MeetingCandidate]
/// resolutions into prompt / auto-stop actions.
/// MeetingPromptStateMachine: debounce with min-presence, suppress a dismissed
/// candidate until it clears, and auto-stop after a sustained no-signal gap.
///
/// The host drives it by calling [update] whenever signals change (or on a
/// timer) and reacts to the returned [MeetingDetectionAction]; it reports user
/// choices via [accept] / [dismiss] / [stopped].
class MeetingDetectionStateMachine {
  /// Creates a machine with the given [policy].
  MeetingDetectionStateMachine({
    this.policy = const MeetingDetectionPolicy(),
  });

  /// Detection thresholds.
  final MeetingDetectionPolicy policy;

  MeetingDetectionState _state = MeetingDetectionState.idle;
  DateTime? _candidateSince;
  DateTime? _lastCandidateAt;
  String? _dismissedLabel;

  /// Current state.
  MeetingDetectionState get state => _state;

  /// Advances the machine with the latest resolved [candidate] (or null) at
  /// [now], returning the action the host should take.
  MeetingDetectionAction update({
    required MeetingCandidate? candidate,
    required DateTime now,
  }) {
    if (candidate != null) {
      _lastCandidateAt = now;
    }

    switch (_state) {
      case MeetingDetectionState.recording:
        // Once recording, watch for the meeting ending (sustained no-signal).
        final last = _lastCandidateAt;
        if (candidate == null &&
            last != null &&
            now.difference(last) >= policy.autoStopAfter) {
          return MeetingDetectionAction.suggestAutoStop;
        }
        return MeetingDetectionAction.none;

      case MeetingDetectionState.idle:
      case MeetingDetectionState.watching:
      case MeetingDetectionState.prompting:
        if (candidate == null) {
          final wasPrompting = _state == MeetingDetectionState.prompting;
          _resetToIdle();
          return wasPrompting
              ? MeetingDetectionAction.hidePrompt
              : MeetingDetectionAction.none;
        }
        // A candidate is present. Suppress if the user dismissed this label and
        // it never cleared.
        if (_dismissedLabel != null && _dismissedLabel == candidate.label) {
          _state = MeetingDetectionState.watching;
          return MeetingDetectionAction.none;
        }
        _candidateSince ??= candidate.since;
        final persisted = now.difference(_candidateSince!) >= policy.minPresence;
        if (persisted) {
          if (_state != MeetingDetectionState.prompting) {
            _state = MeetingDetectionState.prompting;
            return MeetingDetectionAction.showPrompt;
          }
          return MeetingDetectionAction.none;
        }
        _state = MeetingDetectionState.watching;
        return MeetingDetectionAction.none;
    }
  }

  /// The user accepted the prompt — a recording has started.
  void accept() {
    _state = MeetingDetectionState.recording;
    _dismissedLabel = null;
  }

  /// The user dismissed the prompt for [label]; suppress it until it clears.
  void dismiss(String? label) {
    _dismissedLabel = label;
    _state = MeetingDetectionState.watching;
    _candidateSince = null;
  }

  /// The recording stopped — return to idle detection.
  void stopped() => _resetToIdle();

  void _resetToIdle() {
    _state = MeetingDetectionState.idle;
    _candidateSince = null;
    _dismissedLabel = null;
  }
}
