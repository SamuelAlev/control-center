import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_channel_auto_open.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_recording_hud.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_overlay.dart';
import 'package:control_center/features/messaging/presentation/widgets/channels_sub_sidebar.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/shell/presentation/layout/shell_title_bar.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:control_center/features/shell/presentation/widgets/banner_rail.dart';
import 'package:control_center/features/shell/presentation/widgets/web_update_banner.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_audio_host.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root shell layout: a FULL-WIDTH [ShellTitleBar] on top (its bottom hairline
/// runs edge to edge and, on macOS, its content clears the traffic-light
/// cluster), then a row of the left [AppSidebar] (which therefore starts below
/// the bar — no border segment runs up beside the traffic lights) and the
/// routed content area. Settings exposes a contextual second sidebar next to
/// content; the channels surface gets one too while the global sidebar is
/// collapsed to its rail.
class ControlCenterLayout extends ConsumerStatefulWidget {
  /// Creates a [ControlCenterLayout].
  const ControlCenterLayout({super.key, required this.child});

  /// The routed content widget rendered in the main area.
  final Widget child;

  @override
  ConsumerState<ControlCenterLayout> createState() =>
      _ControlCenterLayoutState();
}

class _ControlCenterLayoutState extends ConsumerState<ControlCenterLayout> {
  /// Free-text filter for the settings sub-sidebar. Lets the operator jump to
  /// a category by name instead of scanning a 14-item list.
  final TextEditingController _settingsFilterController =
      TextEditingController();
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
    // Presence idle detection (PRD 16 §1): any hardware key registers as
    // activity. Never marks the event handled — this must never steal a key
    // from the app's real shortcut/input handling.
    HardwareKeyboard.instance.addHandler(_onKeyEventTouch);
    // Desktop in-app updater (Sparkle/WinSparkle): arm the check schedule
    // once the shell is live (past the boot path). The busy probe defers any
    // prompt while a meeting is recording — never interrupt it with an
    // update dialog. No-op on web.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(desktopUpdateProvider.notifier)
            .start(
              busyProbe: () =>
                  ref.read(meetingRecorderControllerProvider).isRecording,
            );
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEventTouch);
    _settingsFilterController.dispose();
    super.dispose();
  }

  bool _onKeyEventTouch(KeyEvent event) {
    ref.read(myPresenceProvider.notifier).touch();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final location = routerState.matchedLocation;
    // The shell only renders for `/workspaces/:workspaceId/…` routes, so the
    // workspace id is always present here.
    final workspaceId = routerState.pathParameters['workspaceId']!;
    // Feed the *logical* route (with the `/workspaces/:id` prefix stripped) to
    // the keybinding dispatcher so `route == '/inbox'` when-clauses gate
    // screen-scoped shortcuts correctly (e.g. the PR list's bare-key shortcuts
    // stay off while the detail page is open over it). Idempotent: a no-op when
    // the route is unchanged.
    final logicalRoute = workspaceShellLogicalRoute(location);
    ref.read(keybindingDispatcherProvider).setRoute(logicalRoute);
    // Keep a Slack-bridged channel opening itself even while this window is
    // in the background — otherwise the row only appears after a focus.
    ref.watch(chatBridgeChannelAutoOpenProvider);
    final inSettings = logicalRoute.startsWith('/settings');
    final inChannels = logicalRoute.startsWith('/channels');
    // In rail mode the global sidebar's inline channel list is gone, so the
    // channels surface gets a settings-like contextual sub-sidebar carrying
    // the (filterable) channel list. Expanded mode keeps the inline list and
    // mounts nothing here — mounting both would duplicate it.
    final showChannelsSubSidebar =
        inChannels && ref.watch(sidebarCollapsedProvider);
    final historyNotifier = ref.read(navigationHistoryProvider.notifier);
    final navState = ref.watch(navigationHistoryProvider);

    // Presence idle detection (PRD 16 §1): any pointer activity anywhere in
    // the shell registers as activity, alongside the key handler above.
    return Listener(
      onPointerDown: (_) => ref.read(myPresenceProvider.notifier).touch(),
      onPointerMove: (_) => ref.read(myPresenceProvider.notifier).touch(),
      onPointerHover: (_) => ref.read(myPresenceProvider.notifier).touch(),
      onPointerSignal: (_) => ref.read(myPresenceProvider.notifier).touch(),
      child: MouseNavigationHandler(
        historyController: historyNotifier,
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  // Web-only "a new version is available" strip (a no-op on
                  // desktop — the desktop updater lives in Settings → About).
                  // In-flow above the title bar so it never overlaps the
                  // banner rail or the HUD.
                  const WebUpdateBanner(),
                  // Full-width top bar: sidebar toggle, back/forward,
                  // breadcrumb, notifications, focus.
                  ShellTitleBar(
                    canGoBack: navState.canGoBack,
                    canGoForward: navState.canGoForward,
                    onGoBack: historyNotifier.goBack,
                    onGoForward: historyNotifier.goForward,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Primary navigation.
                        AppSidebar(
                          location: location,
                          workspaceId: workspaceId,
                        ),
                        if (inSettings)
                          CcSidebar(
                            width: 240,
                            trailingBorder: BorderSide(
                              color:
                                  (context.designSystem ??
                                          DesignSystemTokens.light())
                                      .borderPrimary,
                            ),
                            header: _SettingsSidebarHeader(
                              controller: _settingsFilterController,
                            ),
                            children: _buildSettingsGroups(
                              context,
                              location,
                              workspaceId,
                              needsIntegrationSetup: _integrationsNeedSetup(),
                            ),
                          ),
                        if (showChannelsSubSidebar) const ChannelsSubSidebar(),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              ),
              // Floating recording HUD — persists across navigation while a
              // meeting is being recorded.
              const MeetingRecordingHud(),
              // Agent-action approvals awaiting a human decision — surfaces
              // anywhere in the app so a blocked agent can be unblocked in a
              // glance. Renders nothing when nothing is pending.
              const AgentApprovalOverlay(),
              // Ambient banner rail (PRD 25 §1): time-critical, actionable
              // events (meeting starting, calendar auth expired). Self-positions
              // top-center below the title bar; renders nothing when idle.
              const BannerRail(),
              // Always-mounted soundscape audio host: owns the Player that
              // streams the server-generated ambience and persists across
              // navigation. Renders nothing (SizedBox.shrink).
              const SoundscapeAudioHost(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings contextual sub-sidebar ───────────────────────────────────
  //
  // Rendered from `kSettingsNav`, the single source of truth for the settings
  // information architecture. Groups are SCOPES — You / Workspace / Server —
  // each carrying a one-line statement of what a change there affects, because
  // "who does this affect?" is the question the old topic-based grouping could
  // not answer. The header filter narrows the visible items by name.

  /// True when neither a GitHub PAT nor an authenticated `gh` CLI is available,
  /// so agents can't reach GitHub — surfaced as an attention dot on the
  /// connected-accounts item.
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
    String location,
    String workspaceId, {
    required bool needsIntegrationSetup,
  }) {
    final l10n = AppLocalizations.of(context);
    final filter = _settingsFilter.trim().toLowerCase();

    CcSidebarItem? item(SettingsNavItem entry) {
      final label = entry.label(l10n);
      if (filter.isNotEmpty && !label.toLowerCase().contains(filter)) {
        return null;
      }
      final route = entry.route(workspaceId);
      final selected = entry.matchesSubroutes
          ? (location == route || location.startsWith('$route/'))
          : location == route;
      // The only attention affordance: agents cannot reach GitHub until a PAT
      // or an authenticated `gh` CLI exists and that is configured here.
      final attention = needsIntegrationSetup && entry.id == 'you.accounts';
      return CcSidebarItem(
        icon: entry.icon,
        label: label,
        badge: attention
            ? _AttentionDot(semanticLabel: l10n.needsSetupLabel)
            : null,
        selected: selected,
        onPressed: () => context.go(route),
      );
    }

    final groups = <CcSidebarGroup>[];
    for (final group in kSettingsNav) {
      final visible = group.items.map(item).whereType<CcSidebarItem>().toList();
      if (visible.isEmpty) {
        continue;
      }
      groups.add(CcSidebarGroup(label: group.label(l10n), children: visible));
    }

    if (groups.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text(
            l10n.noSettingsMatch(_settingsFilter.trim()),
            style: CcTypography.caption.copyWith(
              color: context.designSystem?.textTertiary,
            ),
          ),
        ),
      ];
    }
    return groups;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.settings,
                size: 16,
                color: context.designSystem?.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.navSettings,
                style: CcTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.ds.textPrimary,
                ),
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
    final color =
        context.designSystem?.fgWarningPrimary ?? const Color(0xFFCA8504);
    return CcTooltip(
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
