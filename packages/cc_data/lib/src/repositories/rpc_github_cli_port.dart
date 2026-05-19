import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [GitHubCliPort] backed by the RPC client — the thin-client data path.
///
/// The `gh` CLI is probed on the SERVER's machine (`gh auth status`), so the
/// thin client reads its status over the host's `github_cli.probe` op. The host
/// deliberately NEVER returns its resolved `gh` token over the wire — a remote
/// client must not receive the host machine's GitHub credentials — so the
/// reconstructed [GitHubCliStatus] carries installed / authenticated / username
/// only, with an empty [GitHubCliStatus.token]. The thin client reaches GitHub
/// through the server's own authenticated client over the other server ops, so
/// it never needs the host's token locally. A host that wires no `gh` probe
/// leaves the op absent (default-deny → `opUnknown`); the client degrades to a
/// "not installed" status.
class RpcGitHubCliPort implements GitHubCliPort {
  /// Creates an [RpcGitHubCliPort] over [_client].
  RpcGitHubCliPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<GitHubCliStatus> probe() async {
    try {
      final data = await _client.call('github_cli.probe', const {});
      return GitHubCliStatus(
        isInstalled: data['is_installed'] as bool? ?? false,
        isAuthenticated: data['is_authenticated'] as bool? ?? false,
        username: data['username'] as String? ?? '',
        // token intentionally omitted — the host never ships its `gh` token to
        // a remote client (the default empty string is correct here).
      );
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const GitHubCliStatus();
      }
      rethrow;
    }
  }
}
