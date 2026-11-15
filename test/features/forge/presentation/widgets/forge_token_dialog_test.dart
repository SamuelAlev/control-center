import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_token_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<List<Map<String, dynamic>>> pump(
    WidgetTester tester,
    ForgeHost forge, {
    TextDirection? textDirection,
  }) async {
    final saved = <Map<String, dynamic>>[];
    final host = FakeRpcHost()
      ..onCall = (op, args) => switch (op) {
        'credentials.setForgeToken' => () {
          saved.add(args);
          return {
            'forge': forge.wire,
            'authenticated': true,
            'source': 'settings',
          };
        }(),
        'forge.listConnections' => {'connections': <Object>[]},
        _ => <String, dynamic>{},
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          activeWorkspaceIdOverride(),
        ],
        child: testWrap(
          ForgeTokenDialog(forge: forge),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  }

  group('isPlausibleAccountEmail', () {
    test('takes an ordinary address', () {
      expect(isPlausibleAccountEmail('ana@example.com'), isTrue);
    });

    test('refuses what would break the email:token pair', () {
      expect(isPlausibleAccountEmail(''), isFalse);
      expect(isPlausibleAccountEmail('ana'), isFalse);
      expect(isPlausibleAccountEmail('ana:x@example.com'), isFalse);
      expect(isPlausibleAccountEmail('ana @example.com'), isFalse);
    });
  });

  testWidgets('GitLab asks for the token alone', (tester) async {
    final saved = await pump(tester, ForgeHost.gitlab);
    expect(find.text(l10n.forgeTokenEmailLabel), findsNothing);
    await tester.enterText(find.byType(EditableText).first, 'glpat-1');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    // The person's own token in every workspace: nothing else is sent, not
    // even the workspace it was pasted from.
    expect(saved.single, {'forge': 'gitlab', 'token': 'glpat-1'});
  });

  testWidgets('Bitbucket sends the account email with its API token', (
    tester,
  ) async {
    final saved = await pump(tester, ForgeHost.bitbucket);
    expect(find.text(l10n.forgeTokenEmailLabel), findsOneWidget);
    expect(find.text(l10n.forgeTokenApiTokenLabel), findsOneWidget);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), ' ana@example.com ');
    await tester.enterText(fields.at(1), 'ATATT-1');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(saved.single['token'], 'ana@example.com:ATATT-1');
  });

  testWidgets('a malformed email is refused before anything is sent', (
    tester,
  ) async {
    final saved = await pump(tester, ForgeHost.bitbucket);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'ana');
    await tester.enterText(fields.at(1), 'ATATT-1');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(find.text(l10n.forgeTokenEmailInvalid), findsOneWidget);
  });

  testWidgets('renders right to left', (tester) async {
    await pump(tester, ForgeHost.bitbucket, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.forgeTokenEmailLabel), findsOneWidget);
  });
}
