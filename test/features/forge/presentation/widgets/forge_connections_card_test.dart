import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('connected row names the signed-in account', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const ForgeConnectionRow(
          forge: ForgeHost.github,
          connection: ForgeConnection(
            forge: ForgeHost.github,
            authenticated: true,
            username: 'octocat',
            source: ForgeCredentialSource.oauth,
          ),
          loading: false,
          canSignIn: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.signedInAs('octocat')), findsOneWidget);
    expect(find.text(l10n.disconnect), findsOneWidget);
  });

  testWidgets('disconnected row offers a token path', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const ForgeConnectionRow(
          forge: ForgeHost.github,
          connection: null,
          loading: false,
          canSignIn: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.notConnected), findsOneWidget);
    expect(find.text(l10n.addToken), findsOneWidget);
  });

  Future<void> exerciseDeviceLogin(
    WidgetTester tester, {
    bool alreadyConnected = false,
    bool dismissBeforeApproval = false,
  }) async {
    var approved = false;
    var loginAttempts = 0;
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
        'oauth.begin' => {
          'mode': 'device',
          'login_id': 'attempt-${++loginAttempts}',
          'user_code': 'ABCD-1234',
          'verification_uri': '',
          'expires_in': 900,
        },
        'oauth.status' => {'status': approved ? 'succeeded' : 'pending'},
        _ => throw StateError('unexpected op $op'),
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          activeWorkspaceIdOverride(),
          signInProvidersProvider.overrideWith(
            (ref) async => const {
              'github': SignInProvider(id: 'github', flow: SignInFlow.device),
            },
          ),
        ],
        child: testWrap(const ForgeConnectionsCard()),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(
      find.text(
        alreadyConnected ? l10n.signInAgain : l10n.signInWithProvider('GitHub'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ABCD-1234'), findsOneWidget);

    // The older credential must not complete the new attempt.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('ABCD-1234'), findsOneWidget);
    if (dismissBeforeApproval) {
      await tester.tap(find.text(l10n.close));
      await tester.pump(const Duration(milliseconds: 300));
    }

    approved = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('ABCD-1234'), findsNothing);
    expect(find.text(l10n.signedInAs('octocat')), findsOneWidget);
    expect(find.text(l10n.signInAgain), findsOneWidget);
    expect(loginAttempts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets(
    'first device approval closes and shows the connected account',
    exerciseDeviceLogin,
  );

  testWidgets(
    'approval still refreshes the account after closing the dialog',
    (tester) => exerciseDeviceLogin(tester, dismissBeforeApproval: true),
  );

  testWidgets(
    'sign in again closes after the new attempt is approved',
    (tester) => exerciseDeviceLogin(tester, alreadyConnected: true),
  );
}
