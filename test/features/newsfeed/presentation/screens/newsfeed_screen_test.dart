import 'dart:async';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_screen.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_grid.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_skeleton.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Fake Repository
// ---------------------------------------------------------------------------

class _FakeNewsfeedRepository implements NewsfeedRepository {
  _FakeNewsfeedRepository({
    this.feeds = const [],
    this.articles = const [],
    this.savedArticles = const [],
  }) : seedThrows = false;

  final List<RssFeed> feeds;
  final List<RssArticle> articles;
  final List<RssArticle> savedArticles;
  final bool seedThrows;

  @override
  Stream<List<RssFeed>> watchFeeds() => Stream.value(feeds);

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      Stream.value(articles);

  @override
  Stream<List<RssArticle>> watchSavedArticles() =>
      Stream.value(savedArticles);

  @override
  Future<RssArticle?> getArticleById(String id) async => null;

  @override
  Future<RssFeed> addFeed({
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) async {}

  @override
  Future<void> deleteFeed(String feedId) async {}

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> refreshFeed(String feedId) async {}

  @override
  Future<void> setArticleSaved(String articleId, {required bool saved}) async {}

  @override
  Future<void> setArticleRead(String articleId, {required bool read}) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> seedDefaultFeedsIfEmpty() async {
    if (seedThrows) {
      throw Exception('Seeding failed');
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RssArticle _testArticle({
  String id = 'article-1',
  String title = 'Test Article',
  bool saved = false,
  bool read = false,
}) {
  return RssArticle(
    id: id,
    feedId: 'feed-1',
    guid: 'guid-$id',
    title: title,
    link: 'https://example.com/$id',
    summary: 'Summary for $title',
    saved: saved,
    read: read,
    createdAt: DateTime(2024),
  );
}

RssFeed _testFeed({
  String id = 'feed-1',
  String name = 'Test Feed',
  bool enabled = true,
}) {
  return RssFeed(
    id: id,
    name: name,
    url: 'https://example.com/feed',
    enabled: enabled,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

/// A [NewsfeedViewController] whose [build] returns a fixed value.
class _FixedNewsfeedViewController extends NewsfeedViewController {
  _FixedNewsfeedViewController(this._view);
  final NewsfeedView _view;

  @override
  NewsfeedView build() => _view;
}

/// Returns the common newsfeed overrides for testing.
///
/// [newsfeedViewProvider] is deliberately absent — add it per-test so the
/// saved-view test can supply its own controller without a duplicate override.
List<Override> _newsfeedOverrides({
  required _FakeNewsfeedRepository repo,
  AsyncValue<List<RssArticle>>? filteredArticles,
}) {
  return [
    newsfeedRepositoryProvider.overrideWith((ref) => repo),
    feedsProvider.overrideWith((ref) => repo.watchFeeds()),
    articlesProvider.overrideWith((ref) => repo.watchArticles()),
    savedArticlesProvider.overrideWith((ref) => repo.watchSavedArticles()),
    if (filteredArticles != null)
      filteredArticlesProvider.overrideWith((ref) => filteredArticles),
    newsfeedRefreshControllerProvider.overrideWith(
      NewsfeedRefreshController.new,
    ),
    newsfeedLayoutProvider.overrideWith(NewsfeedLayoutController.new),
    newsfeedFilterProvider.overrideWith(SelectedFeedIdsController.new),
    newsfeedSearchProvider.overrideWith(SearchQueryController.new),
    feedUnreadCountsProvider.overrideWith((ref) => const <String, int>{}),
    articleActionsProvider.overrideWith(ArticleActionsNotifier.new),
    markAllReadControllerProvider.overrideWith(MarkAllReadController.new),
    focusedArticleIdProvider.overrideWith(FocusedArticleIdNotifier.new),
    articleOpenModeProvider.overrideWith(ArticleOpenModeController.new),
    contentBlockingProvider.overrideWith(ContentBlockingController.new),
    filterListUpdateProvider.overrideWith(FilterListUpdateController.new),
  ];
}

/// Wraps [child] in [testWrap] (base overrides) with an inner
/// [ProviderScope] carrying the newsfeed overrides.
Widget _wrap(Widget child, List<Override> overrides) {
  return testWrap(ProviderScope(overrides: overrides, child: child));
}

/// Sets up mock [SharedPreferences] and returns the override for
/// [sharedPreferencesProvider].
Future<Override> _sharedPrefsOverride() async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(sp);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NewsfeedScreen initial render', () {
    testWidgets('renders with articles', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final articles = [
        _testArticle(id: 'a1', title: 'Article One'),
        _testArticle(id: 'a2', title: 'Article Two'),
      ];
      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: articles,
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: AsyncValue.data(articles),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Article One'), findsOneWidget);
      expect(find.text('Article Two'), findsOneWidget);
    });

    testWidgets('renders page title', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final articles = [_testArticle()];
      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: articles,
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: AsyncValue.data(articles),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Newsfeed'), findsOneWidget);
    });
  });

  group('NewsfeedScreen empty state', () {
    testWidgets('shows empty state when no articles exist', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: const [],
        savedArticles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: const AsyncValue.data([]),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No articles yet'), findsOneWidget);
    });

    testWidgets('shows empty state when saved view has no bookmarks',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final articles = [_testArticle(id: 'a1')];
      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: articles,
        savedArticles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: const AsyncValue.data([]),
        ),
        newsfeedViewProvider.overrideWith(
          () => _FixedNewsfeedViewController(NewsfeedView.saved),
        ),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No saved articles'), findsOneWidget);
    });
  });

  group('NewsfeedScreen loading state', () {
    testWidgets('shows skeleton while loading', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: const AsyncValue.loading(),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NewsfeedSkeleton), findsOneWidget);
    });

    testWidgets('does not show empty state while loading', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: const AsyncValue.loading(),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No articles yet'), findsNothing);
    });
  });

  group('NewsfeedScreen error state', () {
    testWidgets('shows error message when articles fail to load',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: AsyncValue.error(
            Exception('Network failure'),
            StackTrace.empty,
          ),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // l10n.failedWithError('$e') produces "Failed: $e" in English.
      expect(
        find.text('Failed: Exception: Network failure'),
        findsOneWidget,
      );
    });

    testWidgets('does not show skeleton on error', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeNewsfeedRepository(
        feeds: [_testFeed()],
        articles: const [],
      );
      final overrides = [
        await _sharedPrefsOverride(),
        ..._newsfeedOverrides(
          repo: repo,
          filteredArticles: AsyncValue.error(
            Exception('Boom'),
            StackTrace.empty,
          ),
        ),
        newsfeedViewProvider.overrideWith(NewsfeedViewController.new),
      ];

      await tester.pumpWidget(_wrap(const NewsfeedScreen(), overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NewsfeedSkeleton), findsNothing);
    });
  });
}
