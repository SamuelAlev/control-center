import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_login_command_block.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_sign_in_account_list.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/claude_sign_in_watch.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/fake_claude_accounts_repository.dart';
import '../../../../../helpers/test_wrap.dart';

ClaudeAccount _account(
  String id, {
  bool loggedIn = true,
  DateTime? authFailedAt,
  DateTime? credentialExpiresAt,
}) => ClaudeAccount(
  id: id,
  label: '$id-label',
  email: '$id@example.test',
  loggedIn: loggedIn,
  authFailedAt: authFailedAt,
  credentialExpiresAt: credentialExpiresAt,
);

void main() {
  late AppLocalizations l10n;
  late FakeClaudeAccountsRepository repo;

  /// How often [ClaudeSignInAccountList.onAllSignedIn] was called.
  late int allSignedIn;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Pumps the list over [accounts]. With [closesItself] it is given the
  /// callback a self-closing surface passes.
  Future<void> pumpList(
    WidgetTester tester,
    List<ClaudeAccount> accounts, {
    List<String> accountIds = const [],
    bool handsOutCommands = true,
    bool closesItself = false,
    bool showIdentity = true,
    TextDirection? textDirection,
  }) async {
    repo = FakeClaudeAccountsRepository(
      accounts: accounts,
      handsOutCommands: handsOutCommands,
    );
    allSignedIn = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [claudeAccountsRepositoryProvider.overrideWithValue(repo)],
        child: testWrap(
          ClaudeSignInAccountList(
            accountIds: accountIds,
            showIdentity: showIdentity,
            onAllSignedIn: closesItself ? () => allSignedIn++ : null,
          ),
          textDirection: textDirection,
        ),
      ),
    );
    // The roster, then each command, then the watch's first reading.
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  /// Lets one reading of the watch happen and its consequences land.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump(claudeSignInPollInterval);
    await tester.pump();
    await tester.pump();
  }

  Finder badge(String label) => find.widgetWithText(CcBadge, label);

  testWidgets('lists only the accounts that need a sign-in, with commands', (
    tester,
  ) async {
    await pumpList(tester, [
      _account('fine'),
      _account('out', loggedIn: false),
      // A revoked token still looks signed in and unexpired; the failed run
      // is the only signal.
      _account('revoked', authFailedAt: DateTime.utc(2026, 10, 19)),
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
    await pumpList(
      tester,
      [_account('work'), _account('personal', loggedIn: false)],
      accountIds: const ['work'],
    );

    expect(find.text('work-label'), findsOneWidget);
    expect(find.text('personal-label'), findsNothing);
  });

  testWidgets('with nothing flagged it offers the CLI\'s own login', (
    tester,
  ) async {
    await pumpList(tester, [_account('fine')], closesItself: true);

    expect(find.text(l10n.claudeSignInNoAccounts), findsOneWidget);
    expect(find.text('claude auth login'), findsOneWidget);
    // Nothing of the host's to wait for: the CLI's own login is not watched.
    await tick(tester);
    expect(repo.stateReads, 0);
    expect(find.text(l10n.claudeSignInClosesItself), findsNothing);
  });

  group('once a sign-in finishes', () {
    testWidgets('the account reads as signed in and stays listed', (
      tester,
    ) async {
      await pumpList(tester, [_account('out', loggedIn: false)]);
      expect(badge(l10n.claudeAccountSignedOut), findsOneWidget);

      repo.signIn('out');
      await tick(tester);

      // The roster no longer says it needs a sign-in. It is still here.
      expect(find.text('out-label'), findsOneWidget);
      expect(badge(l10n.claudeAccountSignedOut), findsNothing);
      expect(
        tester.widget<CcBadge>(badge(l10n.claudeAccountSignedIn)).variant,
        CcBadgeVariant.success,
      );
      expect(repo.rosterReads, 2, reason: 'the watch re-read the roster');
    });

    testWidgets('an expired sign-in stops reading as expired', (tester) async {
      await pumpList(tester, [
        _account('lapsed', credentialExpiresAt: DateTime.utc(2000)),
      ]);
      expect(badge(l10n.claudeAccountExpired), findsOneWidget);

      repo.signIn('lapsed');
      await tick(tester);

      expect(badge(l10n.claudeAccountExpired), findsNothing);
      expect(badge(l10n.claudeAccountSignedIn), findsOneWidget);
    });

    testWidgets('tells its surface once, when every account is signed in', (
      tester,
    ) async {
      await pumpList(tester, [
        _account('one', loggedIn: false),
        _account('two', loggedIn: false),
      ], closesItself: true);

      repo.signIn('one');
      await tick(tester);
      expect(allSignedIn, 0);
      expect(badge(l10n.claudeAccountSignedIn), findsOneWidget);
      expect(badge(l10n.claudeAccountSignedOut), findsOneWidget);

      repo.signIn('two');
      await tick(tester);
      expect(allSignedIn, 1);
      expect(badge(l10n.claudeAccountSignedIn), findsNWidgets(2));

      await tick(tester);
      await tick(tester);
      expect(allSignedIn, 1);
    });

    testWidgets('a named account is watched the same way', (tester) async {
      // Signed in already, as when its row offers "Sign in again": only a new
      // credential counts.
      await pumpList(
        tester,
        [_account('work')],
        accountIds: const ['work'],
        closesItself: true,
      );
      await tick(tester);
      await tick(tester);
      expect(allSignedIn, 0);

      repo.signIn('work', expiresAt: DateTime.utc(2101));
      await tick(tester);
      expect(allSignedIn, 1);
    });
  });

  group('the line under the commands', () {
    testWidgets('says the surface closes itself, and then that it did', (
      tester,
    ) async {
      await pumpList(tester, [
        _account('out', loggedIn: false),
      ], closesItself: true);

      expect(find.text(l10n.claudeSignInClosesItself), findsOneWidget);
      expect(find.byType(CcSpinner), findsOneWidget);

      repo.signIn('out');
      await tick(tester);

      expect(find.text(l10n.claudeSignInClosesItself), findsNothing);
      expect(find.text(l10n.signedIn), findsOneWidget);
      expect(find.byType(CcSpinner), findsNothing);
    });

    testWidgets('names every account when several are listed', (tester) async {
      await pumpList(tester, [
        _account('one', loggedIn: false),
        _account('two', loggedIn: false),
      ], closesItself: true);

      expect(find.text(l10n.claudeSignInClosesItselfAll), findsOneWidget);
      expect(find.text(l10n.claudeSignInClosesItself), findsNothing);
    });

    testWidgets('is left out where the surface does not close itself', (
      tester,
    ) async {
      await pumpList(tester, [_account('out', loggedIn: false)]);

      expect(find.text(l10n.claudeSignInClosesItself), findsNothing);
      // The account is watched all the same.
      expect(repo.stateReads, 1);
    });
  });

  testWidgets('where no command is handed out, nothing is watched', (
    tester,
  ) async {
    await pumpList(
      tester,
      [_account('out', loggedIn: false)],
      handsOutCommands: false,
      closesItself: true,
    );

    expect(find.text(l10n.claudeSignInCommandUnavailable), findsOneWidget);
    expect(find.byType(ClaudeLoginCommandBlock), findsNothing);
    expect(find.text(l10n.claudeSignInClosesItself), findsNothing);

    await tick(tester);
    await tick(tester);
    expect(repo.stateReads, 0, reason: 'the host would refuse every reading');
  });

  testWidgets('one account can be shown as its command alone', (tester) async {
    await pumpList(
      tester,
      [_account('work', loggedIn: false)],
      accountIds: const ['work'],
      showIdentity: false,
      closesItself: true,
    );

    expect(find.text('work-label'), findsNothing);
    expect(find.byType(CcBadge), findsNothing);
    expect(find.byType(ClaudeLoginCommandBlock), findsOneWidget);
    expect(find.text(l10n.claudeSignInClosesItself), findsOneWidget);
  });

  testWidgets('lays out right to left', (tester) async {
    await pumpList(
      tester,
      [_account('out', loggedIn: false)],
      closesItself: true,
      textDirection: TextDirection.rtl,
    );

    // The name leads from the right, its badge follows on the left.
    expect(
      tester.getCenter(badge(l10n.claudeAccountSignedOut)).dx,
      lessThan(tester.getCenter(find.text('out-label')).dx),
    );
    // So does the spinner before its line.
    expect(
      tester.getCenter(find.byType(CcSpinner)).dx,
      greaterThan(
        tester.getCenter(find.text(l10n.claudeSignInClosesItself)).dx,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
