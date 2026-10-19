import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_sign_in_account_list.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

ClaudeAccountView _view(
  String id, {
  bool loggedIn = true,
  DateTime? authFailedAt,
  DateTime? credentialExpiresAt,
}) => ClaudeAccountView(
  account: ClaudeAccount(
    id: id,
    label: '$id-label',
    email: '$id@example.test',
    loggedIn: loggedIn,
    authFailedAt: authFailedAt,
    credentialExpiresAt: credentialExpiresAt,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  List<ClaudeAccountView> roster, {
  List<String> accountIds = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        claudeAccountsProvider.overrideWith((ref) async => roster),
        claudeLoginCommandProvider.overrideWith(
          (ref, id) async => (
            argv: const ['claude', 'auth', 'login'],
            environment: {'CLAUDE_CONFIG_DIR': '/data/claude accounts/$id'},
          ),
        ),
      ],
      child: testWrap(ClaudeSignInAccountList(accountIds: accountIds)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('lists only the accounts that need a sign-in, with commands', (
    tester,
  ) async {
    await _pump(tester, [
      _view('fine'),
      _view('out', loggedIn: false),
      // A revoked token still looks signed in and unexpired; the failed run
      // is the only signal.
      _view('revoked', authFailedAt: DateTime.utc(2026, 10, 19)),
    ]);

    expect(find.text('fine-label'), findsNothing);
    expect(find.text('out-label'), findsOneWidget);
    expect(find.text('revoked-label'), findsOneWidget);
    expect(find.text(l10n.claudeAccountSignedOut), findsOneWidget);
    expect(find.text(l10n.claudeAccountSignInFailed), findsOneWidget);
    // The path is quoted so it survives the paste.
    expect(
      find.text(
        "CLAUDE_CONFIG_DIR='/data/claude accounts/out' claude auth login",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "CLAUDE_CONFIG_DIR='/data/claude accounts/revoked' claude auth login",
      ),
      findsOneWidget,
    );
  });

  testWidgets('a parked run lists exactly the accounts it tried', (
    tester,
  ) async {
    await _pump(
      tester,
      [_view('work'), _view('personal', loggedIn: false)],
      accountIds: const ['work'],
    );

    expect(find.text('work-label'), findsOneWidget);
    expect(find.text('personal-label'), findsNothing);
  });

  testWidgets('with nothing flagged it offers the CLI\'s own login', (
    tester,
  ) async {
    await _pump(tester, [_view('fine')]);

    expect(find.text(l10n.claudeSignInNoAccounts), findsOneWidget);
    expect(find.text('claude auth login'), findsOneWidget);
  });
}
