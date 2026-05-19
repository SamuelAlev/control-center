// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_settings_screen.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/newsfeed/providers/site_allowlist_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

RssFeed _makeFeed({
  String id = 'feed-1',
  String name = 'Test Feed',
  String url = 'https://example.com/feed',
  String description = '',
  bool enabled = true,
  String? lastError,
  DateTime? lastFetchedAt,
}) {
  return RssFeed(
    id: id,
    name: name,
    url: url,
    description: description,
    enabled: enabled,
    lastError: lastError,
    lastFetchedAt: lastFetchedAt,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

Future<List> _defaultOverrides({
  List<RssFeed>? feeds,
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final sp = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    feedsProvider.overrideWith((ref) => Stream.value(feeds ?? <RssFeed>[])),
    articleOpenModeProvider.overrideWith(ArticleOpenModeController.new),
    contentBlockingProvider.overrideWith(ContentBlockingController.new),
    newsfeedRefreshControllerProvider.overrideWith(NewsfeedRefreshController.new),
    filterListUpdateProvider.overrideWith(FilterListUpdateController.new),
  ];
}

Future<List> _inlineOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    articleOpenModeProvider.overrideWith(ArticleOpenModeController.new),
    contentBlockingProvider.overrideWith(ContentBlockingController.new),
    newsfeedRefreshControllerProvider.overrideWith(NewsfeedRefreshController.new),
    filterListUpdateProvider.overrideWith(FilterListUpdateController.new),
  ];
}

/// Overrides for when content-blocking is ON and we control allowlist directly.
Future<List> _blockingOverrides({
  List<RssFeed>? feeds,
  Set<String> trustedSites = const {},
  FilterListUpdateState? filterState,
}) async {
  SharedPreferences.setMockInitialValues({'newsfeed.blockContent': true});
  final sp = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    feedsProvider.overrideWith((ref) => Stream.value(feeds ?? <RssFeed>[])),
    articleOpenModeProvider.overrideWith(ArticleOpenModeController.new),
    contentBlockingProvider.overrideWith(ContentBlockingController.new),
    newsfeedRefreshControllerProvider.overrideWith(NewsfeedRefreshController.new),
    filterListUpdateProvider.overrideWith(
      () => _FixedFilterListState(filterState ?? const FilterListUpdateState(
        isUpdating: false,
        errors: [],
        cookieHidingRules: 0,
        adHidingRules: 0,
        networkBlockRules: 0,
        removeParamsCount: 0,
      )),
    ),
    siteAllowlistProvider.overrideWith(
      (ref) => Stream.value(trustedSites),
    ),
  ];
}

class _FixedFilterListState extends FilterListUpdateController {
  _FixedFilterListState(this._state);
  final FilterListUpdateState _state;
  @override
  FilterListUpdateState build() => _state;
}

class _RefreshingController extends NewsfeedRefreshController {
  @override
  bool build() => true;
}

void _setupViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpScreen(WidgetTester tester, {required List overrides}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: _wrap(const NewsfeedSettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('NewsfeedSettingsScreen', () {
    // ── Page-level rendering ────────────────────────────────────────────

    testWidgets('renders page title and breadcrumbs', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.text('Newsfeed settings'), findsOneWidget);
    });

    testWidgets('renders Reader preferences section', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.text('READER PREFERENCES'), findsOneWidget);
    });

    testWidgets('renders Open in app preference', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.text('Open articles in app'), findsOneWidget);
    });

    testWidgets('renders content blocking preference', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.text('Block ads, trackers & cookie banners'), findsOneWidget);
    });

    testWidgets('hides filter lists section when blocking is off',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        prefs: {'newsfeed.blockContent': false},
      ));
      expect(find.text('Filter lists'), findsNothing);
    });

    testWidgets('renders Add feed button', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.text('Add feed'), findsOneWidget);
    });

    testWidgets('renders Feeds section with count', (tester) async {
      _setupViewport(tester);
      final feeds = [RssFeed(id: 'f1', name: 'My Feed',
        url: 'https://example.com/feed',
        createdAt: DateTime(2024), updatedAt: DateTime(2024))];
      await _pumpScreen(tester, overrides: await _defaultOverrides(feeds: feeds));
      expect(find.textContaining('FEEDS (1)'), findsOneWidget);
    });

    testWidgets('renders empty feeds message', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.textContaining('No feeds yet'), findsOneWidget);
    });

    testWidgets('renders Refresh all button', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed()],
      ));
      expect(find.text('Refresh all'), findsOneWidget);
    });

    testWidgets('renders loading state for feeds', (tester) async {
      _setupViewport(tester);
      final controller = StreamController<List<RssFeed>>();
      addTearDown(controller.close);
      await _pumpScreen(tester, overrides: [
        ...await _inlineOverrides(),
        feedsProvider.overrideWith((ref) => controller.stream),
      ]);
      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('renders error state for feeds', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: [
        ...await _inlineOverrides(),
        feedsProvider.overrideWith(
          (ref) => Stream.error(Exception('Network error')),
        ),
      ]);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('Failed to load feeds'), findsOneWidget);
    });

    // ── Feed row rendering ──────────────────────────────────────────────

    testWidgets('renders feed name in feed row', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Hacker News')],
      ));
      expect(find.text('Hacker News'), findsOneWidget);
    });

    testWidgets('renders feed URL as subtitle when no description',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'My Feed', url: 'https://rss.example.com/atom')],
      ));
      expect(find.text('https://rss.example.com/atom'), findsOneWidget);
    });

    testWidgets('renders feed description as subtitle when present',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Dev Blog',
          description: 'A blog about software development')],
      ));
      expect(find.text('A blog about software development'), findsOneWidget);
    });

    testWidgets('renders error message on feed with error', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Broken Feed',
          lastError: 'Connection timed out')],
      ));
      expect(find.text('Connection timed out'), findsOneWidget);
    });

    testWidgets('does NOT render error for feed with null lastError',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Good Feed',
          url: 'https://good.example.com/rss', lastError: null)],
      ));
      expect(find.text('Good Feed'), findsOneWidget);
      expect(find.text('https://good.example.com/rss'), findsOneWidget);
    });

    testWidgets('does NOT treat empty lastError as an error',
        (tester) async {
      _setupViewport(tester);
      final feed = RssFeed(id: 'f1', name: 'Clean Feed',
        url: 'https://clean.example.com/rss', lastError: '',
        enabled: true, createdAt: DateTime(2024), updatedAt: DateTime(2024));
      await _pumpScreen(tester, overrides: await _defaultOverrides(feeds: [feed]));
      expect(find.text('Clean Feed'), findsOneWidget);
      expect(find.text('https://clean.example.com/rss'), findsOneWidget);
    });

    testWidgets('renders enable/disable toggle per feed', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed()],
      ));
      expect(find.byType(CcSwitch), findsAtLeast(3));
    });

    testWidgets('renders refresh button per feed', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed()],
      ));
      expect(find.byIcon(LucideIcons.refreshCw), findsWidgets);
    });

    testWidgets('renders delete button per feed', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed()],
      ));
      expect(find.byIcon(LucideIcons.trash2), findsWidgets);
    });

    testWidgets('renders relative updated label when feed was fetched',
        (tester) async {
      _setupViewport(tester);
      final justNow = DateTime.now().subtract(const Duration(minutes: 2));
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Fresh Feed', description: 'Dev updates',
          lastFetchedAt: justNow)],
      ));
      expect(find.textContaining('Updated '), findsOneWidget);
      expect(find.textContaining('Dev updates'), findsOneWidget);
    });

    testWidgets('renders description with relative label combined',
        (tester) async {
      _setupViewport(tester);
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Blog', description: 'A tech blog',
          lastFetchedAt: threeHoursAgo)],
      ));
      expect(find.textContaining('Updated 3h ago'), findsOneWidget);
      expect(find.textContaining('A tech blog'), findsOneWidget);
    });

    testWidgets('renders relative updated label for days ago',
        (tester) async {
      _setupViewport(tester);
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Older Feed', description: 'Updates',
          lastFetchedAt: twoDaysAgo)],
      ));
      expect(find.textContaining('Updated 2d ago'), findsOneWidget);
    });

    testWidgets('multiple feeds render all rows', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [
          _makeFeed(id: 'a', name: 'Feed A', url: 'https://a.example.com'),
          _makeFeed(id: 'b', name: 'Feed B', url: 'https://b.example.com'),
        ],
      ));
      expect(find.textContaining('FEEDS (2)'), findsOneWidget);
      expect(find.text('Feed A'), findsOneWidget);
      expect(find.text('Feed B'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsAtLeast(2));
    });

    testWidgets('Refresh all button shows progress while refreshing',
        (tester) async {
      _setupViewport(tester);
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      await _pumpScreen(tester, overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        feedsProvider.overrideWith(
          (ref) => Stream.value([_makeFeed()]),
        ),
        articleOpenModeProvider.overrideWith(ArticleOpenModeController.new),
        contentBlockingProvider.overrideWith(ContentBlockingController.new),
        newsfeedRefreshControllerProvider.overrideWith(
          _RefreshingController.new,
        ),
        filterListUpdateProvider.overrideWith(FilterListUpdateController.new),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Refresh all'), findsOneWidget);
      expect(find.byType(CcSpinner), findsWidgets);
    });

    // ── Settings toggles ────────────────────────────────────────────────

    testWidgets('toggling content blocking off hides filter + trusted sections',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides());
      expect(find.text('FILTER LISTS'), findsOneWidget);
      expect(find.text('TRUSTED SITES'), findsOneWidget);

      final switches = find.byType(CcSwitch);
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(find.text('FILTER LISTS'), findsNothing);
      expect(find.text('TRUSTED SITES'), findsNothing);
    });

    testWidgets('toggling open mode changes switch state', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        prefs: {'newsfeed.openMode': 'browser'},
      ));
      final switches = find.byType(CcSwitch);
      final openModeSwitch = tester.widget<CcSwitch>(switches.first);
      expect(openModeSwitch.value, isFalse);
    });

    testWidgets('open mode defaults to in-app', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      final switches = find.byType(CcSwitch);
      final openModeSwitch = tester.widget<CcSwitch>(switches.first);
      expect(openModeSwitch.value, isTrue);
    });

    // ── Filter list status ──────────────────────────────────────────────

    testWidgets('renders filter list section when blocking is on',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides());
      expect(find.text('FILTER LISTS'), findsOneWidget);
    });

    testWidgets('shows Check for updates button', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides());
      expect(find.text('Check for updates'), findsOneWidget);
    });

    testWidgets('shows bundled defaults label when never updated',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: const FilterListUpdateState(
          isUpdating: false, errors: [],
          cookieHidingRules: 0, adHidingRules: 0,
          networkBlockRules: 0, removeParamsCount: 0,
          lastSuccess: null,
        ),
      ));
      expect(find.text('Bundled defaults \u2014 never updated'), findsOneWidget);
    });

    testWidgets('shows relative last updated label when fetched',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: FilterListUpdateState(
          isUpdating: false, errors: [],
          cookieHidingRules: 1, adHidingRules: 2,
          networkBlockRules: 3, removeParamsCount: 4,
          lastSuccess: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ));
      expect(find.textContaining('Updated '), findsOneWidget);
    });

    testWidgets('shows counter chips with rule counts', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: const FilterListUpdateState(
          isUpdating: false, errors: [],
          cookieHidingRules: 12, adHidingRules: 34,
          networkBlockRules: 56, removeParamsCount: 78,
        ),
      ));
      expect(find.textContaining('12 cookie rules'), findsOneWidget);
      expect(find.textContaining('34 ad rules'), findsOneWidget);
      expect(find.textContaining('56 network blocks'), findsOneWidget);
      expect(find.textContaining('78 tracking params'), findsOneWidget);
    });

    testWidgets('shows updating state with progress indicator',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: const FilterListUpdateState(
          isUpdating: true, errors: [],
          cookieHidingRules: 0, adHidingRules: 0,
          networkBlockRules: 0, removeParamsCount: 0,
        ),
      ));
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.byType(CcSpinner), findsWidgets);
    });

    testWidgets('shows error messages when present', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: const FilterListUpdateState(
          isUpdating: false,
          errors: ['Download failed', 'DNS error'],
          cookieHidingRules: 0, adHidingRules: 0,
          networkBlockRules: 0, removeParamsCount: 0,
        ),
      ));
      expect(find.text('Download failed'), findsOneWidget);
      expect(find.text('DNS error'), findsOneWidget);
    });

    testWidgets('does not show error area when errors list is empty',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        filterState: const FilterListUpdateState(
          isUpdating: false, errors: [],
          cookieHidingRules: 5, adHidingRules: 5,
          networkBlockRules: 5, removeParamsCount: 5,
        ),
      ));
      expect(find.textContaining('5 cookie rules'), findsOneWidget);
    });

    // ── Trusted sites ───────────────────────────────────────────────────

    testWidgets('renders trusted sites section when blocking is on',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides());
      expect(find.text('TRUSTED SITES'), findsOneWidget);
    });

    testWidgets('shows empty state when no trusted sites', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        trustedSites: {},
      ));
      expect(find.textContaining('No trusted sites'), findsOneWidget);
    });

    testWidgets('shows Add trusted site button', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides());
      expect(find.text('Add trusted site'), findsOneWidget);
    });

    testWidgets('renders trusted site domains', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        trustedSites: {'example.com', 'test.org'},
      ));
      expect(find.text('example.com'), findsOneWidget);
      expect(find.text('test.org'), findsOneWidget);
    });

    testWidgets('each trusted site row has a remove button', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _blockingOverrides(
        trustedSites: {'example.com'},
      ));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    // ── Edge cases ──────────────────────────────────────────────────────

    testWidgets('0 feeds shows empty state', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides());
      expect(find.textContaining('No feeds yet'), findsOneWidget);
    });

    testWidgets('disabled feed renders', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [
          _makeFeed(id: 'a', name: 'Disabled', enabled: false),
          _makeFeed(id: 'b', name: 'Enabled', enabled: true),
        ],
      ));
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
    });

    testWidgets('feed with long name renders', (tester) async {
      _setupViewport(tester);
      final longName = 'A' * 100;
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: longName)],
      ));
      expect(find.text(longName), findsOneWidget);
    });

    testWidgets('disabled feed has off toggle', (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [_makeFeed(name: 'Off Feed', enabled: false)],
      ));
      final switches = find.byType(CcSwitch);
      final feedSwitch = tester.widget<CcSwitch>(switches.at(2));
      expect(feedSwitch.value, isFalse);
    });

    testWidgets('filter list section not rendered when blocking off',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        prefs: {'newsfeed.blockContent': false},
      ));
      expect(find.text('Filter lists'), findsNothing);
      expect(find.text('Trusted sites'), findsNothing);
      expect(find.text('Check for updates'), findsNothing);
      expect(find.text('Add trusted site'), findsNothing);
    });

    testWidgets('feeds section label reflects count dynamically',
        (tester) async {
      _setupViewport(tester);
      await _pumpScreen(tester, overrides: await _defaultOverrides(
        feeds: [
          _makeFeed(id: '1', name: 'A', url: 'https://a.com'),
          _makeFeed(id: '2', name: 'B', url: 'https://b.com'),
          _makeFeed(id: '3', name: 'C', url: 'https://c.com'),
        ],
      ));
      expect(find.textContaining('FEEDS (3)'), findsOneWidget);
    });
  });
}
