import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';

/// One provider's usage, paging through its accounts when it has several.
class SubscriptionProviderBlock extends StatefulWidget {
  /// Creates a [SubscriptionProviderBlock].
  const SubscriptionProviderBlock({required this.accounts, super.key});

  /// This provider's snapshots — one per account, or a single unattributed one.
  final List<SubscriptionUsage> accounts;

  @override
  State<SubscriptionProviderBlock> createState() =>
      _SubscriptionProviderBlockState();
}

/// `$1.41` / `€12.00` — minor units are already folded in by the entity.
String _money(double amount, String currency) {
  const symbols = {'USD': r'$', 'EUR': '€', 'GBP': '£'};
  final symbol = symbols[currency];
  final text = amount.toStringAsFixed(2);
  return symbol != null ? '$symbol$text' : '$text $currency';
}

class _SubscriptionProviderBlockState extends State<SubscriptionProviderBlock> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // A refresh can shrink the list (an account was removed) while this block
    // sits on a later page, so the index is clamped on every build rather than
    // trusted from the last one.
    final index = widget.accounts.isEmpty
        ? 0
        : _index.clamp(0, widget.accounts.length - 1);
    final usage = widget.accounts[index];
    final multiple = widget.accounts.length > 1;
    // "Has something to show" is windows OR a spend balance — an account
    // billed per token has no windows at all and would otherwise read as
    // unconfigured while money was actively being spent on it.
    final ok = usage.status == SubscriptionStatus.ok && usage.hasReading;
    final exhausted = usage.status == SubscriptionStatus.exhausted;
    // The two states that ask the operator for something, and so earn a tint
    // and a heavier weight in a popover that is otherwise deliberately quiet.
    final actionable =
        exhausted || usage.status == SubscriptionStatus.signInRequired;
    final spend = usage.spend;

    void page(int delta) => setState(
      () => _index =
          (index + delta + widget.accounts.length) % widget.accounts.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                usage.displayName,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (multiple) ...[
              // The position, then the arrows — with three accounts the arrows
              // alone say you can move but never where you are.
              Text(
                '${index + 1}/${widget.accounts.length}',
                style: TextStyle(color: t.textTertiary, fontSize: 11),
              ),
              const SizedBox(width: 2),
              CcIconButton(
                icon: AppIcons.chevronLeft,
                size: CcButtonSize.sm,
                tooltip: l10n.subscriptionUsagePreviousAccount,
                onPressed: () => page(-1),
              ),
              CcIconButton(
                icon: AppIcons.chevronRight,
                size: CcButtonSize.sm,
                tooltip: l10n.subscriptionUsageNextAccount,
                onPressed: () => page(1),
              ),
            ],
          ],
        ),
        // The account gets its OWN line. An address plus a plan plus an org
        // does not fit beside a provider name and a pager in a 320px popover —
        // sharing the row truncated the one part that identifies the account.
        if (multiple && usage.accountLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              usage.accountLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.textTertiary, fontSize: 12),
            ),
          ),
        const SizedBox(height: 6),
        if (!ok) ...[
          // Five different silences, and conflating them misdirects the
          // operator every time. A plan that reports no windows at all (a fresh
          // account, or one whose org publishes none) is quiet; a plan that
          // answered and is SPENT needs a top-up; a login that lapsed overnight
          // fixes itself on the next run; a login that cannot authenticate at
          // all has quietly dropped out of the rotation and needs a human; a
          // fetch that failed is the only one that is actually breakage. They
          // all used to read "no usage reported for this account".
          Text(
            switch (usage.status) {
              SubscriptionStatus.unconfigured =>
                l10n.subscriptionUsageNoneReported,
              SubscriptionStatus.exhausted => l10n.subscriptionUsageExhausted,
              SubscriptionStatus.signInRequired =>
                l10n.subscriptionUsageSignInRequired,
              SubscriptionStatus.signInExpired =>
                l10n.subscriptionUsageSignInExpired,
              _ => l10n.subscriptionUsageUnavailable,
            },
            style: TextStyle(
              // Colour is additive here, never the carrier: the line states the
              // status in words, so the reading survives without it. Only the
              // two states a person has to DO something about are tinted —
              // `signInExpired` stays muted precisely because every account
              // nobody used overnight is in it by morning.
              color: switch (usage.status) {
                SubscriptionStatus.exhausted => t.danger,
                SubscriptionStatus.signInRequired => t.warn,
                _ => t.textTertiary,
              },
              fontSize: 12,
              fontWeight: actionable ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          // The provider's own sentence — "Credits used up." — says what to do
          // about it where the localized line above only says what happened.
          // Verbatim and unlocalized for the same reason as [accountLabel]:
          // it is a value the provider handed back, not our copy to translate.
          if (exhausted && (usage.error?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 2),
            Text(
              usage.error!.trim(),
              style: TextStyle(color: t.textTertiary, fontSize: 12),
            ),
          ],
        ] else ...[
          for (var i = 0; i < usage.windows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            SubscriptionWindowRow(window: usage.windows[i]),
          ],
          if (spend != null) ...[
            if (usage.windows.isNotEmpty) const SizedBox(height: 8),
            SubscriptionWindowRow(
              window: SubscriptionWindow(
                id: 'spend',
                label: l10n.subscriptionUsageCredits,
                // An UNCAPPED balance has no fraction to draw, so the bar
                // stays empty and the amounts carry the meaning.
                usedFraction: spend.usedFraction,
              ),
              // The dollars are the reading here; a percentage of a $600 cap
              // rounds to "0%" at $1.41 and says nothing. Spent AND cap on one
              // line, because they are one fact — "$1.41 of $600.00" reads as
              // a sentence, where a cap parked under the bar reads as a
              // separate note about something else.
              valueOverride: spend.hasLimit
                  ? l10n.subscriptionUsageSpend(
                      _money(spend.used, spend.currency),
                      _money(spend.limit, spend.currency),
                    )
                  : _money(spend.used, spend.currency),
            ),
          ],
        ],
      ],
    );
  }
}
