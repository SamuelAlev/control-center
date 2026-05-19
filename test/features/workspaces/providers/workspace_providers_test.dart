import 'package:cc_persistence/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, null);
    });

    test('build returns first workspace id when no saved preference', () async {
      final prefs = AppPreferences.inMemory({});

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-1');
    });

    test('build returns saved workspace id when valid', () async {
      final prefs = AppPreferences.inMemory({_wsKey: 'ws-2'});

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-2');
    });

    test(
      'build falls back to first when saved workspace no longer exists',
      () async {
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-gone'});

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWithValue(prefs),
            workspaceRepositoryProvider.overrideWith(
              (ref) => ref.watch(daoWorkspaceRepositoryProvider),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(activeWorkspaceIdProvider, (_, _) {});
        container.listen(workspacesProvider, (_, _) {});
        await Future.delayed(const Duration(milliseconds: 50));
        final id = container.read(activeWorkspaceIdProvider);
        expect(id, 'ws-1');
      },
    );

    test('setActive persists and updates state', () async {
      final prefs = AppPreferences.inMemory({});

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
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
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-2'});

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
        );
        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Second'),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWithValue(prefs),
            workspaceRepositoryProvider.overrideWith(
              (ref) => ref.watch(daoWorkspaceRepositoryProvider),
            ),
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
      final prefs = AppPreferences.inMemory({
        _wsKey: 'ws-1',
        _wsNameKey: 'Cached name',
        _wsLogoKey: '/logo.png',
      });

      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Real name'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Before the stream emits, the cached display is used (no "no workspace").
      final cached = container.read(activeWorkspaceDisplayProvider);
      expect(cached?.name, 'Cached name');
      expect(cached?.logoPath, '/logo.png');

      // Once the real row loads, it takes over.
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(activeWorkspaceDisplayProvider)?.name, 'Real name');
    });

    test('returns null once the list loads with no workspaces', () async {
      final prefs = AppPreferences.inMemory({});

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
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
      final prefs = AppPreferences.inMemory({});

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
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep the write-through cache alive, then let the workspace resolve.
      container.listen(workspaceDisplayCacheProvider, (_, _) {});
      // Warm the active-id notifier so its Dao-backed bootstrap workspace list
      // subscribes and emits during the delay below (the notifier reconciles
      // the persisted id against that list).
      container.listen(activeWorkspaceIdProvider, (_, _) {});
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
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repoId = container.read(activeRepoIdProvider);
      expect(repoId, isNull);
    });

    test('setActive returns early when no workspace is active', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          // workspaceRepositoryProvider is RPC-flipped (composition flip); the UI
          // `workspacesProvider` chain would build the in-process host and hang
          // on the round-trip. Point it at the Dao-backed impl so the list
          // resolves from the in-memory DB directly. (ActiveWorkspaceIdNotifier
          // already reconciles against the Dao-backed bootstrap list.)
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeRepoIdProvider.notifier).setActive('repo-1');
      expect(container.read(activeRepoIdProvider), isNull);
    });

    test('setActive flips state synchronously, before the persist resolves', () async {
      // Regression: setActive() persisted to shared_preferences BEFORE flipping
      // in-memory state. openPrInRepo() / the command palette call setActive
      // WITHOUT awaiting and navigate immediately, so the PR detail screen built
      // against the PREVIOUS active repo — the PR-review surface then resolved
      // the wrong owner/repo and the host 404'd a cross-repo PR. The flip must
      // be visible synchronously, before the (awaited) persist completes.
      final prefs = AppPreferences.inMemory({_wsKey: 'ws-1'});
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'First'),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          workspaceRepositoryProvider.overrideWith(
            (ref) => ref.watch(daoWorkspaceRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Active workspace resolves synchronously from the persisted id.
      expect(container.read(activeWorkspaceIdProvider), 'ws-1');

      // Fire-and-forget, exactly like openPrInRepo(): do NOT await.
      final pending = container
          .read(activeRepoIdProvider.notifier)
          .setActive('repo-x');

      // The flip is already visible — before the persist future resolves.
      expect(container.read(activeRepoIdProvider), 'repo-x');

      await pending;
      expect(prefs.getString('active_repo_id:ws-1'), 'repo-x');
    });
  });
}
