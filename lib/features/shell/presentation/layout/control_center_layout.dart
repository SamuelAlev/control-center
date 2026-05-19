import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_recording_hud.dart';
import 'package:control_center/features/shell/presentation/layout/shell_title_bar.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Root shell layout: a left [AppSidebar] for primary navigation, a slim top
/// bar (breadcrumb, search, notifications, focus), and the routed content area.
/// Settings and newsfeed expose a contextual second sidebar next to content.
class ControlCenterLayout extends ConsumerStatefulWidget {
  /// Creates a [ControlCenterLayout].
  const ControlCenterLayout({super.key, required this.child});

  /// The routed content widget rendered in the main area.
  final Widget child;

  @override
  ConsumerState<ControlCenterLayout> createState() => _ControlCenterLayoutState();
}

class _ControlCenterLayoutState extends ConsumerState<ControlCenterLayout> {
  /// Free-text filter for the settings sub-sidebar. Lets the operator jump to
  /// a category by name instead of scanning a 14-item list.
  final TextEditingController _settingsFilterController = TextEditingController();
  String _settingsFilter = '';

  @override
  void initState() {
    super.initState();
    _settingsFilterController.addListener(() {
      final next = _settingsFilterController.text;
      if (next != _settingsFilter) {
        setState(() => _settingsFilter = next);
      }
    });
  }

  @override
  void dispose() {
    _settingsFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Feed the active route to the keybinding dispatcher so `route == '...'`
    // when-clauses gate screen-scoped shortcuts correctly (e.g. the PR list's
    // bare-key shortcuts stay off while the detail page is open over it).
    // Idempotent: a no-op when the route is unchanged.
    ref.read(keybindingDispatcherProvider).setRoute(location);
    final inSettings = location.startsWith(settingsRoute);
    final historyNotifier = ref.read(navigationHistoryProvider.notifier);
    final navState = ref.watch(navigationHistoryProvider);

    return MouseNavigationHandler(
      historyController: historyNotifier,
      child: Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                // Primary navigation.
                AppSidebar(location: location),
                // Top bar + content.
                Expanded(
                  child: Column(
                    children: [
                      ShellTitleBar(
                        canGoBack: navState.canGoBack,
                        canGoForward: navState.canGoForward,
                        onGoBack: historyNotifier.goBack,
                        onGoForward: historyNotifier.goForward,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (inSettings)
                              CcSidebar(
                                width: 240,
                                trailingBorder: BorderSide(
                                  color: (context.designSystem ??
                                          DesignSystemTokens.light())
                                      .borderPrimary,
                                ),
                                header: _SettingsSidebarHeader(
                                  controller: _settingsFilterController,
                                ),
                                children: _buildSettingsGroups(
                                  context,
                                  location,
                                  needsIntegrationSetup:
                                      _integrationsNeedSetup(),
                                ),
                              ),
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Floating recording HUD — persists across navigation while a
            // meeting is being recorded.
            const MeetingRecordingHud(),
          ],
        ),
      ),
    );
  }

  // ── Settings contextual sub-sidebar ───────────────────────────────────
  //
  // Categories are grouped (General / Agents / Resources / Automation) so the
  // operator can predict where a setting lives instead of scanning one flat
  // list. The header filter narrows the visible items by name.

  /// True when neither a GitHub PAT nor an authenticated `gh` CLI is available,
  /// so agents can't reach GitHub — surfaced as an attention dot on the
  /// Integrations category.
  bool _integrationsNeedSetup() {
    final credentials =
        ref.watch(credentialsProvider).asData?.value ?? const ApiCredentials();
    final cli = ref.watch(githubCliStatusProvider).value;
    final githubReady =
        credentials.hasGitHubToken || (cli?.isAuthenticated ?? false);
    return !githubReady;
  }

  List<Widget> _buildSettingsGroups(
    BuildContext context,
    String location, {
    required bool needsIntegrationSetup,
  }) {
    final l10n = AppLocalizations.of(context);
    final filter = _settingsFilter.trim().toLowerCase();

    CcSidebarItem? item(IconData icon, String label, String route,
        {bool exact = true, bool attention = false}) {
      if (filter.isNotEmpty && !label.toLowerCase().contains(filter)) {
        return null;
      }
      final selected = exact
          ? location == route
          : (location == route || location.startsWith('$route/'));
      return CcSidebarItem(
        icon: icon,
        label: label,
        badge: attention
            ? _AttentionDot(semanticLabel: l10n.needsSetupLabel)
            : null,
        selected: selected,
        onPressed: () => context.go(route),
      );
    }

    CcSidebarGroup? group(String label, List<CcSidebarItem?> items) {
      final visible = items.whereType<CcSidebarItem>().toList();
      if (visible.isEmpty) {
        return null;
      }
      return CcSidebarGroup(
        label: label,
        children: visible,
      );
    }

    final groups = <CcSidebarGroup?>[
      group(l10n.settingsGroupGeneral, [
        item(LucideIcons.settings2, l10n.appearance, settingsAppearanceRoute),
        item(LucideIcons.bell, l10n.notifications, settingsNotificationsRoute),
        item(LucideIcons.keyboard, l10n.keybindings, settingsKeybindingsRoute),
        item(LucideIcons.slidersHorizontal, l10n.advanced, settingsAdvancedRoute),
      ]),
      group(l10n.settingsGroupAgents, [
        item(LucideIcons.bot, l10n.agentRegistry, settingsAgentsRoute),
        item(LucideIcons.plug, l10n.adapters, settingsAdaptersRoute),
        item(LucideIcons.sparkles, l10n.skills, settingsSkillsRoute),
        item(LucideIcons.workflow, l10n.pipelineTemplatesNav,
            settingsPipelinesRoute,
            exact: false),
        item(LucideIcons.shield, l10n.sandboxing, settingsSandboxingRoute),
        item(LucideIcons.users, l10n.teamsNav, teamsRoute),
      ]),
      group(l10n.settingsGroupResources, [
        item(LucideIcons.folderGit2, l10n.repositories, settingsReposRoute),
        item(LucideIcons.cable, l10n.integrations, settingsIntegrationsRoute,
            attention: needsIntegrationSetup),
      ]),
    ];

    final visibleGroups = groups.whereType<CcSidebarGroup>().toList();
    if (visibleGroups.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text(
            l10n.noSettingsMatch(_settingsFilter.trim()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.designSystem?.textTertiary,
                ),
          ),
        ),
      ];
    }
    return visibleGroups;
  }
}

/// Header for the settings sub-sidebar: a title row plus a name filter that
/// narrows the category list below.
class _SettingsSidebarHeader extends StatelessWidget {
  const _SettingsSidebarHeader({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.settings,
                  size: 16, color: context.designSystem?.textTertiary),
              const SizedBox(width: 8),
              Text(
                l10n.navSettings,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CcTextField(
            controller: controller,
            hintText: l10n.filterSettingsHint,
          ),
        ],
      ),
    );
  }
}

/// A small caution-amber dot that flags a settings category needing setup.
/// Paired with a [Semantics] label so it isn't status-by-color-alone.
class _AttentionDot extends StatelessWidget {
  const _AttentionDot({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.designSystem?.fgWarningPrimary ?? const Color(0xFFCA8504);
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
