import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_account_pager.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_usage_rows.dart';
import 'package:control_center/features/desktop_app/providers/tray_panel_providers.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/ai_brand_logo.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of the provider column when each provider is one line.
const double _compactLabelWidth = 104;

/// The same, when a provider in it also carries its account pager.
const double _compactPagedLabelWidth = 132;

/// The logo's edge, and the gap after it: where a provider's name starts.
const double _logoSize = 14;
const double _logoGap = AppSpacing.sm;

/// Providers shown with every window; past this each one is a single line
/// with its fullest window, so usage never pushes the spaces off the panel.
const int _fullProviders = 2;

/// Plan usage, one block per configured provider, paging through its
/// accounts when it has several: the title-bar pill's flyout, condensed. A
/// block opens the accounts page.
class TrayUsageSection extends ConsumerWidget {
  /// Creates a [TrayUsageSection].
  const TrayUsageSection({required this.workspaceId, super.key});

  /// Where the accounts page opens; the blocks are inert without one.
  final String? workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    final groups = subscriptionAccountGroups(
      ref.watch(subscriptionUsageProvider).value ?? const [],
    );
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final compact = groups.length > _fullProviders;
    // One provider column for every line, wide enough for a pager if any
    // line has one, so the meters still start together.
    final leadingWidth = groups.any((g) => g.length > 1)
        ? _compactPagedLabelWidth
        : _compactLabelWidth;
    final id = workspaceId;
    final open = id == null
        ? null
        : () => actions.openRoute(settingsAdaptersRoute(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcDivider(color: t.borderSecondary),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: CcSidebarGroup(
            label: l10n.trayPanelUsage,
            children: [
              for (final accounts in groups)
                _ProviderUsage(
                  key: ValueKey(accounts.first.providerId),
                  accounts: accounts,
                  compact: compact,
                  leadingWidth: leadingWidth,
                  onPress: open,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One provider: its name and every reading of the account on show, or in
/// [compact] form one line with that account's reading closest to its
/// limit. Several accounts page from the first, as the flyout does, and the
/// panel stays on the one paged to.
class _ProviderUsage extends ConsumerWidget implements CcFluidHoverTarget {
  const _ProviderUsage({
    required this.accounts,
    required this.compact,
    required this.leadingWidth,
    required this.onPress,
    super.key,
  });

  final List<SubscriptionUsage> accounts;
  final bool compact;
  final double leadingWidth;
  final VoidCallback? onPress;

  @override
  bool get fluidHoverEnabled => onPress != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final providerId = accounts.first.providerId;
    final shown = ref.watch(
      trayUsageAccountProvider.select((m) => m[providerId]),
    );
    // A refresh can drop the account paged to; the first stands in.
    final index = accounts.indexWhere((a) => a.accountId == shown);
    final usage = accounts[index < 0 ? 0 : index];
    final multiple = accounts.length > 1;
    final readings = _readings(usage, l10n);
    // A prepaid account reads in money left, which has no meter to draw.
    final balances = usage.status == SubscriptionStatus.ok
        ? usage.balances
        : const <SubscriptionBalance>[];
    final note = readings.isEmpty && balances.isEmpty
        ? _note(usage, l10n)
        : null;
    final noteTint = switch (usage.status) {
      SubscriptionStatus.exhausted => t.textErrorPrimary,
      SubscriptionStatus.signInRequired => t.textWarningPrimary,
      _ => null,
    };
    final account = multiple ? usage.accountLabel : null;

    Widget name = Text(
      usage.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: t.textPrimary,
        fontSize: compact ? 12 : 13,
        fontWeight: FontWeight.w600,
      ),
    );
    // A compact line has no room for the account's name; it is a hover away.
    if (compact && account != null) {
      name = CcTooltip(message: account, child: name);
    }
    final provider = Row(
      children: [
        AiBrandLogo(
          brand: AiBrand.forProvider(providerId),
          color: t.textPrimary,
          size: _logoSize,
        ),
        const SizedBox(width: _logoGap),
        Expanded(child: name),
        if (multiple)
          TrayAccountPager(
            index: index < 0 ? 0 : index,
            count: accounts.length,
            onPage: (to) => ref
                .read(trayUsageAccountProvider.notifier)
                .show(providerId, accounts[to].accountId ?? ''),
          ),
      ],
    );

    final Widget content;
    if (compact) {
      content = readings.isEmpty
          ? TrayUsageLine(
              leading: provider,
              leadingWidth: leadingWidth,
              child: note != null
                  ? TrayUsageNote(text: note, tint: noteTint)
                  : CcTooltip(
                      message: l10n.subscriptionUsageBalance,
                      child: TrayBalanceAmount(balance: balances.first),
                    ),
            )
          : TrayWindowMeter(
              reading: readings.reduce(
                (a, b) =>
                    a.window.usedFraction >= b.window.usedFraction ? a : b,
              ),
              leading: provider,
              leadingWidth: leadingWidth,
            );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: trayUsageLineHeight, child: provider),
          // The account on its own line, under the name: an address and a
          // plan do not fit beside a name and a pager.
          if (account != null)
            _Hanging(
              child: Text(
                account,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.textTertiary, fontSize: 12),
              ),
            ),
          if (note != null)
            _Hanging(
              child: TrayUsageNote(text: note, tint: noteTint),
            )
          else ...[
            const SizedBox(height: AppSpacing.xs),
            for (final reading in readings) TrayWindowMeter(reading: reading),
            for (final balance in balances) TrayBalanceLine(balance: balance),
          ],
        ],
      );
    }
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      child: content,
    );
    final press = onPress;
    if (press == null) {
      return padded;
    }
    return CcTappable(
      onPressed: press,
      borderRadius: AppRadii.brSm,
      semanticLabel: usage.displayName,
      builder: (context, states) {
        // Inside the group the travelling wash is the hover; on its own the
        // block paints one.
        final fluid =
            CcFluidHover.controlsTappable(context) &&
            CcFluidHover.isItemActive(context);
        final hovered = states.contains(WidgetState.hovered) && !fluid;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.hover.withValues(alpha: 0),
            borderRadius: AppRadii.brSm,
          ),
          child: padded,
        );
      },
    );
  }
}

/// What [usage] has to show, in the flyout's order: its windows, then its
/// credits. Empty when it has nothing, and a note says why.
List<TrayUsageReading> _readings(
  SubscriptionUsage usage,
  AppLocalizations l10n,
) {
  if (usage.status != SubscriptionStatus.ok) {
    return const [];
  }
  final spend = usage.spend;
  return [
    for (final window in usage.windows)
      (window: window, value: null, detail: null),
    if (spend != null)
      (
        window: SubscriptionWindow(
          id: 'spend',
          label: l10n.subscriptionUsageCredits,
          usedFraction: spend.usedFraction,
        ),
        value: formatSubscriptionMoney(spend.used, spend.currency),
        detail: spend.hasLimit
            ? l10n.subscriptionUsageSpend(
                formatSubscriptionMoney(spend.used, spend.currency),
                formatSubscriptionMoney(spend.limit, spend.currency),
              )
            : null,
      ),
  ];
}

/// The flyout's five silences, for an account with no reading.
String _note(SubscriptionUsage usage, AppLocalizations l10n) =>
    switch (usage.status) {
      SubscriptionStatus.ok ||
      SubscriptionStatus.unconfigured => l10n.subscriptionUsageNoneReported,
      SubscriptionStatus.exhausted => l10n.subscriptionUsageExhausted,
      SubscriptionStatus.signInRequired => l10n.subscriptionUsageSignInRequired,
      SubscriptionStatus.signInExpired => l10n.subscriptionUsageSignInExpired,
      _ => l10n.subscriptionUsageUnavailable,
    };

/// Under the provider's name rather than its logo.
class _Hanging extends StatelessWidget {
  const _Hanging({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: _logoSize + _logoGap,
      top: 2,
    ),
    child: child,
  );
}
