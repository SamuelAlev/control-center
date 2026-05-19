import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates channel read-cursors over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The server is stateless
/// and a workspace id selects the database file, so both calls name their
/// `workspace_id` explicitly rather than leaning on the client's ambient active
/// workspace: that ambient value flips on a switch independently of the caller
/// that validated this channel, which would pair the channel with the wrong
/// workspace (the server then rejects it with "Channel belongs to a different
/// workspace"). Mirrors the `channel_read.*` op + the
/// `channel_read.watchUserLastReadAt` subscription in the host catalog.
class RemoteChannelReadRepository {
  /// Creates a [RemoteChannelReadRepository] over [_client].
  RemoteChannelReadRepository(this._client);

  final RemoteRpcClient _client;

  /// Marks the user's read cursor for [channelId] within [workspaceId] as now.
  Future<void> markChannelRead(String workspaceId, String channelId) =>
      _client.call('channel_read.markChannelRead', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      });

  /// Live read cursor for the user participant of [channelId] within
  /// [workspaceId] — a fresh snapshot ([ChannelReadDto]) on every change.
  Stream<ChannelReadDto> watchUserLastReadAt(
    String workspaceId,
    String channelId,
  ) => _client
      .subscribe('channel_read.watchUserLastReadAt', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      })
      .map((data) => ChannelReadDto.fromJson(data.cast<String, dynamic>()));
}
