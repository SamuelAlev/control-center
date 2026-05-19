import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_provider_block.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_usage_pill.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SubscriptionUsage _usage({
  String providerId = 'claude',
  String displayName = 'Claude',
  String? accountId,
  String? accountLabel,
  double used = 0.4,
}) => SubscriptionUsage(
  providerId: providerId,
  displayName: displayName,
  status: SubscriptionStatus.ok,
  accountId: accountId,
  accountLabel: accountLabel,
  windows: [SubscriptionWindow(id: '5h', label: 'Session', usedFraction: used)],
);

class _FakeUsage extends SubscriptionUsageNotifier {
  _FakeUsage(this._value);
  final List<SubscriptionUsage> _value;

  @override
  Future<List<SubscriptionUsage>> build() async => _value;

  @override
  Future<void> refresh() async {}
}

Future<void> _openPill(
  WidgetTester tester,
  List<SubscriptionUsage> usage,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionUsageProvider.overrideWith(() => _FakeUsage(usage)),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: SubscriptionUsagePill(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SubscriptionUsagePill));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a single account shows no paging chrome', (tester) async {
    // One login is not something to page through — the arrows would be dead
    // controls, and the account line would repeat what the provider name says.
    await _openPill(tester, [_usage()]);
    expect(find.byIcon(AppIcons.chevronLeft), findsNothing);
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    expect(find.text('Claude'), findsOneWidget);
  });

  testWidgets('several accounts page, wrap, and say where you are', (
    tester,
  ) async {
    await _openPill(tester, [
      _usage(accountId: 'a', accountLabel: 'me@work · max · Acme'),
      _usage(accountId: 'b', accountLabel: 'me@home · pro'),
    ]);

    // The provider is ONE block, not two — the question is which of my Claude
    // accounts has room, not how many blocks there are.
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('me@work · max · Acme'), findsOneWidget);
    expect(find.text('me@home · pro'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('me@home · pro'), findsOneWidget);

    // Wrapping, so the arrows are never dead ends.
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('each provider gets its own block and its own paging', (
    tester,
  ) async {
    await _openPill(tester, [
      _usage(accountId: 'a', accountLabel: 'me@work'),
      _usage(accountId: 'b', accountLabel: 'me@home'),
      _usage(providerId: 'kimi-code', displayName: 'Kimi Code'),
    ]);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Kimi Code'), findsOneWidget);
    // Only the multi-account provider carries arrows.
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
  });

  testWidgets('an account with no reported usage still gets its page', (
    tester,
  ) async {
    // Three accounts must page as three. Dropping the quiet one would leave
    // the operator counting their accounts and finding one missing.
    await _openPill(tester, [
      _usage(accountId: 'a', accountLabel: 'me@work'),
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.unconfigured,
        accountId: 'b',
        accountLabel: 'me@quiet',
      ),
      _usage(accountId: 'c', accountLabel: 'me@home'),
    ]);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('me@quiet'), findsOneWidget);
    // …and it says WHY it is quiet, rather than reading as breakage.
    expect(find.text(l10n.subscriptionUsageNoneReported), findsOneWidget);
  });

  testWidgets('paging swaps the window rows, not just the label', (
    tester,
  ) async {
    await _openPill(tester, [
      _usage(accountId: 'a', accountLabel: 'me@work', used: 0.2),
      _usage(accountId: 'b', accountLabel: 'me@home', used: 0.76),
    ]);
    // Scoped to the block: the pill CHIP also renders a percentage (the worst
    // provider's), so a bare text finder would match it and prove nothing.
    Finder inBlock(String text) => find.descendant(
      of: find.byType(SubscriptionProviderBlock),
      matching: find.text(text),
    );

    expect(inBlock('20%'), findsOneWidget);
    expect(inBlock('76%'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();
    expect(inBlock('76%'), findsOneWidget);
    expect(inBlock('20%'), findsNothing);
  });

  testWidgets('a per-token account shows money, not a percentage', (
    tester,
  ) async {
    // $1.41 of a $600 cap is 0.24%, which rounds to "0%" and says nothing.
    // The dollars are the reading.
    await _openPill(tester, [
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.ok,
        spend: SubscriptionSpend(
          usedMinor: 141,
          limitMinor: 60000,
          currency: 'USD',
        ),
      ),
    ]);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.subscriptionUsageCredits), findsOneWidget);
    // One line, reading as a sentence: the amount and the cap are one fact.
    expect(
      find.text(l10n.subscriptionUsageSpend(r'$1.41', r'$600.00')),
      findsOneWidget,
    );
    expect(find.text(r'$1.41'), findsNothing, reason: 'not split across lines');
    // …and it is NOT treated as an unconfigured account.
    expect(find.text(l10n.subscriptionUsageNoneReported), findsNothing);
  });

  testWidgets('an account with both windows and spend shows both', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.ok,
        windows: [
          SubscriptionWindow(id: '5h', label: 'Session', usedFraction: 0.2),
        ],
        spend: SubscriptionSpend(
          usedMinor: 500,
          limitMinor: 10000,
          currency: 'USD',
        ),
      ),
    ]);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('20%'), findsWidgets);
    expect(
      find.text(l10n.subscriptionUsageSpend(r'$5.00', r'$100.00')),
      findsOneWidget,
    );
  });

  testWidgets('a spent plan says so, and quotes the provider', (tester) async {
    // "Unavailable" would send the operator looking for a broken integration.
    // The plan answered; the answer is that it has nothing left.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      SubscriptionUsage(
        providerId: 'kimi-code',
        displayName: 'Kimi Code',
        status: SubscriptionStatus.exhausted,
        error: 'Credits used up.',
        fetchedAt: DateTime.utc(2026, 8, 28),
      ),
    ]);

    expect(find.text(l10n.subscriptionUsageExhausted), findsOneWidget);
    expect(find.text('Credits used up.'), findsOneWidget);
    expect(find.text(l10n.subscriptionUsageNoneReported), findsNothing);
    // Scoped to the block: the CHIP legitimately reads "Unavailable" here,
    // because the only configured provider is the spent one.
    expect(
      find.descendant(
        of: find.byType(SubscriptionProviderBlock),
        matching: find.text(l10n.subscriptionUsageUnavailable),
      ),
      findsNothing,
    );
  });

  testWidgets('an account that cannot authenticate asks for a sign-in', (
    tester,
  ) async {
    // It has quietly dropped out of the rotation. "No usage reported for this
    // account" made that indistinguishable from an account nobody happened to
    // use, which is how two Claude logins sat dead for hours.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.signInRequired,
        accountId: 'account-2',
        accountLabel: 'work@example.com',
        error: 'OAuth access token has expired. Re-authenticate to continue.',
      ),
    ]);

    expect(find.text(l10n.subscriptionUsageSignInRequired), findsOneWidget);
    expect(find.text(l10n.subscriptionUsageNoneReported), findsNothing);
  });

  testWidgets('a lapsed but self-renewing sign-in says so quietly', (
    tester,
  ) async {
    // Every account nobody used overnight is in this state by morning, so it
    // must NOT read as the one that needs a human.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.signInExpired,
        accountId: 'account',
        accountLabel: 'me@example.com',
      ),
    ]);

    expect(find.text(l10n.subscriptionUsageSignInExpired), findsOneWidget);
    expect(find.text(l10n.subscriptionUsageSignInRequired), findsNothing);
    // Muted, not tinted: the two states are told apart by weight and colour as
    // well as by wording.
    final style = tester
        .widget<Text>(find.text(l10n.subscriptionUsageSignInExpired))
        .style!;
    expect(style.fontWeight, FontWeight.w400);
  });

  testWidgets('a sign-in problem does not masquerade as a spent quota', (
    tester,
  ) async {
    // An unreadable account contributes NOTHING to the headline. Counting it as
    // fully consumed would report a quota problem where the problem is a login.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      _usage(accountId: 'a', accountLabel: 'me@example.com'),
      const SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.signInRequired,
        accountId: 'b',
        accountLabel: 'work@example.com',
      ),
    ]);

    expect(find.text(l10n.subscriptionUsagePartiallyAvailable), findsNothing);
    expect(find.text(l10n.subscriptionUsageUnavailable), findsNothing);
    expect(find.text('40%'), findsWidgets);
  });

  testWidgets('a spent plan is not hidden behind a healthy one', (
    tester,
  ) async {
    // The chip reports the most-constrained provider, so an exhausted plan
    // has to beat a Claude account sitting at 40%.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _openPill(tester, [
      _usage(),
      const SubscriptionUsage(
        providerId: 'kimi-code',
        displayName: 'Kimi Code',
        status: SubscriptionStatus.exhausted,
        error: 'Credits used up.',
      ),
    ]);

    expect(
      find.text(l10n.subscriptionUsagePartiallyAvailable),
      findsOneWidget,
      reason: 'one plan is spent while the other still has headroom',
    );
    expect(find.text('40%'), findsWidgets);
  });
}
