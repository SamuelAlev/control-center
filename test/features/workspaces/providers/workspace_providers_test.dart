import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/test_database.dart';

const String _wsKey = 'active_workspace_id';
const String _wsNameKey = 'active_workspace_name';
const String _wsLogoKey = 'active_workspace_logo';

void main() {
  group('ActiveWorkspaceIdNotifier', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('build returns null when no workspaces exist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, null);
    });

    test('build returns first workspace id when no saved preference', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-1');
    });

    test('build returns saved workspace id when valid', () async {
      SharedPreferences.setMockInitialValues({_wsKey: 'ws-2'});
      final prefs = await SharedPreferences.getInstance();

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-2');
    });

    test(
      'build falls back to first when saved workspace no longer exists',
      () async {
        SharedPreferences.setMockInitialValues({_wsKey: 'ws-gone'});
        final prefs = await SharedPreferences.getInstance();

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(container.dispose);
        container.listen(workspacesProvider, (_, _) {});
        await Future.delayed(const Duration(milliseconds: 50));
        final id = container.read(activeWorkspaceIdProvider);
        expect(id, 'ws-1');
      },
    );

    test('setActive persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-1');

      expect(container.read(activeWorkspaceIdProvider), 'ws-1');
      expect(prefs.getString(_wsKey), 'ws-1');
    });

    test(
      'build exposes the persisted id immediately, before the list loads',
      () async {
        // Regression: the chip flashed "no workspace" for a few seconds on a
        // cold start because the persisted id was discarded while the Drift
        // stream's first emit was pending. The id must surface synchronously.
        SharedPreferences.setMockInitialValues({_wsKey: 'ws-2'});
        final prefs = await SharedPreferences.getInstance();

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
        );
        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(container.dispose);

        // Read synchronously — the workspaces stream has not emitted yet.
        expect(container.read(activeWorkspaceIdProvider), 'ws-2');

        // And it still resolves to the same id once the list loads.
        container.listen(workspacesProvider, (_, _) {});
        await Future.delayed(const Duration(milliseconds: 50));
        expect(container.read(activeWorkspaceIdProvider), 'ws-2');
      },
    );
  });

  group('activeWorkspaceDisplayProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('falls back to the cached display while the list loads', () async {
      SharedPreferences.setMockInitialValues({
        _wsKey: 'ws-1',
        _wsNameKey: 'Cached name',
        _wsLogoKey: '/logo.png',
      });
      final prefs = await SharedPreferences.getInstance();

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Real name'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Before the stream emits, the cached display is used (no "no workspace").
      final cached = container.read(activeWorkspaceDisplayProvider);
      expect(cached?.name, 'Cached name');
      expect(cached?.logoPath, '/logo.png');

      // Once the real row loads, it takes over.
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(activeWorkspaceDisplayProvider)?.name, 'Real name');
    });

    test('returns null once the list loads with no workspaces', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(activeWorkspaceDisplayProvider), isNull);
    });
  });

  group('workspaceDisplayCacheProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('persists name + logo when the active workspace resolves', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-1',
          name: 'First',
          logoPath: const Value('/icon.png'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Keep the write-through cache alive, then let the workspace resolve.
      container.listen(workspaceDisplayCacheProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(prefs.getString(_wsKey), 'ws-1');
      expect(prefs.getString(_wsNameKey), 'First');
      expect(prefs.getString(_wsLogoKey), '/icon.png');
    });
  });

  group('ActiveRepoIdNotifier', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('build returns null when no active workspace', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final repoId = container.read(activeRepoIdProvider);
      expect(repoId, isNull);
    });

    test('setActive returns early when no workspace is active', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeRepoIdProvider.notifier).setActive('repo-1');
      expect(container.read(activeRepoIdProvider), isNull);
    });
  });

  group('workspaceDetailProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns workspace when id exists', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-d', name: 'Detail'),
      );

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(workspaceDetailProvider('ws-d'), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final ws = container.read(workspaceDetailProvider('ws-d')).value;
      expect(ws, isNotNull);
      expect(ws!.name, 'Detail');
    });

    test('returns null when id does not exist', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(workspaceDetailProvider('nope'), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final ws = container.read(workspaceDetailProvider('nope')).value;
      expect(ws, null);
    });
  });
}
