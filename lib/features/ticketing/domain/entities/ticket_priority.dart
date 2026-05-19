/// Ticket priority. Ordering follows Linear's native 0..4 scale so remote
/// round-trips stay lossless (mapping helpers live inside each adapter, not
/// here, to keep the domain vendor-neutral).
enum TicketPriority {
  /// No priority set.
  none,

  /// Urgent.
  urgent,

  /// High.
  high,

  /// Medium.
  medium,

  /// Low.
  low;

  /// Parses the persisted integer value. Unknown → [none].
  static TicketPriority fromStorage(int? raw) {
    return switch (raw) {
      0 => TicketPriority.none,
      1 => TicketPriority.urgent,
      2 => TicketPriority.high,
      3 => TicketPriority.medium,
      4 => TicketPriority.low,
      _ => TicketPriority.none,
    };
  }

  /// Serializes to the persisted integer value.
  int toStorageInt() => index;
}
