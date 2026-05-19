import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';

import 'package:cc_server_core/src/context/context_inspection_service.dart';

/// Repo-RPC ops exposing a conversation's context-window composition.
///
/// `context.inspect` re-derives — server-side, without running anything — what
/// the next built-in-harness dispatch for the (workspace, space, agent) would
/// send, sliced into per-category segments. `include_content: false` (the
/// flyout) returns sizes only; `true` (the explorer) carries every part's
/// verbatim text.
///
/// Injected into the catalog via `extraOps` (the same seam weather/chat use),
/// so `remote_rpc_catalog.dart` is left untouched.
List<RepoOp> buildContextOps({required ContextInspectionService inspection}) =>
    [
      RepoOp(
        name: 'context.inspect',
        kind: RepoOpKind.read,
        requiredArgs: const ['space_id', 'agent_id'],
        handler: (ctx) async {
          final result = await inspection.inspect(
            workspaceId: ctx.workspaceId!,
            spaceId: ctx.args['space_id'] as String,
            agentId: ctx.args['agent_id'] as String,
            includeContent: ctx.args['include_content'] == true,
          );
          return {'inspection': result.toJson()};
        },
      ),
    ];
