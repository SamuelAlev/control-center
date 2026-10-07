import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_editor.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_lanes.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which family of account-pool lanes an agent's runner draws its credential
/// from.
///
/// The ONLY runner-specific thing about account pools on the client: a new
/// runner maps its transport here and every pool surface — this tab, its
/// visibility, the editor — follows. A new harness provider needs nothing.
enum AccountLane {
  /// The Claude Code CLI, which signs in as one of the host's `claude` logins.
  claudeCode,

  /// The built-in harness, which authenticates per provider.
  harness,

  /// A runner that owns its own credential, with nothing here to rotate.
  none;

  /// Whether the pool lane [lane] (from [AccountPoolLanes]) is one this
  /// runner draws from.
  bool covers(String lane) => switch (this) {
    AccountLane.claudeCode => lane == AccountPoolLanes.claudeCode,
    AccountLane.harness => AccountPoolLanes.harnessProviderOf(lane) != null,
    AccountLane.none => false,
  };
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
    AdapterTransport.acp => AccountLane.none,
  };
}

/// The lane [agent] dispatches on, per its saved adapter.
AccountLane accountLaneFor(Agent agent) =>
    accountLaneForAdapter(agent.adapterId);

/// The pool lanes [agentId]'s runner draws from whose editor has something to
/// show — the agent tab's contents, and whether it exists at all.
List<AccountPoolLaneView> watchAgentPoolLanes(
  WidgetRef ref, {
  required String agentId,
  required AccountLane lane,
}) => [
  for (final view in watchAccountPoolLanes(ref))
    if (lane.covers(view.lane) &&
        watchAccountPoolEditorVisible(
          ref,
          AccountPoolScope(lane: view.lane, agentId: agentId),
          view.ids,
        ))
      view,
];

/// Per-agent account pools — this agent's override of the workspace's.
/// Nothing is written until the operator changes something, so an agent that never opens
/// this tab keeps resolving through the workspace exactly as before.
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
    final lanes = watchAgentPoolLanes(ref, agentId: agentId, lane: lane);

    if (lanes.isEmpty) {
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
        for (final view in lanes) ...[
          AccountPoolEditor(
            scope: AccountPoolScope(lane: view.lane, agentId: agentId),
            candidates: view.candidates(l10n),
            title: view.title(l10n),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}
