import 'package:cc_data/cc_data.dart' show RpcAccountPoolsRepository;
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness/provider.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/provider_plan_panel.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart'
    show claudeWindowFact;
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Candidates for one harness provider's pinned / round-robin / serial pool.
///
/// Same shape the Claude Code adapter feeds [AccountPoolEditor]: identity,
/// remaining quota, and whether the account cannot serve a run right now.
List<AccountPoolCandidate> harnessRotationCandidates({
  required HarnessProviderInfo info,
  required AppLocalizations l10n,
  List<SubscriptionUsage> usage = const [],
}) {
  final usageId = harnessPlanUsageIds[info.id];
  return [
    for (final cred in info.credentials)
      () {
        final snap = _usageFor(usage, usageId, cred);
        final peak = snap?.peakWindow;
        return AccountPoolCandidate(
          id: cred.credentialId,
          // A key has no name, only a masked tail — which is still the only
          // thing that tells two of them apart.
          label: cred.label?.isNotEmpty ?? false
              ? cred.label!
              : cred.hint ?? cred.credentialId,
          detail: peak != null
              ? claudeWindowFact(l10n, peak)
              : cred.method == HarnessAuthMethod.oauth
              ? l10n.providerSignedInAccount
              : cred.hint,
          unavailable:
              snap?.status == SubscriptionStatus.exhausted ||
              snap?.status == SubscriptionStatus.signInRequired,
          unavailableReason: switch (snap?.status) {
            SubscriptionStatus.exhausted =>
              snap?.error?.trim().isNotEmpty == true
                  ? snap!.error
                  : l10n.subscriptionUsageExhausted,
            SubscriptionStatus.signInRequired =>
              l10n.subscriptionUsageSignInRequired,
            SubscriptionStatus.signInExpired =>
              l10n.subscriptionUsageSignInExpired,
            _ => null,
          },
        );
      }(),
  ];
}

SubscriptionUsage? _usageFor(
  List<SubscriptionUsage> all,
  String? usageId,
  HarnessCredentialSummary cred,
) {
  if (usageId == null) {
    return null;
  }
  for (final u in all) {
    if (u.providerId == usageId && u.accountId == cred.credentialId) {
      return u;
    }
  }
  for (final u in all) {
    if (u.providerId == usageId &&
        cred.label != null &&
        u.accountLabel == cred.label) {
      return u;
    }
  }
  final matches = [for (final u in all) if (u.providerId == usageId) u];
  if (matches.length == 1 && matches.single.accountId == null) {
    return matches.single;
  }
  return null;
}

/// The rotation control for one harness provider's stored credentials.
///
/// The same editor the Claude Code adapter uses, because the decision is the
/// same one — which keys may be spent, in what order, and whether to drain them
/// or spread across them. What differs is only the mechanism underneath: here
/// the fallback chain swaps credential mid-stream, so the pool decides which
/// one LEADS rather than which one runs alone.
class HarnessRotationEditor extends ConsumerWidget {
  /// Creates a [HarnessRotationEditor].
  const HarnessRotationEditor({required this.info, super.key});

  /// The provider whose credentials are being ordered.
  final HarnessProviderInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(subscriptionUsageProvider).value ?? const [];
    return AccountPoolEditor(
      scope: AccountPoolScope(
        lane: RpcAccountPoolsRepository.harnessLane(info.id),
      ),
      candidates: harnessRotationCandidates(
        info: info,
        l10n: l10n,
        usage: all,
      ),
    );
  }
}
