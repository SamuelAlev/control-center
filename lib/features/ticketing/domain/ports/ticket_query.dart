import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart' show TicketProviderPort;

/// Filter for listing tickets through a [TicketProviderPort].
class TicketQuery {
  /// Creates a [TicketQuery].
  const TicketQuery({
    this.workspaceId,
    this.statuses,
    this.assigneeExternalId,
    this.limit = 50,
  });

  /// Workspace scope, if the provider supports it.
  final String? workspaceId;

  /// Restrict to these statuses, if set.
  final Set<TicketStatus>? statuses;

  /// Restrict to a remote assignee, if set.
  final String? assigneeExternalId;

  /// Max results.
  final int limit;
}
