import 'dart:async';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_settings_screen.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return FTheme(
    data: FThemes.zinc.light.desktop,
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

RssFeed _makeFeed({
  String id = 'feed-1',
  String name = 'Test Feed',
  String url = 'https://example.com/feed',
  bool enabled = true,
  String? lastError,
}) {
  return RssFeed(
    id: id,
    name: name,
    url: url,
    enabled: enabled,
    lastError: lastError,
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

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('NewsfeedSettingsScreen', () {
    testWidgets('renders page title and breadcrumbs', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Newsfeed settings'), findsOneWidget);
    });

    testWidgets('renders Reader preferences section', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('READER PREFERENCES'), findsOneWidget);
    });

    testWidgets('renders Open in app preference', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Open articles in app'), findsOneWidget);
    });

    testWidgets('renders content blocking preference', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Block ads, trackers & cookie banners'),
        findsOneWidget,
      );
    });

    testWidgets('hides filter lists section when blocking is off',
        (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides(
            prefs: {'newsfeed.blockContent': false},
          )],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Filter lists'), findsNothing);
    });

    testWidgets('renders Add feed button', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add feed'), findsOneWidget);
    });

    testWidgets('renders Feeds section with count', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final feeds = [RssFeed(
        id: 'f1', name: 'My Feed', url: 'https://example.com/feed',
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      )];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides(feeds: feeds)],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('FEEDS (1)'), findsOneWidget);
    });

    testWidgets('renders empty feeds message', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides()],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('No feeds yet'),
        findsOneWidget,
      );
    });

    testWidgets('renders Refresh all button', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final feeds = [_makeFeed()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...await _defaultOverrides(feeds: feeds)],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Refresh all'), findsOneWidget);
    });

    testWidgets('renders loading state for feeds', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = StreamController<List<RssFeed>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await _inlineOverrides(),
            feedsProvider.overrideWith((ref) => controller.stream),
          ],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FCircularProgress), findsOneWidget);
    });

    testWidgets('renders error state for feeds', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await _inlineOverrides(),
            feedsProvider.overrideWith(
              (ref) => Stream.error(Exception('Network error')),
            ),
          ],
          child: _wrap(const NewsfeedSettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.textContaining('Failed to load feeds'), findsOneWidget);
    });
  });
}
