import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_bridge_fixtures.dart';

const _code = 'K7Q2-9XPD';

Map<String, dynamic> _pending({String code = _code, bool claimed = true}) => {
  'pending': {
    'provider': 'slack',
    'code': code,
    'expiresAt': DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 15))
        .toIso8601String(),
    if (claimed)
      'claim': {
        'externalTeamId': 'T1',
        'externalUserId': 'U9',
        'label': 'Ada Lovelace',
        'claimedAt': DateTime.now().toUtc().toIso8601String(),
      },
  },
};

ChatTestServer _server() => ChatTestServer(
  (op, args) => switch (op) {
    'chat.providers' => {
      'providers': [slackProviderEntry()],
    },
    'chat.beginUserLink' => {
      'code': _code,
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    },
    'chat.confirmUserLink' => {
      'link': {
        'id': 'l1',
        'provider': 'slack',
        'externalUserId': 'U9',
        'userId': kChatTestUserId,
        'method': 'code',
      },
    },
    'chat.declineUserLink' => {'ok': true},
    _ => null,
  },
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Finder inDialog(Finder matching) =>
      find.descendant(of: find.byType(CcDialog), matching: matching);

  Future<ChatTestServer> openDialog(WidgetTester tester) async {
    final server = _server();
    await pumpChat(
      tester,
      server,
      const ChatBridgesSection(surface: ChatBridgeSurface.myAccountLink),
    );
    await tester.tap(
      find.widgetWithText(CcButton, l10n.chatLinkMyAccount('Slack')),
    );
    await settle(tester);
    return server;
  }

  testWidgets('the dialog shows the code and says to DM it to the bot', (
    tester,
  ) async {
    final server = await openDialog(tester);
    expect(server.argsOf('chat.beginUserLink'), hasLength(1));
    expect(inDialog(find.text(_code)), findsOneWidget);
    expect(
      inDialog(find.text(l10n.chatLinkCodeInstruction('Slack'))),
      findsOneWidget,
    );
    expect(inDialog(find.text(l10n.chatLinkWaiting)), findsOneWidget);

    // A claim on an older code is not this dialog's to answer.
    server.host.emit('chat.watchPendingUserLink', _pending(code: 'OLD-CODE'));
    await settle(tester);
    expect(inDialog(find.text(l10n.chatLinkClaimTitle('Slack'))), findsNothing);
    expect(inDialog(find.text(_code)), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('confirming the claimed profile links exactly that profile', (
    tester,
  ) async {
    final server = await openDialog(tester);
    server.host.emit('chat.watchPendingUserLink', _pending());
    await settle(tester);

    expect(
      inDialog(find.text(l10n.chatLinkClaimTitle('Slack'))),
      findsOneWidget,
    );
    expect(inDialog(find.text('Ada Lovelace')), findsOneWidget);
    expect(inDialog(find.text('U9')), findsOneWidget);

    await tester.tap(inDialog(find.widgetWithText(CcButton, l10n.confirm)));
    await settle(tester);

    final confirms = server.argsOf('chat.confirmUserLink');
    expect(confirms, hasLength(1));
    expect(confirms.single['provider'], 'slack');
    expect(confirms.single['external_user_id'], 'U9');
    expect(confirms.single['workspace_id'], 'ws-test');
    expect(server.argsOf('chat.declineUserLink'), isEmpty);
    expect(
      inDialog(find.text(l10n.chatLinkCodeLinked('Slack'))),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('declining links nothing and offers a fresh code', (
    tester,
  ) async {
    final server = await openDialog(tester);
    server.host.emit('chat.watchPendingUserLink', _pending());
    await settle(tester);

    await tester.tap(
      inDialog(find.widgetWithText(CcButton, l10n.chatLinkDecline)),
    );
    await settle(tester);

    final declines = server.argsOf('chat.declineUserLink');
    expect(declines, hasLength(1));
    expect(declines.single['provider'], 'slack');
    expect(server.argsOf('chat.confirmUserLink'), isEmpty);
    expect(inDialog(find.text(l10n.chatLinkDeclined('Slack'))), findsOneWidget);

    // The server revoked the code with the decline.
    server.host.emit('chat.watchPendingUserLink', {'pending': null});
    await tester.tap(
      inDialog(find.widgetWithText(CcButton, l10n.chatLinkNewCode)),
    );
    await settle(tester);
    expect(server.argsOf('chat.beginUserLink'), hasLength(2));
    expect(inDialog(find.text(_code)), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'a claim made after the dialog closed is answered from settings, in RTL',
    (tester) async {
      final server = _server();
      await pumpChat(
        tester,
        server,
        const ChatBridgesSection(surface: ChatBridgeSurface.myAccountLink),
        textDirection: TextDirection.rtl,
      );
      expect(find.text(l10n.chatLinkClaimTitle('Slack')), findsNothing);

      server.host.emit('chat.watchPendingUserLink', _pending());
      await settle(tester);
      expect(find.text(l10n.chatLinkClaimTitle('Slack')), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(CcButton, l10n.confirm));
      await settle(tester);
      final confirms = server.argsOf('chat.confirmUserLink');
      expect(confirms, hasLength(1));
      expect(confirms.single['external_user_id'], 'U9');

      // The server drops the pending code once linked.
      server.host.emit('chat.watchPendingUserLink', {'pending': null});
      await settle(tester);
      expect(find.text(l10n.chatLinkClaimTitle('Slack')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
