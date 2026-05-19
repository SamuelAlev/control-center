import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Vendor-neutral ticketing domain events. Replaces the old `task_events.dart`
/// and `linear_events.dart`: the pipeline resume listener keys off
/// [TicketCompleted] / [TicketFailed], and [TicketAssigned] carries the same
/// payload shape the `ticket_to_pr` pipeline used to read from the old
/// `LinearIssueAssigned` event.

/// Fired when a ticket is created.
class TicketCreated implements DomainEvent {
  /// Creates a [TicketCreated].
  const TicketCreated({
    required this.ticketId,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Workspace owning the ticket. A ticket id alone does not locate the ticket
  /// — a listener needs the workspace to read it back.
  final String workspaceId;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket is delegated (a child ticket created under a parent).
class TicketDelegated implements DomainEvent {
  /// Creates a [TicketDelegated].
  const TicketDelegated({
    required this.ticketId,
    required this.parentTicketId,
    required this.occurredAt,
  });

  /// Child ticket id.
  final String ticketId;

  /// Parent ticket id.
  final String parentTicketId;
  @override
  final DateTime occurredAt;
}

/// Fired when work on a ticket starts.
class TicketStarted implements DomainEvent {
  /// Creates a [TicketStarted].
  const TicketStarted({required this.ticketId, required this.occurredAt});

  /// Ticket id.
  final String ticketId;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket completes successfully (terminal).
class TicketCompleted implements DomainEvent {
  /// Creates a [TicketCompleted].
  const TicketCompleted({required this.ticketId, required this.occurredAt});

  /// Ticket id.
  final String ticketId;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket fails (terminal).
class TicketFailed implements DomainEvent {
  /// Creates a [TicketFailed].
  const TicketFailed({
    required this.ticketId,
    required this.errorMessage,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Failure detail.
  final String errorMessage;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket is cancelled (terminal).
class TicketCancelled implements DomainEvent {
  /// Creates a [TicketCancelled].
  const TicketCancelled({required this.ticketId, required this.occurredAt});

  /// Ticket id.
  final String ticketId;
  @override
  final DateTime occurredAt;
}

/// Fired on any status change, carrying the before/after for listeners that
/// care about specific transitions (e.g. PR-link resolution on `done`).
class TicketStatusChanged implements DomainEvent {
  /// Creates a [TicketStatusChanged].
  const TicketStatusChanged({
    required this.ticketId,
    required this.from,
    required this.to,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Owning workspace of the ticket. Non-null — tickets are workspace-scoped
  /// and every emit site has the workspace in scope at the mutation chokepoint.
  final String workspaceId;

  /// Previous status (storage string).
  final String from;

  /// New status (storage string).
  final String to;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket is assigned. Replaces `LinearIssueAssigned` and keeps
/// the `ticketId` / `ticketTitle` / `ticketBody` / `ticketUrl` / `workspaceId`
/// fields the `ticket_to_pr` pipeline reads from its trigger payload.
class TicketAssigned implements DomainEvent {
  /// Creates a [TicketAssigned].
  const TicketAssigned({
    required this.ticketId,
    required this.ticketTitle,
    this.ticketBody,
    this.ticketUrl,
    this.assignedAgentId,
    this.assigneeType = 'agent',
    this.assignedTeamId,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Ticket title.
  final String ticketTitle;

  /// Ticket description / body.
  final String? ticketBody;

  /// Web URL of the ticket, if remote.
  final String? ticketUrl;

  /// Principal the ticket was assigned to, if any (agent id or user id, per
  /// [assigneeType]).
  final String? assignedAgentId;

  /// Which kind of principal [assignedAgentId] names: `agent` or `user`.
  final String assigneeType;

  /// Team the ticket was assigned to, if any.
  final String? assignedTeamId;

  /// Workspace owning the ticket — the scope every listener reads it back in.
  final String workspaceId;
  @override
  final DateTime occurredAt;
}

/// Fired when a ticket is reassigned from one agent to another.
class TicketReassigned implements DomainEvent {
  /// Creates a [TicketReassigned].
  const TicketReassigned({
    required this.ticketId,
    required this.workspaceId,
    this.fromAgentId,
    this.toAgentId,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Workspace owning the ticket — the scope every listener reads it back in.
  final String workspaceId;

  /// Previous assignee, if any.
  final String? fromAgentId;

  /// New assignee, if any.
  final String? toAgentId;
  @override
  final DateTime occurredAt;
}

/// Fired when a collaborator is added to a ticket.
class TicketCollaboratorAdded implements DomainEvent {
  /// Creates a [TicketCollaboratorAdded].
  const TicketCollaboratorAdded({
    required this.ticketId,
    required this.agentId,
    required this.role,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Collaborator agent id (or `'user'`).
  final String agentId;

  /// Collaborator role (storage string).
  final String role;
  @override
  final DateTime occurredAt;
}

/// Fired when an external vendor webhook for a ticket has been verified and
/// applied. Lets pipeline triggers react to inbound vendor changes (the
/// `PipelineTriggerDispatcher` matches on the event type + payload).
class ExternalTicketWebhookReceived implements DomainEvent {
  /// Creates an [ExternalTicketWebhookReceived].
  const ExternalTicketWebhookReceived({
    required this.vendor,
    required this.workspaceId,
    this.eventType,
    this.externalId,
    required this.occurredAt,
  });

  /// Vendor identifier (`linear` | `jira` | `github`).
  final String vendor;

  /// Workspace the webhook was routed to.
  final String workspaceId;

  /// Vendor event type (e.g. `issues.opened`), when known.
  final String? eventType;

  /// Vendor ticket id the event concerned, when a single ticket.
  final String? externalId;

  @override
  final DateTime occurredAt;
}

/// Fired when a ticket's title, description, or priority is updated.
class TicketDetailsUpdated implements DomainEvent {
  /// Creates a [TicketDetailsUpdated].
  const TicketDetailsUpdated({
    required this.ticketId,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Ticket id.
  final String ticketId;

  /// Workspace owning the ticket — the scope every listener reads it back in.
  final String workspaceId;
  @override
  final DateTime occurredAt;
}
