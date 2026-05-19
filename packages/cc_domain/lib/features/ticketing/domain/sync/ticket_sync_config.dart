import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';

/// A workspace's sync connection to one external vendor. Workspace-scoped: a
/// config never leaks across workspaces, and every sync operation reads the
/// config for `(workspaceId, vendor)`.
///
/// The credential itself is NOT stored here — only a reference
/// ([credentialRef]) the infra layer resolves against the secure store. The
/// [webhookSecret] is the shared secret used to verify inbound webhook
/// signatures for this vendor/workspace.
class TicketSyncConfig {
  /// Creates a [TicketSyncConfig].
  TicketSyncConfig({
    required this.id,
    required this.workspaceId,
    required this.vendor,
    this.vendorProjectId = '',
    this.direction = SyncDirection.bidirectional,
    this.fieldPolicy = const TicketFieldConflictPolicy(),
    this.credentialRef,
    this.webhookSecret,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// Vendor identifier (matches `TicketSyncAdapter.vendorId`).
  final String vendor;

  /// Vendor-side project / board / repo this workspace syncs with (e.g. a
  /// Linear team id, a Jira project key, an `owner/repo` for GitHub). Empty
  /// when the vendor needs no project scoping.
  final String vendorProjectId;

  /// Allowed sync direction(s).
  final SyncDirection direction;

  /// Per-field conflict-resolution policy.
  final TicketFieldConflictPolicy fieldPolicy;

  /// Opaque reference the infra layer resolves to a vendor credential (never
  /// the secret itself). Null when the vendor uses an ambient credential.
  final String? credentialRef;

  /// Shared secret for verifying inbound webhook signatures, if configured.
  final String? webhookSecret;

  /// Whether this connection is active.
  final bool enabled;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last-modified timestamp.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  TicketSyncConfig copyWith({
    String? vendorProjectId,
    SyncDirection? direction,
    TicketFieldConflictPolicy? fieldPolicy,
    String? credentialRef,
    bool removeCredentialRef = false,
    String? webhookSecret,
    bool removeWebhookSecret = false,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return TicketSyncConfig(
      id: id,
      workspaceId: workspaceId,
      vendor: vendor,
      vendorProjectId: vendorProjectId ?? this.vendorProjectId,
      direction: direction ?? this.direction,
      fieldPolicy: fieldPolicy ?? this.fieldPolicy,
      credentialRef: removeCredentialRef
          ? null
          : (credentialRef ?? this.credentialRef),
      webhookSecret: removeWebhookSecret
          ? null
          : (webhookSecret ?? this.webhookSecret),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSyncConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          vendor == other.vendor &&
          enabled == other.enabled &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, workspaceId, vendor, enabled, updatedAt);
}
