import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_account_pools_tab.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

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
  ),
];

Widget _buildAccountPools(BuildContext context, Agent agent) =>
    AgentAccountPoolsTab(agentId: agent.id);

// Tear-off, so the contribution list stays `const`.
String _accountsLabel(AppLocalizations l) => l.agentAccountsTab;
