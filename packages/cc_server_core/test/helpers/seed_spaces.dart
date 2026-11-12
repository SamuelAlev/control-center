import 'package:cc_persistence/cc_persistence.dart';

// Parent rows for tests that write the space and conversation tables, whose
// foreign keys are enforced. Each helper inserts the smallest valid row with
// `INSERT OR IGNORE`, under the database's own workspace id.

/// Seeds space [id].
Future<void> seedSpace(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO spaces (id, name, workspace_id) VALUES (?, ?, ?)',
  [id, 'Space $id', db.workspaceId],
);

/// Seeds conversation [id] in space [spaceId] (seeded too).
Future<void> seedConversation(
  WorkspaceDatabase db,
  String id, {
  required String spaceId,
}) async {
  await seedSpace(db, spaceId);
  await db.customStatement(
    'INSERT OR IGNORE INTO conversations (id, space_id, workspace_id) '
    'VALUES (?, ?, ?)',
    [id, spaceId, db.workspaceId],
  );
}
