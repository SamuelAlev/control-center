import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionUsage', () {
    test('round-trips through JSON', () {
      final usage = SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.ok,
        windows: [
          SubscriptionWindow(
            id: '5h',
            label: 'Session',
            usedFraction: 0.68,
            resetsAt: DateTime.utc(2030, 1, 1, 12),
          ),
          const SubscriptionWindow(
            id: '7d',
            label: 'Weekly',
            usedFraction: 0.2,
          ),
        ],
        fetchedAt: DateTime.utc(2030),
      );

      final restored = SubscriptionUsage.fromJson(usage.toJson());

      expect(restored, usage);
      expect(restored.windows.first.resetsAt, DateTime.utc(2030, 1, 1, 12));
    });

    test('clamps used fraction into [0, 1] on parse', () {
      final w = SubscriptionWindow.fromJson(const {
        'id': '5h',
        'label': 'Session',
        'used_fraction': 1.4,
      });
      expect(w.usedFraction, 1.0);
    });

    test('peakUsedFraction is the most-consumed window', () {
      const usage = SubscriptionUsage(
        providerId: 'codex',
        displayName: 'Codex',
        status: SubscriptionStatus.ok,
        windows: [
          SubscriptionWindow(id: '5h', label: 'Session', usedFraction: 0.3),
          SubscriptionWindow(id: '7d', label: 'Weekly', usedFraction: 0.91),
        ],
      );
      expect(usage.peakUsedFraction, 0.91);
      expect(usage.peakWindow?.id, '7d');
    });

    test('earliestReset picks the soonest window reset', () {
      final usage = SubscriptionUsage(
        providerId: 'zai',
        displayName: 'z.ai',
        status: SubscriptionStatus.ok,
        windows: [
          SubscriptionWindow(
            id: '7d',
            label: 'Weekly',
            usedFraction: 0.5,
            resetsAt: DateTime.utc(2030, 1, 5),
          ),
          SubscriptionWindow(
            id: '5h',
            label: 'Session',
            usedFraction: 0.5,
            resetsAt: DateTime.utc(2030, 1, 1),
          ),
        ],
      );
      expect(usage.earliestReset, DateTime.utc(2030, 1, 1));
    });

    test('peak getters are null with no windows', () {
      const usage = SubscriptionUsage(
        providerId: 'claude',
        displayName: 'Claude',
        status: SubscriptionStatus.unconfigured,
      );
      expect(usage.peakUsedFraction, isNull);
      expect(usage.peakWindow, isNull);
      expect(usage.earliestReset, isNull);
    });

    test('unknown status wire value parses as error', () {
      expect(SubscriptionStatus.fromWire('weird'), SubscriptionStatus.error);
      expect(SubscriptionStatus.fromWire('ok'), SubscriptionStatus.ok);
      expect(
        SubscriptionStatus.fromWire('unconfigured'),
        SubscriptionStatus.unconfigured,
      );
      expect(
        SubscriptionStatus.fromWire('exhausted'),
        SubscriptionStatus.exhausted,
      );
      expect(
        SubscriptionStatus.fromWire('signInExpired'),
        SubscriptionStatus.signInExpired,
      );
      expect(
        SubscriptionStatus.fromWire('signInRequired'),
        SubscriptionStatus.signInRequired,
      );
    });

    test('the two sign-in states stay distinct over the wire', () {
      // Folding them together is the tempting simplification and the wrong one:
      // one needs a human, the other renews itself on the next run.
      for (final status in [
        SubscriptionStatus.signInExpired,
        SubscriptionStatus.signInRequired,
      ]) {
        final wire = SubscriptionUsage(
          providerId: 'claude',
          displayName: 'Claude',
          status: status,
          accountId: 'a',
        ).toJson();
        expect(SubscriptionUsage.fromJson(wire).status, status);
      }
    });

    test('a spent plan round-trips over the wire with its reason', () {
      const usage = SubscriptionUsage(
        providerId: 'kimi-code',
        displayName: 'Kimi Code',
        status: SubscriptionStatus.exhausted,
        error: 'Credits used up.',
      );
      final wire = usage.toJson();
      expect(wire['status'], 'exhausted');
      final restored = SubscriptionUsage.fromJson(wire);
      expect(restored.status, SubscriptionStatus.exhausted);
      expect(restored.error, 'Credits used up.');
      // An OLD client does not know the value and must degrade to `error`,
      // which every surface already treats as fully consumed — a less specific
      // reading, never a wrong one.
      expect(
        SubscriptionStatus.fromWire('exhausted-v2'),
        SubscriptionStatus.error,
      );
    });
  });
}
