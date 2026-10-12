import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_grid.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/proxied_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  for (final layout in NewsfeedLayout.values) {
    testWidgets('$layout preloads nearby previews but not full images', (
      tester,
    ) async {
      final client = _recordImages();
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final articles = List.generate(
        100,
        (index) => RssArticle(
          id: 'article-$index',
          feedId: 'feed',
          guid: 'guid-$index',
          title: 'Article $index',
          link: 'https://example.com/articles/$index',
          imageUrl: 'https://example.com/images/$index.png',
          createdAt: DateTime(2026),
        ),
      );

      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              newsfeedLayoutProvider.overrideWith(
                () => _FixedLayoutController(layout),
              ),
              feedsProvider.overrideWith((ref) => const Stream.empty()),
            ],
            child: _proxy(
              ArticleGrid(
                articles: articles,
                emptyTitle: 'No articles',
                emptyBody: 'No articles',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(CustomScrollView));
      final builtArticles = articles.where(
        (article) => _article(article.id).evaluate().isNotEmpty,
      );
      final nearby = builtArticles.firstWhere((article) {
        final rect = tester.getRect(_article(article.id));
        // Beyond Flutter's old 250px cache, still within one viewport ahead.
        return rect.top > viewport.bottom + 250 &&
            rect.top < viewport.bottom + viewport.height;
      });
      final visibleUrls = builtArticles
          .where(
            (article) =>
                tester.getRect(_article(article.id)).overlaps(viewport),
          )
          .map((article) => article.imageUrl)
          .toSet();

      expect(client.widthsFor(nearby.imageUrl), [48]);
      expect(client.widthsFor(articles.last.imageUrl), isEmpty);
      final fullRequests = client.requests.where(_isFullImage);
      expect(fullRequests.map(_sourceUrl).toSet(), visibleUrls);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      final targetOffset = tester.getRect(_article(nearby.id)).top;
      scrollable.position.jumpTo(targetOffset - viewport.top);
      await tester.pumpAndSettle();

      // The warmed preview is reused; only the larger variant starts now.
      expect(client.widthsFor(nearby.imageUrl).first, 48);
      expect(client.widthsFor(nearby.imageUrl).where((w) => w == 48), [48]);
      expect(
        client.widthsFor(nearby.imageUrl).where((w) => w > 48),
        hasLength(1),
      );
      expect(client.widthsFor(articles.last.imageUrl), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'replacing a cached offscreen image does not load its full size',
    (tester) async {
      final client = _recordImages();
      final url = ValueNotifier('https://example.com/old.png');
      final controller = ScrollController();
      addTearDown(url.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testWrap(
          _proxy(
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 100,
                child: ValueListenableBuilder(
                  valueListenable: url,
                  builder: (context, source, child) => ListView.builder(
                    controller: controller,
                    itemExtent: 100,
                    scrollCacheExtent: const ScrollCacheExtent.pixels(300),
                    itemCount: 10,
                    itemBuilder: (context, index) => index == 0
                        ? ProxiedImage(url: source, maxWidth: 340)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(client.widthsFor(url.value), [48, 384]);

      controller.jumpTo(200);
      await tester.pump();
      url.value = 'https://example.com/new.png';
      await tester.pump();
      await tester.pump();
      expect(client.widthsFor(url.value), [48]);

      controller.jumpTo(0);
      await tester.pump();
      await tester.pump();
      expect(client.widthsFor(url.value), [48, 384]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _FixedLayoutController extends NewsfeedLayoutController {
  _FixedLayoutController(this.layout);

  final NewsfeedLayout layout;

  @override
  NewsfeedLayout build() => layout;
}

Finder _article(String id) => find.byKey(ValueKey(id), skipOffstage: false);

_RecordingImageClient _recordImages() {
  final client = _RecordingImageClient();
  debugNetworkImageHttpClientProvider = () => client;
  addTearDown(() => debugNetworkImageHttpClientProvider = null);
  return client;
}

Widget _proxy(Widget child) => MediaProxyScope(
  config: MediaProxyConfig(
    httpBase: Uri.parse('https://host.example'),
    deviceId: 'test-device',
    psk: 'test-key',
  ),
  child: child,
);

String _sourceUrl(Uri request) =>
    utf8.decode(base64Url.decode(request.queryParameters['u']!));

bool _isFullImage(Uri request) => int.parse(request.queryParameters['w']!) > 48;

/// Records real provider requests and leaves responses pending, like a slow
/// connection. No decoding/timing race can hide an eager full-size request.
class _RecordingImageClient implements HttpClient {
  final requests = <Uri>[];

  List<int> widthsFor(String source) => [
    for (final request in requests)
      if (_sourceUrl(request) == source)
        int.parse(request.queryParameters['w']!),
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    requests.add(url);
    return SynchronousFuture(_PendingImageRequest());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingImageRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() => Completer<HttpClientResponse>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
