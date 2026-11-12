import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Workspace created.
class WorkspaceCreated implements DomainEvent {
  /// Creates a [WorkspaceCreated] event.
  const WorkspaceCreated({required this.workspaceId, required this.occurredAt});

  /// Identifier of the newly created workspace.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}

/// Rows of [workspaceId]'s database that decide who may do what were
/// rewritten underneath the repositories.
///
/// The repositories invalidate their caches on the writes they make
/// themselves. A restore replaces the whole file, and accepting an imported
/// grant writes it back directly, so neither passes through them: every
/// in-memory cache derived from that workspace's rows (roles, repo grants,
/// login indexes) listens for this and drops what it holds for
/// [workspaceId].
sealed class WorkspaceAuthorityRewritten implements DomainEvent {
  /// The workspace whose rows changed.
  String get workspaceId;
}

/// [workspaceId]'s database was replaced by a restored or imported file.
///
/// Published once the new file serves. Nothing in memory may still describe
/// the old one.
final class WorkspaceRestored implements WorkspaceAuthorityRewritten {
  /// Creates a [WorkspaceRestored] event.
  const WorkspaceRestored({
    required this.workspaceId,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  @override
  final DateTime occurredAt;
}

/// The server owner accepted a grant an imported file carried, so it is live
/// in [workspaceId] again.
final class ImportedAuthorityAccepted implements WorkspaceAuthorityRewritten {
  /// Creates an [ImportedAuthorityAccepted] event.
  const ImportedAuthorityAccepted({
    required this.workspaceId,
    required this.kind,
    required this.occurredAt,
  });

  @override
  final String workspaceId;

  /// The hold's kind, as its wire name.
  final String kind;

  @override
  final DateTime occurredAt;
}
