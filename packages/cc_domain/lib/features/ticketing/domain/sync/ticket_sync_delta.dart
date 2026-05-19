import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// A single normalized change pulled from an external vendor. One delta maps to
/// at most one Control Center ticket (matched on `(vendor, externalId)`); the
/// sync engine decides whether that means create, mirror-update, or close.
///
/// All vendor-specific shape (GraphQL nodes, Jira issue JSON, GitHub issue
/// payloads) is flattened into this provider-neutral form by the adapter's
/// `pullChanges` before it ever reaches the engine.
class TicketSyncDelta {
  /// Creates a [TicketSyncDelta].
  const TicketSyncDelta({
    required this.externalId,
    this.externalKey,
    this.url,
    this.title,
    this.description,
    this.priority,
    this.labels,
    this.status,
    this.rawStatus,
    this.assigneeExternalId,
    this.parentExternalId,
    this.updatedAt,
    this.deleted = false,
    this.dedupeKey,
  });

  /// Stable vendor id for the ticket (the join key against a sync link row).
  final String externalId;

  /// Vendor-native human key (e.g. `ENG-123`, `PROJ-456`, `#789`).
  final String? externalKey;

  /// Web URL of the ticket on the vendor.
  final String? url;

  /// New title, or null when this change did not touch the title.
  final String? title;

  /// New description, or null when unchanged.
  final String? description;

  /// New priority, or null when unchanged.
  final TicketPriority? priority;

  /// New labels, or null when unchanged.
  final List<String>? labels;

  /// New normalized status, or null when unchanged.
  final TicketStatus? status;

  /// Vendor-native state name (preserved on the mirror for lossless display).
  final String? rawStatus;

  /// Vendor assignee id, or null when unchanged.
  final String? assigneeExternalId;

  /// Parent ticket's vendor id, or null when unchanged / top-level.
  final String? parentExternalId;

  /// When the vendor last modified the ticket. Drives last-writer arbitration.
  final DateTime? updatedAt;

  /// Whether the ticket was deleted / closed on the vendor.
  final bool deleted;

  /// Vendor-supplied idempotency token (e.g. a webhook delivery id) used to
  /// drop a re-delivered event before it is applied. Null when not provided.
  final String? dedupeKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSyncDelta &&
          runtimeType == other.runtimeType &&
          externalId == other.externalId &&
          status == other.status &&
          updatedAt == other.updatedAt &&
          deleted == other.deleted;

  @override
  int get hashCode => Object.hash(externalId, status, updatedAt, deleted);
}
