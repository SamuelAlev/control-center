/// A parsed standard 5-field cron expression:
/// `minute hour day-of-month month day-of-week`.
///
/// Pure-Dart and timezone-agnostic: every method operates on the literal
/// wall-clock fields of the [DateTime] it is given (matching against
/// `DateTime.utc` for a UTC schedule, or a timezone-shifted wall-clock the
/// scheduler supplies). It never consults the host's local zone, so it is fully
/// deterministic and unit-testable.
///
/// Supported field syntax: `*`, `*/n` (step), `a`, `a-b` (range), `a-b/n`, and
/// comma-separated lists of those. Day-of-week accepts `0` or `7` for Sunday.
/// Day-of-month / day-of-week follow the standard union rule: when BOTH are
/// restricted (not `*`), a day matches if EITHER matches; when only one is
/// restricted, only that field constrains.
class CronSchedule {
  CronSchedule._({
    required this.minutes,
    required this.hours,
    required this.daysOfMonth,
    required this.months,
    required this.daysOfWeek,
    required this.domRestricted,
    required this.dowRestricted,
    required this.expression,
  });

  /// Minute field (0-59).
  final Set<int> minutes;

  /// Hour field (0-23).
  final Set<int> hours;

  /// Day-of-month field (1-31).
  final Set<int> daysOfMonth;

  /// Month field (1-12).
  final Set<int> months;

  /// Day-of-week field, normalised to 0-6 (Sunday = 0).
  final Set<int> daysOfWeek;

  /// Whether the day-of-month field was restricted (not `*`).
  final bool domRestricted;

  /// Whether the day-of-week field was restricted (not `*`).
  final bool dowRestricted;

  /// The original expression text.
  final String expression;

  /// Parses [expression], returning `null` when it is not a valid 5-field cron.
  static CronSchedule? tryParse(String expression) {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      return null;
    }
    final minutes = _parseField(parts[0], 0, 59);
    final hours = _parseField(parts[1], 0, 23);
    final dom = _parseField(parts[2], 1, 31);
    final months = _parseField(parts[3], 1, 12);
    final dow = _parseField(parts[4], 0, 7);
    if (minutes == null ||
        hours == null ||
        dom == null ||
        months == null ||
        dow == null) {
      return null;
    }
    // Normalise Sunday-as-7 to 0.
    final normalisedDow = dow.map((d) => d == 7 ? 0 : d).toSet();
    return CronSchedule._(
      minutes: minutes,
      hours: hours,
      daysOfMonth: dom,
      months: months,
      daysOfWeek: normalisedDow,
      domRestricted: parts[2].trim() != '*',
      dowRestricted: parts[4].trim() != '*',
      expression: expression.trim(),
    );
  }

  /// Whether [when]'s wall-clock fields satisfy this schedule.
  bool matches(DateTime when) {
    return minutes.contains(when.minute) &&
        hours.contains(when.hour) &&
        months.contains(when.month) &&
        _dayMatches(when);
  }

  /// The next firing strictly after [from] (minute granularity), or `null` if
  /// none is found within [maxIterations] field advances (a malformed-but-parsed
  /// expression such as Feb-30 can be unsatisfiable).
  DateTime? nextAfter(DateTime from, {int maxIterations = 500000}) {
    var t = _build(
      from,
      from.year,
      from.month,
      from.day,
      from.hour,
      from.minute + 1,
    );
    for (var i = 0; i < maxIterations; i++) {
      if (!months.contains(t.month)) {
        t = _build(t, t.year, t.month + 1, 1);
        continue;
      }
      if (!_dayMatches(t)) {
        t = _build(t, t.year, t.month, t.day + 1);
        continue;
      }
      if (!hours.contains(t.hour)) {
        t = _build(t, t.year, t.month, t.day, t.hour + 1);
        continue;
      }
      if (!minutes.contains(t.minute)) {
        t = _build(t, t.year, t.month, t.day, t.hour, t.minute + 1);
        continue;
      }
      return t;
    }
    return null;
  }

  bool _dayMatches(DateTime when) {
    final domOk = daysOfMonth.contains(when.day);
    // Dart weekday: Mon=1..Sun=7. Cron dow: Sun=0..Sat=6.
    final cronDow = when.weekday % 7;
    final dowOk = daysOfWeek.contains(cronDow);
    if (domRestricted && dowRestricted) {
      return domOk || dowOk;
    }
    if (domRestricted) {
      return domOk;
    }
    if (dowRestricted) {
      return dowOk;
    }
    return true;
  }

  /// Builds a [DateTime] in the same zone (UTC vs local) as [ref], letting the
  /// constructor normalise field overflow (e.g. month 13 → next year).
  static DateTime _build(
    DateTime ref,
    int y,
    int mo,
    int d, [
    int h = 0,
    int mi = 0,
  ]) {
    return ref.isUtc
        ? DateTime.utc(y, mo, d, h, mi)
        : DateTime(y, mo, d, h, mi);
  }

  static Set<int>? _parseField(String field, int min, int max) {
    final result = <int>{};
    for (final part in field.split(',')) {
      final token = part.trim();
      if (token.isEmpty) {
        return null;
      }
      var range = token;
      var step = 1;
      final slash = token.indexOf('/');
      if (slash != -1) {
        final stepStr = token.substring(slash + 1);
        final parsed = int.tryParse(stepStr);
        if (parsed == null || parsed <= 0) {
          return null;
        }
        step = parsed;
        range = token.substring(0, slash);
      }
      int lo;
      int hi;
      if (range == '*') {
        lo = min;
        hi = max;
      } else if (range.contains('-')) {
        final bounds = range.split('-');
        if (bounds.length != 2) {
          return null;
        }
        final a = int.tryParse(bounds[0].trim());
        final b = int.tryParse(bounds[1].trim());
        if (a == null || b == null) {
          return null;
        }
        lo = a;
        hi = b;
      } else {
        final v = int.tryParse(range);
        if (v == null) {
          return null;
        }
        lo = v;
        hi = v;
      }
      if (lo < min || hi > max || lo > hi) {
        return null;
      }
      for (var v = lo; v <= hi; v += step) {
        result.add(v);
      }
    }
    return result.isEmpty ? null : result;
  }
}
