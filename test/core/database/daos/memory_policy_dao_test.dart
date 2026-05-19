import 'package:control_center/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  MemoryPoliciesTableCompanion policy({
    required String id,
    required String workspaceId,
  }) =>
      MemoryPoliciesTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        domain: 'ops',
        rule: 'never deploy on Friday',
      );

  setUp(() async {
    db = createTestDatabase();
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'WS 2'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemoryPolicyDao workspace isolation', () {
    test('getById is scoped to the workspace', () async {
      await db.memoryPolicyDao.upsert(policy(id: 'p-1', workspaceId: 'ws-1'));
      expect(await db.memoryPolicyDao.getById('ws-1', 'p-1'), isNotNull);
      expect(await db.memoryPolicyDao.getById('ws-2', 'p-1'), isNull);
    });

    test('deleteById cannot delete another workspace policy', () async {
      await db.memoryPolicyDao.upsert(policy(id: 'p-1', workspaceId: 'ws-1'));

      await db.memoryPolicyDao.deleteById('ws-2', 'p-1'); // wrong workspace
      expect(await db.memoryPolicyDao.getById('ws-1', 'p-1'), isNotNull);

      await db.memoryPolicyDao.deleteById('ws-1', 'p-1'); // owning workspace
      expect(await db.memoryPolicyDao.getById('ws-1', 'p-1'), isNull);
    });
  });
}
