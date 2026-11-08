import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, ServerAuthority;
import 'package:cc_infra/cc_infra.dart' show ClaudeSessionSettingsStore;

/// `claude_accounts.sessionSettings` / `.setSessionSettings`: how this server
/// manages the length of Claude Code sessions. Server-wide like the logins they
/// apply to, so both belong to the server's owner. Injected via `extraOps` so
/// `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildClaudeSessionSettingsOps(ClaudeSessionSettingsStore store) =>
    [
      RepoOp(
        name: 'claude_accounts.sessionSettings',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.read,
        workspaceScoped: false,
        handler: (ctx) async => store.read().toJson(),
      ),
      RepoOp(
        name: 'claude_accounts.setSessionSettings',
        serverAuthority: ServerAuthority.serverOwner,
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        handler: (ctx) async {
          final window = ctx.args['autoCompactWindow'];
          await store.write(
            ClaudeSessionSettings(
              autoCompactWindow: window is num ? window.toInt() : null,
              compactIdleBeforeCacheExpires:
                  ctx.args['compactIdleBeforeCacheExpires'] == true,
            ),
          );
          return store.read().toJson();
        },
      ),
    ];
