import 'package:cc_data/cc_data.dart' show ChatProviderView, ChatUserLinkView;
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';
import '../../../helpers/settings_contribution.dart';
import '../../../helpers/test_wrap.dart';
import 'chat_bridge_fixtures.dart';

ChatUserLinkView _link(String userId, String externalUserId) =>
    ChatUserLinkView.fromWire({
      'id': 'l-$userId',
      'provider': 'slack',
      'externalUserId': externalUserId,
      'userId': userId,
    });

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester, {
    String? state = 'connected',
    List<ChatUserLinkView> links = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          currentUserIdProvider.overrideWithValue(kChatTestUserId),
          chatProvidersProvider.overrideWith(
            (ref) async => [
              ChatProviderView.fromWire(slackProviderEntry(state: state)),
            ],
          ),
          chatUserLinksProvider.overrideWith((ref) => Stream.value(links)),
        ],
        child: testWrap(
          const ContributedSection('chat_bridges.account-status'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  YourAccountLine line(WidgetTester tester) =>
      tester.widget<YourAccountLine>(find.byType(YourAccountLine));

  testWidgets('names the account the reader linked', (tester) async {
    await pump(
      tester,
      links: [_link('someone-else', 'U999'), _link(kChatTestUserId, 'U123')],
    );
    expect(line(tester).status, l10n.yourAccountEntry('Slack', 'U123'));
    expect(line(tester).attention, isFalse);
  });

  testWidgets('says when the reader has not linked one', (tester) async {
    await pump(tester, links: [_link('someone-else', 'U999')]);
    expect(line(tester).status, l10n.yourChatAccountNotLinked('Slack'));
    expect(line(tester).attention, isTrue);
  });

  testWidgets('is absent while the workspace has no chat app connected', (
    tester,
  ) async {
    await pump(tester, state: null);
    expect(find.byType(YourAccountLine), findsNothing);
  });
}
