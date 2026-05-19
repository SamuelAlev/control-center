import 'package:cc_data/src/absent_op.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads and manages the host's Claude Code logins over RPC.
///
/// Every account is a `CLAUDE_CONFIG_DIR` on the SERVER; the client only ever
/// sees identity and quota. No credential crosses this boundary — and the
/// client cannot perform a login either: `loginCommand` returns the argv for a
/// terminal to run `claude auth login` in, and the CLI writes its own
/// credential on the host.
class RpcClaudeAccountsRepository {
  /// Creates an [RpcClaudeAccountsRepository] over [_client].
  RpcClaudeAccountsRepository(this._client);

  final RemoteRpcClient _client;

  /// Every account with its live status and, when the host can report it, the
  /// plan usage behind the picker's headroom column.
  Future<List<ClaudeAccountView>> list() async {
    final data = await _client.readOr('claude_accounts.list', const {}, const {});
    final accounts = data['accounts'];
    if (accounts is! List) {
      return const [];
    }
    return [
      for (final a in accounts)
        if (a is Map) ClaudeAccountView.fromJson(a.cast<String, dynamic>()),
    ];
  }

  /// Creates an empty, signed-out account directory.
  Future<ClaudeAccount?> create({String? label}) async {
    final data = await _client.call('claude_accounts.create', {
      if (label != null && label.isNotEmpty) 'label': label,
    });
    final account = data['account'];
    return account is Map
        ? ClaudeAccount.fromJson(account.cast<String, dynamic>())
        : null;
  }

  /// Renames [id].
  Future<void> rename(String id, String label) =>
      _client.call('claude_accounts.rename', {'id': id, 'label': label});

  /// Signs [id] out and deletes its directory.
  Future<void> remove(String id) =>
      _client.call('claude_accounts.remove', {'id': id});

  /// Makes [id] the account unattributed runs use.
  Future<void> setDefault(String id) =>
      _client.call('claude_accounts.setDefault', {'id': id});

  /// The argv + environment a terminal runs to sign [id] in.
  Future<({List<String> argv, Map<String, String> environment})?> loginCommand(
    String id, {
    String? email,
    bool console = false,
  }) async {
    final data = await _client.call('claude_accounts.loginCommand', {
      'id': id,
      if (email != null && email.isNotEmpty) 'email': email,
      if (console) 'console': true,
    });
    final argv = data['argv'];
    final env = data['environment'];
    if (argv is! List) {
      return null;
    }
    return (
      argv: [for (final a in argv) '$a'],
      environment: <String, String>{
        if (env is Map<String, dynamic>)
          for (final e in env.entries) e.key: '${e.value}',
      },
    );
  }
}
