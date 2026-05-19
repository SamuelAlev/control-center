import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Title-bar pill showing live AI subscription usage (Claude Code, Codex,
/// z.ai): a compact "{worst}% used" chip that expands to a per-provider
/// breakdown with progress bars and reset countdowns.
///
/// Mirrors Claude Code's usage indicator. The compact chip reports the most
/// constrained provider at a glance; the popover carries the full detail and
/// the "resets in Y" times.
class SubscriptionUsagePill extends ConsumerStatefulWidget {
  /// Creates a [SubscriptionUsagePill].
  const SubscriptionUsagePill({super.key});

  @override
  ConsumerState<SubscriptionUsagePill> createState() =>
      _SubscriptionUsagePillState();
}

class _SubscriptionUsagePillState extends ConsumerState<SubscriptionUsagePill> {
  final CcOverlayController _controller = CcOverlayController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(subscriptionUsageProvider);
    // .value (not asData) so a background/foreground refresh — which holds a
    // loading-with-previous state — keeps the last snapshot on screen.
    final providers = async.value ?? const <SubscriptionUsage>[];

    // Only configured providers are shown: a provider that isn't set up
    // ([SubscriptionStatus.unconfigured]) holds no quota, so its "sign in"
    // block is noise in the breakdown. When nothing is set up at all the
    // pill itself drops out of the title bar entirely.
    final configured = [
      for (final p in providers)
        if (p.status != SubscriptionStatus.unconfigured) p,
    ];
    if (configured.isEmpty) {
      return const SizedBox.shrink();
    }

    // The headline reports the most-constrained situation across all
    // configured providers. A provider whose usage fetch failed
    // ([SubscriptionStatus.error]) is treated as fully consumed — most often
    // that's an exhausted subscription that also fails its usage fetch (Claude
    // rate-limits the usage endpoint when the plan is spent) — so an exhausted
    // provider is never hidden behind a healthy one.
    double? headlineFraction(SubscriptionUsage p) {
      if (p.status == SubscriptionStatus.error) {
        return 1.0;
      }
      return p.peakUsedFraction;
    }

    double? worstFrac;
    var hasCapacity = false;
    for (final p in configured) {
      final f = headlineFraction(p);
      if (f == null) {
        continue;
      }
      if (f < 1.0) {
        hasCapacity = true;
      }
      if (worstFrac == null || f > worstFrac) {
        worstFrac = f;
      }
    }

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      semanticLabel: l10n.subscriptionUsage,
      overlayBuilder: (context, _) =>
          _UsageOverlay(providers: configured, isLoading: async.isLoading),
      target: _PillButton(
        fraction: worstFrac,
        hasCapacity: hasCapacity,
        onTap: _open,
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.fraction,
    required this.hasCapacity,
    required this.onTap,
  });

  /// The headline fraction driving the chip — the most-constrained provider's.
  /// May be `1.0` for a provider whose fetch failed (counted as exhausted);
  /// see [_SubscriptionUsagePillState.build].
  final double? fraction;

  /// Whether at least one configured provider still has headroom. Drives the
  /// "Partially available" vs "Unavailable" distinction when [fraction] is
  /// exhausted.
  final bool hasCapacity;

  final VoidCallback onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final frac = widget.fraction;
    final exhausted = frac != null && frac >= 1.0;
    // When the most-constrained provider is spent, the headline still has two
    // flavours: every provider is exhausted (Unavailable) or at least one still
    // has headroom (Partially available). The latter is the common case — one
    // plan maxed out while others carry on.
    final unavailable = exhausted && !widget.hasCapacity;
    final partially = exhausted && widget.hasCapacity;
    final bg = _hover ? t.bgSecondaryHover : t.bgSecondary;
    final border = _hover ? t.lineStrong : t.borderPrimary;
    final dot = frac == null
        ? t.muted
        : unavailable
        ? t.danger
        : (exhausted ? t.warn : subscriptionUsageColor(frac, t));
    final label = (frac == null)
        ? null
        : unavailable
        ? l10n.subscriptionUsageUnavailable
        : partially
        ? l10n.subscriptionUsagePartiallyAvailable
        : '${(frac * 100).round()}%';
    // The tooltip names the control, nothing more: the reading is already on
    // the chip as text (the percentage, or "Partially available"/"Unavailable"),
    // so status is never carried by the dot colour alone and repeating it on
    // hover only makes the label longer and staler.

    return CcTooltip(
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.bottomCenter,
      message: l10n.subscriptionUsage,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (frac == null)
                  Icon(AppIcons.gauge, size: 12, color: t.muted)
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsageOverlay extends StatelessWidget {
  const _UsageOverlay({required this.providers, required this.isLoading});

  final List<SubscriptionUsage> providers;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    // Off-Material overlay: supply a concrete text style so nothing falls
    // through to the 48px yellow error fallback.
    return DefaultTextStyle(
      style: TextStyle(
        color: t.textPrimary,
        fontSize: 13,
        decoration: TextDecoration.none,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(AppIcons.gauge, size: 14, color: t.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
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
                  if (isLoading) const CcSpinner(size: 12),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (providers.isEmpty)
                Text(
                  l10n.notConfiguredLabel,
                  style: TextStyle(color: t.textTertiary, fontSize: 12),
                )
              else
                for (var i = 0; i < providers.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _ProviderBlock(usage: providers[i]),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderBlock extends StatelessWidget {
  const _ProviderBlock({required this.usage});

  final SubscriptionUsage usage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ok =
        usage.status == SubscriptionStatus.ok && usage.windows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          usage.displayName,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (!ok)
          Text(
            // Only configured providers reach the overlay, so a non-ok status
            // here is always a failed usage fetch. Surface the localized
            // message rather than the server's raw English `error` string.
            l10n.subscriptionUsageUnavailable,
            style: TextStyle(color: t.textTertiary, fontSize: 12),
          )
        else
          for (var i = 0; i < usage.windows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            SubscriptionWindowRow(window: usage.windows[i]),
          ],
      ],
    );
  }
}
