import 'package:cc_domain/cc_domain.dart'
    show AuthException, RepoOpKind, ValidationException;
import 'package:cc_host/cc_host.dart'
    show PendingCredentialBlockRegistry, RepoOp, ServerAuthority;
import 'package:cc_infra/cc_infra.dart' show ClaudeAccountStore;

/// `claude_accounts.setupTokenCommand`, `.setToken` and `.clearToken`: the
/// long-lived alternative to `loginCommand`.
///
/// The interactive login's refresh token rotates, so its copies (keychain
/// item, mirrored file) sign each other out; a `claude setup-token` token
/// never refreshes and stays signed in for about a year. Control Center still
/// mints nothing: the CLI prints the token in the operator's terminal and they
/// paste it into `setToken`. It is written into the account directory on the
/// host and never read back out — `list` only reports that one is present.
///
/// Server-owner only, like the rest of `claude_accounts.*`. Empty when the
/// host manages no Claude accounts. Injected via `extraOps` so
/// `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildClaudeAccountTokenOps({
  required ClaudeAccountStore? accounts,
  required PendingCredentialBlockRegistry? credentialBlocks,
  required Future<bool> Function(String userId) isServerOwner,
}) {
  if (accounts == null) {
    return const [];
  }

  Future<void> requireAdmin(String userId) async {
    if (!await isServerOwner(userId)) {
      throw const AuthException(
        'Claude Code accounts are shared by every workspace on this server '
        'and can only be changed by its operator.',
      );
    }
  }

  return [
    RepoOp(
      name: 'claude_accounts.setupTokenCommand',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        final cmd = accounts.setupTokenCommand(ctx.args['id'] as String);
        return {'argv': cmd.argv, 'environment': cmd.environment};
      },
    ),
    RepoOp(
      name: 'claude_accounts.setToken',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['id', 'token'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        try {
          await accounts.setLongLivedToken(
            ctx.args['id'] as String,
            ctx.args['token'] as String,
          );
        } on ArgumentError catch (e) {
          // The message names the problem, never the value: the store
          // redacts the token before it can reach an error.
          throw ValidationException('${e.message}');
        }
        // A run parked on this account being signed out can go now.
        await credentialBlocks?.nudge();
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'claude_accounts.clearToken',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['id'],
      handler: (ctx) async {
        await requireAdmin(ctx.userId);
        await accounts.clearLongLivedToken(ctx.args['id'] as String);
        return {'ok': true};
      },
    ),
  ];
}
