import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates space read-cursors over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The server is stateless
/// and a workspace id selects the database file, so both calls name their
/// `workspace_id` explicitly rather than leaning on the client's ambient active
/// workspace: that ambient value flips on a switch independently of the caller
/// that validated this space, which would pair the space with the wrong
/// workspace (the server then rejects it with "Space belongs to a different
/// workspace"). Mirrors the `space_read.*` op + the
/// `space_read.watchUserLastReadAt` subscription in the host catalog.
class RemoteSpaceReadRepository {
  /// Creates a [RemoteSpaceReadRepository] over [_client].
  RemoteSpaceReadRepository(this._client);

  final RemoteRpcClient _client;

  /// Marks the user's read cursor for [spaceId] within [workspaceId] as now.
  Future<void> markSpaceRead(String workspaceId, String spaceId) =>
      _client.call('space_read.markSpaceRead', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });

  /// Live read cursor for the user participant of [spaceId] within
  /// [workspaceId] — a fresh snapshot ([SpaceReadDto]) on every change.
  Stream<SpaceReadDto> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('space_read.watchUserLastReadAt', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map((data) => SpaceReadDto.fromJson(data.cast<String, dynamic>()));
}
