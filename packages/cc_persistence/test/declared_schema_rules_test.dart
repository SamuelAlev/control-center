import 'package:test/test.dart';

import 'helpers/schema_lint.dart';
import 'helpers/test_database.dart';

/// The structural rules of the declared schema (see `lintSchema`):
///
/// * `workspace_id` is `NOT NULL` wherever it exists and, in a workspace
///   file, never the first column of a key: it holds one value there, so a
///   key that starts with it cannot narrow anything and hides the columns
///   behind it from foreign-key lookups;
/// * no index repeats the leading columns of another;
/// * every foreign key's child columns start an index, so deleting a parent
///   is a lookup and not a scan;
/// * `ON DELETE SET NULL` is only declared on a nullable column;
/// * a column that stores JSON carries a `json_valid` check.
///
/// Each failure names the table and the object. The fix is in the table
/// class, never an exception list here.
void main() {
  String describe(List<SchemaViolation> violations) {
    final lines = violations.map((v) => '  $v').toList()..sort();
    return '${violations.length} schema rule violation(s):\n${lines.join('\n')}';
  }

  test('every workspace table follows the schema rules', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final violations = await lintSchema(db, perWorkspaceFile: true);

    expect(violations, isEmpty, reason: describe(violations));
  });

  test('every code index table follows the schema rules', () async {
    final db = createTestCodeIndexDatabase();
    addTearDown(db.close);

    final violations = await lintSchema(db, perWorkspaceFile: true);

    expect(violations, isEmpty, reason: describe(violations));
  });

  test('every global table follows the schema rules', () async {
    final db = createTestGlobalDatabase();
    addTearDown(db.close);

    final violations = await lintSchema(db, perWorkspaceFile: false);

    expect(violations, isEmpty, reason: describe(violations));
  });
}
