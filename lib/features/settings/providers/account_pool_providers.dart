import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for reading/writing account pools over RPC.
final accountPoolsRepositoryProvider = Provider<RpcAccountPoolsRepository>(
  (ref) => RpcAccountPoolsRepository(ref.watch(rpcClientProvider)),
);

/// Identifies one editable pool: a lane, optionally narrowed to an agent.
///
/// A value class rather than two family arguments because Riverpod keys
/// families by equality — two records with the same lane and agent must resolve
/// to the same provider, or the editor would re-fetch on every rebuild.
class AccountPoolScope {
  /// Creates an [AccountPoolScope].
  const AccountPoolScope({required this.lane, this.agentId});

  /// `claude-code`, or `harness:<providerId>`.
  final String lane;

  /// The agent whose override is being edited, or null for the workspace's own.
  final String? agentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountPoolScope &&
          runtimeType == other.runtimeType &&
          lane == other.lane &&
          agentId == other.agentId;

  @override
  int get hashCode => Object.hash(lane, agentId);
}

/// The pool configured for a scope, plus what it would inherit when unset.
typedef AccountPoolView = ({AccountPool pool, AccountPool? inherited});

/// Reads one scope's pool.
final accountPoolProvider = FutureProvider.autoDispose
    .family<AccountPoolView, AccountPoolScope>(
      (ref, scope) => ref
          .watch(accountPoolsRepositoryProvider)
          .get(scope.lane, agentId: scope.agentId),
    );

/// Whether [scope]'s pool is configured but every account on it is gone from
/// [existingIds]. False while the pool is still loading.
///
/// Surfaces that hide the editor below two accounts check this first: the
/// Claude lane refuses to dispatch on such a pool, so it must stay fixable.
bool watchPoolNamesOnlyRemoved(
  WidgetRef ref,
  AccountPoolScope scope,
  Iterable<String> existingIds,
) =>
    ref
        .watch(accountPoolProvider(scope))
        .value
        ?.pool
        .namesOnlyRemoved(existingIds.toSet()) ??
    false;

/// Whether [scope]'s editor has anything to show: a choice between two or
/// more credentials, or a pool naming only removed ones that must stay fixable.
///
/// THE visibility rule for every pool editor, on every lane and scope — the
/// editor applies it to itself and a surface listing editors (the agent tab)
/// asks the same question to decide whether it has anything to list.
bool watchAccountPoolEditorVisible(
  WidgetRef ref,
  AccountPoolScope scope,
  List<String> existingIds,
) =>
    existingIds.length > 1 ||
    (existingIds.isNotEmpty &&
        watchPoolNamesOnlyRemoved(ref, scope, existingIds));

/// Writes a scope's pool and refreshes the read.
///
/// A null [pool] clears it, which is how an agent goes back to inheriting the
/// workspace's — distinct from an empty pool, which the server also treats as
/// unconfigured but which the editor never writes deliberately.
Future<void> saveAccountPool(
  WidgetRef ref,
  AccountPoolScope scope,
  AccountPool? pool,
) async {
  await ref
      .read(accountPoolsRepositoryProvider)
      .set(scope.lane, pool, agentId: scope.agentId);
  ref.invalidate(accountPoolProvider(scope));
}
