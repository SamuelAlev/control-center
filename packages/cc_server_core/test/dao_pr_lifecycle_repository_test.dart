import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/dao_pr_lifecycle_repository.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoPrLifecycleRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w1');
    repo = DaoPrLifecycleRepository(dbs, (_, _, _) async => null);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('a draft moves only between the statuses a pull request has', () async {
    final id = await repo.createDraft(
      workspaceId: 'w1',
      title: 'Add widgets',
      body: '',
    );

    await repo.updateDraft('w1', id, status: const Published().name);
    expect((await repo.getById('w1', id))!.status, const Published());

    await expectLater(
      repo.updateDraft('w1', id, status: 'merged-ish'),
      throwsA(isA<ValidationException>()),
    );
    expect((await repo.getById('w1', id))!.status, const Published());
  });
}
