import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

ClaudeAccount _account({
  required bool loggedIn,
  DateTime? credentialExpiresAt,
}) => ClaudeAccount(
  id: 'acc-1',
  label: 'thomas@control-center.com',
  email: 'thomas@control-center.com',
  subscriptionType: 'enterprise',
  orgName: 'Control Center',
  loggedIn: loggedIn,
  credentialExpiresAt: credentialExpiresAt,
);

void main() {
  testWidgets('a lapsed login still signed in shows the flyout copy', (
    tester,
  ) async {
    // Same state as the usage flyout's `signInExpired`: the access token is
    // past but `claude auth status` still reports logged in, because it reads
    // credential shape. The CLI renews it on the next run.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      testWrap(
        ClaudeAccountRow(
          view: ClaudeAccountView(
            account: _account(
              loggedIn: true,
              credentialExpiresAt: DateTime.now().subtract(
                const Duration(hours: 1),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.subscriptionUsageSignInExpired), findsOneWidget);
    expect(find.text(l10n.claudeAccountExpired), findsNothing);
    expect(
      find.textContaining(
        'thomas@control-center.com · enterprise · Control Center',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a still-valid login does not claim it expired', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      testWrap(
        ClaudeAccountRow(
          view: ClaudeAccountView(
            account: _account(
              loggedIn: true,
              credentialExpiresAt: DateTime.now().add(const Duration(hours: 8)),
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.subscriptionUsageSignInExpired), findsNothing);
    expect(find.text(l10n.claudeAccountExpired), findsNothing);
  });

  testWidgets('a signed-out expired login keeps the warning badge', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final expiredAt = DateTime.now().subtract(const Duration(hours: 2));
    await tester.pumpWidget(
      testWrap(
        ClaudeAccountRow(
          view: ClaudeAccountView(
            account: _account(loggedIn: false, credentialExpiresAt: expiredAt),
          ),
        ),
      ),
    );

    expect(find.text(l10n.claudeAccountExpired), findsOneWidget);
    expect(find.text(l10n.subscriptionUsageSignInExpired), findsNothing);
  });
}
