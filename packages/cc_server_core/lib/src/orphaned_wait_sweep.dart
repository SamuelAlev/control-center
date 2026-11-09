import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show CrossWorkspaceQueries, WorkspaceDatabase;

/// Closes the agent waits a restart ended (one workspace).
///
/// Every wait an agent can park on a human — a question, an approval, a
/// credential block — lives in server memory, so a process that died took
/// every waiter with it. Without this the stored state keeps claiming the
/// opposite: the question row stays unanswered, so the sidebar's
/// `needsInput` badge (which counts unanswered rows) disagrees with the
/// pending-question views (which count live waiters) forever, and the bell
/// keeps offering a wait that can never end.
///
/// Only rows created at or before [bootedAt] are touched, so a question asked
/// after this server started is never closed by its own boot.
Future<({int questions, int waits})> sweepOrphanedWaitsIn(
  WorkspaceDatabase db,
  DateTime bootedAt,
) async {
  final questions = await db.messagingDao.expireQuestionsCreatedBefore(
    bootedAt,
  );
  final waits = await db.notificationFeedDao.resolveAgentWaitsRecordedBefore(
    db.workspaceId,
    bootedAt,
    DateTime.now(),
  );
  return (questions: questions, waits: waits);
}

/// Runs [sweepOrphanedWaitsIn] over every workspace once, at boot.
///
/// CROSS-WORKSPACE BY DESIGN: a boot reconciler, like the space-provisioning
/// one. Each workspace's rows are written in that workspace's own database.
Future<void> sweepOrphanedWaits(
  CrossWorkspaceQueries crossWorkspace,
  DateTime bootedAt,
) async {
  var questions = 0;
  var waits = 0;
  await crossWorkspace.forEachWorkspace(
    (db) async {
      final swept = await sweepOrphanedWaitsIn(db, bootedAt);
      questions += swept.questions;
      waits += swept.waits;
    },
    onError: (workspaceId, error) => CcHostLog.warning(
      'orphaned-wait sweep failed for workspace $workspaceId: $error',
    ),
  );
  if (questions > 0 || waits > 0) {
    CcHostLog.info(
      'orphaned-wait sweep: closed $questions question(s) and resolved '
      '$waits waiting notification(s) left by the previous run',
    );
  }
}
