part of '../cc_server_runtime.dart';

/// Starts the boot reconcilers that put right what the previous process left
/// behind; neither is awaited, and each logs its own failure.
///
/// * Space provisioning: re-kicks spaces a previous session left stranded in
///   `provisioning`. The ready/failed flip only ever comes from the in-flight
///   provisioning future, so a server exit mid-provision would otherwise
///   leave the space behind an eternal "preparing workspace" spinner —
///   dispatch gated, no retry affordance (retry only shows on `failed`).
///   provision() is idempotent: existing worktrees are reused. One
///   best-effort sweep at boot, mirroring the orphan-run reaper. Skipped when
///   [provisioning] is null (a public demo provisions nothing).
/// * Waits a restart ended: closes orphaned questions and resolves their bell
///   rows, so `needsInput` (unanswered rows) and the pending views (live
///   waiters) agree again. Rows newer than [bootedAt] are never touched.
void _startBootSweeps({
  required CrossWorkspaceQueries crossWorkspace,
  required DateTime bootedAt,
  required SpaceProvisioningService? provisioning,
}) {
  if (provisioning != null) {
    unawaited(() async {
      try {
        // CROSS-WORKSPACE BY DESIGN: a boot reconciler, so it visits every
        // workspace's database once. Each workspace's stranded spaces are
        // resumed with that workspace's own id in hand.
        await crossWorkspace.forEachWorkspace((wsDb) async {
          final workspaceId = wsDb.workspaceId;
          final stranded = await wsDb.messagingDao.spacesByProvisioningStatus(
            'provisioning',
          );
          for (final row in stranded) {
            CcHostLog.info(
              'channel provisioning: resuming stranded channel ${row.id}',
            );
            unawaited(
              provisioning
                  .provision(workspaceId: workspaceId, spaceId: row.id)
                  .catchError((Object err, StackTrace st) {
                    CcHostLog.error(
                      'channel provisioning: resume failed for ${row.id}: $err',
                      err,
                      st,
                    );
                    wsDb.messagingDao.updateSpaceProvisioningStatus(
                      row.id,
                      'failed',
                    );
                  }),
            );
          }
        });
      } on Object catch (e, st) {
        CcHostLog.error(
          'cc_server: stranded-channel provisioning sweep failed: $e',
          e,
          st,
        );
      }
    }());
  }
  unawaited(
    sweepOrphanedWaits(crossWorkspace, bootedAt).catchError(
      (Object e, StackTrace st) =>
          CcHostLog.error('cc_server: orphaned-wait sweep failed: $e', e, st),
    ),
  );
}
