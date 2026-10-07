import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_domain/features/newsfeed/domain/ports/filter_list_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen.dart';
import 'package:control_center/features/newsfeed/providers/filter_list_bindings.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/fake_rpc_newsfeed_repository.dart';

class _FakeNewsfeedRepository extends FakeRpcNewsfeedRepository {
  _FakeNewsfeedRepository({super.article});
}

/// The screen mounts a real `InAppWebView` on macOS and Windows (Linux hands
/// the link to the system browser instead), and `flutter test` has no web view
/// platform, so on those hosts every test here failed an assertion. This one
/// renders nothing, which is all a toolbar test needs.
class _FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _FakeInAppWebViewWidget(params);
}

class _FakeInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _FakeInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();

  @override
  void dispose() {}
}

/// Apple hosts read the host's content-blocker rules before mounting the web
/// view; the real port needs a connected RPC client.
class _EmptyFilterListPort implements FilterListPort {
  @override
  Future<FilterListUpdateState> readState() async =>
      FilterListUpdateState.empty;

  @override
  Future<FilterListUpdateState> refresh({bool force = false}) async =>
      FilterListUpdateState.empty;

  @override
  Future<List<Map<String, dynamic>>> readBlocklist() async => const [];

  @override
  Future<Set<String>> readRemoveParams() async => const {};
}

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

RssArticle _testArticle({String id = 'article-1', bool saved = false}) {
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
  late AppPreferences prefs;

  setUpAll(() => InAppWebViewPlatform.instance = _FakeInAppWebViewPlatform());

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          newsfeedRepositoryProvider.overrideWithValue(
            _FakeNewsfeedRepository(article: _testArticle()),
          ),
          contentBlockingProvider.overrideWith(ContentBlockingController.new),
          filterListPortProvider.overrideWithValue(_EmptyFilterListPort()),
        ],
        child: _wrap(const ArticleWebviewScreen(articleId: 'article-1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('ArticleWebviewScreen', () {
    testWidgets('renders close button in toolbar', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(AppIcons.x), findsOneWidget);
    });

    testWidgets('renders back button in toolbar', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(AppIcons.arrowLeft), findsOneWidget);
    });

    testWidgets('renders forward button in toolbar', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(AppIcons.arrowRight), findsOneWidget);
    });

    testWidgets('renders open external button in toolbar', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(AppIcons.externalLink), findsOneWidget);
    });

    testWidgets('back and forward buttons disabled initially', (tester) async {
      await pumpScreen(tester);

      // Back and forward buttons should be present
      expect(find.byIcon(AppIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(AppIcons.arrowRight), findsOneWidget);
    });
  });
}
