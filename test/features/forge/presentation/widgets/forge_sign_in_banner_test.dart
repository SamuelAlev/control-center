import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_sign_in_banner.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _FixedWorkspace extends ActiveWorkspaceIdNotifier {
  _FixedWorkspace(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

const _signedOut = [
  ForgeConnection(
    forge: ForgeHost.github,
    status: ForgeConnectionStatus.notConnected,
  ),
  ForgeConnection(
    forge: ForgeHost.gitlab,
    status: ForgeConnectionStatus.notConnected,
  ),
];

const _signedIn = [
  ForgeConnection(
    forge: ForgeHost.github,
    status: ForgeConnectionStatus.connected,
    username: 'a',
  ),
  ForgeConnection(
    forge: ForgeHost.gitlab,
    status: ForgeConnectionStatus.notConnected,
  ),
];

/// The banner under a real router, so its link and its "hide on the page
/// that already holds the sign-in" rule run as in the shell.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required List<ForgeConnection> connections,
  String initial = '/workspaces/ws-1/inbox',
  bool demo = false,
  String? workspaceId = 'ws-1',
}) async {
  Widget page(GoRouterState state) => Column(
    children: [const ForgeSignInBanner(), Text(state.matchedLocation)],
  );
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: inboxRoute('ws-1'), builder: (_, s) => page(s)),
      GoRoute(
        path: settingsAccountProfileRoute('ws-1'),
        builder: (_, s) => page(s),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isDemoServerProvider.overrideWith((ref) => demo),
        activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspace(workspaceId),
        ),
        forgeConnectionsProvider.overrideWith((ref) async => connections),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: kSupportedAppLocales,
        locale: const Locale('en'),
        builder: (context, child) => CcTheme(
          data: CcThemeData.light(),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('needsForgeSignIn', () {
    test('every forge answered and none is signed in', () {
      expect(needsForgeSignIn(_signedOut), isTrue);
    });

    test('one signed-in forge is enough', () {
      expect(needsForgeSignIn(_signedIn), isFalse);
    });

    test('an unreachable or unloaded server is not a sign-out', () {
      expect(needsForgeSignIn(const []), isFalse);
      expect(needsForgeSignIn(null), isFalse);
    });
  });

  group('forgeSignInBannerSubject', () {
    const lapsed = ForgeConnection(
      forge: ForgeHost.github,
      status: ForgeConnectionStatus.needsSignIn,
      username: 'a',
    );
    const paused = ForgeConnection(
      forge: ForgeHost.gitlab,
      status: ForgeConnectionStatus.paused,
    );
    const unreachable = ForgeConnection(
      forge: ForgeHost.bitbucket,
      status: ForgeConnectionStatus.unreachable,
    );

    test('a lapsed sign-in comes first: it is the reader\'s to fix', () {
      expect(forgeSignInBannerSubject(const [paused, lapsed]), lapsed);
    });

    test('a paused grant is named when nothing needs a sign-in', () {
      expect(forgeSignInBannerSubject(const [paused]), paused);
    });

    test('a provider that is only retrying raises no banner', () {
      expect(forgeSignInBannerSubject(const [unreachable]), isNull);
    });

    test('nothing to say while a forge is usable', () {
      expect(forgeSignInBannerSubject(_signedIn), isNull);
    });
  });

  group('ForgeSignInBanner', () {
    testWidgets('warns in place and links to the sign-in', (tester) async {
      final router = await _pump(tester, connections: _signedOut);

      expect(find.text(l10n.forgeSignInBannerTitle), findsOneWidget);
      expect(find.text(l10n.forgeSignInBannerBody), findsOneWidget);

      await tester.tap(find.text(l10n.forgeSignInBannerAction));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        settingsAccountsRoute('ws-1'),
      );
      // The page it links to holds the sign-in card: no warning pointing at
      // the screen it sits on, however that screen was opened.
      expect(find.text(l10n.forgeSignInBannerTitle), findsNothing);
      router.go(settingsAccountProfileRoute('ws-1'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.forgeSignInBannerTitle), findsNothing);
    });

    testWidgets('says nothing while a forge is signed in', (tester) async {
      await _pump(tester, connections: _signedIn);
      expect(find.text(l10n.forgeSignInBannerTitle), findsNothing);
    });

    testWidgets('says nothing on a demo server', (tester) async {
      await _pump(tester, connections: _signedOut, demo: true);
      expect(find.text(l10n.forgeSignInBannerTitle), findsNothing);
    });

    testWidgets('dismissing hides it for this workspace', (tester) async {
      await _pump(tester, connections: _signedOut);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.forgeSignInBannerTitle), findsNothing);
    });
  });
}
