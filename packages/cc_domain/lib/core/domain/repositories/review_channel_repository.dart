import 'package:cc_domain/core/domain/entities/review_channel_association.dart';

/// Repository interface for review channel associations.
abstract class ReviewChannelRepository {
  /// Watches the association for a specific PR by [prNodeId], scoped to
  /// [workspaceId] (PR node ids are global, so this must be workspace-scoped).
  Stream<ReviewChannelAssociation?> watchByPr(String workspaceId, String prNodeId);

  /// Watches the association for a specific channel.
  Stream<ReviewChannelAssociation?> watchByChannel(String channelId);

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

  /// Updates the status of an association.
  Future<void> updateStatus(String id, ReviewChannelStatus status);
}
