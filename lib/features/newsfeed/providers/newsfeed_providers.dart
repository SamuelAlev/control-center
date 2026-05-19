import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/data/repositories/dao_newsfeed_repository.dart';
import 'package:control_center/features/newsfeed/data/services/filter_list_service.dart';
import 'package:control_center/features/newsfeed/data/services/rss_fetcher_service.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:control_center/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedicated dio for RSS fetching (no auth interceptor — feeds are public).
final newsfeedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Provider for the RSS fetcher service.
final rssFetcherServiceProvider = Provider<RssFetcherService>((ref) {
  return RssFetcherService(ref.watch(newsfeedDioProvider));
});

/// Provider for the newsfeed repository implementation.
final newsfeedRepositoryProvider = Provider<NewsfeedRepository>((ref) {
  return DaoNewsfeedRepository(
    ref.watch(rssDaoProvider),
    ref.watch(rssFetcherServiceProvider),
  );
});

/// Stream of all RSS feeds.
final feedsProvider = StreamProvider<List<RssFeed>>((ref) {
  return ref.watch(newsfeedRepositoryProvider).watchFeeds();
});

/// Stream of articles across enabled feeds.
final articlesProvider = StreamProvider<List<RssArticle>>((ref) {
  return ref.watch(newsfeedRepositoryProvider).watchArticles();
});

/// Stream of bookmarked articles.
final savedArticlesProvider = StreamProvider<List<RssArticle>>((ref) {
  return ref.watch(newsfeedRepositoryProvider).watchSavedArticles();
});

/// One article by id, for the article reader breadcrumb and deep links.
/// Backed by a one-shot repository fetch so it also resolves older/saved-only
/// articles that aren't in the recent-window [articlesProvider] stream.
final articleByIdProvider = FutureProvider.family<RssArticle?, String>((
  ref,
  id,
) {
  return ref.watch(newsfeedRepositoryProvider).getArticleById(id);
});

/// Source-feed selection for the newsfeed grid. Empty set = all sources.
class SelectedFeedIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Replaces the selected feed IDs with [ids].
  void replaceAll(Set<String> ids) {
    state = Set<String>.unmodifiable(ids);
  }

  /// Clears all selected feed IDs.
  void clear() {
    state = const <String>{};
  }
}

/// Source-feed selection for the newsfeed grid.
final newsfeedFilterProvider =
    NotifierProvider<SelectedFeedIdsController, Set<String>>(
      SelectedFeedIdsController.new,
    );

/// Free-text search applied to article titles, summaries and authors.
class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  /// Updates the active search [query].
  void set(String query) => state = query;

  /// Clears the search query.
  void clear() => state = '';
}

/// Search query for the newsfeed grid.
final newsfeedSearchProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

/// Which slice of articles the newsfeed grid shows.
enum NewsfeedView {
  /// Every article across enabled feeds.
  all,

  /// Only articles the user has not opened yet.
  unread,

  /// Only bookmarked articles.
  saved,
}

/// Holds the active [NewsfeedView] for the grid.
class NewsfeedViewController extends Notifier<NewsfeedView> {
  @override
  NewsfeedView build() => NewsfeedView.all;

  /// Switches the active view.
  void set(NewsfeedView view) => state = view;
}

/// The active newsfeed view (all / unread / saved).
final newsfeedViewProvider =
    NotifierProvider<NewsfeedViewController, NewsfeedView>(
      NewsfeedViewController.new,
    );

/// How the newsfeed renders its articles.
enum NewsfeedLayout {
  /// Dense, scannable rows — the default for a keyboard-first operator.
  list,

  /// Magazine card grid with larger thumbnails.
  grid,
}

const _kNewsfeedLayoutKey = 'newsfeed.layout';

/// Holds the active [NewsfeedLayout], persisted across launches.
///
/// Defaults to [NewsfeedLayout.list]: the operator scans an intel feed rather
/// than browsing a photo wall, so the digest list is the floor and the grid is
/// the opt-in.
class NewsfeedLayoutController extends Notifier<NewsfeedLayout> {
  @override
  NewsfeedLayout build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_kNewsfeedLayoutKey) == 'grid'
        ? NewsfeedLayout.grid
        : NewsfeedLayout.list;
  }

  /// Switches the active layout and persists the choice.
  Future<void> set(NewsfeedLayout layout) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _kNewsfeedLayoutKey,
      layout == NewsfeedLayout.grid ? 'grid' : 'list',
    );
    state = layout;
  }
}

/// The active newsfeed layout (list / grid).
final newsfeedLayoutProvider =
    NotifierProvider<NewsfeedLayoutController, NewsfeedLayout>(
      NewsfeedLayoutController.new,
    );

/// Number of unread articles per feed id across all enabled feeds.
final feedUnreadCountsProvider = Provider<Map<String, int>>((ref) {
  final articles = ref.watch(articlesProvider).value ?? const <RssArticle>[];
  final counts = <String, int>{};
  for (final a in articles) {
    if (!a.read) {
      counts[a.feedId] = (counts[a.feedId] ?? 0) + 1;
    }
  }
  return counts;
});

/// True if [article] matches the lowercased, trimmed search [query].
bool _matchesQuery(RssArticle article, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  return article.title.toLowerCase().contains(q) ||
      article.summary.toLowerCase().contains(q) ||
      article.author.toLowerCase().contains(q);
}

/// Newsfeed articles for the active view, filtered by source and search.
///
/// The `saved` view reads from [savedArticlesProvider] so bookmarks that have
/// scrolled out of the recent-articles window still appear; the other views
/// read the recent window from [articlesProvider].
final filteredArticlesProvider = Provider<AsyncValue<List<RssArticle>>>((ref) {
  final selected = ref.watch(newsfeedFilterProvider);
  final query = ref.watch(newsfeedSearchProvider);
  final view = ref.watch(newsfeedViewProvider);
  final source = view == NewsfeedView.saved
      ? ref.watch(savedArticlesProvider)
      : ref.watch(articlesProvider);
  return source.whenData(
    (list) => list
        .where((a) => selected.isEmpty || selected.contains(a.feedId))
        .where((a) => view != NewsfeedView.unread || !a.read)
        .where((a) => _matchesQuery(a, query))
        .toList(),
  );
});

/// Marks every article across all feeds as read.
class MarkAllReadController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks all articles read. No-op while a previous call is in flight.
  Future<void> markAllRead() async {
    if (state) {
      return;
    }
    state = true;
    try {
      await ref.read(newsfeedRepositoryProvider).markAllRead();
    } finally {
      state = false;
    }
  }
}

/// Provider that controls the mark-all-read action.
final markAllReadControllerProvider =
    NotifierProvider<MarkAllReadController, bool>(MarkAllReadController.new);

/// True while a refresh-all is in progress.
class NewsfeedRefreshController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Refetches every enabled feed.
  Future<void> refreshAll() async {
    if (state) {
      return;
    }
    state = true;
    try {
      await ref.read(newsfeedRepositoryProvider).refreshAll();
    } finally {
      state = false;
    }
  }

  /// Refetches a single feed by [feedId].
  Future<void> refreshFeed(String feedId) async {
    if (state) {
      return;
    }
    state = true;
    try {
      await ref.read(newsfeedRepositoryProvider).refreshFeed(feedId);
    } finally {
      state = false;
    }
  }
}

/// Provider that controls newsfeed refresh state.
final newsfeedRefreshControllerProvider =
    NotifierProvider<NewsfeedRefreshController, bool>(
      NewsfeedRefreshController.new,
    );

// ── Settings ─────────────────────────────────────────────────────────────

/// Where to open an article when the card is clicked.
enum ArticleOpenMode {
  /// Opens articles inside the in-app webview.
  inApp,

  /// Opens articles in the system default browser.
  externalBrowser,
}

const _kArticleOpenModeKey = 'newsfeed.openMode';

/// Article open mode controller.
class ArticleOpenModeController extends Notifier<ArticleOpenMode> {
  @override
  ArticleOpenMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kArticleOpenModeKey);
    return raw == 'browser'
        ? ArticleOpenMode.externalBrowser
        : ArticleOpenMode.inApp;
  }

  /// Updates the preferred article open [mode].
  Future<void> set(ArticleOpenMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _kArticleOpenModeKey,
      mode == ArticleOpenMode.externalBrowser ? 'browser' : 'inApp',
    );
    state = mode;
  }
}

/// Provider for the user's article open-mode preference.
final articleOpenModeProvider =
    NotifierProvider<ArticleOpenModeController, ArticleOpenMode>(
      ArticleOpenModeController.new,
    );

const _kBlockContentKey = 'newsfeed.blockContent';

/// Content blocking controller (ads, trackers, cookie banners).
class ContentBlockingController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getBool(_kBlockContentKey);
    if (value != null) {
      return value;
    }
    final oldAds = prefs.getBool('newsfeed.blockAds');
    if (oldAds != null) {
      return oldAds;
    }
    final oldCookies = prefs.getBool('newsfeed.blockCookies');
    if (oldCookies != null) {
      return oldCookies;
    }
    return true;
  }

  /// Toggles content blocking.
  Future<void> set({required bool enabled}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kBlockContentKey, enabled);
    state = enabled;
  }
}

/// Provider for the content-blocking toggle.
final contentBlockingProvider =
    NotifierProvider<ContentBlockingController, bool>(
      ContentBlockingController.new,
    );

// ── Filter List Auto-Update ──────────────────────────────────────────────

/// Provider for the filter-list download / cache service.
final filterListServiceProvider = Provider<FilterListService>((ref) {
  return FilterListService(
    ref.watch(newsfeedDioProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

/// Controller that tracks the state of filter-list updates and exposes
/// manual refresh / auto-update operations.
class FilterListUpdateController extends Notifier<FilterListUpdateState> {
  @override
  FilterListUpdateState build() {
    return ref.watch(filterListServiceProvider).readState();
  }

  /// Checks whether an update is due and performs it if so.
  Future<void> autoUpdate() async {
    final service = ref.read(filterListServiceProvider);
    final result = await service.autoUpdate();
    state = result;
  }

  /// Forces a full refresh, ignoring the 24-hour cooldown.
  Future<void> refresh() async {
    state = state.copyWith(isUpdating: true);
    final service = ref.read(filterListServiceProvider);
    final result = await service.manualRefresh();
    state = result;
  }
}

/// Provider that exposes the current filter-list update state.
final filterListUpdateProvider =
    NotifierProvider<FilterListUpdateController, FilterListUpdateState>(
      FilterListUpdateController.new,
    );

/// Non-blocking auto-update scheduler. Call once at app startup after
/// the provider scope is ready.
void scheduleFilterListAutoUpdate(WidgetRef ref) {
  Future.delayed(const Duration(seconds: 15), () async {
    try {
      await ref.read(filterListUpdateProvider.notifier).autoUpdate();
    } on Object {
      // Silently ignore — the user can trigger a manual refresh later.
    }
  });
}
