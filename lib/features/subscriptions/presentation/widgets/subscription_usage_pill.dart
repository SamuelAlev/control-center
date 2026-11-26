import 'dart:math' as math;

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_provider_block.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_usage_chip.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Title-bar pill showing live AI subscription usage (Claude Code, Codex,
/// Cursor, z.ai, Kimi Code, Mistral, DeepSeek): each configured provider's
/// logo beside its most-constrained reading, expanding to a per-provider breakdown with
/// progress bars and reset countdowns.
///
/// One reading per provider rather than one for all of them: a single
/// headline could only say "one plan is spent, others are fine" without
/// saying which, and which is the whole question.
class SubscriptionUsagePill extends ConsumerStatefulWidget {
  /// Creates a [SubscriptionUsagePill].
  const SubscriptionUsagePill({super.key});

  @override
  ConsumerState<SubscriptionUsagePill> createState() =>
      _SubscriptionUsagePillState();
}

class _SubscriptionUsagePillState extends ConsumerState<SubscriptionUsagePill> {
  final CcOverlayController _controller = CcOverlayController();

  /// Whether the refresh button's fetch is running. Tracked here rather than
  /// read from the provider: a refresh keeps the last snapshot as plain data
  /// (it never enters a loading state), so the provider cannot say it is busy.
  bool _refreshing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _controller.toggle();
    // Opening the pill is an explicit "show me now" — refresh in the
    // background so the breakdown is fresh without blocking the open.
    ref.read(subscriptionUsageProvider.notifier).refresh();
  }

  Future<void> _refreshNow() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(subscriptionUsageProvider.notifier).refresh(force: true);
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(subscriptionUsageProvider);
    // .value (not asData) so a background/foreground refresh — which holds a
    // loading-with-previous state — keeps the last snapshot on screen.
    final providers = async.value ?? const <SubscriptionUsage>[];

    // Only configured providers are shown (see [subscriptionAccountGroups]).
    // When nothing is set up at all the pill itself drops out of the title
    // bar entirely.
    final configured = [
      for (final group in subscriptionAccountGroups(providers)) ...group,
    ];
    if (configured.isEmpty) {
      return const SizedBox.shrink();
    }

    // Each provider's reading is its most-constrained account, so a spent
    // account ([SubscriptionStatus.exhausted], counted as fully consumed) is
    // never hidden behind a healthy sibling.
    //
    // An account we could not read contributes no NUMBER. One we could not
    // authenticate for ([SubscriptionStatus.signInRequired] /
    // [SubscriptionStatus.signInExpired]) has no reading, and inventing a spent
    // one would report a quota problem where the actual problem is a login. A
    // fetch that failed ([SubscriptionStatus.error]) is often an exhausted plan
    // whose usage endpoint is rate-limited too (Claude does this), but "often"
    // is not "100%": it marks the provider as needing a look instead. The
    // flyout is where either gets said.
    //
    // A prepaid provider has no fraction; its reading is the money left, and
    // its most-constrained account is the one with the least of it.
    final readings = <String, ProviderUsageReading>{};
    final lowest = <String, SubscriptionBalance>{};
    for (final p in configured) {
      if (p.status == SubscriptionStatus.ok && p.balances.isNotEmpty) {
        final balance = p.balances.first;
        final held = lowest[p.providerId];
        // Only amounts in one currency compare; the first seen sets it.
        if (held == null ||
            (held.currency == balance.currency &&
                balance.amount < held.amount)) {
          lowest[p.providerId] = balance;
        }
      }
      final least = lowest[p.providerId];
      final f = p.status == SubscriptionStatus.exhausted
          ? 1.0
          : p.peakUsedFraction;
      final prev = readings[p.providerId];
      final worst = switch ((prev?.fraction, f)) {
        (null, final b) => b,
        (final a, null) => a,
        (final double a, final double b) => a > b ? a : b,
      };
      readings[p.providerId] = ProviderUsageReading(
        providerId: p.providerId,
        displayName: p.displayName,
        fraction: worst,
        failed: (prev?.failed ?? false) || p.status == SubscriptionStatus.error,
        balance: least == null
            ? null
            : formatSubscriptionMoney(least.amount, least.currency),
      );
    }

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: AlignmentDirectional.topEnd,
      targetAnchor: AlignmentDirectional.bottomEnd,
      semanticLabel: l10n.subscriptionUsage,
      overlayBuilder: (context, _) => _UsageOverlay(
        providers: configured,
        isLoading: async.isLoading || _refreshing,
        onRefresh: _refreshNow,
      ),
      target: SubscriptionUsageChip(
        readings: readings.values.toList(),
        onTap: _open,
      ),
    );
  }
}

class _UsageOverlay extends StatelessWidget {
  const _UsageOverlay({
    required this.providers,
    required this.isLoading,
    required this.onRefresh,
  });

  final List<SubscriptionUsage> providers;
  final bool isLoading;
  final VoidCallback onRefresh;

  /// The OLDEST reading on screen. Readings come from caches of different
  /// ages, and "checked a minute ago" is only honest if every number in the
  /// flyout is at least that fresh.
  DateTime? get lastChecked {
    DateTime? oldest;
    for (final p in providers) {
      final at = p.fetchedAt;
      if (at != null && (oldest == null || at.isBefore(oldest))) {
        oldest = at;
      }
    }
    return oldest;
  }

  /// One group per provider, holding its accounts in report order.
  List<List<SubscriptionUsage>> get groups =>
      subscriptionAccountGroups(providers);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    // Merged onto the complete style CcPopover provides, not replacing it:
    // a fresh DefaultTextStyle here dropped the UI family, and every line in
    // the flyout fell back to the platform font.
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 13),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          minWidth: 300,
          // Five providers with several windows each outgrow a short window;
          // the list scrolls under a fixed header instead of running off it.
          maxHeight: math.max(200, MediaQuery.sizeOf(context).height - 96),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.gauge, size: 14, color: t.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.subscriptionUsage,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  RefreshControl(
                    onRefresh: onRefresh,
                    lastChecked: lastChecked,
                    isLoading: isLoading,
                    size: CcButtonSize.sm,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (providers.isEmpty)
                      Text(
                        l10n.notConfiguredLabel,
                        style: TextStyle(color: t.textTertiary, fontSize: 12),
                      )
                    else
                      for (var i = 0; i < groups.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.lg),
                        SubscriptionProviderBlock(accounts: groups[i]),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
