import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';

/// Maps one Control Center ticket to its counterpart on one vendor. A CC ticket
/// (the primary) can carry several links — one per vendor it is synced to —
/// which is why this is a separate table rather than columns on the ticket row.
///
/// Workspace-scoped. The pair `(workspaceId, ticketId, vendor)` is unique
/// (one link per ticket per vendor); `(workspaceId, vendor, externalId)` is the
/// reverse lookup a pull / webhook uses to find the local ticket.
class TicketSyncLink {
  /// Creates a [TicketSyncLink].
  TicketSyncLink({
    required this.id,
    required this.workspaceId,
    required this.ticketId,
    required this.vendor,
    required this.externalId,
    this.externalKey,
    this.externalUrl,
    this.lastSyncedAt,
    this.lastDirection,
  });

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// The Control Center ticket id.
  final String ticketId;

  /// Vendor identifier.
  final String vendor;

  /// Stable vendor id for the linked ticket.
  final String externalId;

  /// Vendor-native human key (e.g. `ENG-123`).
  final String? externalKey;

  /// Web URL on the vendor.
  final String? externalUrl;

  /// When the link last synced in either direction.
  final DateTime? lastSyncedAt;

  /// Direction of the last successful sync.
  final SyncDirection? lastDirection;

  /// Returns a copy with the given fields replaced.
  TicketSyncLink copyWith({
    String? externalId,
    String? externalKey,
    bool removeExternalKey = false,
    String? externalUrl,
    bool removeExternalUrl = false,
    DateTime? lastSyncedAt,
    SyncDirection? lastDirection,
  }) {
    return TicketSyncLink(
      id: id,
      workspaceId: workspaceId,
      ticketId: ticketId,
      vendor: vendor,
      externalId: externalId ?? this.externalId,
      externalKey: removeExternalKey ? null : (externalKey ?? this.externalKey),
      externalUrl: removeExternalUrl ? null : (externalUrl ?? this.externalUrl),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastDirection: lastDirection ?? this.lastDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSyncLink &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          ticketId == other.ticketId &&
          vendor == other.vendor &&
          externalId == other.externalId;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, ticketId, vendor, externalId);
}
