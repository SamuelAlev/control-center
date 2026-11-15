import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_sign_in_dialogs.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/claude_sign_in_watch.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/fake_claude_accounts_repository.dart';
import '../../../../../helpers/test_wrap.dart';

/// A sign-in whose access token lapsed: the roster badges it "Sign-in expired".
final _expired = ClaudeAccount(
  id: 'work',
  label: 'Work',
  loggedIn: true,
  credentialExpiresAt: DateTime.utc(2000),
);

const _signedOut = ClaudeAccount(id: 'personal', label: 'Personal');

/// What sits behind the dialogs: the roster as Settings shows it, and the two
/// ways in.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(claudeAccountsProvider).value ?? const [];
    return Column(
      children: [
        for (final view in roster)
          ClaudeAccountRow(view: view, key: ValueKey(view.account.id)),
        if (roster.isNotEmpty)
          CcButton(
            onPressed: () =>
                showClaudeLoginCommand(context, roster.first.account),
            child: const Text('sign in one'),
          ),
        CcButton(
          onPressed: () => showClaudeSignInDialog(context, ref),
          child: const Text('sign in all'),
        ),
      ],
    );
  }
}

void main() {
  late AppLocalizations l10n;
  late FakeClaudeAccountsRepository repo;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<void> settle(WidgetTester tester) async {
    // Not pumpAndSettle: a waiting dialog spins for as long as it is open.
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  Future<void> pumpHost(
    WidgetTester tester,
    List<ClaudeAccount> accounts, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    repo = FakeClaudeAccountsRepository(accounts: accounts);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [claudeAccountsRepositoryProvider.overrideWithValue(repo)],
        child: testWrap(const _Host(), locale: locale),
      ),
    );
    await settle(tester);
  }

  Future<void> open(WidgetTester tester, String action) async {
    await tester.tap(find.text(action));
    await settle(tester);
  }

  /// Lets one reading of the watch happen and its consequences land.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump(claudeSignInPollInterval);
    await settle(tester);
  }

  final dialog = find.byType(CcDialog);
  const command =
      "CLAUDE_CONFIG_DIR='/data/claude accounts/work' claude auth login";

  group('signing one account in', () {
    testWidgets('shows its command and says it closes itself', (tester) async {
      await pumpHost(tester, [_expired]);
      await open(tester, 'sign in one');

      expect(
        find.descendant(
          of: dialog,
          matching: find.text(l10n.claudeAccountSignIn),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.claudeAccountSignInHint), findsOneWidget);
      expect(find.text(command), findsOneWidget);
      expect(find.text(l10n.claudeSignInClosesItself), findsOneWidget);
      // The row it was opened from names the account; the dialog does not
      // repeat it.
      expect(
        find.descendant(of: dialog, matching: find.text('Work')),
        findsNothing,
      );
    });

    testWidgets('closes itself, with the row behind it already right', (
      tester,
    ) async {
      await pumpHost(tester, [_expired]);
      expect(find.text(l10n.claudeAccountExpired), findsOneWidget);
      await open(tester, 'sign in one');
      final readsWhileOpen = repo.rosterReads;

      // The login finishes in the terminal. The roster read it triggers is
      // held back, to look at the dialog in between.
      repo
        ..signIn('work')
        ..rosterGate = Completer<void>();
      await tick(tester);

      expect(dialog, findsOneWidget, reason: 'waits for the roster');
      expect(
        find.descendant(of: dialog, matching: find.text(l10n.signedIn)),
        findsOneWidget,
      );
      expect(find.text(l10n.claudeSignInClosesItself), findsNothing);

      repo.rosterGate!.complete();
      await settle(tester);

      expect(dialog, findsNothing);
      expect(find.text(l10n.claudeAccountExpired), findsNothing);
      expect(
        repo.rosterReads,
        readsWhileOpen + 1,
        reason: 'read once for the sign-in, not again for closing',
      );
    });

    testWidgets('signing a working account in again waits for the login', (
      tester,
    ) async {
      await pumpHost(tester, [
        _expired.copyWith(credentialExpiresAt: DateTime.utc(2099)),
      ]);
      await open(tester, 'sign in one');

      await tick(tester);
      await tick(tester);
      expect(dialog, findsOneWidget, reason: 'being signed in is not enough');

      repo.signIn('work');
      await tick(tester);
      expect(dialog, findsNothing);
    });

    testWidgets('a roster that never answers does not hold it open', (
      tester,
    ) async {
      await pumpHost(tester, [_expired]);
      await open(tester, 'sign in one');

      repo
        ..signIn('work')
        ..rosterGate = Completer<void>();
      await tick(tester);
      expect(dialog, findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
      expect(dialog, findsNothing);
    });

    testWidgets('copies the same line it shows', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpHost(tester, [_expired]);
      await open(tester, 'sign in one');

      await tester.tap(find.widgetWithText(CcButton, l10n.copy));
      await tester.pump();

      expect(copied, command);
    });
  });

  group('closed by hand, it re-reads the roster once', () {
    Future<int> openOverStaleRoster(WidgetTester tester) async {
      await pumpHost(tester, [_expired]);
      await open(tester, 'sign in one');
      return repo.rosterReads;
    }

    Future<void> expectClosedAndReRead(WidgetTester tester, int before) async {
      await settle(tester);
      expect(dialog, findsNothing);
      expect(repo.rosterReads, before + 1);
    }

    testWidgets('with the Close button', (tester) async {
      final before = await openOverStaleRoster(tester);
      await tester.tap(find.widgetWithText(CcButton, l10n.close));
      await expectClosedAndReRead(tester, before);
    });

    testWidgets('with the close control', (tester) async {
      final before = await openOverStaleRoster(tester);
      await tester.tap(find.byIcon(CcIcons.x));
      await expectClosedAndReRead(tester, before);
    });

    testWidgets('with Escape', (tester) async {
      final before = await openOverStaleRoster(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await expectClosedAndReRead(tester, before);
    });

    testWidgets('by clicking outside it', (tester) async {
      final before = await openOverStaleRoster(tester);
      await tester.tapAt(const Offset(8, 8));
      await expectClosedAndReRead(tester, before);
    });

    testWidgets('and shows a login that finished just before', (tester) async {
      // Finished between two readings of the watch: closing still finds it.
      await openOverStaleRoster(tester);
      repo.signIn('work');

      await tester.tap(find.byIcon(CcIcons.x));
      await settle(tester);

      expect(find.text(l10n.claudeAccountExpired), findsNothing);
    });
  });

  group('signing every account in', () {
    testWidgets('reads the roster fresh and lists who needs it', (
      tester,
    ) async {
      await pumpHost(tester, [_expired, _signedOut]);
      final before = repo.rosterReads;
      await open(tester, 'sign in all');

      expect(repo.rosterReads, before + 1);
      expect(find.text(l10n.claudeSignInDialogTitle), findsOneWidget);
      expect(find.text(l10n.claudeSignInDialogHint), findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Work')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Personal')),
        findsOneWidget,
      );
      expect(find.text(l10n.claudeSignInClosesItselfAll), findsOneWidget);
      // Each command has its own copy control; there is no single line to
      // copy from the footer.
      expect(find.widgetWithText(CcButton, l10n.copy), findsNothing);
    });

    testWidgets('stays open until the last one is signed in', (tester) async {
      await pumpHost(tester, [_expired, _signedOut]);
      await open(tester, 'sign in all');

      repo.signIn('work');
      await tick(tester);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(CcBadge, l10n.claudeAccountSignedIn),
        ),
        findsOneWidget,
      );
      // The row behind caught up as well, while the dialog is still open.
      expect(find.text(l10n.claudeAccountExpired), findsNothing);

      repo.signIn('personal');
      await tick(tester);
      expect(dialog, findsNothing);
    });
  });

  testWidgets('lays out right to left', (tester) async {
    // A dialog sits on the root navigator, so its direction is the locale's.
    final arabic = await appLocalizationsDelegate.load(const Locale('ar'));
    await pumpHost(tester, [_expired], locale: const Locale('ar'));
    await open(tester, 'sign in one');

    // The command stays left to right; the dialog around it mirrors.
    expect(find.text(command), findsOneWidget);
    expect(
      tester.getCenter(find.byType(CcSpinner)).dx,
      greaterThan(
        tester.getCenter(find.text(arabic.claudeSignInClosesItself)).dx,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
