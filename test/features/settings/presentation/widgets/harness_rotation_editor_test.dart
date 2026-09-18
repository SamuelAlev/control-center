import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness/provider.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_rotation_editor.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'harnessRotationCandidates pages quota the same way Claude Code does',
    (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const info = HarnessProviderInfo(
        id: 'kimi-code',
        displayName: 'Kimi Code',
        authMethods: [HarnessAuthMethod.oauth],
        enabled: HarnessProviderEnabled.oauth,
        hasCredential: true,
        credentials: [
          HarnessCredentialSummary(
            credentialId: 'oauth:work@kimi.com',
            method: HarnessAuthMethod.oauth,
            isActive: true,
            removable: true,
            label: 'work@kimi.com',
          ),
          HarnessCredentialSummary(
            credentialId: 'oauth:home@kimi.com',
            method: HarnessAuthMethod.oauth,
            isActive: false,
            removable: true,
            label: 'home@kimi.com',
          ),
        ],
      );

      final candidates = harnessRotationCandidates(
        info: info,
        l10n: l10n,
        usage: [
          SubscriptionUsage(
            providerId: 'kimi-code',
            displayName: 'Kimi Code',
            status: SubscriptionStatus.ok,
            accountId: 'oauth:work@kimi.com',
            accountLabel: 'work@kimi.com',
            windows: const [
              SubscriptionWindow(id: '5h', label: '5h', usedFraction: 0.4),
            ],
            fetchedAt: DateTime.utc(2030),
          ),
          SubscriptionUsage(
            providerId: 'kimi-code',
            displayName: 'Kimi Code',
            status: SubscriptionStatus.exhausted,
            accountId: 'oauth:home@kimi.com',
            accountLabel: 'home@kimi.com',
            error: 'Credits used up.',
            fetchedAt: DateTime.utc(2030),
          ),
        ],
      );

      expect(candidates, hasLength(2));
      expect(candidates[0].id, 'oauth:work@kimi.com');
      expect(candidates[0].unavailable, isFalse);
      expect(candidates[1].id, 'oauth:home@kimi.com');
      expect(candidates[1].unavailable, isTrue);
      expect(candidates[1].unavailableReason, 'Credits used up.');
    },
  );
}
