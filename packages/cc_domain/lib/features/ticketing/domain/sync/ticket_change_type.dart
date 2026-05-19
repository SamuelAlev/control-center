/// The kind of local change being pushed out to an external vendor, so a sync
/// adapter can choose the cheapest vendor operation (a status transition need
/// not re-send the whole body).
enum TicketChangeType {
  /// The ticket was just created in Control Center.
  created,

  /// Title / description / priority / labels changed.
  updated,

  /// The normalized status changed.
  statusChanged,

  /// The assignee changed.
  assigned,

  /// A comment was added.
  commented,

  /// The ticket was deleted / cancelled and should be closed on the vendor.
  deleted;

  /// Parses a stored / wire value, defaulting to [updated] for unknown input
  /// (a forward-compatible vendor payload should still trigger a generic push).
  static TicketChangeType fromStorage(String? value) => switch (value) {
    'created' => TicketChangeType.created,
    'updated' => TicketChangeType.updated,
    'statusChanged' => TicketChangeType.statusChanged,
    'assigned' => TicketChangeType.assigned,
    'commented' => TicketChangeType.commented,
    'deleted' => TicketChangeType.deleted,
    _ => TicketChangeType.updated,
  };

  /// Serializes for storage / wire.
  String toStorageString() => name;
}
