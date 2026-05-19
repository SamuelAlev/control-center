import 'package:cc_data/src/repositories/remote_review_channel_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ReviewChannelRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `review_channel.*` ops + the
/// `review_channel.watchByWorkspace` / `review_channel.watchByPr` /
/// `review_channel.watchByChannel` subscriptions, mapping the
/// [ReviewChannelAssociationDto] wire shape back to [ReviewChannelAssociation].
/// The host owns persistence; this client never touches a database. Reads,
/// watches, and the create/updateStatus row writes are served.
class RpcReviewChannelRepository implements ReviewChannelRepository {
  /// Creates an [RpcReviewChannelRepository] over [client].
  RpcReviewChannelRepository(RemoteRpcClient client)
    : _remote = RemoteReviewChannelRepository(client);

  final RemoteReviewChannelRepository _remote;

  /// Rebuilds a [ReviewChannelAssociation] from its wire DTO. The `status`
  /// enum is encoded as `.name`; a missing/unknown value falls back to
  /// [ReviewChannelStatus.requested], and missing timestamps fall back to the
  /// epoch so the entity stays valid.
  static ReviewChannelAssociation _fromDto(ReviewChannelAssociationDto d) =>
      ReviewChannelAssociation(
        id: d.id,
        channelId: d.channelId,
        workspaceId: d.workspaceId,
        prNodeId: d.prNodeId,
        prNumber: d.prNumber,
        repoFullName: d.repoFullName,
        status:
            ReviewChannelStatus.values.asNameMap()[d.status] ??
            ReviewChannelStatus.requested,
        createdAt: d.createdAt == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(d.createdAt!),
        updatedAt: d.updatedAt == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(d.updatedAt!),
      );

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prNodeId,
  ) => _remote
      .watchByPr(prNodeId)
      .map((dto) => dto == null ? null : _fromDto(dto));

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(String channelId) => _remote
      .watchByChannel(channelId)
      .map((dto) => dto == null ? null : _fromDto(dto));

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(
    String workspaceId,
  ) => _remote.watchByWorkspace().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final dto = await _remote.create(
      channelId: channelId,
      prNodeId: prNodeId,
      prNumber: prNumber,
      repoFullName: repoFullName,
    );
    return _fromDto(dto);
  }

  @override
  Future<void> updateStatus(String id, ReviewChannelStatus status) =>
      _remote.updateStatus(id, status.name);
}
