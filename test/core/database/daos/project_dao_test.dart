import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProjectsTableCompanion project(String id, String ws, {String name = 'P'}) =>
      ProjectsTableCompanion.insert(id: id, workspaceId: ws, name: name);

  test('getForWorkspace is scoped to the workspace', () async {
    await db.projectDao.insert(project('p-1', 'w-1'));
    await db.projectDao.insert(project('p-2', 'w-1'));
    await db.projectDao.insert(project('p-3', 'w-2'));

    final w1 = await db.projectDao.getForWorkspace('w-1');
    expect(w1.map((p) => p.id), unorderedEquals(['p-1', 'p-2']));
    final w2 = await db.projectDao.getForWorkspace('w-2');
    expect(w2.map((p) => p.id), ['p-3']);
  });

  test('updateById does not match a foreign workspace', () async {
    await db.projectDao.insert(project('p-1', 'w-1', name: 'Original'));

    final foreign = await db.projectDao.updateById(
      'p-1',
      'other-ws',
      const ProjectsTableCompanion(name: Value('Hacked')),
    );
    expect(foreign, 0);
    expect((await db.projectDao.getById('p-1'))!.name, 'Original');

    final owned = await db.projectDao.updateById(
      'p-1',
      'w-1',
      const ProjectsTableCompanion(name: Value('Renamed')),
    );
    expect(owned, 1);
    expect((await db.projectDao.getById('p-1'))!.name, 'Renamed');
  });

  test('deleteProject is workspace-scoped and orphans its tickets', () async {
    await db.projectDao.insert(project('p-1', 'w-1'));
    await db.ticketDao.insert(
      TicketsTableCompanion.insert(
        id: 't-1',
        workspaceId: 'w-1',
        title: 'In project',
        projectId: const Value('p-1'),
      ),
    );

    // A foreign workspace cannot delete it.
    final foreign = await db.projectDao.deleteProject('p-1', 'other-ws');
    expect(foreign, 0);
    expect(await db.projectDao.getById('p-1'), isNotNull);
    expect((await db.ticketDao.getById('t-1'))!.projectId, 'p-1');

    // The owning workspace deletes it; the ticket survives but is orphaned.
    final deleted = await db.projectDao.deleteProject('p-1', 'w-1');
    expect(deleted, 1);
    expect(await db.projectDao.getById('p-1'), isNull);
    final ticket = await db.ticketDao.getById('t-1');
    expect(ticket, isNotNull);
    expect(ticket!.projectId, isNull);
  });

  test('watchForWorkspace only emits this workspace', () async {
    await db.projectDao.insert(project('p-1', 'w-1'));
    await db.projectDao.insert(project('p-2', 'w-2'));

    final first = await db.projectDao.watchForWorkspace('w-1').first;
    expect(first.map((p) => p.id), ['p-1']);
  });
}
