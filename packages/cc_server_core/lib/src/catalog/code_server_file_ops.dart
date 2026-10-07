import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/ide/domain/code_server_port.dart';
import 'package:cc_host/cc_host.dart';

/// Per-window file navigation in the embedded editor (`codeServer.openFile` /
/// `codeServer.closeFile`).
///
/// The client keeps one editor window per worktree and moves it between app
/// tabs, so these address files in a running code-server rather than booting
/// one. Both return `{sent: bool}`, false when no code-server runs for the
/// worktree.
///
/// Spread from `buildRemoteRpcCatalog` (under its `fullClientOnly` gate) so
/// the catalog freeze does not grow.
List<RepoOp> buildCodeServerFileOps({required CodeServerPort codeServer}) => [
  // Switch the file one embedded editor window shows: a tab switch is an
  // `open` command to the bridge in that window (addressed by its
  // `window_id`) rather than a fresh VS Code boot.
  RepoOp(
    name: 'codeServer.openFile',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['space_id', 'window_id', 'path'],
    handler: (ctx) async {
      final line = ctx.args['line'];
      final sent = await codeServer.openFile(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        repoId: ctx.args['repo_id'] as String? ?? '',
        windowId: ctx.args['window_id'] as String,
        path: ctx.args['path'] as String,
        line: line is num ? line.toInt() : null,
      );
      return {'sent': sent};
    },
  ),
  // Close a file in the worktree's editor windows once its app tab closed,
  // discarding the unsaved buffer when `revert` is set (the close prompt's
  // "Don't save").
  RepoOp(
    name: 'codeServer.closeFile',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['space_id', 'path'],
    handler: (ctx) async {
      final sent = await codeServer.closeFile(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        repoId: ctx.args['repo_id'] as String? ?? '',
        path: ctx.args['path'] as String,
        revert: ctx.args['revert'] == true,
      );
      return {'sent': sent};
    },
  ),
];
