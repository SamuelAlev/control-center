import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One recorded layer of a space's branch stack.
class SpaceStackLayer {
  /// Creates a [SpaceStackLayer].
  const SpaceStackLayer({
    required this.repoId,
    required this.position,
    required this.branch,
    required this.baseBranch,
    required this.label,
    required this.current,
    this.prNumber,
  });

  /// Parses one `stack.list` entry. Returns null when the row is incomplete.
  static SpaceStackLayer? fromWire(Map<String, dynamic> wire) {
    final repoId = wire['repo_id'];
    final branch = wire['branch'];
    final base = wire['base_branch'];
    final position = wire['position'];
    if (repoId is! String ||
        branch is! String ||
        base is! String ||
        position is! int) {
      return null;
    }
    final number = wire['pr_number'];
    return SpaceStackLayer(
      repoId: repoId,
      position: position,
      branch: branch,
      baseBranch: base,
      label: wire['label'] as String? ?? branch,
      current: wire['current'] == true,
      prNumber: number is int ? number : null,
    );
  }

  /// Repo whose checkout holds this layer.
  final String repoId;

  /// 0 is the bottom of the stack.
  final int position;

  /// Branch name.
  final String branch;

  /// The branch this layer's pull request targets.
  final String baseBranch;

  /// Last path segment, the part's name.
  final String label;

  /// Whether this layer is checked out.
  final bool current;

  /// Forge pull-request number, once published.
  final int? prNumber;
}

/// Outcome of a stack mutation.
typedef StackCallResult = ({bool ok, bool dirty, String? error});

/// The layers recorded for a space. Empty until the first cut, and empty
/// when the call fails, so a sidebar that cannot reach the server stays quiet.
final spaceStackProvider = FutureProvider.autoDispose
    .family<List<SpaceStackLayer>, String>((ref, spaceId) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || spaceId.isEmpty) {
        return const [];
      }
      try {
        final data = await ref.watch(rpcClientProvider).call('stack.list', {
          'workspace_id': workspaceId,
          'space_id': spaceId,
        });
        final raw = data['entries'];
        if (raw is! List) {
          return const [];
        }
        final layers = <SpaceStackLayer>[];
        for (final item in raw) {
          if (item is! Map) {
            continue;
          }
          final layer = SpaceStackLayer.fromWire(item.cast<String, dynamic>());
          if (layer != null) {
            layers.add(layer);
          }
        }
        return layers;
      } on Object {
        return const [];
      }
    });

StackCallResult _stackResult(Map<String, dynamic> data) => (
  ok: data['ok'] == true,
  dirty: data['dirty'] == true,
  error: data['error'] as String?,
);

/// Checks [branch] out inside the space. Does not open a review room.
Future<StackCallResult> checkoutStackLayer(
  RemoteRpcClient client, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required String branch,
}) async {
  try {
    final data = await client.call('stack.checkout', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
      'branch': branch,
    });
    return _stackResult(data);
  } on Object catch (e) {
    return (ok: false, dirty: false, error: '$e');
  }
}

/// Starts the next part named [name] on [repoId]'s checkout.
Future<StackCallResult> cutStackLayer(
  RemoteRpcClient client, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required String name,
}) async {
  try {
    final data = await client.call('stack.cut', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
      'name': name,
    });
    return _stackResult(data);
  } on Object catch (e) {
    return (ok: false, dirty: false, error: '$e');
  }
}

/// Pushes the stack and opens the missing pull requests.
///
/// On a demo server this op is absent. The error is toasted by the button.
Future<StackCallResult> publishStack(
  RemoteRpcClient client, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  bool draft = true,
}) async {
  try {
    final data = await client.call('stack.publish', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
      'draft': draft,
    });
    return _stackResult(data);
  } on Object catch (e) {
    return (ok: false, dirty: false, error: '$e');
  }
}
