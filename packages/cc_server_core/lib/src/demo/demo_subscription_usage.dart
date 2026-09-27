import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// Fictional quotas for the public demo's title-bar pill.
///
/// The demo does not inspect logins, provider stores, CLIs, host files or the
/// network. Recompute reset times from the request time so a recording always
/// shows meaningful relative durations without pretending to be live usage.
List<Map<String, dynamic>> demoSubscriptionUsage() {
  final now = DateTime.now().toUtc();
  return [
    SubscriptionUsage(
      providerId: 'claude',
      displayName: 'Claude Code (demo)',
      status: SubscriptionStatus.ok,
      fetchedAt: now,
      windows: [
        SubscriptionWindow(
          id: '5h',
          label: 'Session',
          usedFraction: 0.38,
          resetsAt: now.add(const Duration(hours: 3, minutes: 12)),
        ),
        SubscriptionWindow(
          id: '7d',
          label: 'Weekly',
          usedFraction: 0.64,
          resetsAt: now.add(const Duration(days: 4, hours: 6)),
        ),
      ],
    ),
    SubscriptionUsage(
      providerId: 'codex',
      displayName: 'Codex (demo)',
      status: SubscriptionStatus.ok,
      fetchedAt: now,
      windows: [
        SubscriptionWindow(
          id: '5h',
          label: 'Session',
          usedFraction: 0.52,
          resetsAt: now.add(const Duration(hours: 2, minutes: 40)),
        ),
        SubscriptionWindow(
          id: '7d',
          label: 'Weekly',
          usedFraction: 0.27,
          resetsAt: now.add(const Duration(days: 5, hours: 9)),
        ),
      ],
    ),
    SubscriptionUsage(
      providerId: 'cursor',
      displayName: 'Cursor (demo)',
      status: SubscriptionStatus.ok,
      fetchedAt: now,
      windows: [
        SubscriptionWindow(
          id: 'monthly',
          label: 'Monthly',
          usedFraction: 0.78,
          resetsAt: now.add(const Duration(days: 12)),
        ),
      ],
    ),
    SubscriptionUsage(
      providerId: 'zai',
      displayName: 'z.ai (demo)',
      status: SubscriptionStatus.ok,
      fetchedAt: now,
      windows: [
        SubscriptionWindow(
          id: '5h',
          label: 'Session',
          usedFraction: 0.21,
          resetsAt: now.add(const Duration(hours: 4, minutes: 6)),
        ),
        SubscriptionWindow(
          id: 'monthly',
          label: 'Monthly',
          usedFraction: 0.43,
          resetsAt: now.add(const Duration(days: 17)),
        ),
      ],
    ),
    SubscriptionUsage(
      providerId: 'kimi-code',
      displayName: 'Kimi Code (demo)',
      status: SubscriptionStatus.ok,
      fetchedAt: now,
      windows: [
        SubscriptionWindow(
          id: 'weekly',
          label: 'Weekly',
          usedFraction: 0.33,
          resetsAt: now.add(const Duration(days: 3, hours: 11)),
        ),
      ],
    ),
  ].map((usage) => usage.toJson()).toList();
}
