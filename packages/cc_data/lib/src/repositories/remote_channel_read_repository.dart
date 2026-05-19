import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates channel read-cursors over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// validates that the `channel_id` belongs to that workspace before touching
/// the cursor (channels are workspace-scoped, but the cursor is keyed only by
/// `channel_id`). Mirrors the `channel_read.*` op + the
/// `channel_read.watchUserLastReadAt` subscription in the host catalog.
class RemoteChannelReadRepository {
  /// Creates a [RemoteChannelReadRepository] over [_client].
  RemoteChannelReadRepository(this._client);

  final RemoteRpcClient _client;

  /// Marks the user's read cursor for [channelId] as now (ownership-checked
  /// server-side against the bound workspace).
  Future<void> markChannelRead(String channelId) => _client.call(
    'channel_read.markChannelRead',
    {'channel_id': channelId},
  );

  /// Live read cursor for the user participant of [channelId] — a fresh
  /// snapshot ([ChannelReadDto]) on every change.
  Stream<ChannelReadDto> watchUserLastReadAt(String channelId) => _client
      .subscribe('channel_read.watchUserLastReadAt', {'channel_id': channelId})
      .map(
        (data) => ChannelReadDto.fromJson(data.cast<String, dynamic>()),
      );
}
