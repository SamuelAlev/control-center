import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Workspace created.
class WorkspaceCreated implements DomainEvent {
  /// Creates a [WorkspaceCreated] event.
  const WorkspaceCreated({required this.workspaceId, required this.occurredAt});

  /// Identifier of the newly created workspace.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}
