import 'package:cc_domain/core/domain/entities/review_space_association.dart';

/// Repository interface for review space associations.
abstract class ReviewSpaceRepository {
  /// Watches the association for a specific PR by [prExternalId], scoped to
  /// [workspaceId] (PR node ids are global, so this must be workspace-scoped).
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  );

  /// Watches the most recent association for [spaceId] within [workspaceId].
  /// The space id resolves only inside that workspace.
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  );

  /// Watches every association for a space (a space can carry multiple PRs
  /// across one or more repos), workspace-scoped for isolation. Newest first.
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  );

  /// Watches all associations for a workspace.
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId);

  /// Creates a new review space association.
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  });

  /// Updates the status of the association [id] within [workspaceId]. An
  /// association belonging to another workspace is not matched.
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  );
}
