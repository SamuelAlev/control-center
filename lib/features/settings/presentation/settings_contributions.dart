import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_account_pools_tab.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_apps_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sync_health_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_gifs_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_own_app_card.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What `settings` itself puts on Server → Single sign-on: this server's own
/// provider apps, below the Connect card that decides whether they are needed.
///
/// On Workspace → Integrations, each in its provider's band: the workspace's
/// own Linear and Google Calendar apps (only while it uses its own apps),
/// ticket sync health beside the ticketing card it reports on, and where GIF
/// search runs (with the workspace's Klipy key in its own-apps mode).
const List<SettingsSectionContribution> settingsSettingsSections = [
  SettingsSectionContribution(
    id: 'settings.provider-apps',
    slot: SettingsSlot.serverSignIn,
    order: 20,
    builder: _buildProviderApps,
    visible: watchProviderAppsApplies,
  ),
  SettingsSectionContribution(
    id: 'settings.workspace-app.linear',
    slot: SettingsSlot.workspaceIntegrations,
    order: 32,
    builder: _buildWorkspaceLinearApp,
    visible: _workspaceLinearAppApplies,
  ),
  SettingsSectionContribution(
    id: 'settings.sync-health',
    slot: SettingsSlot.workspaceIntegrations,
    order: 33,
    builder: _buildSyncHealth,
    visible: watchSyncHealthApplies,
  ),
  SettingsSectionContribution(
    id: 'settings.workspace-app.google',
    slot: SettingsSlot.workspaceIntegrations,
    order: 41,
    builder: _buildWorkspaceGoogleApp,
    visible: _workspaceGoogleAppApplies,
  ),
  SettingsSectionContribution(
    id: 'settings.gifs',
    slot: SettingsSlot.workspaceIntegrations,
    order: 60,
    builder: _buildGifs,
    visible: watchWorkspaceGifsApplies,
  ),
];

Widget _buildProviderApps(BuildContext context) => const ProviderAppsSection();

Widget _buildWorkspaceLinearApp(BuildContext context) =>
    const WorkspaceOwnAppCard(provider: 'linear');

Widget _buildSyncHealth(BuildContext context) => const SyncHealthCard();

Widget _buildWorkspaceGoogleApp(BuildContext context) =>
    const WorkspaceOwnAppCard(provider: 'google');

Widget _buildGifs(BuildContext context) => const WorkspaceGifsCard();

// Tear-offs, so the contribution list stays `const`.
bool _workspaceLinearAppApplies(WidgetRef ref) =>
    watchWorkspaceOwnAppApplies(ref, 'linear');

bool _workspaceGoogleAppApplies(WidgetRef ref) =>
    watchWorkspaceOwnAppApplies(ref, 'google');

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
