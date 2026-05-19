import 'package:cc_domain/core/domain/entities/review_channel_association.dart';

/// Repository interface for review channel associations.
abstract class ReviewChannelRepository {
  /// Watches the association for a specific PR by [prNodeId], scoped to
  /// [workspaceId] (PR node ids are global, so this must be workspace-scoped).
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prNodeId,
  );

  /// Watches the most recent association for [channelId] within [workspaceId].
  /// The channel id resolves only inside that workspace.
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  );

  /// Watches every association for a channel (a channel can carry multiple PRs
  /// across one or more repos), workspace-scoped for isolation. Newest first.
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  );

  /// Watches all associations for a workspace.
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId);

  /// Creates a new review channel association.
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  });

  /// Updates the status of the association [id] within [workspaceId]. An
  /// association belonging to another workspace is not matched.
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  );
}
