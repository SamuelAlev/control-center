import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_account_pools_tab.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What `settings` itself contributes to the agent registry's detail pane.
///
/// Account pools are the one thing settings genuinely OWNS at agent scope: the
/// pool editor and the accounts card already live here, and the tab imports no
/// other feature's presentation, so contributing it from settings keeps the
/// one-way dependency the registry exists to enforce.
const List<AgentSettingsTab> settingsAgentSettingsTabs = [
  AgentSettingsTab(
    id: 'settings.account-pools',
    label: _accountsLabel,
    order: 20,
    builder: _buildAccountPools,
    visible: agentHasAccountsToRotate,
  ),
];

Widget _buildAccountPools(BuildContext context, Agent agent) =>
    AgentAccountPoolsTab(agentId: agent.id, lane: accountLaneFor(agent));

/// Whether [agent]'s runner has any pool editor worth showing — the same
/// lanes and the same visibility rule the tab itself renders, so the tab never
/// opens onto an empty state.
///
/// The tab used to list EVERY lane unconditionally, on the reasoning that an
/// agent's adapter can change and inferring one lane would hide the pool that
/// mattered. In practice that put an "Accounts" tab on every agent — including
/// the common install with a single Claude login and no rotatable provider,
/// where opening it only ever produced an empty state. Nothing is lost by
/// hiding it: an agent whose adapter changes re-evaluates this on the next
/// build, and a pool that was written while the tab was visible keeps
/// resolving server-side whether or not the editor is on screen.
bool agentHasAccountsToRotate(WidgetRef ref, Agent agent) =>
    watchAgentPoolLanes(
      ref,
      agentId: agent.id,
      lane: accountLaneFor(agent),
    ).isNotEmpty;

// Tear-off, so the contribution list stays `const`.
String _accountsLabel(AppLocalizations l) => l.agentAccountsTab;
