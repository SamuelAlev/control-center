import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart' show TicketProviderPort;

/// Describes what a [TicketProviderPort] supports, so the UI and MCP tools can
/// gracefully hide unsupported actions (the `SandboxBackendCapabilities`
/// analogue).
class TicketProviderCapabilities {
  /// Creates a [TicketProviderCapabilities].
  const TicketProviderCapabilities({
    required this.provider,
    this.supportsCreate = false,
    this.supportsUpdate = false,
    this.supportsStatusUpdate = false,
    this.supportsAssignee = false,
    this.supportsLabels = false,
    this.supportsPriority = false,
    this.supportsHierarchy = false,
    this.supportsList = false,
    this.supportsRemoteSync = false,
  });

  /// All-true capabilities for the given [provider] (the local backend).
  const TicketProviderCapabilities.full(this.provider)
      : supportsCreate = true,
        supportsUpdate = true,
        supportsStatusUpdate = true,
        supportsAssignee = true,
        supportsLabels = true,
        supportsPriority = true,
        supportsHierarchy = true,
        supportsList = true,
        supportsRemoteSync = false;

  /// All-false capabilities for an unimplemented [provider] (stub adapters).
  const TicketProviderCapabilities.none(this.provider)
      : supportsCreate = false,
        supportsUpdate = false,
        supportsStatusUpdate = false,
        supportsAssignee = false,
        supportsLabels = false,
        supportsPriority = false,
        supportsHierarchy = false,
        supportsList = false,
        supportsRemoteSync = false;

  /// The provider these capabilities describe.
  final TicketProvider provider;

  /// Can create tickets.
  final bool supportsCreate;

  /// Can update title/description/etc.
  final bool supportsUpdate;

  /// Can transition status.
  final bool supportsStatusUpdate;

  /// Can set an assignee.
  final bool supportsAssignee;

  /// Supports labels.
  final bool supportsLabels;

  /// Supports priority.
  final bool supportsPriority;

  /// Supports parent/child hierarchy.
  final bool supportsHierarchy;

  /// Can list/query tickets.
  final bool supportsList;

  /// Whether tickets must be mirrored from a remote source of truth.
  final bool supportsRemoteSync;
}
