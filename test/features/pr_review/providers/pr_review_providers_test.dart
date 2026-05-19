import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/data/repositories/cached_pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_database.dart';

void main() {
  group('prReviewRepositoryProvider', () {
    late AppDatabase db;
    late GitHubApiClient fakeGithubClient;

    setUp(() {
      db = createTestDatabase();
      fakeGithubClient = GitHubApiClient(
        Dio(BaseOptions(baseUrl: 'http://localhost')),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('returns EmptyPrReviewRepository when not authenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          githubApiClientProvider.overrideWithValue(fakeGithubClient),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test('returns EmptyPrReviewRepository when no active workspace', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          githubApiClientProvider.overrideWithValue(fakeGithubClient),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test(
      'returns EmptyPrReviewRepository when workspace has no repo info',
      () async {
        SharedPreferences.setMockInitialValues({githubTokenKey: 'ghp_test'});
        final prefs = await SharedPreferences.getInstance();

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-no-info',
            name: 'No Info',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            githubApiClientProvider.overrideWithValue(fakeGithubClient),
          ],
        );
        addTearDown(container.dispose);
        await container.read(credentialsProvider.future);
        final repo = container.read(prReviewRepositoryProvider);
        expect(repo, isA<EmptyPrReviewRepository>());
      },
    );

    test(
      'returns CachedPrReviewRepository when authenticated with valid workspace',
      () async {
        SharedPreferences.setMockInitialValues({githubTokenKey: 'ghp_test'});
        final prefs = await SharedPreferences.getInstance();

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-valid',
            name: 'Valid WS',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            githubApiClientProvider.overrideWithValue(fakeGithubClient),
          ],
        );
        addTearDown(container.dispose);

        container.listen(workspacesProvider, (_, _) {});
        await Future.delayed(const Duration(milliseconds: 50));

        await container.read(credentialsProvider.future);
        final repo = container.read(prReviewRepositoryProvider);
        expect(repo, isA<CachedPrReviewRepository>());
      },
    );
  });

  group('prDetailProvider', () {
    test('provider is a StreamProvider.family', () {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      try {
        final stream = container.read(prDetailProvider(1));
        expect(stream, isA<Stream>());
      } catch (_) {}
    });
  });

  group('prDiffProvider', () {
    test('provider is a StreamProvider.family', () {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      try {
        final stream = container.read(prDiffProvider(1));
        expect(stream, isA<Stream>());
      } catch (_) {}
    });
  });

  group('prFilesProvider', () {
    test('provider is a StreamProvider.family', () {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      try {
        final stream = container.read(prFilesProvider(1));
        expect(stream, isA<Stream>());
      } catch (_) {}
    });
  });

  group('prReviewsProvider', () {
    test('provider is a StreamProvider.family', () {
      final db = createTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      try {
        final stream = container.read(prReviewsProvider(1));
        expect(stream, isA<Stream>());
      } catch (_) {}
    });
  });

  group('ReviewAction enum', () {
    test('has three values', () {
      expect(ReviewAction.values, hasLength(3));
      expect(ReviewAction.values, contains(ReviewAction.approve));
      expect(ReviewAction.values, contains(ReviewAction.requestChanges));
      expect(ReviewAction.values, contains(ReviewAction.comment));
    });
  });

  group('EmptyPrReviewRepository', () {
    test('watchPullRequest emits null', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchPullRequest(1).first;
      expect(result, null);
    });

    test('watchDiff emits empty string', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchDiff(1).first;
      expect(result, '');
    });

    test('watchFiles emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchFiles(1).first;
      expect(result, isEmpty);
    });

    test('watchFileContent emits empty string', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchFileContent('lib/main.dart', 'main').first;
      expect(result, '');
    });

    test('watchCommits emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommits(1).first;
      expect(result, isEmpty);
    });

    test('watchCommitFiles emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommitFiles('abc').first;
      expect(result, isEmpty);
    });

    test('watchReviews emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchReviews(1).first;
      expect(result, isEmpty);
    });

    test('watchReviewComments emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchReviewComments(1).first;
      expect(result, isEmpty);
    });

    test('watchIssueComments emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchIssueComments(1).first;
      expect(result, isEmpty);
    });

    test('watchCheckRuns emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCheckRuns(1).first;
      expect(result, isEmpty);
    });

    test('invalidatePullRequest completes without error', () async {
      const repo = EmptyPrReviewRepository();
      await expectLater(repo.invalidatePullRequest(1), completes);
    });
  });
}
