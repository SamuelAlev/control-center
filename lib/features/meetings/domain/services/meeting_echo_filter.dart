import 'dart:async';
import 'dart:math' as math;

import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/services/transcribed_window.dart';

/// Called when the filter decides a window is genuine and should be persisted.
/// Returns a future so [MeetingEchoFilter.drain] can await persistence before
/// the recorder reads segments back at stop().
typedef OnAccepted = Future<void> Function(
  MeetingSpeaker speaker,
  TranscribedWindow window,
);

/// A transcribed window offered to the [MeetingEchoFilter], tagged with its
/// channel and a recording-relative emit timestamp (ms) from a single shared
/// clock — the only timeline on which the two channels are comparable.
class EchoCandidate {
  /// Creates an [EchoCandidate].
  const EchoCandidate({
    required this.speaker,
    required this.window,
    required this.emitMs,
  });

  /// Which channel produced this window.
  final MeetingSpeaker speaker;

  /// The transcribed window.
  final TranscribedWindow window;

  /// Recording-relative emit time (ms) from the shared clock.
  final int emitMs;
}

/// Removes the duplicate "me" windows that arise when the microphone picks up
/// the remote participants playing out of the speakers/headphones.
///
/// The system loopback ("them") never captures the mic, so "them" is always the
/// authoritative copy and the mic echo is a degraded, fragmented duplicate of
/// it. Resolution is therefore strictly one-directional: a "me" window that
/// matches a near-contemporaneous "them" window is dropped; "them" is never
/// dropped, held, or reordered.
///
/// Ordering is handled both ways. "them" is committed immediately and buffered;
/// a "me" that matches a buffered "them" is dropped on arrival (them-first). A
/// "me" with no match yet is *held* so a later "them" can still cancel it
/// (me-first). The hold is adaptive (see [noteSystemActivity]): long
/// ([activeHoldMs]) while the remote is playing — the bleed's authoritative
/// "them" window is longer and emitted seconds later, so the hold must outlast
/// that lag — and brief ([idleHoldMs]) while the remote is quiet, when no echo
/// is possible. The invariant [activeHoldMs] >= [matchWindowMs] guarantees a
/// held "me" never commits before its same-band "them" could cancel it.
///
/// When the remote is quiet (the user is speaking into silence, or there is no
/// bleed at all) nothing matches, every "me" commits after the short
/// [idleHoldMs], and the only effect is a negligible latency on the user's own
/// lines. A "me" spoken *over* the remote is held for [activeHoldMs] and then
/// committed if no "them" claimed it — correct, just delayed.
class MeetingEchoFilter {
  /// Creates a [MeetingEchoFilter].
  ///
  /// A "me" window with no matching "them" is held before committing. The hold
  /// is *adaptive*, keyed on recent system-channel activity (fed via
  /// [noteSystemActivity]): [activeHoldMs] when the remote played within the
  /// last [activeWindowMs] (the "me" could be speaker bleed, and its
  /// authoritative "them" window — longer, emitted seconds later — must be given
  /// time to arrive and cancel it), or the much shorter [idleHoldMs] when the
  /// remote was quiet (no echo is possible). [bufferMs] is how long recent
  /// "them" windows are retained for comparison. [matchWindowMs] is the ±
  /// emit-time band within which a "me" and "them" window can match — wide
  /// enough to span the lag between a short, early "me" echo and its long, late
  /// "them" source. [similarityThreshold] and [minTokens] govern the text match.
  MeetingEchoFilter({
    required OnAccepted onAccepted,
    this.idleHoldMs = 700,
    this.activeHoldMs = 7000,
    this.activeWindowMs = 2500,
    this.bufferMs = 11000,
    this.matchWindowMs = 7000,
    this.similarityThreshold = 0.6,
    this.minTokens = 3,
  })  : _onAccepted = onAccepted,
        assert(activeHoldMs >= matchWindowMs,
            'activeHoldMs must be >= matchWindowMs so a held "me" cannot commit '
            'before its same-band "them" could cancel it');

  final OnAccepted _onAccepted;

  /// Brief debounce (ms) before committing a "me" emitted while the remote was
  /// quiet — no echo is possible, so it commits almost immediately.
  final int idleHoldMs;

  /// Long debounce (ms) for a "me" emitted while the remote was recently
  /// playing: held until its (late, long) "them" source could arrive and cancel
  /// it. A genuine "me" spoken over the remote commits after this delay.
  final int activeHoldMs;

  /// How recently (ms) the system channel must have had audio for a "me" to be
  /// treated as echo-possible (and thus held for [activeHoldMs] not [idleHoldMs]).
  final int activeWindowMs;

  /// Retention window (ms) for recent "them" windows.
  final int bufferMs;

  /// ± emit-time band (ms) within which a "me" can match a "them".
  final int matchWindowMs;

  /// Containment-similarity threshold (0–1) for a match.
  final double similarityThreshold;

  /// Windows shorter than this many tokens are never matched as echoes
  /// (protects backchannels like "okay" / "yeah").
  final int minTokens;

  final List<_BufferedWindow> _recentThem = [];
  final List<_PendingMe> _pendingMe = [];
  bool _disposed = false;

  /// Shared-clock time (ms) of the most recent system-channel audio above the
  /// silence floor — null until the remote first plays. Drives the adaptive
  /// hold in [_offerMe].
  int? _lastSystemActivityMs;

  /// Records that the system ("them") channel had audio at [emitMs] (shared
  /// clock). Cheap; called per active system chunk by the recorder. A "me"
  /// emitted within [activeWindowMs] of the latest activity is treated as
  /// echo-possible and held for [activeHoldMs]; otherwise it commits promptly.
  void noteSystemActivity(int emitMs) {
    if (_disposed) {
      return;
    }
    if (_lastSystemActivityMs == null || emitMs > _lastSystemActivityMs!) {
      _lastSystemActivityMs = emitMs;
    }
  }

  /// Offers a transcribed [candidate] to the filter.
  void add(EchoCandidate candidate) {
    if (_disposed) {
      return;
    }
    _pruneThem(candidate.emitMs);
    final tokens = echoTokens(candidate.window.text).toSet();
    if (candidate.speaker == MeetingSpeaker.them) {
      _acceptThem(candidate, tokens);
    } else {
      _offerMe(candidate, tokens);
    }
  }

  void _acceptThem(EchoCandidate candidate, Set<String> tokens) {
    // Authoritative: persist immediately, never held or dropped.
    _commit(candidate);
    final buffered =
        _BufferedWindow(candidate.window, candidate.emitMs, tokens);
    _recentThem.add(buffered);
    // Reconcile: a "me" held earlier may be an echo of this just-arrived "them".
    _pendingMe.removeWhere((p) {
      final sim = _echoSim(p.candidate.emitMs, p.tokens, buffered);
      if (sim != null) {
        p.timer.cancel();
        _logDrop(p.candidate, buffered, sim);
        return true;
      }
      return false;
    });
  }

  void _offerMe(EchoCandidate candidate, Set<String> tokens) {
    for (final them in _recentThem) {
      final sim = _echoSim(candidate.emitMs, tokens, them);
      if (sim != null) {
        _logDrop(candidate, them, sim);
        return; // echo of a buffered "them" — drop now.
      }
    }
    // No match yet — hold so a still-incoming "them" can cancel it. The hold is
    // adaptive: if the remote was playing when this "me" was emitted it may be
    // bleed whose (late, long) "them" source hasn't arrived yet → hold long;
    // otherwise no echo is possible → commit promptly.
    final last = _lastSystemActivityMs;
    final echoPossible =
        last != null && (candidate.emitMs - last) <= activeWindowMs;
    final hold = echoPossible ? activeHoldMs : idleHoldMs;
    late _PendingMe pending;
    final timer = Timer(Duration(milliseconds: hold), () {
      _pendingMe.remove(pending);
      _commit(candidate);
    });
    pending = _PendingMe(candidate, tokens, timer);
    _pendingMe.add(pending);
  }

  /// Returns the match similarity if [meTokens] (emitted at [meEmitMs]) is an
  /// echo of the buffered [them] window, or null if they do not match.
  double? _echoSim(int meEmitMs, Set<String> meTokens, _BufferedWindow them) {
    if ((meEmitMs - them.emitMs).abs() > matchWindowMs) {
      return null;
    }
    if (meTokens.length < minTokens || them.tokens.length < minTokens) {
      return null;
    }
    final sim = echoSimilarity(meTokens, them.tokens);
    return sim >= similarityThreshold ? sim : null;
  }

  /// Commits the held "me" windows immediately, awaiting persistence. Called on
  /// stop() so the tail of the recording is not lost and is on disk before the
  /// recorder reads segments back.
  Future<void> drain() async {
    if (_disposed) {
      return;
    }
    final pending = List<_PendingMe>.of(_pendingMe);
    _pendingMe.clear();
    for (final p in pending) {
      p.timer.cancel();
      try {
        await _onAccepted(p.candidate.speaker, p.candidate.window);
      } catch (e) {
        AppLog.w('MeetingEchoFilter', 'drain commit failed: $e');
      }
    }
    _recentThem.clear();
  }

  /// Hard teardown: cancels pending timers and commits nothing.
  void dispose() {
    _disposed = true;
    for (final p in _pendingMe) {
      p.timer.cancel();
    }
    _pendingMe.clear();
    _recentThem.clear();
  }

  void _commit(EchoCandidate candidate) {
    unawaited(
      Future<void>(() => _onAccepted(candidate.speaker, candidate.window))
          .catchError((Object e, StackTrace s) {
        AppLog.w('MeetingEchoFilter', 'persist failed: $e');
      }),
    );
  }

  void _pruneThem(int nowEmitMs) {
    _recentThem.removeWhere((t) => t.emitMs < nowEmitMs - bufferMs);
  }

  void _logDrop(EchoCandidate me, _BufferedWindow them, double sim) {
    AppLog.d(
      'MeetingCapture',
      'dropped echo of them (sim ${sim.toStringAsFixed(2)}): '
          '"${_snippet(me.window.text)}"',
    );
  }

  static String _snippet(String text) =>
      text.length <= 60 ? text : '${text.substring(0, 60)}…';
}

class _BufferedWindow {
  _BufferedWindow(this.window, this.emitMs, this.tokens);
  final TranscribedWindow window;
  final int emitMs;
  final Set<String> tokens;
}

class _PendingMe {
  _PendingMe(this.candidate, this.tokens, this.timer);
  final EchoCandidate candidate;
  final Set<String> tokens;
  final Timer timer;
}

final RegExp _nonTokenChars = RegExp(r'[^a-z0-9 ]');
final RegExp _whitespace = RegExp(r'\s+');

/// Normalizes [text] to comparable tokens: lowercase, fold out punctuation
/// (Whisper's punctuation is unreliable), split on whitespace. Both channels
/// are processed identically, so the representation only has to be consistent,
/// not linguistically perfect.
List<String> echoTokens(String text) {
  final cleaned = text.toLowerCase().replaceAll(_nonTokenChars, ' ');
  return cleaned.split(_whitespace).where((t) => t.isNotEmpty).toList();
}

/// Containment / overlap coefficient: `|a ∩ b| / min(|a|, |b|)`.
///
/// NOT Jaccard — the mic echo is usually a *fragment* of the longer "them"
/// line, and Jaccard under-scores fragments. Containment scores a clean subset
/// 1.0 in either direction.
double echoSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  final inter = a.intersection(b).length;
  final denom = math.min(a.length, b.length);
  return denom == 0 ? 0 : inter / denom;
}

/// Whether [a] and [b] are similar enough (by [echoSimilarity]) to be the same
/// utterance, at or above [threshold].
bool isEchoMatch(Set<String> a, Set<String> b, {double threshold = 0.6}) {
  if (a.isEmpty || b.isEmpty) {
    return false;
  }
  return echoSimilarity(a, b) >= threshold;
}
