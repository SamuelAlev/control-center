import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
