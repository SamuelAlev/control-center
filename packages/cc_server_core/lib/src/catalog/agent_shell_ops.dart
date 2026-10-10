import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';

/// `process.agentShells` and `process.killAgentShell`: a space's running agent
/// shell commands, and the stop for one.
///
/// Spread from `buildRemoteRpcCatalog` so these [RepoOp] literals stay out of
/// the catalog file. Unlike the `process.detect` pair this is workspace AND
/// space scoped: the port derives every pid from the space's own runs and
/// refuses any other. Both read the space's worktree surface (command lines
/// name its paths), so they carry the same per-repo grant check a terminal
/// does through [reposExposedBySpace]; a stop is privileged, so both are
/// fullClient-only like the terminal ops. Empty when [shells] is null → the
/// TERMINALS section lists terminals only.
List<RepoOp> buildAgentShellOps({
  required AgentShellProcessPort? shells,
  required RepoAccessRepoResolver reposExposedBySpace,
}) => [
  if (shells != null) ...[
    RepoOp(
      name: 'process.agentShells',
      kind: RepoOpKind.read,
      requiredArgs: ['space_id'],
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.read,
      repoAccessVia: reposExposedBySpace,
      // Polled while the TERMINALS section is open.
      audited: false,
      handler: (ctx) async {
        final found = await shells.list(
          workspaceId: ctx.workspaceId!,
          spaceId: ctx.args['space_id'] as String,
        );
        return {
          'processes': [
            for (final p in found)
              {
                'pid': p.pid,
                'agent_id': p.agentId,
                'run_id': ?p.runId,
                'command': p.command,
                'started_at': p.startedAt.toUtc().toIso8601String(),
                'origin': p.origin.name,
              },
          ],
        };
      },
    ),
    RepoOp(
      name: 'process.killAgentShell',
      kind: RepoOpKind.mutate,
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: ['space_id', 'pid'],
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.read,
      repoAccessVia: reposExposedBySpace,
      handler: (ctx) async {
        final killed = await shells.kill(
          workspaceId: ctx.workspaceId!,
          spaceId: ctx.args['space_id'] as String,
          pid: (ctx.args['pid'] as num).toInt(),
        );
        if (!killed) {
          throw const NotFoundException(
            'No running agent command with that pid in this space',
          );
        }
        return {'killed': true};
      },
    ),
  ],
];
