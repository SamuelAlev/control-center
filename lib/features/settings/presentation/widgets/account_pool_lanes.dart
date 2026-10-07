import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart'
    show ClaudeAccountView;
import 'package:cc_domain/features/subscriptions/subscriptions.dart'
    show SubscriptionUsage;
import 'package:cc_harness/provider.dart' show HarnessProviderInfo;
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_rotation_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_account_row.dart'
    show claudeShortTime, claudeWindowFact;
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One lane an account pool can be attached to, as the settings surfaces show
/// it: what to call it, which credentials exist on it, and their editor rows.
///
/// Rows are a builder rather than a list so the catalog itself needs no
/// localizations — a tab's visibility check reads [ids] without a context.
class AccountPoolLaneView {
  /// Creates an [AccountPoolLaneView].
  const AccountPoolLaneView({
    required this.lane,
    required this.title,
    required this.ids,
    required this.candidates,
  });

  /// The lane id, from [AccountPoolLanes].
  final String lane;

  /// The heading above this lane's editor.
  final String Function(AppLocalizations l10n) title;

  /// Every credential that exists on this lane right now.
  final List<String> ids;

  /// This lane's editor rows.
  final List<AccountPoolCandidate> Function(AppLocalizations l10n) candidates;
}

/// Every lane this install can attach accounts on — the ONE place a lane's
/// credentials become editor rows, shared by the agent tab and the
/// workspace-level editors.
///
/// A new harness provider needs nothing here: it appears as soon as it holds a
/// credential. A runner with its own logins adds one entry, and every surface
/// that edits pools picks it up.
List<AccountPoolLaneView> watchAccountPoolLanes(WidgetRef ref) {
  final claude = ref.watch(claudeAccountsProvider).asData?.value ?? const [];
  final providers = [
    for (final p
        in ref.watch(harnessProvidersProvider).asData?.value ??
            const <HarnessProviderInfo>[])
      if (p.credentials.isNotEmpty) p,
  ];
  // Only harness rows read plan usage, so a Claude-only install never asks.
  final usage = providers.isEmpty
      ? const <SubscriptionUsage>[]
      : ref.watch(subscriptionUsageProvider).value ?? const [];
  return [
    if (claude.isNotEmpty)
      AccountPoolLaneView(
        lane: AccountPoolLanes.claudeCode,
        title: (l10n) => l10n.claudeAccountsTitle,
        ids: [for (final v in claude) v.account.id],
        candidates: (l10n) => claudePoolCandidates(l10n, claude),
      ),
    for (final p in providers)
      AccountPoolLaneView(
        lane: AccountPoolLanes.harness(p.id),
        title: (_) => p.displayName,
        ids: [for (final c in p.credentials) c.credentialId],
        candidates: (l10n) =>
            harnessRotationCandidates(info: p, l10n: l10n, usage: usage),
      ),
  ];
}

/// Editor rows for the host's Claude Code logins.
List<AccountPoolCandidate> claudePoolCandidates(
  AppLocalizations l10n,
  List<ClaudeAccountView> views,
) => [
  for (final v in views)
    AccountPoolCandidate(
      id: v.account.id,
      label: v.account.label,
      detail: _claudeDetail(l10n, v),
      unavailable: !v.account.loggedIn || v.account.isRateLimited(),
      // A lapsed access token is still usable — the CLI renews it on the next
      // run — so it is not [AccountPoolCandidate.unavailable]. The reason still
      // has to show, or the roster disagrees with the usage flyout.
      unavailableReason: v.account.loggedIn && v.account.isCredentialExpired()
          ? l10n.subscriptionUsageSignInExpired
          : !v.account.loggedIn && v.account.isCredentialExpired()
          ? l10n.accountPoolExpired
          : !v.account.loggedIn
          ? l10n.accountPoolSignedOut
          : v.account.isRateLimited()
          ? l10n.accountPoolCoolingOff(
              claudeShortTime(v.account.rateLimitedUntil!),
            )
          : null,
    ),
];

/// `max · Weekly: 62% used` — what makes one account the better pick.
String? _claudeDetail(AppLocalizations l10n, ClaudeAccountView view) {
  final window = view.tightestWindow;
  final parts = [
    if (view.account.subtitle.isNotEmpty) view.account.subtitle,
    if (window != null) claudeWindowFact(l10n, window),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
