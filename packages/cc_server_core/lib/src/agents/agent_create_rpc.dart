import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/agents/domain/usecases/create_agent.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart' show agentToWire;

/// Repo-RPC op that creates an agent at a server chokepoint.
///
/// Duplicate-name refusal, id minting and `AGENTS.md` generation live in
/// [CreateAgentUseCase]. `agents.upsert` is update-only (an unknown id is
/// refused) so a second client / MCP / scripted `repo/call` cannot skip those
/// rules. Injected via `extraOps` so `remote_rpc_catalog.dart` is not grown.
List<RepoOp> buildAgentCreateOps({
  required AgentRepository agentRepository,
  required WorkspaceFilesystemPort filesystem,
}) => [
  RepoOp(
    name: 'agents.create',
    kind: RepoOpKind.mutate,
    requiredArgs: ['name', 'title'],
    handler: (ctx) async {
      final skillsArg = ctx.args['skills'];
      final skills = skillsArg is List
          ? skillsArg.map((s) => s.toString()).toList()
          : const <String>[];
      final agent = await CreateAgentUseCase(
        repository: agentRepository,
        filesystemService: filesystem,
      ).execute(
        CreateAgentCommand(
          name: ctx.args['name'] as String,
          title: ctx.args['title'] as String,
          skills: skills,
          workspaceId: ctx.workspaceId,
          reportsTo: ctx.args['reportsTo'] as String?,
          persona: ctx.args['persona'] as String?,
          systemPrompt: ctx.args['systemPrompt'] as String?,
          adapterId: ctx.args['adapterId'] as String?,
          modelId: ctx.args['modelId'] as String?,
          strictMode: ctx.args['strictMode'] == true,
          effort: ctx.args['effort'] as String?,
          contextSize: (ctx.args['contextSize'] as num?)?.toInt(),
        ),
      );
      return {'agent': agentToWire(agent)};
    },
  ),
];
