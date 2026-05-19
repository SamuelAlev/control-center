import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// A repository was registered. Triggers background code indexing via the
/// `index_code` pipeline in the workspace specified by [workspaceId].
class RepoAdded implements DomainEvent {
  /// Creates a [RepoAdded] event.
  const RepoAdded({
    required this.repoId,
    required this.path,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Identifier of the newly added repo.
  final String repoId;

  /// Absolute local working-tree path of the repo.
  final String path;

  /// Workspace where the repo was added.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}
