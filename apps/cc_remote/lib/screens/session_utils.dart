/// Statuses a ticket may move through, in display order. Matches the desktop's
/// `TicketStatus` storage strings used by `tickets.list`/`tickets.update`.
const List<({String value, String label})> ticketStatuses =
    <({String value, String label})>[
  (value: 'open', label: 'Open'),
  (value: 'inProgress', label: 'In progress'),
  (value: 'blocked', label: 'Blocked'),
  (value: 'inReview', label: 'In review'),
  (value: 'done', label: 'Done'),
  (value: 'backlog', label: 'Backlog'),
];

/// Human label for a ticket status storage string, falling back to the raw
/// value when unknown.
String ticketStatusLabel(String value) {
  final match = ticketStatuses.firstWhere(
    (s) => s.value == value,
    orElse: () => (value: value, label: value),
  );
  return match.label;
}
