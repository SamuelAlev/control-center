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
  ForgeConnection(forge: ForgeHost.github, authenticated: false),
  ForgeConnection(forge: ForgeHost.gitlab, authenticated: false),
];

const _signedIn = [
  ForgeConnection(forge: ForgeHost.github, authenticated: true, username: 'a'),
  ForgeConnection(forge: ForgeHost.gitlab, authenticated: false),
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
      GoRoute(path: settingsProfileRoute('ws-1'), builder: (_, s) => page(s)),
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

  group('ForgeSignInBanner', () {
    testWidgets('warns in place and links to the sign-in', (tester) async {
      final router = await _pump(tester, connections: _signedOut);

      expect(find.text(l10n.forgeSignInBannerTitle), findsOneWidget);
      expect(find.text(l10n.forgeSignInBannerBody), findsOneWidget);

      await tester.tap(find.text(l10n.forgeSignInBannerAction));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        settingsProfileRoute('ws-1'),
      );
      // The page it links to holds the sign-in card: no warning pointing at
      // the screen it sits on.
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
