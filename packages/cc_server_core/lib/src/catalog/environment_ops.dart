import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';

/// Environment RPC ops.
///
/// Definitions are commands the server runs as itself, so writing them
/// is admin-only, and members read them with their `env` values and overrides
/// hidden. Everything under `environment.` derives the environment from
/// `space_id` and never accepts a second name: a caller can only reach the
/// environment of a space they can already see.
///
/// `repoAccessVia` applies the per-repo grant check to every repo the space
/// exposes, because an environment mounts and runs those repos.
List<RepoOp> buildEnvironmentOps({
  required EnvironmentPort environments,
  required RepoAccessRepoResolver reposExposedBySpace,
  required Future<void> Function(String workspaceId, String spaceId)
  assertSpaceOwned,
}) {
  Future<String> space(RepoOpContext ctx) async {
    final spaceId = _string(ctx.args, 'space_id');
    await assertSpaceOwned(ctx.workspaceId!, spaceId);
    return spaceId;
  }

  return [
    RepoOp(
      name: 'environments.listDefinitions',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final records = await environments.listDefinitions(ctx.workspaceId!);
        return {
          'definitions': [for (final record in records) _wire(ctx, record)],
        };
      },
    ),
    RepoOp(
      name: 'environments.getDefinition',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['definition_id'],
      handler: (ctx) async {
        final record = await environments.definition(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        );
        if (record == null) {
          throw const NotFoundException('Definition not found');
        }
        return _wire(ctx, record);
      },
    ),
    RepoOp(
      name: 'environments.eligible',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['space_id'],
      handler: (ctx) async {
        final records = await environments.eligibleDefinitions(
          ctx.workspaceId!,
          await space(ctx),
        );
        return {
          'definitions': [for (final record in records) _wire(ctx, record)],
        };
      },
    ),
    RepoOp(
      name: 'environments.setDefinition',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: const ['definition'],
      handler: (ctx) async {
        final definition = ctx.args['definition'];
        if (definition is! Map) {
          throw const ValidationException('definition must be an object');
        }
        final record = await environments.saveDefinition(
          workspaceId: ctx.workspaceId!,
          definitionId: ctx.args['definition_id'] as String?,
          definition: Map<String, dynamic>.from(definition),
          by: ctx.principal,
        );
        return record.toJson();
      },
    ),
    RepoOp(
      name: 'environments.deleteDefinition',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: const ['definition_id'],
      handler: (ctx) async {
        await environments.deleteDefinition(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environments.draftDefinition',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['repo_id'],
      handler: (ctx) => environments.draftDefinition(
        ctx.workspaceId!,
        _string(ctx.args, 'repo_id'),
      ),
    ),
    RepoOp(
      name: 'environments.approveSource',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: const ['repo_id', 'path'],
      handler: (ctx) async {
        final overrides = ctx.args['overrides'];
        final record = await environments.approveSource(
          workspaceId: ctx.workspaceId!,
          definitionId: ctx.args['definition_id'] as String?,
          repoId: _string(ctx.args, 'repo_id'),
          path: _string(ctx.args, 'path'),
          overrides: overrides is Map
              ? Map<String, dynamic>.from(overrides)
              : null,
          expectedBlobHash: ctx.args['blob_hash'] as String?,
          by: ctx.principal,
        );
        return record.toJson();
      },
    ),
    RepoOp(
      name: 'environments.sourceUpdate',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['definition_id'],
      handler: (ctx) async =>
          await environments.sourceUpdate(
            ctx.workspaceId!,
            _string(ctx.args, 'definition_id'),
          ) ??
          const {},
    ),
    RepoOp(
      name: 'environments.testDefinition',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['definition_id'],
      handler: (ctx) async => {
        'run_id': await environments.testDefinition(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        ),
      },
    ),
    RepoOp(
      name: 'environments.check',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['definition_id'],
      handler: (ctx) async {
        final results = await environments.check(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        );
        return {
          'checks': [for (final result in results) result.toJson()],
        };
      },
    ),
    RepoOp(
      name: 'environments.listInstances',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      // Every space of the workspace at once, whoever started them.
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['definition_id'],
      handler: (ctx) async {
        final instances = await environments.definitionEnvironments(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        );
        return {
          'instances': [
            for (final instance in instances)
              {
                ...instance.environment.toJson(),
                'space_name': instance.spaceName,
              },
          ],
        };
      },
    ),
    RepoOp(
      name: 'environments.listRuns',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['definition_id'],
      handler: (ctx) async {
        final runs = await environments.definitionRuns(
          ctx.workspaceId!,
          _string(ctx.args, 'definition_id'),
        );
        return _runs(runs);
      },
    ),
    RepoOp(
      name: 'environment.ensure',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async {
        final options = ctx.args['options'];
        final environment = await environments.ensure(
          workspaceId: ctx.workspaceId!,
          spaceId: await space(ctx),
          definitionId: ctx.args['definition_id'] as String?,
          options: options is Map
              ? Map<String, dynamic>.from(options)
              : const {},
          by: ctx.principal,
        );
        return environment.toJson();
      },
    ),
    RepoOp(
      name: 'environment.down',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async => (await environments.stop(
        ctx.workspaceId!,
        await space(ctx),
        by: ctx.principal,
      )).toJson(),
    ),
    RepoOp(
      name: 'environment.reset',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async => (await environments.reset(
        ctx.workspaceId!,
        await space(ctx),
        by: ctx.principal,
      )).toJson(),
    ),
    RepoOp(
      name: 'environment.refresh',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async => (await environments.refresh(
        ctx.workspaceId!,
        await space(ctx),
        by: ctx.principal,
      )).toJson(),
    ),
    RepoOp(
      name: 'environment.destroy',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = await space(ctx);
        // Destroy discards data someone else may be using: the creator or an
        // admin, not any member with a grant.
        if (ctx.role?.isAdmin != true) {
          final mine = await environments.environmentsFor(workspaceId, spaceId);
          final wire = ctx.principal.wire;
          if (mine.any((environment) => environment.createdBy != wire)) {
            throw const AuthException(
              'Only its creator or an admin can destroy an environment',
            );
          }
        }
        await environments.destroy(workspaceId, spaceId, by: ctx.principal);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environment.startSetup',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id'],
      handler: (ctx) async => {
        'session_id': await environments.startSetup(
          ctx.workspaceId!,
          await space(ctx),
          by: ctx.principal,
        ),
      },
    ),
    RepoOp(
      name: 'environment.exec',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'service', 'command'],
      handler: (ctx) async {
        final command = ctx.args['command'];
        if (command is! List || command.isEmpty) {
          throw const ValidationException('command must be a non-empty list');
        }
        final result = await environments.exec(
          ctx.workspaceId!,
          await space(ctx),
          service: _string(ctx.args, 'service'),
          command: [for (final part in command) '$part'],
          by: ctx.principal,
        );
        return result.toJson();
      },
    ),
    RepoOp(
      name: 'environment.restartProcess',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'target'],
      handler: (ctx) async {
        await environments.restart(
          ctx.workspaceId!,
          await space(ctx),
          _string(ctx.args, 'target'),
          by: ctx.principal,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environment.stopProcess',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.enclosureControl,
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'component_id'],
      handler: (ctx) async {
        await environments.stopProcess(
          ctx.workspaceId!,
          await space(ctx),
          _string(ctx.args, 'component_id'),
          by: ctx.principal,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environment.launchApp',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'component_id'],
      handler: (ctx) async {
        await environments.launchApp(
          ctx.workspaceId!,
          await space(ctx),
          _string(ctx.args, 'component_id'),
          rebuild: ctx.args['rebuild'] == true,
          by: ctx.principal,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environment.stopApp',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.hostExecution,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'component_id'],
      handler: (ctx) async {
        await environments.stopApp(
          ctx.workspaceId!,
          await space(ctx),
          _string(ctx.args, 'component_id'),
          by: ctx.principal,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'environment.runTask',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: reposExposedBySpace,
      actionClasses: const {
        ActionClass.hostExecution,
        ActionClass.networkEgress,
        ActionClass.processSpawn,
      },
      requiredArgs: const ['space_id', 'task_id'],
      handler: (ctx) async {
        final arguments = ctx.args['arguments'];
        final run = await environments.runTask(
          ctx.workspaceId!,
          await space(ctx),
          _string(ctx.args, 'task_id'),
          arguments: arguments is List
              ? [for (final argument in arguments) '$argument']
              : const [],
          by: ctx.principal,
        );
        return run.toJson();
      },
    ),
  ];
}

/// Refuses a caller without a read grant on [repoId].
typedef RepoReadGrantCheck =
    Future<void> Function({
      required String workspaceId,
      required String userId,
      required String repoId,
    });

/// The `space_id` of [ctx], once it is known to belong to the workspace and the
/// caller can read every repo the space exposes.
///
/// A watch has no `repoAccessVia` to declare, so a stream showing what a
/// space's repos do checks the grant itself.
Future<String> requireReadableSpace(
  WatchQueryContext ctx, {
  required RepoAccessRepoResolver reposExposedBySpace,
  required RepoReadGrantCheck requireRepoReadGrant,
  required Future<void> Function(String workspaceId, String spaceId)
  assertSpaceOwned,
}) async {
  final workspaceId = ctx.workspaceId!;
  final spaceId = _string(ctx.args, 'space_id');
  await assertSpaceOwned(workspaceId, spaceId);
  final repos = await reposExposedBySpace(
    RepoOpContext(
      args: ctx.args,
      workspaceId: workspaceId,
      deviceId: ctx.deviceId,
      userId: ctx.userId,
    ),
  );
  for (final repoId in repos) {
    await requireRepoReadGrant(
      workspaceId: workspaceId,
      userId: ctx.userId,
      repoId: repoId,
    );
  }
  return spaceId;
}

/// Live environment state, behind [requireReadableSpace].
List<WatchQuery> buildEnvironmentWatchQueries({
  required EnvironmentPort environments,
  required RepoAccessRepoResolver reposExposedBySpace,
  required RepoReadGrantCheck requireRepoReadGrant,
  required Future<void> Function(String workspaceId, String spaceId)
  assertSpaceOwned,
}) {
  Future<String> readableSpace(WatchQueryContext ctx) => requireReadableSpace(
    ctx,
    reposExposedBySpace: reposExposedBySpace,
    requireRepoReadGrant: requireRepoReadGrant,
    assertSpaceOwned: assertSpaceOwned,
  );

  return [
    WatchQuery(
      name: 'environment.watch',
      handler: (ctx) async* {
        final spaceId = await readableSpace(ctx);
        yield* environments
            .watch(ctx.workspaceId!, spaceId)
            .map(
              (list) => {
                'environments': [for (final item in list) item.toJson()],
              },
            );
      },
    ),
    WatchQuery(
      name: 'environment.watchLogs',
      // Every line matters, so lines are events, not snapshots to coalesce.
      isEventStream: true,
      handler: (ctx) async* {
        final spaceId = await readableSpace(ctx);
        final tail = ctx.args['tail'];
        // Lines are events: `seq` lets a client drop a replayed tail.
        var seq = 0;
        yield* environments
            .followLogs(
              ctx.workspaceId!,
              spaceId,
              target: _string(ctx.args, 'target'),
              tail: tail is int && tail > 0 && tail <= 5000 ? tail : 200,
            )
            .map((line) => {'line': line, 'seq': seq++});
      },
    ),
    WatchQuery(
      name: 'environment.watchRuns',
      handler: (ctx) async* {
        final spaceId = await readableSpace(ctx);
        yield _runs(await environments.runs(ctx.workspaceId!, spaceId));
        yield* environments
            .watch(ctx.workspaceId!, spaceId)
            .asyncMap(
              (_) async =>
                  _runs(await environments.runs(ctx.workspaceId!, spaceId)),
            );
      },
    ),
  ];
}

/// [record] as [ctx]'s caller may read it. A role nobody resolved hides too.
Map<String, dynamic> _wire(
  RepoOpContext ctx,
  EnvironmentDefinitionRecord record,
) => (ctx.role?.isAdmin ?? false) ? record.toJson() : record.toRedactedJson();

Map<String, dynamic> _runs(List<EnvironmentRun> runs) => {
  'runs': [for (final run in runs) run.toJson()],
};

String _string(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is! String || value.isEmpty) {
    throw ValidationException('Missing or invalid argument: $key');
  }
  return value;
}
