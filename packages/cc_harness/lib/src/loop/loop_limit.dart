/// A bound on how long a `/loop` runs.
sealed class LoopLimit {
  const LoopLimit();
}

/// Stop after this many iterations.
final class LoopIterationLimit extends LoopLimit {
  /// Creates a [LoopIterationLimit].
  const LoopIterationLimit(this.iterations);

  /// How many iterations the loop may run.
  final int iterations;

  @override
  String toString() => '$iterations iteration${iterations == 1 ? '' : 's'}';
}

/// Stop once this much wall-clock time has passed.
final class LoopDurationLimit extends LoopLimit {
  /// Creates a [LoopDurationLimit].
  const LoopDurationLimit(this.duration);

  /// How long the loop may run.
  final Duration duration;

  @override
  String toString() {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    final hours = duration.inHours;
    final rest = minutes - hours * 60;
    return rest == 0 ? '$hours hour${hours == 1 ? '' : 's'}' : '${hours}h ${rest}m';
  }
}

/// The parsed form of `/loop [limit] [prompt]`.
class ParsedLoopArgs {
  /// Creates a [ParsedLoopArgs].
  const ParsedLoopArgs({this.limit, this.prompt, this.error});

  /// The iteration or duration bound, when one was given.
  final LoopLimit? limit;

  /// Everything after the limit — the work to iterate on.
  final String? prompt;

  /// Set when a leading token LOOKED like a limit and failed to parse.
  final String? error;

  /// Whether parsing failed.
  bool get isError => error != null;
}

const Map<String, int> _unitSeconds = {
  's': 1, 'sec': 1, 'secs': 1, 'second': 1, 'seconds': 1,
  'm': 60, 'min': 60, 'mins': 60, 'minute': 60, 'minutes': 60,
  'h': 3600, 'hr': 3600, 'hrs': 3600, 'hour': 3600, 'hours': 3600,
};

const String _usage =
    'Usage: /loop [count|duration] <prompt>. '
    'Examples: /loop 10 fix the tests, /loop 30m refactor, /loop keep going.';

/// Parses `/loop` arguments into an optional bound plus the prompt.
///
/// The rule that makes this feel right in practice: a leading token that
/// LOOKS like a limit (starts with a digit or a sign) but fails to parse is a
/// hard error, while anything else is simply prompt text. So `/loop 10x` is a
/// mistake worth reporting, and `/loop keep going until the tests pass` starts
/// an unbounded loop rather than complaining that "keep" is not a number.
///
/// Accepted bounds: a bare count (`10`), a compact duration (`30m`, `2h`,
/// `1h30m`), or a count followed by a unit word (`10 minutes`).
ParsedLoopArgs parseLoopArgs(String args) {
  final trimmed = args.trim();
  if (trimmed.isEmpty) {
    return const ParsedLoopArgs();
  }

  final firstSpace = trimmed.indexOf(RegExp(r'\s'));
  final head = firstSpace < 0 ? trimmed : trimmed.substring(0, firstSpace);
  final rest = firstSpace < 0 ? '' : trimmed.substring(firstSpace + 1).trim();
  final token = head.toLowerCase();

  // Not a limit attempt at all → the whole thing is the prompt.
  if (!RegExp(r'^[+-]?\d').hasMatch(token)) {
    return ParsedLoopArgs(prompt: trimmed);
  }

  // A bare integer is a count — unless the NEXT word is a unit, in which case
  // it was a duration typed with a space ("10 minutes").
  if (RegExp(r'^\d+$').hasMatch(token)) {
    final count = int.parse(token);
    if (rest.isNotEmpty) {
      final restFirstSpace = rest.indexOf(RegExp(r'\s'));
      final unitWord = (restFirstSpace < 0
              ? rest
              : rest.substring(0, restFirstSpace))
          .toLowerCase();
      final seconds = _unitSeconds[unitWord];
      if (seconds != null) {
        if (count <= 0) {
          return const ParsedLoopArgs(error: _usage);
        }
        final remainder = restFirstSpace < 0
            ? ''
            : rest.substring(restFirstSpace + 1).trim();
        return ParsedLoopArgs(
          limit: LoopDurationLimit(Duration(seconds: count * seconds)),
          prompt: remainder.isEmpty ? null : remainder,
        );
      }
    }
    if (count <= 0) {
      return const ParsedLoopArgs(error: _usage);
    }
    return ParsedLoopArgs(
      limit: LoopIterationLimit(count),
      prompt: rest.isEmpty ? null : rest,
    );
  }

  // A compact duration: 30m, 2h, 1h30m, 90s.
  final duration = _parseCompactDuration(token);
  if (duration != null) {
    return ParsedLoopArgs(
      limit: LoopDurationLimit(duration),
      prompt: rest.isEmpty ? null : rest,
    );
  }

  // It started like a number and is not a valid limit — say so rather than
  // silently treating "10x" as prose.
  return const ParsedLoopArgs(error: _usage);
}

Duration? _parseCompactDuration(String token) {
  final pattern = RegExp(r'^(\d+)(s|sec|secs|m|min|mins|h|hr|hrs)');
  var remaining = token;
  var total = 0;
  var matched = false;
  while (remaining.isNotEmpty) {
    final match = pattern.firstMatch(remaining);
    if (match == null) {
      return null;
    }
    final value = int.parse(match.group(1)!);
    final unit = _unitSeconds[match.group(2)!];
    if (unit == null) {
      return null;
    }
    total += value * unit;
    matched = true;
    remaining = remaining.substring(match.end);
  }
  if (!matched || total <= 0) {
    return null;
  }
  return Duration(seconds: total);
}

/// Tracks a loop's remaining budget across iterations.
///
/// Deliberately separate from the parser so the supervisor can persist and
/// restore it: a `/loop 10` that survives a server restart has to remember it
/// is on iteration 4, and a counter living only in a parse result could not.
class LoopBudget {
  /// Creates a [LoopBudget] from a parsed [limit], starting now.
  LoopBudget({LoopLimit? limit, DateTime? startedAt})
    : _limit = limit,
      _startedAt = startedAt ?? DateTime.now();

  /// Restores a budget mid-flight.
  LoopBudget.resumed({
    LoopLimit? limit,
    required DateTime startedAt,
    required int completed,
  }) : _limit = limit,
       _startedAt = startedAt,
       _completed = completed;

  final LoopLimit? _limit;
  final DateTime _startedAt;
  int _completed = 0;

  /// How many iterations have finished.
  int get completed => _completed;

  /// When the loop started.
  DateTime get startedAt => _startedAt;

  /// The bound, or null for an unbounded loop.
  LoopLimit? get limit => _limit;

  /// Records that an iteration finished.
  void recordIteration() => _completed++;

  /// Whether another iteration is allowed, as of [now].
  bool allowsAnother({DateTime? now}) {
    final at = now ?? DateTime.now();
    return switch (_limit) {
      null => true,
      LoopIterationLimit(:final iterations) => _completed < iterations,
      // Checked against elapsed time rather than a deadline computed at parse
      // time, so a loop that was paused (server restart, take-over) resumes
      // with the wall clock it actually consumed.
      LoopDurationLimit(:final duration) =>
        at.difference(_startedAt) < duration,
    };
  }

  /// A short human-readable state, for the status line and the stop notice.
  String describe({DateTime? now}) {
    final at = now ?? DateTime.now();
    return switch (_limit) {
      null => 'unbounded ($_completed done)',
      LoopIterationLimit(:final iterations) =>
        'iteration ${_completed + 1} of $iterations',
      LoopDurationLimit(:final duration) => () {
        final left = duration - at.difference(_startedAt);
        if (left.isNegative) {
          return 'time budget spent';
        }
        final minutes = left.inMinutes;
        return minutes >= 1
            ? '$minutes minute(s) left'
            : '${left.inSeconds} second(s) left';
      }(),
    };
  }

  /// Why the loop stopped, when it stopped because of the budget.
  String get exhaustedReason => switch (_limit) {
    null => 'The loop was stopped.',
    LoopIterationLimit(:final iterations) =>
      'Loop finished: $iterations iteration'
          '${iterations == 1 ? '' : 's'} completed.',
    LoopDurationLimit(:final duration) =>
      'Loop finished: the $duration budget is spent.',
  };
}
