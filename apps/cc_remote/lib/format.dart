/// Small display formatters shared by the phone's surfaces.
///
/// Locale-aware: month/weekday names come from `package:intl`'s [DateFormat]
/// (whose symbols are loaded once in `main()` via `initializeDateFormatting()`
/// — required on web for non-English locales) and the relative words (`now`,
/// `Today`, compact `4m`/`3h` forms) come from the ARB bundle. Every formatter
/// takes the [BuildContext] it renders under, which supplies both the resolved
/// locale and the [AppLocalizations] lookup.
library;

import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A compact "time since" label: `now`, `4m`, `3h`, `6d`, then a date.
///
/// Rows on a phone are dense; `2026-08-21` in a list of twenty PRs reads as
/// noise, while `3d` reads as recency at a glance. Past two weeks the absolute
/// date carries more than a growing day count, so it takes over.
String shortAgo(BuildContext context, DateTime? when) {
  if (when == null) {
    return '';
  }
  final l10n = AppLocalizations.of(context);
  final delta = DateTime.now().difference(when.toLocal());
  if (delta.isNegative || delta.inMinutes < 1) {
    return l10n.now;
  }
  if (delta.inMinutes < 60) {
    return l10n.agoMinutes(delta.inMinutes);
  }
  if (delta.inHours < 24) {
    return l10n.agoHours(delta.inHours);
  }
  if (delta.inDays <= 14) {
    return l10n.agoDays(delta.inDays);
  }
  return shortDate(context, when);
}

/// `Aug 21` (locale order) for a date in the current year, with the year
/// appended otherwise.
String shortDate(BuildContext context, DateTime when) {
  final local = when.toLocal();
  final locale = _localeOf(context);
  return local.year == DateTime.now().year
      ? DateFormat.MMMd(locale).format(local)
      : DateFormat.yMMMd(locale).format(local);
}

/// `14:05` — 24-hour by design (dense rows), digits and separator follow the
/// locale.
String clockTime(BuildContext context, DateTime when) {
  return DateFormat.Hm(_localeOf(context)).format(when.toLocal());
}

/// `Mon, Aug 21` — the calendar's day-header form, with `Today` / `Tomorrow` /
/// `Yesterday` for the adjacent days.
String dayHeading(BuildContext context, DateTime day) {
  final local = day.toLocal();
  final today = _dayKey(DateTime.now());
  final key = _dayKey(local);
  final l10n = AppLocalizations.of(context);
  if (key == today) {
    return l10n.today;
  }
  if (key == today + 1) {
    return l10n.tomorrow;
  }
  if (key == today - 1) {
    return l10n.yesterday;
  }
  return DateFormat.MMMEd(_localeOf(context)).format(local);
}

/// A duration as `45m` / `1h 30m` / `2h`.
String shortDuration(BuildContext context, Duration d) {
  final l10n = AppLocalizations.of(context);
  final minutes = d.inMinutes;
  if (minutes < 60) {
    return l10n.durationMinutes(minutes);
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? l10n.durationHours(hours)
      : l10n.durationHoursMinutes(hours, rest);
}

/// `+120 −8` churn, or an empty string when there is none. Numeric and
/// universal — deliberately not localised.
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

/// The resolved locale as a BCP 47 tag, for [DateFormat] constructors.
String _localeOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();
