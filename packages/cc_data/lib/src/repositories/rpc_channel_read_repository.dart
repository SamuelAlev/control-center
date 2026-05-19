import 'package:cc_data/src/repositories/remote_channel_read_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ChannelReadRepository] backed by the RPC client — the thin-client data
/// path for the sidebar's unread indicator.
///
/// Implements the domain interface over the host's `channel_read.markChannelRead`
/// op + the `channel_read.watchUserLastReadAt` subscription, mapping the
/// [ChannelReadDto] wire shape back to the cursor [DateTime?]. The host owns
/// persistence (the read cursor on `channel_participants`) and validates that
/// the `channel_id` belongs to the bound workspace; this client never touches a
/// database.
class RpcChannelReadRepository implements ChannelReadRepository {
  /// Creates an [RpcChannelReadRepository] over [client].
  RpcChannelReadRepository(RemoteRpcClient client)
    : _remote = RemoteChannelReadRepository(client);

  final RemoteChannelReadRepository _remote;

  @override
  Future<void> markChannelRead(String channelId) =>
      _remote.markChannelRead(channelId);

  @override
  Stream<DateTime?> watchUserLastReadAt(String channelId) =>
      _remote.watchUserLastReadAt(channelId).map(_fromDto);

  /// Rebuilds the cursor [DateTime?] from its wire DTO. A missing/null
  /// `lastReadAt` means the channel has never been opened under the user.
  static DateTime? _fromDto(ChannelReadDto d) =>
      d.lastReadAt == null ? null : DateTime.parse(d.lastReadAt!);
}
