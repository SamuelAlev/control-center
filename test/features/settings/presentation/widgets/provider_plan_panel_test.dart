import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/provider_plan_panel.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A notifier that serves a fixed snapshot, standing in for the live poll.
class _StubUsage extends SubscriptionUsageNotifier {
  _StubUsage(this._value);

  final List<SubscriptionUsage> _value;

  @override
  Future<List<SubscriptionUsage>> build() async => _value;
}

Future<void> _pump(
  WidgetTester tester, {
  required String providerId,
  String? accountLabel,
  List<SubscriptionUsage> usage = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionUsageProvider.overrideWith(() => _StubUsage(usage)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: Scaffold(
            body: ProviderPlanPanel(
              providerId: providerId,
              accountLabel: accountLabel,
              trailing: const Text('Sign out'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SubscriptionUsage _plan(
  String id, {
  required List<SubscriptionWindow> windows,
}) => SubscriptionUsage(
  providerId: id,
  displayName: id,
  status: SubscriptionStatus.ok,
  windows: windows,
  fetchedAt: DateTime.utc(2030),
);

void main() {
  group('ProviderPlanPanel', () {
    testWidgets('shows the account, the quota bars, and the reset countdown', (
      tester,
    ) async {
      await _pump(
        tester,
        providerId: 'kimi-code',
        accountLabel: 'dev@example.com',
        usage: [
          _plan(
            'kimi-code',
            windows: [
              SubscriptionWindow(
                id: '5h',
                label: '5h',
                usedFraction: 0.48,
                resetsAt: DateTime.now().add(const Duration(hours: 2)),
              ),
              const SubscriptionWindow(
                id: '7d',
                label: '7d',
                usedFraction: 0.21,
              ),
            ],
          ),
        ],
      );

      expect(find.text('dev@example.com'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('5h'), findsOneWidget);
      expect(find.text('48%'), findsOneWidget);
      expect(find.text('21%'), findsOneWidget);
      // One meter per window, so the reading is never colour-only.
      expect(find.byType(CcProgressBar), findsNWidgets(2));
      expect(find.textContaining('Resets in'), findsOneWidget);
    });

    testWidgets('no account label renders no placeholder line', (tester) async {
      // z.ai is a bare key with no identity attached — inventing "Account" text
      // would be worse than saying nothing.
      await _pump(
        tester,
        providerId: 'zai',
        usage: [
          _plan(
            'zai',
            windows: [
              const SubscriptionWindow(
                id: '5h',
                label: 'Session',
                usedFraction: 0.4,
              ),
            ],
          ),
        ],
      );

      expect(find.text('Session'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.byType(CcProgressBar), findsOneWidget);
    });

    testWidgets('a provider that reported nothing says so', (tester) async {
      // An empty meter with no explanation reads as "zero used".
      await _pump(
        tester,
        providerId: 'kimi-code',
        accountLabel: 'dev@example.com',
        usage: [
          const SubscriptionUsage(
            providerId: 'kimi-code',
            displayName: 'Kimi Code',
            status: SubscriptionStatus.error,
          ),
        ],
      );

      expect(find.byType(CcProgressBar), findsNothing);
      expect(find.textContaining("didn't report usage"), findsOneWidget);
    });

    testWidgets('a provider with no plan source shows only the account row', (
      tester,
    ) async {
      await _pump(tester, providerId: 'moonshotai', accountLabel: 'key hint');

      expect(find.text('key hint'), findsOneWidget);
      expect(find.byType(CcProgressBar), findsNothing);
      expect(find.textContaining('usage'), findsNothing);
    });

    test('only plan providers map to a usage source', () {
      // Claude/Codex usage comes from the CLIs' own logins — a different
      // account from anything connected here, so it must not be shown per-tile.
      expect(harnessPlanUsageIds.keys, containsAll(['zai', 'kimi-code']));
      expect(harnessPlanUsageIds.containsKey('anthropic'), isFalse);
      expect(harnessPlanUsageIds.containsKey('openai'), isFalse);
      expect(harnessPlanUsageIds.containsKey('moonshotai'), isFalse);
    });
  });
}
