import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_space_auto_open.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_shell_overlay.dart';
import 'package:control_center/features/dispatch/presentation/widgets/credential_gate_overlay.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_recording_hud.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_overlay.dart';
import 'package:control_center/features/messaging/presentation/widgets/spaces_sub_sidebar.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/shell/presentation/layout/shell_title_bar.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:control_center/features/shell/presentation/widgets/banner_rail.dart';
import 'package:control_center/features/shell/presentation/widgets/web_update_banner.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_audio_host.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Root shell layout: a FULL-WIDTH [ShellTitleBar] on top (its bottom hairline
/// runs edge to edge and, on macOS, its content clears the traffic-light
/// cluster), then a row of the left [AppSidebar] (which therefore starts below
/// the bar — no border segment runs up beside the traffic lights) and the
/// routed content area. Settings drills the global sidebar into its own
/// navigation (see [AppSidebar]); the spaces surface gets a contextual second
/// sidebar while the global sidebar is collapsed to its rail.
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
  @override
  void initState() {
    super.initState();
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
    // Keep a Slack-bridged space opening itself even while this window is
    // in the background — otherwise the row only appears after a focus.
    ref.watch(chatBridgeSpaceAutoOpenProvider);
    final inSpaces = logicalRoute.startsWith('/spaces');
    // In rail mode the global sidebar's inline space list is gone, so the
    // spaces surface gets a settings-like contextual sub-sidebar carrying
    // the (filterable) space list. Expanded mode keeps the inline list and
    // mounts nothing here — mounting both would duplicate it.
    final showSpacesSubSidebar =
        inSpaces && ref.watch(sidebarCollapsedProvider);
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
                  // Each chrome region is its own layer so scrolling the
                  // routed page does not repaint the bar or the sidebars,
                  // and a sidebar hover does not repaint the page.
                  RepaintBoundary(
                    child: ShellTitleBar(
                      canGoBack: navState.canGoBack,
                      canGoForward: navState.canGoForward,
                      onGoBack: historyNotifier.goBack,
                      onGoForward: historyNotifier.goForward,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Primary navigation.
                        RepaintBoundary(
                          child: AppSidebar(
                            location: location,
                            workspaceId: workspaceId,
                          ),
                        ),
                        if (showSpacesSubSidebar)
                          const RepaintBoundary(child: SpacesSubSidebar()),
                        Expanded(child: RepaintBoundary(child: widget.child)),
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
              // Runs the server has PARKED on a credential — a spent plan, a
              // signed-out account, a provider with no key. Unlike the approval
              // above, nothing has failed: the turn is held open and continues
              // by itself once the credential works, so this is a modal rather
              // than a card (the fix is a login form, not a yes/no).
              const CredentialGateOverlay(),
              // Ambient banner rail (PRD 25 §1): time-critical, actionable
              // events (meeting starting, calendar auth expired). Self-positions
              // top-center below the title bar; renders nothing when idle.
              const BannerRail(),
              // The demo's first-run disclosure. Positioned like the banner
              // rail and, like it, renders nothing when there is nothing to
              // say — against a real server that is always. It says the three
              // things a visitor cannot work out for themselves: the data is
              // invented, the agents are scripted, and the workspace is
              // temporary.
              const DemoShellOverlay(),
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
}
