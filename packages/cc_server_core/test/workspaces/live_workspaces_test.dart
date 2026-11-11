import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_server_core/src/workspaces/live_workspaces.dart';
import 'package:test/test.dart';

Workspace _ws(String id, {DateTime? deletedAt}) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deletedAt: deletedAt,
);

void main() {
  test('a workspace deleted while a sweep runs is never visited', () async {
    final registry = _Registry({
      'ws1': _ws('ws1'),
      'ws2': _ws('ws2'),
      'ws3': _ws('ws3'),
    });
    final visited = <String>[];
    await forEachLiveWorkspace(registry, (workspace) async {
      visited.add(workspace.id);
      if (workspace.id == 'ws1') {
        // Deleted by its owner while the sweep is busy with ws1.
        registry.rows['ws2'] = _ws('ws2', deletedAt: DateTime(2026));
      }
    });
    expect(visited, ['ws1', 'ws3']);
  });

  test('a listed row already marked deleted is skipped', () async {
    final registry = _Registry({
      'ws1': _ws('ws1', deletedAt: DateTime(2026)),
      'ws2': _ws('ws2'),
    })..listDeleted = true;
    final visited = <String>[];
    await forEachLiveWorkspace(registry, (w) async => visited.add(w.id));
    expect(visited, ['ws2']);
    expect(await isLiveWorkspace(registry, 'ws1'), isFalse);
    expect(await isLiveWorkspace(registry, 'ws2'), isTrue);
    expect(await isLiveWorkspace(registry, 'nope'), isFalse);
  });
}

/// A registry whose listing is read once, then rows change underneath.
class _Registry implements WorkspaceRepository {
  _Registry(this.rows);

  final Map<String, Workspace> rows;
  bool listDeleted = false;

  @override
  Future<List<Workspace>> getAll() async => [
    for (final w in rows.values)
      if (listDeleted || !w.isDeleted) w,
  ];

  @override
  Future<Workspace?> getById(String id) async {
    final row = rows[id];
    return row == null || row.isDeleted ? null : row;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
