/// How the calendar screen is laid out. Persisted via SharedPreferences
/// (see `calendarViewModeProvider`).
enum CalendarViewMode {
  /// Month grid.
  month,

  /// Week time-grid.
  week,

  /// Single-day time-grid.
  day,

  /// Chronological agenda list.
  agenda;

  /// Parses the persisted value. Unknown / null → [month].
  static CalendarViewMode fromStorage(String? value) => switch (value) {
        'week' => CalendarViewMode.week,
        'day' => CalendarViewMode.day,
        'agenda' => CalendarViewMode.agenda,
        'month' => CalendarViewMode.month,
        _ => CalendarViewMode.month,
      };

  /// Serializes for storage.
  String toStorageString() => name;
}
