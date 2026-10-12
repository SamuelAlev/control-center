import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
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
  testWidgets('warns on expiry even while the CLI reports logged in', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      testWrap(
        ClaudeAccountRow(
          view: ClaudeAccountView(
            account: _account(
              loggedIn: true,
              credentialExpiresAt: DateTime.utc(2000),
            ),
          ),
        ),
      ),
    );

    final badge = tester.widget<CcBadge>(
      find.widgetWithText(CcBadge, l10n.claudeAccountExpired),
    );
    expect(badge.variant, CcBadgeVariant.warning);
  });

  testWidgets('a still-valid login does not claim it expired', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      testWrap(
        ClaudeAccountRow(
          view: ClaudeAccountView(
            account: _account(
              loggedIn: true,
              credentialExpiresAt: DateTime.utc(2100),
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
    final expiredAt = DateTime.utc(2000);
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
