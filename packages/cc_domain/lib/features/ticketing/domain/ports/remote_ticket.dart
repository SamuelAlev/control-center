import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// A provider-neutral view of a ticket as it exists on the backend — carries
/// only what a remote provider knows (no Control-Center orchestration fields).
/// Adapters map their native DTOs to/from this at the port boundary.
class RemoteTicket {
  /// Creates a [RemoteTicket].
  const RemoteTicket({
    required this.externalId,
    this.externalKey,
    this.url,
    required this.title,
    this.description,
    this.priority = TicketPriority.none,
    this.labels = const [],
    required this.status,
    this.rawStatus,
    this.parentExternalId,
    this.assigneeExternalId,
    this.createdAt,
    this.updatedAt,
  });

  /// Stable provider id (used for `getByExternalId` / update / transition).
  final String externalId;

  /// Provider-native human key (e.g. `LIN-123`).
  final String? externalKey;

  /// Web URL.
  final String? url;

  /// Title.
  final String title;

  /// Body / description.
  final String? description;

  /// Priority.
  final TicketPriority priority;

  /// Labels.
  final List<String> labels;

  /// Normalized status (the adapter maps [rawStatus] → this).
  final TicketStatus status;

  /// Native state name as returned by the provider.
  final String? rawStatus;

  /// Parent ticket's provider id, if any.
  final String? parentExternalId;

  /// Remote assignee id (a provider user — NOT a Control-Center agent).
  final String? assigneeExternalId;

  /// Remote creation time.
  final DateTime? createdAt;

  /// Remote last-update time.
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteTicket &&
          runtimeType == other.runtimeType &&
          externalId == other.externalId &&
          status == other.status &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(externalId, status, updatedAt);
}

/// Input to create a ticket on a provider.
class RemoteTicketDraft {
  /// Creates a [RemoteTicketDraft].
  const RemoteTicketDraft({
    required this.title,
    this.description,
    this.priority = TicketPriority.none,
    this.labels = const [],
    this.parentExternalId,
    this.assigneeExternalId,
    this.providerExtras = const {},
  });

  /// Title (required).
  final String title;

  /// Body / description.
  final String? description;

  /// Priority.
  final TicketPriority priority;

  /// Labels.
  final List<String> labels;

  /// Parent ticket's provider id.
  final String? parentExternalId;

  /// Remote assignee id.
  final String? assigneeExternalId;

  /// Vendor-specific extras carried neutrally across the port boundary
  /// (e.g. Linear's required `teamId`).
  final Map<String, String> providerExtras;
}

/// Partial update for a ticket on a provider. Null fields are left unchanged.
class RemoteTicketPatch {
  /// Creates a [RemoteTicketPatch].
  const RemoteTicketPatch({
    this.title,
    this.description,
    this.priority,
    this.labels,
  });

  /// New title, or null to leave unchanged.
  final String? title;

  /// New description, or null to leave unchanged.
  final String? description;

  /// New priority, or null to leave unchanged.
  final TicketPriority? priority;

  /// New labels, or null to leave unchanged.
  final List<String>? labels;
}
