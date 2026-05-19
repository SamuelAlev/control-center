import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates review channel associations over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every call names its `workspace_id` — PR
/// node ids are global and channel/association ids are uuids, neither of which
/// is an access boundary. Mirrors the `review_channel.*` ops + the
/// `review_channel.watchByWorkspace` / `review_channel.watchByPr` /
/// `review_channel.watchByChannel` subscriptions in the host catalog.
class RemoteReviewChannelRepository {
  /// Creates a [RemoteReviewChannelRepository] over [_client].
  RemoteReviewChannelRepository(this._client);

  final RemoteRpcClient _client;

  /// Creates a new association for [prExternalId]/[channelId] in [workspaceId];
  /// returns the created association.
  Future<ReviewChannelAssociationDto> create({
    required String workspaceId,
    required String channelId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final data = await _client.call('review_channel.create', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'pr_external_id': prExternalId,
      'pr_number': prNumber,
      'repo_full_name': repoFullName,
    });
    return ReviewChannelAssociationDto.fromJson(
      (data['association'] as Map).cast<String, dynamic>(),
    );
  }

  /// Updates the status of association [id] in [workspaceId] to [status] (an
  /// enum `.name`).
  Future<void> updateStatus(String workspaceId, String id, String status) =>
      _client.call('review_channel.updateStatus', {
        'workspace_id': workspaceId,
        'id': id,
        'status': status,
      });

  /// Live association for [prExternalId] in [workspaceId] — a fresh snapshot on
  /// every change, or null when none exists.
  Stream<ReviewChannelAssociationDto?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => _client
      .subscribe('review_channel.watchByPr', {
        'workspace_id': workspaceId,
        'pr_external_id': prExternalId,
      })
      .map(_association);

  /// Live association for [channelId] in [workspaceId] — a fresh snapshot on
  /// every change, or null when none exists.
  Stream<ReviewChannelAssociationDto?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => _client
      .subscribe('review_channel.watchByChannel', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      })
      .map(_association);

  /// Live list of every association for [channelId] in [workspaceId] (multiple
  /// PRs / repos) — a fresh snapshot on every change.
  Stream<List<ReviewChannelAssociationDto>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => _client
      .subscribe('review_channel.watchAllByChannel', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      })
      .map(_associations);

  /// Live associations in [workspaceId] — a fresh snapshot on every change.
  Stream<List<ReviewChannelAssociationDto>> watchByWorkspace(
    String workspaceId,
  ) => _client
      .subscribe('review_channel.watchByWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(_associations);

  ReviewChannelAssociationDto? _association(Map<String, dynamic> data) {
    final association = data['association'];
    return association is Map
        ? ReviewChannelAssociationDto.fromJson(
            association.cast<String, dynamic>(),
          )
        : null;
  }

  List<ReviewChannelAssociationDto> _associations(Map<String, dynamic> data) =>
      ((data['associations'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (a) =>
                ReviewChannelAssociationDto.fromJson(a.cast<String, dynamic>()),
          )
          .toList();
}
