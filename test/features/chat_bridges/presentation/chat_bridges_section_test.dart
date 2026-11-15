import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInUnavailableReason;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_bridge_fixtures.dart';

const _authorizeUrl = 'https://connect.example/v1/oauth/slack/start?state=s1';

ChatTestServer _server(Map<String, dynamic> entry) => ChatTestServer(
  (op, args) => switch (op) {
    'chat.providers' => {
      'providers': [entry],
    },
    'oauth.begin' => {
      'login_id': 'login-1',
      'lane': args['lane'],
      'mode': 'connect',
      'url': _authorizeUrl,
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
      'status': 'pending',
    },
    'oauth.status' => {
      'login_id': args['login_id'],
      'lane': 'slack',
      'mode': 'connect',
      'url': _authorizeUrl,
      'status': 'pending',
    },
    _ => null,
  },
);

const _slackLane = {
  ConnectOAuthLane.slack: SignInLaneInfo(
    lane: ConnectOAuthLane.slack,
    mode: SignInLaneMode.connect,
  ),
};

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  testWidgets('a shared-app connection offers no tokens or bot settings', (
    tester,
  ) async {
    await pumpChat(
      tester,
      _server(slackProviderEntry(mode: 'connect')),
      const ChatBridgesSection(),
      lanes: _slackLane,
    );
    expect(find.text(l10n.chatConnectedTo('Control Center', 'Acme')), findsOne);
    expect(find.text(l10n.chatSharedAppConnected), findsOneWidget);
    expect(find.text(l10n.chatCustomizeBot), findsNothing);
    expect(find.text(l10n.chatConnectProvider('Slack')), findsNothing);
    expect(find.text(l10n.chatCreateAppCta), findsNothing);
    expect(find.text(l10n.chatAddToProvider('Slack')), findsNothing);
    // Disconnecting stays: it is how a workspace switches to its own app.
    expect(find.text(l10n.chatDisconnectProvider), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a workspace-owned app keeps its bot settings', (tester) async {
    await pumpChat(
      tester,
      _server(slackProviderEntry()),
      const ChatBridgesSection(),
      lanes: _slackLane,
    );
    expect(find.text(l10n.chatSharedAppConnected), findsNothing);
    expect(find.text(l10n.chatCustomizeBot), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Add Control Center to Slack starts the slack lane here', (
    tester,
  ) async {
    final opened = <String>[];
    final server = _server(slackProviderEntry(state: null));
    await pumpChat(
      tester,
      server,
      const ChatBridgesSection(),
      lanes: _slackLane,
      openUrl: (url) {
        opened.add(url);
        return true;
      },
    );
    expect(find.text(l10n.signInAddControlCenter('Slack')), findsOneWidget);
    expect(find.text(l10n.chatSharedAppHint('Slack')), findsOneWidget);
    // The workspace's own app stays on offer beside the shared one.
    expect(find.text(l10n.chatConnectProvider('Slack')), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CcButton, l10n.chatAddToProvider('Slack')),
    );
    await settle(tester);

    final begins = server.argsOf('oauth.begin');
    expect(begins, hasLength(1));
    expect(begins.single['lane'], 'slack');
    expect(begins.single['workspace_id'], 'ws-test');
    expect(opened, [_authorizeUrl]);
    expect(find.byType(CcDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unavailable shared app says why and cannot start', (
    tester,
  ) async {
    final server = _server(slackProviderEntry(state: null));
    await pumpChat(
      tester,
      server,
      const ChatBridgesSection(),
      lanes: const {
        ConnectOAuthLane.slack: SignInLaneInfo(
          lane: ConnectOAuthLane.slack,
          mode: SignInLaneMode.unavailable,
          unavailableReason: SignInUnavailableReason.laneNotOffered,
        ),
      },
    );
    expect(
      find.text(l10n.signInUnavailableLaneNotOffered('Slack')),
      findsOneWidget,
    );
    final add = tester.widget<CcButton>(
      find.widgetWithText(CcButton, l10n.chatAddToProvider('Slack')),
    );
    expect(add.onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('only an admin can install the shared app', (tester) async {
    await pumpChat(
      tester,
      _server(slackProviderEntry(state: null)),
      const ChatBridgesSection(),
      role: WorkspaceRole.member,
      lanes: _slackLane,
    );
    final add = tester.widget<CcButton>(
      find.widgetWithText(CcButton, l10n.chatAddToProvider('Slack')),
    );
    expect(add.onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
