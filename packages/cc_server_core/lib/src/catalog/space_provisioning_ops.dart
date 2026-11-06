import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/space_provisioning_log_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/environment_ops.dart';

/// Runs or stops a space's workspace preparation.
typedef SpaceProvisioningAction =
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
    });

/// `messaging.retrySpaceProvisioning` and `messaging.cancelSpaceProvisioning`.
///
/// Each is omitted when its action is null, and asserts space ownership before
/// acting.
List<RepoOp> buildSpaceProvisioningOps({
  required SpaceProvisioningAction? retry,
  required SpaceProvisioningAction? cancel,
  required Future<void> Function(String workspaceId, String spaceId)
  assertSpaceOwned,
}) {
  RepoOpHandler run(SpaceProvisioningAction action) => (ctx) async {
    final spaceId = ctx.args['space_id'] as String;
    await assertSpaceOwned(ctx.workspaceId!, spaceId);
    await action(workspaceId: ctx.workspaceId!, spaceId: spaceId);
    return {'ok': true};
  };

  // Names stay literal: rpc_op_coverage_test reads them from source.
  return [
    if (retry != null)
      RepoOp(
        name: 'messaging.retrySpaceProvisioning',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        handler: run(retry),
      ),
    if (cancel != null)
      RepoOp(
        name: 'messaging.cancelSpaceProvisioning',
        kind: RepoOpKind.mutate,
        requiredArgs: ['space_id'],
        handler: run(cancel),
      ),
  ];
}

/// `messaging.watchSpaceProvisioningLog`: what a space's workspace preparation
/// is printing.
///
/// The output names the space's repos and runs their `provision` tasks, so it
/// takes the read grant an environment's logs do. Attaches and reads only.
WatchQuery buildSpaceProvisioningLogWatchQuery({
  required SpaceProvisioningLogPort log,
  required RepoAccessRepoResolver reposExposedBySpace,
  required RepoReadGrantCheck requireRepoReadGrant,
  required Future<void> Function(String workspaceId, String spaceId)
  assertSpaceOwned,
}) => WatchQuery(
  name: 'messaging.watchSpaceProvisioningLog',
  // Lines are ordered events. `seq` lets a reconnecting client replace a line
  // that rewrote itself and drop the ones it already has.
  isEventStream: true,
  handler: (ctx) async* {
    final spaceId = await requireReadableSpace(
      ctx,
      reposExposedBySpace: reposExposedBySpace,
      requireRepoReadGrant: requireRepoReadGrant,
      assertSpaceOwned: assertSpaceOwned,
    );
    yield* log
        .follow(ctx.workspaceId!, spaceId)
        .map((line) => {'seq': line.seq, 'line': line.text});
  },
);
