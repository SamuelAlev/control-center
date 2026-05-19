import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [CacheRepository] backed by the SERVER over the `cache.read` / `cache.write`
/// RPC ops.
///
/// The messaging IDE editor layout is persisted per conversation in the
/// server-owned `cache` table, so a layout saved on one client (desktop) is
/// restored on another (web) and vice versa. Both platforms resolve the same
/// RPC client — a connected `cc_server` (spawned locally by desktop self-serve,
/// or a remote instance) — so this single implementation drives both targets
/// with no per-platform binding.
///
/// Only `read` / `put` are exercised by the IDE layout; the delete variants are
/// not surfaced as ops, so they throw [UnsupportedError] (callers that need
/// eviction should add a `cache.delete` op first).
class RpcCacheRepository implements CacheRepository {
  /// Creates an [RpcCacheRepository].
  RpcCacheRepository(this._rpc);

  final RemoteRpcClient _rpc;

  @override
  Future<String?> read(String workspaceId, String kind, String key) async {
    try {
      final result = await _rpc.call('cache.read', {
        'workspace_id': workspaceId,
        'kind': kind,
        'key': key,
      });
      return result['payload'] as String?;
    } on RemoteRpcException catch (e) {
      // A server that doesn't expose the op (e.g. an older headless host) → no
      // persisted layout, rather than surfacing an error to the editor.
      if (e.code == RpcErrorCodes.opUnknown) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {
    try {
      await _rpc.call('cache.write', {
        'workspace_id': workspaceId,
        'kind': kind,
        'key': key,
        'payload': payload,
      });
    } on RemoteRpcException catch (e) {
      // A server that can't persist (no op) → drop the write silently; a failed
      // layout save must never surface in the editor.
      if (e.code == RpcErrorCodes.opUnknown) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) =>
      throw UnsupportedError('cache.deleteEntry is not exposed over RPC');

  @override
  Future<void> deleteKind(String workspaceId, String kind) =>
      throw UnsupportedError('cache.deleteKind is not exposed over RPC');

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) => throw UnsupportedError(
    'cache.deleteKindWithPrefix is not exposed over RPC',
  );
}

/// Provides the SERVER-backed [CacheRepository] used to persist + restore the
/// messaging IDE editor layout (and other workspace-scoped cache payloads that
/// must be shared across clients).
final editorLayoutCacheRepositoryProvider = Provider<CacheRepository>(
  (ref) => RpcCacheRepository(ref.watch(rpcClientProvider)),
);
