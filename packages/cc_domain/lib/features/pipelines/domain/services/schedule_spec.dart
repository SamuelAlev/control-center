import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';

/// The slots a schedule has, whatever owns it: a pipeline's scheduled trigger
/// or a wake rule (`every:` / `cron:`). `PipelineCronScheduler` computes every
/// slot from these three facts, so the epoch-aligned interval arithmetic and
/// the time-zone handling exist once.
///
/// Exactly one of [intervalSeconds] and [cronSchedule] is set for a schedule
/// that has slots; neither for one that has none (a webhook trigger, a
/// one-off or self-paced wake rule, a watch).
abstract interface class ScheduleSpec {
  /// The period of an interval schedule, in seconds: slots start at every
  /// multiple of it since the Unix epoch (UTC). Null for a cron schedule.
  int? get intervalSeconds;

  /// The parsed five-field cron of a cron schedule, read in [timezone]. Null
  /// for an interval schedule.
  CronSchedule? get cronSchedule;

  /// The IANA time zone a [cronSchedule] is read in; null or empty is UTC.
  String? get timezone;
}
