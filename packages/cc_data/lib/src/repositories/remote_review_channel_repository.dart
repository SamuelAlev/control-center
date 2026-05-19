import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates review channel associations over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `review_channel.*` ops + the `review_channel.watchByWorkspace` /
/// `review_channel.watchByPr` / `review_channel.watchByChannel` subscriptions in
/// the host catalog.
class RemoteReviewChannelRepository {
  /// Creates a [RemoteReviewChannelRepository] over [_client].
  RemoteReviewChannelRepository(this._client);

  final RemoteRpcClient _client;

  /// Creates a new association for [prNodeId]/[channelId] in the bound
  /// workspace; returns the created association.
  Future<ReviewChannelAssociationDto> create({
    required String channelId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final data = await _client.call('review_channel.create', {
      'channel_id': channelId,
      'pr_node_id': prNodeId,
      'pr_number': prNumber,
      'repo_full_name': repoFullName,
    });
    return ReviewChannelAssociationDto.fromJson(
      (data['association'] as Map).cast<String, dynamic>(),
    );
  }

  /// Updates the status of association [id] to [status] (an enum `.name`).
  Future<void> updateStatus(String id, String status) => _client.call(
    'review_channel.updateStatus',
    {'id': id, 'status': status},
  );

  /// Live association for [prNodeId] in the bound workspace — a fresh snapshot
  /// on every change, or null when none exists.
  Stream<ReviewChannelAssociationDto?> watchByPr(String prNodeId) => _client
      .subscribe('review_channel.watchByPr', {'pr_node_id': prNodeId})
      .map(_association);

  /// Live association for [channelId] — a fresh snapshot on every change, or
  /// null when none exists.
  Stream<ReviewChannelAssociationDto?> watchByChannel(String channelId) =>
      _client
          .subscribe('review_channel.watchByChannel', {'channel_id': channelId})
          .map(_association);

  /// Live associations in the bound workspace — a fresh snapshot on every
  /// change.
  Stream<List<ReviewChannelAssociationDto>> watchByWorkspace() => _client
      .subscribe('review_channel.watchByWorkspace', const {})
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
            (a) => ReviewChannelAssociationDto.fromJson(
              a.cast<String, dynamic>(),
            ),
          )
          .toList();
}
