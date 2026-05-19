/// How the tickets screen is laid out.
///
/// [list] is the default — a Linear-style grouped list. [board] is the kanban
/// board. The user's choice is persisted as the default via SharedPreferences
/// (see `ticketViewModeProvider`).
enum TicketViewMode {
  /// Grouped, single-column list (the default).
  list,

  /// Kanban board with one column per status group.
  board;

  /// Parses the persisted value. Unknown / null → [list].
  static TicketViewMode fromStorage(String? value) => switch (value) {
        'board' => TicketViewMode.board,
        'list' => TicketViewMode.list,
        _ => TicketViewMode.list,
      };

  /// Serializes for storage.
  String toStorageString() => name;
}
