import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Who a setting affects — the axis the settings surface is organised around.
///
/// The old grouping was by topic (General / Agents / Workspace / Integrations /
/// System), which made sense for a solo, single-workspace desktop tool. Now
/// that the product is multi-user, multi-workspace and multi-device, the
/// question an operator actually asks is "who does changing this affect?" and
/// nothing in the UI answered it: a value in NSUserDefaults on one laptop and a
/// workspace policy every member reads rendered identically.
enum SettingScope {
  /// Follows the signed-in user to every device they sign in from.
  user,

  /// This machine only. Never leaves it — hardware, filesystem paths, window
  /// geometry, or anything read before the RPC session exists.
  device,

  /// Affects everyone in the current workspace.
  workspace,

  /// Affects every workspace on this server install.
  server,
}

/// One settings destination.
@immutable
class SettingsNavItem {
  /// Creates a [SettingsNavItem].
  const SettingsNavItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.route,
    this.matchesSubroutes = false,
  });

  /// Stable identifier, used by tests and to key the route registry.
  final String id;

  /// Leading glyph in the sub-sidebar.
  final IconData icon;

  /// Localized display name.
  final String Function(AppLocalizations) label;

  /// Builds the concrete path for a workspace.
  final String Function(String workspaceId) route;

  /// When true the item stays selected on `<route>/…` children (e.g. the
  /// pipeline-template editor).
  final bool matchesSubroutes;
}

/// A scope-labelled group of settings destinations.
@immutable
class SettingsNavGroup {
  /// Creates a [SettingsNavGroup].
  const SettingsNavGroup({
    required this.scope,
    required this.label,
    required this.items,
  });

  /// The scope every item in this group shares.
  final SettingScope scope;

  /// Localized group heading — "You" / "Workspace" / "Server". The name is the
  /// statement: it says who a change below affects without further prose.
  final String Function(AppLocalizations) label;

  /// The group's destinations, in display order.
  final List<SettingsNavItem> items;
}

/// The settings information architecture — **the single source of truth**.
///
/// The sub-sidebar, the J/K cycle order, the breadcrumb registry and the route
/// title registry all derive from this list. Before it existed, five files each
/// held their own copy of the nav model and drifted: Memory was in the sidebar
/// but missing from the J/K list, so the shortcut silently skipped it and a
/// doc comment described groups ("Resources", "Automation") that no longer
/// existed.
///
/// `settings_nav_test.dart` asserts every registered `GoRoute` under
/// `/settings/` appears here exactly once, so a new page cannot be half-wired.
///
/// Ordering rule: a page has ONE scope. Where a feature genuinely spans scopes
/// it is split and cross-linked rather than filed under its dominant scope with
/// the rest hidden — see the Accounts / Voice / Adapters splits.
const List<SettingsNavGroup> kSettingsNav = [
  SettingsNavGroup(
    scope: SettingScope.user,
    label: _youLabel,
    items: [
      SettingsNavItem(
        id: 'you.profile',
        icon: AppIcons.userCheck,
        label: _profileLabel,
        route: settingsProfileRoute,
      ),
      SettingsNavItem(
        id: 'you.appearance',
        icon: AppIcons.paintbrushVertical,
        label: _appearanceLabel,
        route: settingsAppearanceRoute,
      ),
      SettingsNavItem(
        id: 'you.notifications',
        icon: AppIcons.bell,
        label: _notificationsLabel,
        route: settingsNotificationsRoute,
      ),
      SettingsNavItem(
        id: 'you.keybindings',
        icon: AppIcons.keyboard,
        label: _keybindingsLabel,
        route: settingsKeybindingsRoute,
      ),
      SettingsNavItem(
        id: 'you.audio',
        icon: AppIcons.audioWaveform,
        label: _audioSettingsLabel,
        route: settingsAudioRoute,
      ),
      SettingsNavItem(
        id: 'you.devices',
        icon: AppIcons.smartphone,
        label: _devicesLabel,
        route: settingsRemoteControlRoute,
      ),
      SettingsNavItem(
        id: 'you.newsfeed',
        icon: AppIcons.newspaper,
        label: _newsfeedLabel,
        route: settingsNewsfeedRoute,
      ),
    ],
  ),
  SettingsNavGroup(
    scope: SettingScope.workspace,
    label: _workspaceLabel,
    items: [
      SettingsNavItem(
        id: 'workspace.general',
        icon: AppIcons.slidersHorizontal,
        label: _generalLabel,
        route: settingsWorkspaceGeneralRoute,
      ),
      SettingsNavItem(
        id: 'workspace.members',
        icon: AppIcons.users,
        label: _membersLabel,
        route: settingsMembersRoute,
      ),
      SettingsNavItem(
        id: 'workspace.agents',
        icon: AppIcons.bot,
        label: _agentsLabel,
        route: settingsAgentsRoute,
      ),
      SettingsNavItem(
        id: 'workspace.repositories',
        icon: AppIcons.folderGit2,
        label: _repositoriesLabel,
        route: settingsReposRoute,
      ),
      SettingsNavItem(
        id: 'workspace.skills',
        icon: AppIcons.sparkles,
        label: _skillsLabel,
        route: settingsSkillsRoute,
      ),
      SettingsNavItem(
        id: 'workspace.memory',
        icon: AppIcons.brain,
        label: _memoryLabel,
        route: memoryRoute,
      ),
      SettingsNavItem(
        id: 'workspace.permissions',
        icon: AppIcons.scale,
        label: _permissionsLabel,
        route: settingsGuardrailsRoute,
      ),
      SettingsNavItem(
        id: 'workspace.pipelines',
        icon: AppIcons.workflow,
        label: _pipelinesLabel,
        route: settingsPipelinesRoute,
        matchesSubroutes: true,
      ),
    ],
  ),
  SettingsNavGroup(
    scope: SettingScope.server,
    label: _serverLabel,
    items: [
      SettingsNavItem(
        id: 'server.connection',
        icon: AppIcons.plug,
        label: _connectionLabel,
        route: settingsServerConnectionRoute,
      ),
      SettingsNavItem(
        id: 'server.sso',
        icon: AppIcons.shieldCheck,
        label: _ssoLabel,
        route: settingsSsoRoute,
      ),
      SettingsNavItem(
        id: 'server.providers',
        icon: AppIcons.sparkles,
        label: _providersLabel,
        route: settingsAdaptersRoute,
      ),
      SettingsNavItem(
        id: 'server.mcp',
        icon: AppIcons.puzzle,
        label: _mcpLabel,
        route: settingsMcpRoute,
      ),
      SettingsNavItem(
        id: 'server.voice',
        icon: AppIcons.mic,
        label: _voiceLabel,
        route: settingsVoiceMeetingsRoute,
      ),
      SettingsNavItem(
        id: 'server.rigs',
        icon: AppIcons.monitor,
        label: _rigsLabel,
        route: settingsRigsRoute,
      ),
      SettingsNavItem(
        id: 'server.diagnostics',
        icon: AppIcons.shieldCheck,
        label: _diagnosticsLabel,
        route: settingsDiagnosticsRoute,
      ),
      SettingsNavItem(
        id: 'server.about',
        icon: AppIcons.info,
        label: _aboutLabel,
        route: settingsAboutRoute,
      ),
    ],
  ),
];

/// Every settings destination, flattened in sidebar order.
///
/// This is what the J/K cycle walks, so it cannot drift from what is displayed.
List<SettingsNavItem> get kSettingsNavItems => [
  for (final group in kSettingsNav) ...group.items,
];

/// The scope of the page at [location], or null when it is not a settings page.
///
/// Matches on the scope segment rather than a lookup table so a page added to
/// the router but forgotten here still reports the right scope.
SettingScope? settingScopeForLocation(String location) {
  if (location.startsWith('/settings/you/')) {
    return SettingScope.user;
  }
  if (location.startsWith('/settings/workspace/')) {
    return SettingScope.workspace;
  }
  if (location.startsWith('/settings/server/')) {
    return SettingScope.server;
  }
  return null;
}

// Tear-offs, so the nav model stays a `const` list. A closure would make each
// entry non-const and the whole structure rebuild per frame.
String _youLabel(AppLocalizations l) => l.settingsScopeYou;
String _workspaceLabel(AppLocalizations l) => l.settingsScopeWorkspace;
String _serverLabel(AppLocalizations l) => l.settingsScopeServer;

String _profileLabel(AppLocalizations l) => l.settingsProfile;
String _appearanceLabel(AppLocalizations l) => l.appearance;
String _notificationsLabel(AppLocalizations l) => l.notifications;
String _keybindingsLabel(AppLocalizations l) => l.keybindings;
String _audioSettingsLabel(AppLocalizations l) => l.settingsAudio;
String _devicesLabel(AppLocalizations l) => l.settingsYourDevices;
String _newsfeedLabel(AppLocalizations l) => l.newsfeedLabel;

String _generalLabel(AppLocalizations l) => l.settingsWorkspaceGeneral;
String _membersLabel(AppLocalizations l) => l.membersNav;
String _agentsLabel(AppLocalizations l) => l.agentRegistry;
String _repositoriesLabel(AppLocalizations l) => l.repositories;
String _skillsLabel(AppLocalizations l) => l.skills;
String _memoryLabel(AppLocalizations l) => l.navMemory;
String _permissionsLabel(AppLocalizations l) => l.agentPermissions;
String _pipelinesLabel(AppLocalizations l) => l.pipelineTemplatesNav;

String _connectionLabel(AppLocalizations l) => l.settingsServerConnection;
String _ssoLabel(AppLocalizations l) => l.settingsServerSso;
String _providersLabel(AppLocalizations l) => l.settingsModelProviders;
String _mcpLabel(AppLocalizations l) => l.mcpServers;
String _voiceLabel(AppLocalizations l) => l.settingsVoiceModels;
String _rigsLabel(AppLocalizations l) => l.navRigs;
String _diagnosticsLabel(AppLocalizations l) => l.settingsDiagnostics;
String _aboutLabel(AppLocalizations l) => l.settingsAbout;
