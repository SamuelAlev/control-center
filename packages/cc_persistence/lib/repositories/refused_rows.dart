import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Maps rows to entities for a repository whose open rows drive a queue or
/// count against a limit (wakes, wake rules, peer asks, improvement
/// proposals).
///
/// A row the entity refuses (an import or a hand edit broke one of its
/// rules) is left out. When such a row is still open, [settle] moves it out
/// of the open states with one conditional update, so no reader sees it
/// again and no "due", "pending" or count query keeps returning it. One
/// warning line per read reports both numbers.
Future<List<E>> mapSettlingRefused<R, E>({
  required WorkspaceDatabaseManager dbs,
  required String workspaceId,
  required String repository,
  required String table,
  required Iterable<R> rows,
  required E? Function(R row) map,
  required bool Function(R row) isOpen,
  required String Function(R row) idOf,
  required Future<int> Function(List<String> ids) settle,
  required String settledAs,
}) async {
  final entities = <E>[];
  final refusedOpen = <String>[];
  var refused = 0;
  for (final row in rows) {
    final entity = map(row);
    if (entity != null) {
      entities.add(entity);
      continue;
    }
    refused++;
    if (isOpen(row)) {
      refusedOpen.add(idOf(row));
    }
  }
  if (refused == 0) {
    return entities;
  }
  final moved = refusedOpen.isEmpty ? 0 : await settle(refusedOpen);
  dbs.onWarn?.call(
    repository,
    'workspace $workspaceId: skipped $refused unreadable $table rows'
    '${moved == 0 ? '' : '; $moved open ones settled as $settledAs'}',
  );
  return entities;
}
