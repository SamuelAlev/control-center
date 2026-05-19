import 'package:cc_data/src/repositories/remote_review_space_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ReviewSpaceRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `review_space.*` ops + the
/// `review_space.watchByWorkspace` / `review_space.watchByPr` /
/// `review_space.watchBySpace` subscriptions, mapping the
/// [ReviewSpaceAssociationDto] wire shape back to [ReviewSpaceAssociation].
/// The host owns persistence; this client never touches a database. Reads,
/// watches and the create/updateStatus row writes are served.
class RpcReviewSpaceRepository implements ReviewSpaceRepository {
  /// Creates an [RpcReviewSpaceRepository] over [client].
  RpcReviewSpaceRepository(RemoteRpcClient client)
    : _remote = RemoteReviewSpaceRepository(client);

  final RemoteReviewSpaceRepository _remote;

  /// Rebuilds a [ReviewSpaceAssociation] from its wire DTO. The `status`
  /// enum is encoded as `.name`; a missing/unknown value falls back to
  /// [ReviewSpaceStatus.requested] and missing timestamps fall back to the
  /// epoch so the entity stays valid.
  static ReviewSpaceAssociation _fromDto(ReviewSpaceAssociationDto d) =>
      ReviewSpaceAssociation(
        id: d.id,
        spaceId: d.spaceId,
        workspaceId: d.workspaceId,
        prExternalId: d.prExternalId,
        prNumber: d.prNumber,
        repoFullName: d.repoFullName,
        status:
            _reviewSpaceStatusByName[d.status] ?? ReviewSpaceStatus.requested,
        createdAt: d.createdAt == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(d.createdAt!),
        updatedAt: d.updatedAt == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(d.updatedAt!),
      );

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => _remote
      .watchByPr(workspaceId, prExternalId)
      .map((dto) => dto == null ? null : _fromDto(dto));

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => _remote
      .watchBySpace(workspaceId, spaceId)
      .map((dto) => dto == null ? null : _fromDto(dto));

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => _remote
      .watchAllBySpace(workspaceId, spaceId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      _remote
          .watchByWorkspace(workspaceId)
          .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final dto = await _remote.create(
      workspaceId: workspaceId,
      spaceId: spaceId,
      prExternalId: prExternalId,
      prNumber: prNumber,
      repoFullName: repoFullName,
    );
    return _fromDto(dto);
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) => _remote.updateStatus(workspaceId, id, status.name);
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, ReviewSpaceStatus> _reviewSpaceStatusByName =
    ReviewSpaceStatus.values.asNameMap();
