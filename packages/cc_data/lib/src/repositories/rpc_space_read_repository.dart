import 'package:cc_data/src/repositories/remote_space_read_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [SpaceReadRepository] backed by the RPC client — the thin-client data
/// path for the sidebar's unread indicator.
///
/// Implements the domain interface over the host's `space_read.markSpaceRead`
/// op + the `space_read.watchUserLastReadAt` subscription, mapping the
/// [SpaceReadDto] wire shape back to the cursor [DateTime?]. The host owns
/// persistence (the read cursor on `space_participants`) and resolves the
/// space inside the workspace each call names; this client never touches a
/// database.
class RpcSpaceReadRepository implements SpaceReadRepository {
  /// Creates an [RpcSpaceReadRepository] over [client].
  RpcSpaceReadRepository(RemoteRpcClient client)
    : _remote = RemoteSpaceReadRepository(client);

  final RemoteSpaceReadRepository _remote;

  // The server resolves the acting user from the session's authenticated
  // device credential; the [userId] the interface carries is never sent over
  // the wire (a client cannot act as another user).
  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId,
  ) => _remote.markSpaceRead(workspaceId, spaceId);

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  ) => _remote.watchUserLastReadAt(workspaceId, spaceId).map(_fromDto);

  /// Rebuilds the cursor [DateTime?] from its wire DTO. A missing/null
  /// `lastReadAt` means the space has never been opened under the user.
  static DateTime? _fromDto(SpaceReadDto d) =>
      d.lastReadAt == null ? null : DateTime.parse(d.lastReadAt!);
}
