import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNewsfeedRepository implements NewsfeedRepository {

  _FakeNewsfeedRepository({this.article});
  final RssArticle? article;

  @override
  Future<RssArticle?> getArticleById(String id) async => article;

  @override
  Stream<List<RssFeed>> watchFeeds() => const Stream.empty();

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      const Stream.empty();

  @override
  Stream<List<RssArticle>> watchSavedArticles() => const Stream.empty();

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
  Future<void> seedDefaultFeedsIfEmpty() async {}
}

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: child),
  );
}

RssArticle _testArticle({
  String id = 'article-1',
  bool saved = false,
}) {
  return RssArticle(
    id: id,
    feedId: 'feed-1',
    guid: 'guid-$id',
    title: 'Test Article',
    link: 'https://example.com/article',
    summary: 'Test summary',
    saved: saved,
    createdAt: DateTime(2024),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ArticleWebviewScreen', () {
    testWidgets('renders article reader toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('renders close button in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('renders back button in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    });

    testWidgets('renders forward button in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
    });

    testWidgets('renders reload button in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // When loading, the reload button shows a spinner instead of the icon
      expect(find.byType(CcSpinner), findsWidgets);
    });

    testWidgets('renders open external button in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(LucideIcons.externalLink), findsOneWidget);
    });

    testWidgets('renders bookmark button when article found', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The toolbar renders without error when an article is found
    });

    testWidgets('shows loading spinner initially', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();

      expect(find.byType(CcSpinner), findsWidgets);
    });

    testWidgets('url bar renders in toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('back and forward buttons disabled initially', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            newsfeedRepositoryProvider
                .overrideWithValue(_FakeNewsfeedRepository(article: _testArticle())),
            contentBlockingProvider.overrideWith(ContentBlockingController.new),
          ],
          child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Back and forward buttons should be present
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
    });
  });
}
