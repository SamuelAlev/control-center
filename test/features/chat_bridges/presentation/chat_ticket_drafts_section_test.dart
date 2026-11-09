import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_ticket_drafts_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_bridge_fixtures.dart';

Map<String, dynamic> _draft(String id, String title, {String? description}) => {
  'id': id,
  'workspaceId': 'ws-test',
  'provider': 'slack',
  'reporterUserId': kChatTestUserId,
  'title': title,
  'description': ?description,
  'externalUserId': 'U9',
  'externalChannelId': 'C1',
  'createdAt': DateTime.now()
      .toUtc()
      .subtract(const Duration(minutes: 5))
      .toIso8601String(),
  'expiresAt': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 23))
      .toIso8601String(),
};

final _drafts = {
  'drafts': [
    _draft('d1', 'Login redirect loops', description: 'Seen on Safari'),
    _draft('d2', 'Flaky upload test'),
  ],
};

/// The text field currently holding [text].
Finder _field(String text) => find.byWidgetPredicate(
  (w) => w is EditableText && w.controller.text == text,
);

ChatTestServer _server() => ChatTestServer(
  (op, args) => switch (op) {
    'chat.confirmTicketDraft' => {
      'ticket': {'id': 't1', 'key': 'CC-12', 'title': args['title']},
    },
    'chat.discardTicketDraft' => {'ok': true},
    _ => null,
  },
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Finder createButtons() =>
      find.widgetWithText(CcButton, l10n.chatTicketDraftCreate);

  testWidgets('renders nothing until a draft arrives', (tester) async {
    final server = _server();
    await pumpChat(tester, server, const ChatTicketDraftsSection());
    expect(find.text(l10n.chatTicketDraftsDescription), findsNothing);

    server.host.emit('chat.watchTicketDrafts', _drafts);
    await settle(tester);
    expect(find.text(l10n.chatTicketDraftsDescription), findsOneWidget);
    expect(find.text('Login redirect loops'), findsOneWidget);
    expect(find.text('Seen on Safari'), findsOneWidget);
    expect(createButtons(), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('create sends the corrected title and description', (
    tester,
  ) async {
    final server = _server();
    await pumpChat(tester, server, const ChatTicketDraftsSection());
    server.host.emit('chat.watchTicketDrafts', _drafts);
    await settle(tester);

    await tester.enterText(
      _field('Login redirect loops'),
      'Login redirect loops on Safari 18',
    );
    await tester.enterText(
      _field('Seen on Safari'),
      'Repro: sign out, then sign in again.',
    );
    await tester.pump();
    await tester.tap(createButtons().first);
    await settle(tester);

    final confirms = server.argsOf('chat.confirmTicketDraft');
    expect(confirms, hasLength(1));
    expect(confirms.single['workspace_id'], 'ws-test');
    expect(confirms.single['draft_id'], 'd1');
    expect(confirms.single['title'], 'Login redirect loops on Safari 18');
    expect(
      confirms.single['description'],
      'Repro: sign out, then sign in again.',
    );
    expect(server.argsOf('chat.discardTicketDraft'), isEmpty);
    expect(find.text(l10n.chatTicketDraftCreated('CC-12')), findsOneWidget);

    // The server drops the confirmed draft; the row goes with it.
    server.host.emit('chat.watchTicketDrafts', {
      'drafts': [_draft('d2', 'Flaky upload test')],
    });
    await settle(tester);
    expect(find.text('Login redirect loops on Safari 18'), findsNothing);
    expect(createButtons(), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('discard drops the draft without creating it', (tester) async {
    final server = _server();
    await pumpChat(tester, server, const ChatTicketDraftsSection());
    server.host.emit('chat.watchTicketDrafts', _drafts);
    await settle(tester);

    await tester.tap(find.widgetWithText(CcButton, l10n.discard).last);
    await settle(tester);

    final discards = server.argsOf('chat.discardTicketDraft');
    expect(discards, hasLength(1));
    expect(discards.single['draft_id'], 'd2');
    expect(server.argsOf('chat.confirmTicketDraft'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an empty title cannot become a ticket', (tester) async {
    final server = _server();
    await pumpChat(tester, server, const ChatTicketDraftsSection());
    server.host.emit('chat.watchTicketDrafts', _drafts);
    await settle(tester);

    await tester.enterText(_field('Flaky upload test'), '   ');
    await tester.pump();
    expect(tester.widget<CcButton>(createButtons().last).onPressed, isNull);
    expect(tester.widget<CcButton>(createButtons().first).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a viewer, who cannot create tickets, sees none', (tester) async {
    final server = _server();
    await pumpChat(
      tester,
      server,
      const ChatTicketDraftsSection(),
      role: WorkspaceRole.viewer,
    );
    server.host.emit('chat.watchTicketDrafts', _drafts);
    await settle(tester);
    expect(find.text(l10n.chatTicketDraftsDescription), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
