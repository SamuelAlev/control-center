import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/subscription_window_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Harness provider id → the id its plan usage is reported under.
///
/// Only plan-based providers appear: a metered API key has no quota to show, so
/// its tile stays a key field and nothing more. Claude usage is still absent —
/// that snapshot comes from the CLI's own login, a different account from
/// anything connected here.
const Map<String, String> harnessPlanUsageIds = {
  // `zai-coding`, not `zai`: the quota belongs to the GLM Coding Plan, and the
  // plain z.ai lane is a metered key billed against the account balance.
  'zai-coding': 'zai',
  'kimi-code': 'kimi-code',
  // Cursor Ultra/Pro and Codex ChatGPT are the same accounts connected in
  // Settings → Adapters.
  'cursor': 'cursor',
  'codex': 'codex',
  // A Mistral key bills pay-as-you-go unless its organization holds a Vibe
  // plan; see [watchShowsPlanPanel].
  'mistral': 'mistral',
};

/// Plan providers whose key may carry no plan at all. The server drops such
/// keys from the usage list, leaving the provider `unconfigured`.
const Set<String> _planOptionalIds = {'mistral'};

/// Whether [providerId]'s tile shows a [ProviderPlanPanel].
///
/// A dedicated plan always does — "loading" and "unavailable" are both worth
/// saying there. A key that may or may not carry a plan only does once the
/// server has read a plan for it: until then it is a metered key, and a quota
/// block would claim a plan the account may not have.
bool watchShowsPlanPanel(WidgetRef ref, String providerId) {
  final usageId = harnessPlanUsageIds[providerId];
  if (usageId == null) {
    return false;
  }
  if (!_planOptionalIds.contains(providerId)) {
    return true;
  }
  return ref.watch(
    subscriptionUsageProvider.select(
      (async) => (async.value ?? const <SubscriptionUsage>[]).any(
        (u) =>
            u.providerId == usageId &&
            u.status != SubscriptionStatus.unconfigured,
      ),
    ),
  );
}

/// The connected-plan block on a Settings → Adapters provider tile: which
/// account is signed in and what the plan has left. Disconnecting lives on the
/// credential rows of the login panel, one row per connected account.
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
    super.key,
  });

  /// Harness provider id (e.g. `kimi-code`).
  final String providerId;

  /// The signed-in identity to name — an email when the provider reports one,
  /// otherwise whatever label the credential carries. Null renders no account
  /// line, never a placeholder.
  final String? accountLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem;
    final usageId = harnessPlanUsageIds[providerId];
    // .value, not asData: a background refresh holds loading-with-previous and
    // blanking a quota the user is reading would be worse than showing it a few
    // seconds stale.
    final all = usageId == null
        ? const <SubscriptionUsage>[]
        : ref.watch(subscriptionUsageProvider).value ??
              const <SubscriptionUsage>[];
    SubscriptionUsage? labeled;
    SubscriptionUsage? first;
    for (final u in all) {
      if (u.providerId != usageId) {
        continue;
      }
      first ??= u;
      // Several accounts of the same plan: pick the one this tile is
      // showing. Fall through to the first snapshot when the live list has
      // not stamped labels yet (a single-account install).
      if (accountLabel != null && u.accountLabel == accountLabel) {
        labeled = u;
        break;
      }
    }
    final usage = labeled ?? first;
    final windows = usage?.status == SubscriptionStatus.ok
        ? usage!.windows
        : const <SubscriptionWindow>[];

    final label = accountLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: t?.textPrimary),
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
