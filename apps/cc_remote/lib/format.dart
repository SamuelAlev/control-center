/// Small display formatters shared by the phone's surfaces.
///
/// Deliberately dependency-free and English-only: cc_remote ships no ARB
/// bundle yet (its chrome is English, and `appLocaleProvider` stores the
/// choice for when it does), so pulling `package:intl` in for these would add
/// locale data to the most bandwidth-sensitive tier in the product for output
/// nothing localises yet.
library;

/// A compact "time since" label: `now`, `4m`, `3h`, `6d`, then a date.
///
/// Rows on a phone are dense; `2026-08-21` in a list of twenty PRs reads as
/// noise, while `3d` reads as recency at a glance. Past two weeks the absolute
/// date carries more than a growing day count, so it takes over.
String shortAgo(DateTime? when) {
  if (when == null) {
    return '';
  }
  final delta = DateTime.now().difference(when.toLocal());
  if (delta.isNegative) {
    return 'now';
  }
  if (delta.inMinutes < 1) {
    return 'now';
  }
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes}m';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h';
  }
  if (delta.inDays <= 14) {
    return '${delta.inDays}d';
  }
  return shortDate(when);
}

/// `21 Aug` for a date in the current year, `21 Aug 2025` otherwise.
String shortDate(DateTime when) {
  final local = when.toLocal();
  final month = _months[local.month - 1];
  return local.year == DateTime.now().year
      ? '${local.day} $month'
      : '${local.day} $month ${local.year}';
}

/// `14:05`, 24-hour.
String clockTime(DateTime when) {
  final local = when.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// `Mon 21 Aug` — the calendar's day-header form.
String dayHeading(DateTime day) {
  final local = day.toLocal();
  final today = _dayKey(DateTime.now());
  final key = _dayKey(local);
  if (key == today) {
    return 'Today';
  }
  if (key == today + 1) {
    return 'Tomorrow';
  }
  if (key == today - 1) {
    return 'Yesterday';
  }
  return '${_weekdays[local.weekday - 1]} ${local.day} '
      '${_months[local.month - 1]}';
}

/// A duration as `45m` / `1h 30m` / `2h`.
String shortDuration(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 60) {
    return '${minutes}m';
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

/// `+120 −8` churn, or an empty string when there is none.
String churn(int additions, int deletions) {
  if (additions == 0 && deletions == 0) {
    return '';
  }
  return '+$additions −$deletions';
}

/// Days since the epoch, in LOCAL time — the key that makes "same calendar
/// day" a comparison instead of a three-field test.
int _dayKey(DateTime when) {
  final local = when.toLocal();
  return DateTime(local.year, local.month, local.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// The local calendar day [when] falls on, at midnight.
DateTime startOfDay(DateTime when) {
  final local = when.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Whether [a] and [b] fall on the same local calendar day.
bool sameDay(DateTime a, DateTime b) => _dayKey(a) == _dayKey(b);

String _two(int n) => n.toString().padLeft(2, '0');

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
