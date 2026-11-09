import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// IANA timezone rules for scheduled pipeline triggers, backed by the embedded
/// `timezone` database.
///
/// Plugs into [PipelineCronScheduler] as its `toLocal` / `toUtc` converters, so
/// a cron trigger with `timezone: Europe/Berlin` fires at Berlin wall-clock
/// time across DST changes instead of being read as UTC. The cron matcher works
/// on the literal fields of the [DateTime] it is handed, so a wall-clock time
/// travels as a UTC-flagged [DateTime] carrying the local fields.
///
/// A non-existent wall-clock time (inside a spring-forward gap) resolves to the
/// instant just after the gap; an ambiguous one (the repeated fall-back hour)
/// resolves to its first occurrence.
final class TimezoneZoneConverter {
  TimezoneZoneConverter._();

  /// The process-wide converter. Loads the zone database on first use.
  static final TimezoneZoneConverter instance = TimezoneZoneConverter._();

  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) {
      return;
    }
    tzdata.initializeTimeZones();
    _loaded = true;
  }

  tz.Location _location(String name) {
    _ensureLoaded();
    if (name.isEmpty || name == 'UTC' || name == 'Etc/UTC') {
      return tz.UTC;
    }
    return tz.getLocation(name);
  }

  /// Whether [name] is a zone this database knows (`UTC` and the empty string
  /// always are). Used to reject a trigger whose timezone could never resolve.
  bool isKnown(String name) {
    try {
      _location(name.trim());
      return true;
    } on Object {
      return false;
    }
  }

  /// [utc] as wall-clock fields in [timezone] (returned UTC-flagged).
  DateTime toLocal(DateTime utc, String timezone) {
    final local = tz.TZDateTime.from(utc.toUtc(), _location(timezone));
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }

  /// The instant at which [wallClock]'s fields occur in [timezone].
  DateTime toUtc(DateTime wallClock, String timezone) => tz.TZDateTime(
    _location(timezone),
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  ).toUtc();

  /// A scheduler that evaluates every trigger in its own timezone.
  PipelineCronScheduler scheduler() =>
      PipelineCronScheduler(toLocal: toLocal, toUtc: toUtc);
}
