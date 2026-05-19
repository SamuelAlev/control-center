import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

RssArticle _makeArticle({
  String id = 'article-1',
  String feedId = 'feed-1',
  String title = 'Test Article',
  String link = 'https://example.com/article',
  String summary = 'This is a test summary.',
  String imageUrl = '',
  bool saved = false,
  DateTime? publishedAt,
}) {
  return RssArticle(
    id: id,
    feedId: feedId,
    guid: 'guid-$id',
    title: title,
    link: link,
    summary: summary,
    imageUrl: imageUrl,
    saved: saved,
    publishedAt: publishedAt,
    createdAt: DateTime(2024),
  );
}

RssFeed _makeFeed({
  String id = 'feed-1',
  String name = 'Test Feed',
}) {
  return RssFeed(
    id: id,
    name: name,
    url: 'https://example.com/feed',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  testWidgets('renders article title', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle();

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: _makeFeed(),
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Test Article'), findsOneWidget);
  });

  testWidgets('renders article summary', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle();

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('This is a test summary.'), findsOneWidget);
  });

  testWidgets('renders feed name when provided', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle();
    final feed = _makeFeed(name: 'My RSS Feed');

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: feed,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('My RSS Feed'), findsOneWidget);
  });

  testWidgets('renders placeholder thumbnail when no image', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(imageUrl: '');

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('renders bookmark icon', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle();

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('renders relative time', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
    );

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('3h'), findsOneWidget);
  });

  testWidgets('renders relative time in minutes', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(
      publishedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('30m'), findsOneWidget);
  });

  testWidgets('renders saved article icon color', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(saved: true);

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('relative time with days', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('3d'), findsOneWidget);
  });

  testWidgets('renders without feed (null feed)', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final article = _makeArticle(summary: '');

    await tester.pumpWidget(
      _wrap(
        ArticleCard(
          article: article,
          feed: null,
          onTap: () {},
          onToggleSaved: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Test Article'), findsOneWidget);
  });
}
