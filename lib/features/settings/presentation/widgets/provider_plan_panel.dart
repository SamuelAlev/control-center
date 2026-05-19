import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_window_row.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Harness provider id → the id its plan usage is reported under.
///
/// Only plan-based providers appear: a metered API key has no quota to show, so
/// its tile stays a key field and nothing more. `claude`/`codex` usage is
/// deliberately absent — those snapshots come from the CLIs' own logins, which
/// are a different account from anything connected here, and showing one under
/// the other's tile would misattribute the quota.
const Map<String, String> harnessPlanUsageIds = {
  'zai': 'zai',
  'kimi-code': 'kimi-code',
};

/// The connected-plan block on a Settings → Adapters provider tile: which
/// account is signed in, what the plan has left, and the action to disconnect.
///
/// A plan is not a key — "connected" is not the useful fact about it, "how much
/// is left and until when" is. This surfaces the same live quota the title-bar
/// pill shows, at the place where the account is managed, so the operator does
/// not have to cross-reference two surfaces to answer "can I still run this?".
class ProviderPlanPanel extends ConsumerWidget {
  /// Creates a [ProviderPlanPanel].
  const ProviderPlanPanel({
    required this.providerId,
    required this.accountLabel,
    this.trailing,
    super.key,
  });

  /// Harness provider id (e.g. `kimi-code`).
  final String providerId;

  /// The signed-in identity to name — an email when the provider reports one,
  /// otherwise whatever label the credential carries. Null renders no account
  /// line, never a placeholder.
  final String? accountLabel;

  /// The disconnect action, placed on the account row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem;
    final usageId = harnessPlanUsageIds[providerId];
    // .value, not asData: a background refresh holds loading-with-previous, and
    // blanking a quota the user is reading would be worse than showing it a few
    // seconds stale.
    final all = usageId == null
        ? const <SubscriptionUsage>[]
        : ref.watch(subscriptionUsageProvider).value ??
              const <SubscriptionUsage>[];
    SubscriptionUsage? usage;
    for (final u in all) {
      if (u.providerId == usageId) {
        usage = u;
      }
    }
    final windows = usage?.status == SubscriptionStatus.ok
        ? usage!.windows
        : const <SubscriptionWindow>[];

    final label = accountLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: label == null
                  ? const SizedBox.shrink()
                  : Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: t?.textPrimary),
                    ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        if (windows.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (var i = 0; i < windows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            SubscriptionWindowRow(window: windows[i]),
          ],
        ] else if (usageId != null) ...[
          const SizedBox(height: 6),
          Text(
            // Distinguish "the plan reports nothing" from "we haven't asked
            // yet" — an empty meter with no explanation reads as zero usage.
            usage == null
                ? l10n.providerPlanUsageLoading
                : l10n.providerPlanUsageUnavailable,
            style: TextStyle(fontSize: 11, color: t?.textTertiary),
          ),
        ],
      ],
    );
  }
}
