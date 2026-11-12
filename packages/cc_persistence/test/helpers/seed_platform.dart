import 'package:cc_persistence/cc_persistence.dart';

// Parent rows for tests of the repository, review, rig, environment,
// membership and server-global tables, whose foreign keys are enforced.
//
// Each helper inserts the smallest valid row with `INSERT OR IGNORE`, so a
// test can seed a parent it may already have created. Rows of a table with a
// workspace column carry the database's own workspace id.

/// Seeds user [id] in [global], with a handle of the same id.
Future<void> seedUser(GlobalDatabase global, String id) =>
    global.customStatement(
      'INSERT OR IGNORE INTO users (id, handle, display_name) '
      'VALUES (?, ?, ?)',
      [id, id, 'User $id'],
    );

/// Seeds the registry row of workspace [id] in [global] (no database file).
Future<void> seedWorkspaceRow(GlobalDatabase global, String id) =>
    global.customStatement(
      'INSERT OR IGNORE INTO workspaces (id, name) VALUES (?, ?)',
      [id, 'Workspace $id'],
    );

/// Seeds feed [id] of [userId] (seeded too), at [url] or one derived from
/// the id.
Future<void> seedRssFeed(
  GlobalDatabase global,
  String id, {
  String userId = 'u-feeds',
  String? url,
}) async {
  await seedUser(global, userId);
  await global.customStatement(
    'INSERT OR IGNORE INTO rss_feeds (id, user_id, name, url) '
    'VALUES (?, ?, ?, ?)',
    [id, userId, 'Feed $id', url ?? 'https://example.com/$id.xml'],
  );
}

/// Seeds worker [id] in [global].
Future<void> seedWorker(GlobalDatabase global, String id) =>
    global.customStatement(
      'INSERT OR IGNORE INTO workers (id, name) VALUES (?, ?)',
      [id, 'Worker $id'],
    );

/// Seeds repo [id] in [db], at a path derived from the id.
Future<void> seedRepo(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO repos (id, name, path) VALUES (?, ?, ?)',
  [id, id, '/tmp/repos/$id'],
);

/// Seeds environment definition [id] in [db].
Future<void> seedEnvironmentDefinition(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO environment_definitions '
      '(id, name, definition_json, created_at, updated_at) '
      "VALUES (?, ?, '{}', 0, 0)",
      [id, 'Environment $id'],
    );

/// Seeds rig session [id] in [db].
Future<void> seedRigSession(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO rig_sessions '
      '(id, workspace_id, conversation_id, surface, backend, spec_json, '
      'created_by) '
      "VALUES (?, ?, ?, 'browser', 'smolvm', '{}', 'u')",
      [id, db.workspaceId, id],
    );
