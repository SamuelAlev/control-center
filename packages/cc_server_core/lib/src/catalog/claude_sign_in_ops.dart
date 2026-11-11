import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_host/cc_host.dart' show RepoOp, ServerAuthority;
import 'package:cc_infra/cc_infra.dart' show ClaudeAccountStore;

/// `claude_accounts.signInStates`: whether each Claude Code account holds a
/// credential a run could use right now.
///
/// `claude auth login` runs in a terminal, so nothing tells a client that it
/// finished. A sign-in dialog asks this every couple of seconds while it is
/// open. Unlike `claude_accounts.list` it starts no CLI and reads no plan
/// usage: a keychain read per account, mirrored into the account's directory
/// exactly as a run would do it.
///
/// It takes no arguments. The accounts come from the server's own registry,
/// never from the caller. It is the server owner's, like
/// `claude_accounts.loginCommand`: whoever is handed the command may watch it
/// finish. Injected via `extraOps` so `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildClaudeSignInOps(ClaudeAccountStore store) => [
  RepoOp(
    name: 'claude_accounts.signInStates',
    serverAuthority: ServerAuthority.serverOwner,
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async => {
      'accounts': [
        for (final state in await store.signInStates()) state.toJson(),
      ],
    },
  ),
];
