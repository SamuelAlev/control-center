import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Height of one line of the usage section: a provider's name, a window.
const double trayUsageLineHeight = 22;

/// Width of a window's name column, so the meters line up across providers.
const double trayUsageLabelWidth = 76;

/// A meter to draw: a plan window, or the credits of an account billed per
/// token, which read in money (`value`, with the cap in `detail`) where a
/// share of the cap would round to nothing.
typedef TrayUsageReading = ({
  SubscriptionWindow window,
  String? value,
  String? detail,
});

/// A compact line with no meter: the provider column, then [child] where
/// the meter goes.
class TrayUsageLine extends StatelessWidget {
  /// Creates a [TrayUsageLine].
  const TrayUsageLine({
    required this.leading,
    required this.leadingWidth,
    required this.child,
    super.key,
  });

  /// The provider.
  final Widget leading;

  /// The provider column's width, shared by every line.
  final double leadingWidth;

  /// What stands in for the meter.
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: trayUsageLineHeight),
    child: Row(
      children: [
        SizedBox(
          width: leadingWidth,
          height: trayUsageLineHeight,
          child: leading,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: child),
      ],
    ),
  );
}

/// An account's state in place of its meters; [tint] (an error or warning
/// the person has to act on) adds the alert glyph. Wraps rather than cuts.
class TrayUsageNote extends StatelessWidget {
  /// Creates a [TrayUsageNote].
  const TrayUsageNote({required this.text, required this.tint, super.key});

  /// The state, in words.
  final String text;

  /// The color of a state to act on; null for a quiet one.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = tint ?? t.textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tint != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(AppIcons.triangleAlert, size: 12, color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// What is left on a prepaid account, at the line's end.
class TrayBalanceAmount extends StatelessWidget {
  /// Creates a [TrayBalanceAmount].
  const TrayBalanceAmount({required this.balance, super.key});

  /// The balance to show.
  final SubscriptionBalance balance;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      formatSubscriptionMoney(balance.amount, balance.currency),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: CcFonts.numeric(
        textStyle: CcTypography.numeric,
      ).copyWith(color: t.textPrimary),
    );
  }
}

/// A prepaid balance on one line: its name, then the amount where a window
/// has its share used. No meter, because nothing caps it.
class TrayBalanceLine extends StatelessWidget {
  /// Creates a [TrayBalanceLine].
  const TrayBalanceLine({required this.balance, super.key});

  /// The balance to show.
  final SubscriptionBalance balance;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: trayUsageLineHeight,
      child: Row(
        children: [
          SizedBox(
            width: trayUsageLabelWidth,
            child: Text(
              l10n.subscriptionUsageBalance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: TrayBalanceAmount(balance: balance)),
        ],
      ),
    );
  }
}

/// One reading on one line: its name (or [leading], the provider, on a
/// compact line), a meter, then the share used and the time to its reset,
/// or the amount spent across both.
class TrayWindowMeter extends StatelessWidget {
  /// Creates a [TrayWindowMeter].
  const TrayWindowMeter({
    required this.reading,
    this.leading,
    this.leadingWidth = trayUsageLabelWidth,
    super.key,
  });

  /// What to draw.
  final TrayUsageReading reading;

  /// The provider, on a compact line; the window's name otherwise.
  final Widget? leading;

  /// The first column's width.
  final double leadingWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final window = reading.window;
    final value = reading.value;
    final detail = reading.detail;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final percent = NumberFormat.percentPattern(
      locale,
    ).format(window.usedFraction.clamp(0, 1));
    final reset = window.resetsAt;
    final numeric = CcFonts.numeric(textStyle: CcTypography.numeric);
    // The provider's own label, not ours ("5-hour"): isolated so an RTL
    // panel keeps its order instead of reading "hour-5".
    final label = '\u2068${window.label}\u2069';
    final meter = CcProgressBar(
      value: window.usedFraction,
      color: subscriptionUsageColor(window.usedFraction, t),
      trackColor: t.hoverStrong,
      semanticLabel:
          '${window.label}: '
          '${value ?? l10n.subscriptionUsagePercentUsed((window.usedFraction * 100).round())}',
    );
    Widget amount = Text(
      value ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: numeric.copyWith(color: t.textPrimary),
    );
    if (detail != null) {
      amount = CcTooltip(message: detail, child: amount);
    }
    return SizedBox(
      height: trayUsageLineHeight,
      child: Row(
        children: [
          SizedBox(
            width: leadingWidth,
            child:
                leading ??
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // A compact line names its window only on hover.
          Expanded(
            child: leading == null
                ? meter
                : CcTooltip(message: label, child: meter),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (value != null)
            SizedBox(width: 96, child: amount)
          else ...[
            SizedBox(
              width: 40,
              child: Text(
                percent,
                textAlign: TextAlign.end,
                style: numeric.copyWith(color: t.textPrimary),
              ),
            ),
            SizedBox(
              width: 56,
              child: reset == null
                  ? null
                  : CcTooltip(
                      message: l10n.resetsIn(formatSubscriptionReset(reset)),
                      child: Text(
                        formatSubscriptionReset(reset),
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: numeric.copyWith(color: t.textTertiary),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
