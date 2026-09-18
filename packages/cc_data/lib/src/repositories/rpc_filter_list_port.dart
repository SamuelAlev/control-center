import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_domain/features/newsfeed/domain/ports/filter_list_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [FilterListPort] over the host's `newsfeed.filterLists.*` ops.
///
/// The host owns the EasyList / uBlock fetch and the on-disk cache under its
/// data dir. Thin clients never dial those URLs.
class RpcFilterListPort implements FilterListPort {
  /// Creates an [RpcFilterListPort] over [_client].
  RpcFilterListPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<FilterListUpdateState> readState() async {
    final data = await _client.call('newsfeed.filterLists.state', const {});
    return FilterListUpdateState.fromJson(data);
  }

  @override
  Future<FilterListUpdateState> refresh({bool force = false}) async {
    final data = await _client.call('newsfeed.filterLists.refresh', {
      'force': force,
    }, timeout: const Duration(minutes: 2));
    return FilterListUpdateState.fromJson(data);
  }

  @override
  Future<List<Map<String, dynamic>>> readBlocklist() async {
    final data = await _client.call(
      'newsfeed.filterLists.blocklist',
      const {},
      timeout: const Duration(minutes: 1),
    );
    final raw = data['rules'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final entry in raw)
        if (entry is Map)
          {for (final e in entry.entries) e.key.toString(): e.value},
    ];
  }

  @override
  Future<Set<String>> readRemoveParams() async {
    final data = await _client.call(
      'newsfeed.filterLists.removeParams',
      const {},
    );
    final raw = data['params'];
    if (raw is! List) {
      return const {};
    }
    return {
      for (final p in raw)
        if (p is String && p.isNotEmpty) p,
    };
  }
}
