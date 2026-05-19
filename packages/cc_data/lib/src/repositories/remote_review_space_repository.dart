import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates review space associations over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every call names its `workspace_id` — PR
/// node ids are global and space/association ids are uuids, neither of which
/// is an access boundary. Mirrors the `review_space.*` ops + the
/// `review_space.watchByWorkspace` / `review_space.watchByPr` /
/// `review_space.watchBySpace` subscriptions in the host catalog.
class RemoteReviewSpaceRepository {
  /// Creates a [RemoteReviewSpaceRepository] over [_client].
  RemoteReviewSpaceRepository(this._client);

  final RemoteRpcClient _client;

  /// Creates a new association for [prExternalId]/[spaceId] in [workspaceId];
  /// returns the created association.
  Future<ReviewSpaceAssociationDto> create({
    required String workspaceId,
    required String spaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final data = await _client.call('review_space.create', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'pr_external_id': prExternalId,
      'pr_number': prNumber,
      'repo_full_name': repoFullName,
    });
    return ReviewSpaceAssociationDto.fromJson(
      (data['association'] as Map).cast<String, dynamic>(),
    );
  }

  /// Updates the status of association [id] in [workspaceId] to [status] (an
  /// enum `.name`).
  Future<void> updateStatus(String workspaceId, String id, String status) =>
      _client.call('review_space.updateStatus', {
        'workspace_id': workspaceId,
        'id': id,
        'status': status,
      });

  /// Live association for [prExternalId] in [workspaceId] — a fresh snapshot on
  /// every change, or null when none exists.
  Stream<ReviewSpaceAssociationDto?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => _client
      .subscribe('review_space.watchByPr', {
        'workspace_id': workspaceId,
        'pr_external_id': prExternalId,
      })
      .map(_association);

  /// Live association for [spaceId] in [workspaceId] — a fresh snapshot on
  /// every change, or null when none exists.
  Stream<ReviewSpaceAssociationDto?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('review_space.watchBySpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_association);

  /// Live list of every association for [spaceId] in [workspaceId] (multiple
  /// PRs / repos) — a fresh snapshot on every change.
  Stream<List<ReviewSpaceAssociationDto>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('review_space.watchAllBySpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_associations);

  /// Live associations in [workspaceId] — a fresh snapshot on every change.
  Stream<List<ReviewSpaceAssociationDto>> watchByWorkspace(
    String workspaceId,
  ) => _client
      .subscribe('review_space.watchByWorkspace', {'workspace_id': workspaceId})
      .map(_associations);

  ReviewSpaceAssociationDto? _association(Map<String, dynamic> data) {
    final association = data['association'];
    return association is Map
        ? ReviewSpaceAssociationDto.fromJson(
            association.cast<String, dynamic>(),
          )
        : null;
  }

  List<ReviewSpaceAssociationDto> _associations(Map<String, dynamic> data) =>
      ((data['associations'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (a) =>
                ReviewSpaceAssociationDto.fromJson(a.cast<String, dynamic>()),
          )
          .toList();
}
