import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/demo/demo_world.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_tour_panel.dart';
import 'package:control_center/features/demo/providers/demo_repo_stars_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;

const _workspaceId = 'ws-1';

Space _space(String id, String name) => Space(
  id: id,
  name: name,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// The seeded shape the demo server hands a visitor: the agent space is NOT
/// first and its id is a runtime UUID, which is what the panel must resolve by
/// name.
final _seededSpaces = [
  _space('uuid-general', 'general'),
  _space('uuid-harbor', kDemoAgentSpaceName),
];

/// Hosts the panel inside a router whose routes mirror the real destinations
/// (as opaque placeholders), so `context.go` works and the resulting location
/// can be asserted without mounting the real screens.
GoRouter _router({bool Function(String url)? openUrl}) => GoRouter(
  initialLocation: '/workspaces/$_workspaceId/inbox',
  routes: [
    GoRoute(
      path: '/workspaces/:workspaceId/inbox',
      builder: (_, _) => Scaffold(body: _PanelHost(openUrl: openUrl)),
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/spaces',
      builder: (_, _) => Scaffold(body: _PanelHost(openUrl: openUrl)),
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/spaces/:spaceId',
      builder: (_, _) => Scaffold(body: _PanelHost(openUrl: openUrl)),
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/pull-requests/:owner/:repo/:number',
      builder: (_, _) => Scaffold(body: _PanelHost(openUrl: openUrl)),
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/tickets/:ticketId',
      builder: (_, _) => Scaffold(body: _PanelHost(openUrl: openUrl)),
    ),
  ],
);

class _PanelHost extends StatelessWidget {
  const _PanelHost({this.openUrl});

  /// The URL opener the panel's "Star on GitHub" button calls; defaults to a
  /// no-op because the native opener cannot load under `flutter_tester`.
  final bool Function(String url)? openUrl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DemoTourPanel(
          workspaceId: _workspaceId,
          openUrl: openUrl ?? (_) => true,
        ),
      ),
    );
  }
}

Widget _wrap(GoRouter router, List<Override> overrides) => ProviderScope(
  overrides: [isDemoServerProvider.overrideWith((ref) => true), ...overrides],
  child: CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ),
);

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  // The four "Open" buttons share one label and are laid out in the stops'
  // build order: spaces, review, tickets, inbox.
  late Finder openButtons;

  Future<GoRouter> pumpPanel(
    WidgetTester tester, {
    List<Space> spaces = const [],
    bool Function(String url)? openUrl,
    int? repoStars,
  }) async {
    _setDesktopViewport(tester);
    final router = _router(openUrl: openUrl);
    final overrides = [
      workspaceSpacesProvider(_workspaceId).overrideWith(
        (ref) => Stream.value(spaces),
      ),
      if (repoStars != null)
        demoRepoStarsProvider.overrideWith((ref) => Future.value(repoStars)),
    ];
    await tester.pumpWidget(_wrap(router, overrides));
    await tester.pumpAndSettle();
    openButtons = find.widgetWithText(CcButton, 'Open');
    expect(openButtons, findsNWidgets(4));
    return router;
  }

  testWidgets('"Talk to an agent" opens the seeded space conversation', (
    tester,
  ) async {
    final router = await pumpPanel(tester, spaces: _seededSpaces);

    await tester.tap(openButtons.at(0));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      spaceRoute(_workspaceId, 'uuid-harbor'),
    );
  });

  testWidgets('without the seeded space it falls back to the first space', (
    tester,
  ) async {
    final router = await pumpPanel(
      tester,
      spaces: [_space('uuid-other', 'somewhere-else')],
    );

    await tester.tap(openButtons.at(0));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      spaceRoute(_workspaceId, 'uuid-other'),
    );
  });

  testWidgets('with no spaces at all it still navigates to the list', (
    tester,
  ) async {
    final router = await pumpPanel(tester, spaces: const []);

    await tester.tap(openButtons.at(0));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      spacesRoute(_workspaceId),
    );
  });

  testWidgets('"Review a pull request" opens the seeded PR detail', (
    tester,
  ) async {
    final router = await pumpPanel(tester, spaces: _seededSpaces);

    await tester.tap(openButtons.at(1));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      pullRequestDetailRoute(
        _workspaceId,
        kDemoRepoFullName,
        kDemoReviewPrNumber,
      ),
    );
  });

  testWidgets('"Follow the work" opens the seeded ticket', (tester) async {
    final router = await pumpPanel(tester, spaces: _seededSpaces);

    await tester.tap(openButtons.at(2));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      ticketDetailRoute(_workspaceId, kDemoTicketId),
    );
  });

  testWidgets('"See the whole operation" opens the inbox', (tester) async {
    final router = await pumpPanel(tester, spaces: _seededSpaces);

    await tester.tap(openButtons.at(3));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      inboxRoute(_workspaceId),
    );
  });

  testWidgets('"Star on GitHub" opens the project repo in the OS browser', (
    tester,
  ) async {
    final opened = <String>[];
    await pumpPanel(
      tester,
      spaces: _seededSpaces,
      openUrl: (url) {
        opened.add(url);
        return true;
      },
    );

    // It must be the REAL project repo, never the invented `parced/closing`
    // world the seeded PRs live in — that repo does not exist on GitHub.
    await tester.tap(find.text('Star on GitHub'));
    await tester.pumpAndSettle();

    expect(opened, [kDemoProjectRepoUrl]);
    expect(opened.single, isNot(contains(kDemoRepoFullName)));
  });

  testWidgets('"Star on GitHub" shows the count compactly (1.2K, not 1,200)', (
    tester,
  ) async {
    await pumpPanel(tester, spaces: _seededSpaces, repoStars: 1200);

    expect(find.text('1.2K'), findsOneWidget);
  });

  testWidgets('"Star on GitHub" renders without a count while unknown', (
    tester,
  ) async {
    // Loading or failed: no spinner, no placeholder, no error — the button
    // just carries its label. (Without an override the provider's RPC read
    // throws and is caught, which is exactly this path.)
    await pumpPanel(tester, spaces: _seededSpaces);

    expect(find.text('Star on GitHub'), findsOneWidget);
    expect(find.textContaining('K'), findsNothing);
  });
}
