import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_wrap.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<GoRouter> pump(
    WidgetTester tester, {
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    final router = GoRouter(
      initialLocation: settingsWorkspaceIntegrationsRoute('ws-1'),
      routes: [
        GoRoute(
          path: settingsWorkspaceIntegrationsRoute(':workspaceId'),
          builder: (_, _) => Directionality(
            textDirection: textDirection,
            child: const Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 600,
                child: YourAccountLine(
                  workspaceId: 'ws-1',
                  status: 'GitHub: octocat',
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: settingsAccountProfileRoute(':workspaceId'),
          builder: (_, state) => Text(
            opensAtConnectedAccounts(state.uri)
                ? 'profile at the accounts'
                : 'profile',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(testRouterWrap(router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('names the reader\'s account and leads to their accounts', (
    tester,
  ) async {
    final router = await pump(tester);
    expect(find.textContaining(l10n.yourAccountLabel), findsOneWidget);
    expect(find.textContaining('GitHub: octocat'), findsOneWidget);
    // The link text is the heading it leads to on the profile.
    expect(find.text(l10n.linkedAccountsTitle), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.yourAccountLineSemantics('GitHub: octocat')),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.linkedAccountsTitle));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      settingsAccountsRoute('ws-1'),
    );
    expect(find.text('profile at the accounts'), findsOneWidget);
  });

  testWidgets('right to left puts the link on the reading end', (tester) async {
    await pump(tester, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final link = tester.getCenter(find.text(l10n.linkedAccountsTitle));
    final status = tester.getCenter(find.textContaining('GitHub: octocat'));
    expect(link.dx, lessThan(status.dx));
  });

  group('yourAccountEntry', () {
    test('names the account while it works', () {
      expect(
        yourAccountEntry(
          l10n,
          provider: 'GitHub',
          status: ForgeConnectionStatus.connected,
          account: 'octocat',
        ),
        l10n.yourAccountEntry('GitHub', 'octocat'),
      );
    });

    test('names the state it is stuck in otherwise', () {
      expect(
        yourAccountEntry(
          l10n,
          provider: 'GitLab',
          status: ForgeConnectionStatus.needsSignIn,
          account: 'tanuki',
        ),
        l10n.yourAccountEntry('GitLab', l10n.linkedAccountStatusNeedsSignIn),
      );
    });
  });
}
