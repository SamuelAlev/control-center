import 'package:cc_data/cc_data.dart' show RpcAccountPoolsRepository;
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-agent account pools — this agent's override of the workspace's.
///
/// ## Why it lists every lane rather than the agent's own adapter
///
/// An agent's adapter can change, and the model syntax lets one run reach a
/// second provider mid-chain, so "the lane this agent uses" is not a single
/// stable answer. Showing every lane that HAS something to choose between costs
/// a heading each and is never wrong; inferring one lane would silently hide
/// the pool that actually mattered the day the adapter changed.
///
/// Every block starts out inheriting. Nothing is written until the operator
/// changes something, so an agent that never opens this tab keeps resolving
/// through the workspace exactly as before.
class AgentAccountPoolsTab extends ConsumerWidget {
  /// Creates an [AgentAccountPoolsTab] for [agentId].
  const AgentAccountPoolsTab({required this.agentId, super.key});

  /// The agent whose overrides are edited here.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final claude = ref.watch(claudeAccountsProvider).asData?.value ?? const [];
    final providers =
        ref.watch(harnessProvidersProvider).asData?.value ?? const [];
    final rotatable = [
      for (final p in providers)
        if (p.credentials.length > 1) p,
    ];

    if (claude.length < 2 && rotatable.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CcEmptyState(
          icon: AppIcons.user,
          message: l10n.agentAccountsNothingToRotate,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.agentAccountsDescription,
          style: TextStyle(fontSize: 12, color: t.fgSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (claude.length > 1) ...[
          _Heading(label: l10n.claudeAccountsTitle),
          AccountPoolEditor(
            scope: AccountPoolScope(
              lane: RpcAccountPoolsRepository.claudeLane,
              agentId: agentId,
            ),
            candidates: [
              for (final v in claude)
                AccountPoolCandidate(
                  id: v.account.id,
                  label: v.account.label,
                  detail: v.account.subtitle,
                  unavailable: !v.account.loggedIn || v.account.isRateLimited(),
                  unavailableReason: !v.account.loggedIn
                      ? l10n.accountPoolSignedOut
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        for (final p in rotatable) ...[
          _Heading(label: p.displayName),
          AccountPoolEditor(
            scope: AccountPoolScope(
              lane: RpcAccountPoolsRepository.harnessLane(p.id),
              agentId: agentId,
            ),
            candidates: [
              for (final cred in p.credentials)
                AccountPoolCandidate(
                  id: cred.credentialId,
                  label: cred.label?.isNotEmpty ?? false
                      ? cred.label!
                      : cred.hint ?? cred.credentialId,
                  detail: cred.method == HarnessAuthMethod.oauth
                      ? l10n.providerSignedInAccount
                      : cred.hint,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.fgPrimary,
        ),
      ),
    );
  }
}
