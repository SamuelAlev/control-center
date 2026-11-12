/// What became of one claimed cron slot (`cron_executions.status`).
enum CronFireStatus {
  /// The slot was claimed and its run started.
  fired,

  /// The slot came due but was deliberately not run (catch-up policy).
  skipped,

  /// The slot was claimed but its run could not start.
  failed;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static CronFireStatus parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a CronFireStatus'),
  );
}
