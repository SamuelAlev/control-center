import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

const _authorizeUrl = 'https://github.com/login/oauth/authorize?state=s1';

Widget _row(ForgeHost forge, {ForgeConnection? connection}) => ProviderScope(
  overrides: [
    githubSignInScopeProvider.overrideWithValue(null),
    oauthLanesProvider.overrideWith(
      (ref, workspaceId) async => const {
        ConnectOAuthLane.github: SignInLaneInfo(
          lane: ConnectOAuthLane.github,
          mode: SignInLaneMode.own,
        ),
      },
    ),
  ],
  child: testWrap(
    ForgeConnectionRow(forge: forge, connection: connection, loading: false),
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('connected row names the signed-in account', (tester) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          authenticated: true,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.signedInAs('octocat')), findsOneWidget);
    expect(find.text(l10n.disconnect), findsOneWidget);
    expect(find.text(l10n.signInAgain), findsOneWidget);
  });

  testWidgets('a signed-out GitHub row offers sign-in, never a token', (
    tester,
  ) async {
    await tester.pumpWidget(_row(ForgeHost.github));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notConnected), findsOneWidget);
    expect(find.text(l10n.signInToProvider('GitHub')), findsOneWidget);
    expect(find.text(l10n.addToken), findsNothing);
  });

  testWidgets('GitLab keeps its pasted token', (tester) async {
    await tester.pumpWidget(_row(ForgeHost.gitlab));
    await tester.pumpAndSettle();
    expect(find.text(l10n.addToken), findsOneWidget);
    expect(find.textContaining('Sign in to'), findsNothing);
  });

  Future<void> exerciseOwnSignIn(
    WidgetTester tester, {
    bool alreadyConnected = false,
    bool dismissBeforeApproval = false,
  }) async {
    var approved = false;
    var begins = 0;
    final opened = <String>[];
    final statusScopes = <Object?>[];
    final host = FakeRpcHost()
      ..onCall = (op, args) => switch (op) {
        'forge.listConnections' => {
          'connections': [
            {
              'forge': 'github',
              'authenticated': alreadyConnected || approved,
              'username': alreadyConnected || approved ? 'octocat' : '',
              'source': alreadyConnected || approved ? 'oauth' : 'none',
            },
          ],
        },
        'oauth.lanes' => {
          'lanes': [
            {'lane': 'github', 'mode': 'own'},
          ],
        },
        'oauth.begin' => {
          'login_id': 'login-${++begins}',
          'lane': 'github',
          'mode': 'own',
          'url': _authorizeUrl,
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 10))
              .toIso8601String(),
          'status': 'pending',
        },
        'oauth.status' => () {
          statusScopes.add(args['workspace_id']);
          return {
            'login_id': args['login_id'],
            'lane': 'github',
            'mode': 'own',
            'url': _authorizeUrl,
            'status': approved ? 'succeeded' : 'pending',
            'account': approved ? 'octocat' : '',
          };
        }(),
        _ => throw StateError('unexpected op $op'),
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          activeWorkspaceIdOverride(null),
          githubSignInScopeProvider.overrideWithValue(null),
          externalUrlOpenerProvider.overrideWithValue((url) {
            opened.add(url);
            return true;
          }),
        ],
        child: testWrap(const ForgeConnectionsCard()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        alreadyConnected ? l10n.signInAgain : l10n.signInToProvider('GitHub'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(opened, [_authorizeUrl]);
    expect(find.text(l10n.signInWaiting('GitHub')), findsOneWidget);

    // Still pending: the dialog waits and keeps polling.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text(l10n.signInWaiting('GitHub')), findsOneWidget);
    if (dismissBeforeApproval) {
      await tester.tap(find.widgetWithText(CcButton, l10n.close));
      // The press lands once the button's double-tap window passes; then the
      // exit animation runs. Both finish well short of the next poll.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.signInWaiting('GitHub')), findsNothing);
    }

    approved = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInWaiting('GitHub')), findsNothing);
    expect(find.text(l10n.signedInAs('octocat')), findsOneWidget);
    expect(find.text(l10n.signInAgain), findsOneWidget);
    expect(begins, 1);
    // Server-wide sign-in: the scope goes out as an explicit null.
    expect(statusScopes, everyElement(isNull));
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets(
    'an approved own-app sign-in closes and shows the connected account',
    exerciseOwnSignIn,
  );

  testWidgets(
    'approval still refreshes the account after closing the dialog',
    (tester) => exerciseOwnSignIn(tester, dismissBeforeApproval: true),
  );

  testWidgets(
    'sign in again closes after the new attempt is approved',
    (tester) => exerciseOwnSignIn(tester, alreadyConnected: true),
  );
}
