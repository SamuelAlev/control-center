import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/settings_contribution.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester,
    Future<List<ForgeConnection>> Function() connections, {
    bool demo = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          forgeConnectionsProvider.overrideWith((ref) => connections()),
        ],
        child: testWrap(
          const ContributedSection('forge.account-status'),
          isDemo: demo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing connected, says so', (tester) async {
    await pump(
      tester,
      () async => [
        for (final forge in ForgeHost.supported)
          ForgeConnection.disconnected(forge),
      ],
    );
    expect(find.textContaining(l10n.yourForgeAccountNone), findsOneWidget);
    expect(
      tester.widget<YourAccountLine>(find.byType(YourAccountLine)).attention,
      isTrue,
    );
  });

  testWidgets('names each held account, working or not', (tester) async {
    await pump(
      tester,
      () async => const [
        ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.connected,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
        ForgeConnection(
          forge: ForgeHost.gitlab,
          status: ForgeConnectionStatus.needsSignIn,
          username: 'tanuki',
          source: ForgeCredentialSource.settings,
        ),
        ForgeConnection(
          forge: ForgeHost.bitbucket,
          status: ForgeConnectionStatus.notConnected,
        ),
      ],
    );
    final expected = [
      l10n.yourAccountEntry('GitHub', 'octocat'),
      l10n.yourAccountEntry('GitLab', l10n.linkedAccountStatusNeedsSignIn),
    ].join(' · ');
    final line = tester.widget<YourAccountLine>(find.byType(YourAccountLine));
    expect(line.status, expected);
    expect(line.attention, isTrue);
    expect(find.textContaining('Bitbucket'), findsNothing);
  });

  testWidgets('a working account needs no attention', (tester) async {
    await pump(
      tester,
      () async => const [
        ForgeConnection(
          forge: ForgeHost.github,
          status: ForgeConnectionStatus.connected,
          username: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      ],
    );
    expect(
      tester.widget<YourAccountLine>(find.byType(YourAccountLine)).attention,
      isFalse,
    );
  });

  testWidgets('says nothing on a demo server', (tester) async {
    await pump(tester, () async => const [], demo: true);
    expect(find.byType(YourAccountLine), findsNothing);
  });
}
