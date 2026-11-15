import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connection_row.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

const _authorizeUrl = 'https://github.com/login/oauth/authorize?state=s1';

Widget _row(
  ForgeHost forge, {
  ForgeConnection? connection,
  String? workspaceId,
  TextDirection? textDirection,
  RemoteRpcClient? rpc,
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdOverride(workspaceId),
    if (rpc != null) rpcClientProvider.overrideWithValue(rpc),
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
    textDirection: textDirection,
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  testWidgets('connected row names the signed-in account', (tester) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.connected,
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

  testWidgets('a lapsed grant says so and offers sign in again', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.needsSignIn,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.connectionNeedsSignInAs('GitHub', 'octocat')),
      findsOneWidget,
    );
    expect(find.text(l10n.signInAgain), findsOneWidget);
    expect(find.text(l10n.disconnect), findsOneWidget);
  });

  testWidgets('a paused grant explains itself and offers no sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.paused,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectionPaused), findsOneWidget);
    expect(find.text(l10n.signInAgain), findsNothing);
    expect(find.text(l10n.signInToProvider('GitHub')), findsNothing);
  });

  testWidgets('an unreachable provider reads as retrying, not signed out', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.gitlab,
        connection: const ForgeConnection(
          forge: ForgeHost.gitlab,
          status: ForgeConnectionStatus.unreachable,
          username: 'tanuki',
          source: ForgeCredentialSource.settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectionUnreachable('GitLab')), findsOneWidget);
    expect(find.text(l10n.updateToken), findsNothing);
    expect(find.text(l10n.notConnected), findsNothing);
  });

  testWidgets('a pasted token is the person\'s own in every workspace', (
    tester,
  ) async {
    final cleared = <Map<String, dynamic>>[];
    final host = FakeRpcHost()
      ..onCall = (op, args) => switch (op) {
        'credentials.clearForgeToken' => () {
          cleared.add(args);
          return <String, dynamic>{'ok': true};
        }(),
        _ => <String, dynamic>{},
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      _row(
        ForgeHost.gitlab,
        workspaceId: kTestWorkspaceId,
        rpc: rpc,
        connection: const ForgeConnection(
          forge: ForgeHost.gitlab,
          status: ForgeConnectionStatus.connected,
          username: 'tanuki',
          source: ForgeCredentialSource.settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Where it applies is the card's line, not the row's.
    expect(find.text(l10n.signedInAs('tanuki')), findsOneWidget);
    await tester.tap(find.text(l10n.disconnect));
    await tester.pumpAndSettle();
    expect(find.text(l10n.disconnectScopeGlobalBody('GitLab')), findsOneWidget);
    await tester.tap(find.text(l10n.disconnect).last);
    await tester.pumpAndSettle();
    expect(cleared, [
      {'forge': 'gitlab'},
    ]);
  });

  testWidgets('a GitHub sign-in kept for this workspace says so on '
      'disconnect', (tester) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        workspaceId: kTestWorkspaceId,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.connected,
          scope: ForgeCredentialScope.workspace,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.signedInAs('octocat')), findsOneWidget);
    await tester.tap(find.text(l10n.disconnect));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.disconnectScopeWorkspaceBody('GitHub')),
      findsOneWidget,
    );
  });

  group('the card says where its accounts apply', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required ForgeCredentialScope githubScope,
      TextDirection? textDirection,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            activeWorkspaceProvider.overrideWithValue(
              Workspace(
                id: kTestWorkspaceId,
                name: 'Acme',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
            forgeConnectionsProvider.overrideWith(
              (ref) async => [
                ForgeConnection(
                  forge: ForgeHost.github,
                  status: ForgeConnectionStatus.notConnected,
                  scope: githubScope,
                ),
              ],
            ),
            oauthLanesProvider.overrideWith(
              (ref, workspaceId) async => const {
                ConnectOAuthLane.github: SignInLaneInfo(
                  lane: ConnectOAuthLane.github,
                  mode: SignInLaneMode.own,
                ),
              },
            ),
          ],
          // Not `testWrap`: its own scope pins the active workspace to none,
          // and the line names the workspace.
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Directionality(
              textDirection: textDirection ?? TextDirection.ltr,
              child: CcTheme(
                data: CcThemeData.light(),
                child: const Scaffold(body: ForgeConnectionsCard()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('every workspace on this server', (tester) async {
      await pumpCard(tester, githubScope: ForgeCredentialScope.global);
      expect(find.text(l10n.accountReachServer), findsOneWidget);
      expect(find.text(l10n.forgeReachGitHubOwnApp('Acme')), findsNothing);
    });

    testWidgets('GitHub only here when the workspace has its own app', (
      tester,
    ) async {
      await pumpCard(tester, githubScope: ForgeCredentialScope.workspace);
      expect(find.text(l10n.forgeReachGitHubOwnApp('Acme')), findsOneWidget);
      expect(find.text(l10n.accountReachServer), findsNothing);
    });

    testWidgets('renders right to left', (tester) async {
      await pumpCard(
        tester,
        githubScope: ForgeCredentialScope.workspace,
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.forgeReachGitHubOwnApp('Acme')), findsOneWidget);
    });
  });

  testWidgets('renders right to left', (tester) async {
    await tester.pumpWidget(
      _row(
        ForgeHost.github,
        textDirection: TextDirection.rtl,
        connection: const ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.needsSignIn,
          source: ForgeCredentialSource.oauth,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.signInAgain), findsOneWidget);
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
              'status': alreadyConnected || approved
                  ? 'connected'
                  : 'not_connected',
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
    expect(find.text(l10n.signInCodePrompt), findsOneWidget);

    // Still pending: the dialog waits and keeps polling.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text(l10n.signInCodePrompt), findsOneWidget);
    if (dismissBeforeApproval) {
      await tester.tap(find.widgetWithText(CcButton, l10n.close));
      // The press lands once the button's double-tap window passes; then the
      // exit animation runs. Both finish well short of the next poll.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.signInCodePrompt), findsNothing);
    }

    approved = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInCodePrompt), findsNothing);
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
