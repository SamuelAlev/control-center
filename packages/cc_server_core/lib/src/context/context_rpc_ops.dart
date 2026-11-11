import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/space_repo_access.dart'
    show spaceExposedRepos;
import 'package:cc_server_core/src/context/context_inspection_service.dart';

/// Repo-RPC ops exposing a conversation's context-window composition.
///
/// `context.inspect` re-derives — server-side, without running anything — what
/// the next dispatch for the (workspace, space, conversation, agent) would
/// send, sliced into per-category segments. `include_content: false` (the
/// flyout) returns sizes only; `true` (the explorer) carries every part's
/// verbatim text.
///
/// The explorer answers the space's AGENTS.md, skills and worktree files
/// verbatim, so the caller passes the space read gate: a read grant and
/// forge read on every repository the space exposes ([spaceExposedRepos]
/// over [workspaces]), checked by the dispatcher before the handler runs.
/// Full clients only, like the other code-reading ops.
///
/// Injected into the catalog via `extraOps` (the same seam weather/chat use),
/// so `remote_rpc_catalog.dart` is left untouched.
List<RepoOp> buildContextOps({
  required ContextInspectionService inspection,
  required WorkspaceRepository workspaces,
}) => [
  RepoOp(
    name: 'context.inspect',
    kind: RepoOpKind.read,
    requiredArgs: const ['space_id', 'conversation_id', 'agent_id'],
    requiredCapability: SessionCapability.fullClient,
    repoAccess: RepoGrantLevel.read,
    repoAccessVia: (ctx) async => spaceExposedRepos(
      workspaces,
      ctx.workspaceId!,
      await inspection.spaceRepoSelection(
        ctx.workspaceId!,
        ctx.args['space_id'] as String,
      ),
    ),
    handler: (ctx) async {
      final result = await inspection.inspect(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        conversationId: ctx.args['conversation_id'] as String,
        agentId: ctx.args['agent_id'] as String,
        includeContent: ctx.args['include_content'] == true,
      );
      return {'inspection': result.toJson()};
    },
  ),
];
