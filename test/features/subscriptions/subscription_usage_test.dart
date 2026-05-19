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
    });
  });
}
