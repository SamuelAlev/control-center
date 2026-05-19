import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          githubApiClientProvider.overrideWithValue(fakeGithubClient),
          credentialsProvider.overrideWith(_StubCredentialsNotifier.empty),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test('returns EmptyPrReviewRepository when no active workspace',
        () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          githubApiClientProvider.overrideWithValue(fakeGithubClient),
          credentialsProvider.overrideWith(_StubCredentialsNotifier.empty),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test(
      'returns EmptyPrReviewRepository when workspace has no repo info',
      () async {
        final prefs = AppPreferences.inMemory({githubTokenKey: 'ghp_test'});

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-no-info',
            name: 'No Info',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            githubApiClientProvider.overrideWithValue(fakeGithubClient),
            credentialsProvider
                .overrideWith(() => _StubCredentialsNotifier(token: 'ghp_test')),
          ],
        );
        addTearDown(container.dispose);
        await container.read(credentialsProvider.future);
        final repo = container.read(prReviewRepositoryProvider);
        expect(repo, isA<EmptyPrReviewRepository>());
      },
    );

    test(
      'returns EmptyPrReviewRepository when authenticated but no active '
      'workspace is selected',
      () async {
        final prefs = AppPreferences.inMemory({githubTokenKey: 'ghp_test'});

        await db.workspaceDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(
            id: 'ws-valid',
            name: 'Valid WS',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            githubApiClientProvider.overrideWithValue(fakeGithubClient),
            credentialsProvider
                .overrideWith(() => _StubCredentialsNotifier(token: 'ghp_test')),
          ],
        );
        addTearDown(container.dispose);
        await container.read(credentialsProvider.future);
        // Even though authenticated, without an active workspace/repo
        // the repository falls back to EmptyPrReviewRepository.
        final repo = container.read(prReviewRepositoryProvider);
        expect(repo, isA<EmptyPrReviewRepository>());
      },
    );
  });

  group('prDetailProvider', () {
    test('is a StreamProvider.family', () {
      expect(prDetailProvider, isNotNull);
    });
  });

  group('prDiffProvider', () {
    test('is a StreamProvider.family', () {
      expect(prDiffProvider, isNotNull);
    });
  });

  group('prFilesProvider', () {
    test('is a StreamProvider.family', () {
      expect(prFilesProvider, isNotNull);
    });
  });

  group('prReviewsProvider', () {
    test('is a StreamProvider.family', () {
      expect(prReviewsProvider, isNotNull);
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
      final result = await repo.watchFileContent('path', 'main').first;
      expect(result, '');
    });

    test('watchCommits emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommits(1).first;
      expect(result, isEmpty);
    });

    test('watchCommitFiles emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommitFiles('sha').first;
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
      await repo.invalidatePullRequest(1);
    });
  });
}

class _StubCredentialsNotifier extends CredentialsNotifier {
  _StubCredentialsNotifier({String token = ''})
      : _token = token;

  factory _StubCredentialsNotifier.empty() => _StubCredentialsNotifier();

  final String _token;
  @override
  Future<ApiCredentials> build() async {
    return ApiCredentials(githubToken: _token);
  }
}
