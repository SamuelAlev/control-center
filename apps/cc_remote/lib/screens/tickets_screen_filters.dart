part of 'tickets_screen.dart';

extension _TicketsScreenFilters on _TicketsScreenState {
  List<TicketDto> _filteredTickets(
    List<TicketDto>? all,
    String? workspaceId,
    Map<String, String> agentNames,
    String q,
  ) {
    return all?.where((ticket) {
          if (ticket.workspaceId != workspaceId ||
              (_status.isNotEmpty && ticket.status != _status) ||
              (_assignee == 'assigned' && ticket.assignee == null) ||
              (_assignee == 'unassigned' && ticket.assignee != null) ||
              (_assignee.isNotEmpty &&
                  _assignee != 'assigned' &&
                  _assignee != 'unassigned' &&
                  ticket.assignee != _assignee) ||
              (_priority.isNotEmpty && ticket.priority != _priority)) {
            return false;
          }
          return q.isEmpty ||
              [
                ticket.key,
                ticket.title,
                ticket.description ?? '',
                ticket.assignee ?? '',
                agentNames[ticket.assignee] ?? '',
                ...ticket.labels,
              ].any((field) => field.toLowerCase().contains(q));
        }).toList() ??
        const <TicketDto>[];
  }
}
