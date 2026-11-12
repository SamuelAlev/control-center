import 'package:cc_persistence/cc_persistence.dart';

// Parent rows for tests that write the server-global tables, whose foreign
// keys are enforced.
//
// Each helper inserts the smallest valid row with `INSERT OR IGNORE`, so a
// test can seed a parent it may already have created.

/// Seeds user [id] in [global], with a handle of the same id.
Future<void> seedUser(GlobalDatabase global, String id) =>
    global.customStatement(
      'INSERT OR IGNORE INTO users (id, handle, display_name) '
      'VALUES (?, ?, ?)',
      [id, id, 'User $id'],
    );

/// Seeds every user in [ids].
Future<void> seedUsers(GlobalDatabase global, Iterable<String> ids) async {
  for (final id in ids) {
    await seedUser(global, id);
  }
}
