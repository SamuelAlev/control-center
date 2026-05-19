import 'dart:convert';

/// The number of consecutive identical tool calls that constitutes a doom loop.
///
/// An agent that calls the *same* tool with the *same* arguments this many times in
/// a row is stuck repeating itself instead of making progress.
const int kDoomLoopThreshold = 3;

/// The outcome of feeding one tool call to a [DoomLoopDetector].
enum DoomLoopDecision {
  /// No doom loop: the trailing streak of identical calls is below threshold.
  none,

  /// A doom loop: the last [DoomLoopDetector.threshold] calls were all identical
  /// (same tool + same arguments). The caller should steer or abort.
  detected,
}

/// A stable, comparable fingerprint of a single tool invocation.
///
/// Two invocations are considered "the same call" when their [toolName] and
/// their canonical [argsJson] both match. The canonical encoding makes
/// comparison robust to incidental map key ordering, so `{a: 1, b: 2}` and
/// `{b: 2, a: 1}` produce equal signatures.
class ToolCallSignature {
  /// Creates a signature from an already-canonical [toolName] and [argsJson].
  ///
  /// Prefer [ToolCallSignature.from], which derives a stable [argsJson] for you.
  const ToolCallSignature(this.toolName, this.argsJson);

  /// Builds a signature for a call to [toolName] with [args].
  ///
  /// [args] is encoded to a stable JSON string: every map encountered (at any
  /// depth) is re-emitted with its keys sorted, so logically-equal argument
  /// objects that differ only in key order compare equal.
  factory ToolCallSignature.from(String toolName, Object? args) {
    return ToolCallSignature(toolName, _stableJson(args));
  }

  /// The name of the invoked tool.
  final String toolName;

  /// A stable JSON encoding of the call arguments (maps have sorted keys).
  final String argsJson;

  /// Encodes [value] to JSON with all nested map keys sorted, so the result is
  /// independent of the original key insertion order.
  static String _stableJson(Object? value) => jsonEncode(_canonicalize(value));

  /// Recursively rewrites [value] so that every map is re-emitted with its keys
  /// sorted lexicographically; lists keep their order; scalars pass through
  /// unchanged.
  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final out = <String, Object?>{};
      for (final key in keys) {
        out[key] = _canonicalize(value[key]);
      }
      return out;
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolCallSignature &&
          other.toolName == toolName &&
          other.argsJson == argsJson;

  @override
  int get hashCode => Object.hash(toolName, argsJson);

  @override
  String toString() => 'ToolCallSignature($toolName, $argsJson)';
}

/// Detects an agent stuck calling the same tool with the same arguments
/// repeatedly — the "doom loop" failure mode.
///
/// Feed each tool call's [ToolCallSignature] to [record] in order. It tracks a
/// running streak of consecutive identical trailing signatures (equivalent to
/// the reference's "last N signatures all equal" check, but without retaining a
/// slice of history). [record] returns [DoomLoopDecision.detected] once that
/// streak reaches [threshold], and keeps returning `detected` for each further
/// identical call — the caller decides how to escalate. Any differing call
/// resets the streak to 1.
class DoomLoopDetector {
  /// Creates a detector that fires after [threshold] identical calls in a row.
  DoomLoopDetector({this.threshold = kDoomLoopThreshold})
    : assert(threshold >= 1, 'threshold must be at least 1');

  /// The number of consecutive identical calls that triggers detection.
  final int threshold;

  ToolCallSignature? _last;
  int _streak = 0;

  /// The current count of consecutive identical trailing signatures.
  ///
  /// `0` before any call is recorded (or after [reset]); otherwise the length of
  /// the unbroken run of the most recent signature.
  int get currentStreak => _streak;

  /// Records [sig] and reports whether a doom loop is now present.
  ///
  /// Extends the streak when [sig] equals the previously recorded signature,
  /// otherwise restarts the streak at 1. Returns [DoomLoopDecision.detected]
  /// when the streak is at or above [threshold], else [DoomLoopDecision.none].
  DoomLoopDecision record(ToolCallSignature sig) {
    if (_last != null && _last == sig) {
      _streak++;
    } else {
      _streak = 1;
      _last = sig;
    }
    return _streak >= threshold
        ? DoomLoopDecision.detected
        : DoomLoopDecision.none;
  }

  /// Clears all accumulated state, so the next [record] starts a fresh streak.
  void reset() {
    _last = null;
    _streak = 0;
  }
}

/// Builds the steering message shown to an agent caught in a doom loop.
///
/// [toolName] is the repeated tool and [count] is how many times in a row it has
/// been called with identical arguments. The message instructs the agent to
/// stop repeating the call and change approach or report what is blocking it.
String doomLoopSteerNotice(String toolName, int count) =>
    '[loop notice] You have called `$toolName` with identical arguments $count '
    'times in a row. Stop repeating it — change approach or report what is '
    'blocking you.';
