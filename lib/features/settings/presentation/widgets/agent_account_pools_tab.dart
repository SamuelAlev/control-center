import 'package:cc_data/cc_data.dart' show RpcAccountPoolsRepository;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
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

/// Which account lane an agent's runner draws its credential from.
enum AccountLane {
  /// The Claude Code CLI, which signs in as one of the host's `claude` logins.
  claudeCode,

  /// The built-in harness, which authenticates per provider.
  harness,

  /// A runner that owns its own credential, with nothing here to rotate.
  none,
}

/// The lane the runner [adapterId] names draws its credential from.
///
/// A null id is the built-in harness, not "no adapter" — the same fallback
/// `DispatchAgentUseCase` applies, and the two must agree or a surface here
/// describes a lane the run does not use. Keyed on the TRANSPORT rather than
/// the adapter id, so a second Claude-CLI runner needs no change here.
AccountLane accountLaneForAdapter(String? adapterId) {
  final adapter =
      predefinedAdapters.where((a) => a.id == adapterId).firstOrNull ??
      builtInAdapter;
  return switch (adapter.transport) {
    AdapterTransport.claudeCli => AccountLane.claudeCode,
    AdapterTransport.harness => AccountLane.harness,
    AdapterTransport.acp || AdapterTransport.structuredCli => AccountLane.none,
  };
}

/// The lane [agent] dispatches on, per its saved adapter.
AccountLane accountLaneFor(Agent agent) =>
    accountLaneForAdapter(agent.adapterId);

/// Per-agent account pools — this agent's override of the workspace's.
///
/// ## Why it shows the agent's own lane
///
/// This listed EVERY lane at first, on the reasoning that an agent's adapter
/// can change and inferring one lane would hide the pool that mattered the day
/// it did. But the cost of that landed on every other agent: an "Accounts" tab
/// on a harness agent that headed a block of Claude Code logins it cannot use.
/// The tab is now gated and scoped by transport (`agentHasAccountsToRotate` /
/// `accountLaneFor`); an adapter change re-evaluates both on the next build,
/// and a pool written earlier keeps resolving server-side regardless.
///
/// The harness lane deliberately stays plural. One run can reach a second
/// provider mid-chain through the `a/b|c/d` model syntax, so every provider
/// with something to choose between is in scope for a harness agent.
///
/// Every block starts out inheriting. Nothing is written until the operator
/// changes something, so an agent that never opens this tab keeps resolving
/// through the workspace exactly as before.
class AgentAccountPoolsTab extends ConsumerWidget {
  /// Creates an [AgentAccountPoolsTab] for [agentId].
  const AgentAccountPoolsTab({
    required this.agentId,
    required this.lane,
    super.key,
  });

  /// The agent whose overrides are edited here.
  final String agentId;

  /// The lane this agent dispatches on, and the only one shown.
  final AccountLane lane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final claude = lane == AccountLane.claudeCode
        ? ref.watch(claudeAccountsProvider).asData?.value ?? const []
        : const <ClaudeAccountView>[];
    final rotatable = lane == AccountLane.harness
        ? ref.watch(rotatableHarnessProvidersProvider)
        : const <HarnessProviderInfo>[];

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
