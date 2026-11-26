import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/features/changelog/presentation/widgets/changelog_after_update.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_space_auto_open.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_shell_overlay.dart';
import 'package:control_center/features/dispatch/presentation/widgets/credential_gate_overlay.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_sign_in_banner.dart';
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
import 'package:control_center/features/workspaces/presentation/widgets/workspace_read_only_banner.dart';
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
  // Reparent the live panes between the rail Row and expanded splitter without
  // losing settings return navigation, disclosure state or editor contents.
  final _sidebarKey = GlobalKey();
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Presence idle detection (PRD 16 §1): any hardware key registers as
    // activity. Never marks the event handled — this must never steal a key
    // from the app's real shortcut/input handling.
    HardwareKeyboard.instance.addHandler(_onKeyEventTouch);
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
    // The shell builder runs on every navigation anyway (it hands this
    // layout the new routed child), so reading the route here costs nothing
    // extra. What matters is that the chrome below is const: the sidebar
    // derives its highlight from the router itself, so a route change does
    // not rebuild it.
    final location = GoRouterState.of(context).matchedLocation;
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
          // Tab finishes one region before the next, in reading order down
          // the window: the bars on top, then the panes, then whatever floats
          // over them. Without the regions one geometric sort ran over the
          // whole window and interleaved them.
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Web-only "a new version is available" strip (a no-op on
                    // desktop — the desktop updater lives in Settings →
                    // About). In-flow above the title bar so it never overlaps
                    // the banner rail or the HUD.
                    const _ShellRegion(order: 0, child: WebUpdateBanner()),
                    // Full-width top bar: sidebar toggle, back/forward,
                    // breadcrumb, notifications, focus.
                    // Each chrome region is its own layer so scrolling the
                    // routed page does not repaint the bar or the sidebars,
                    // and a sidebar hover does not repaint the page.
                    _ShellRegion(
                      order: 1,
                      child: RepaintBoundary(
                        child: ShellTitleBar(
                          canGoBack: navState.canGoBack,
                          canGoForward: navState.canGoForward,
                          onGoBack: historyNotifier.goBack,
                          onGoForward: historyNotifier.goForward,
                        ),
                      ),
                    ),
                    // No code host answers for this workspace: warn in place
                    // with the sign-in one click away, rather than gating the
                    // whole app on it.
                    const _ShellRegion(order: 2, child: ForgeSignInBanner()),
                    // The workspace's database failed its integrity check: it
                    // reads but refuses writes until restored. Said once,
                    // here, before anyone types.
                    const _ShellRegion(
                      order: 3,
                      child: WorkspaceReadOnlyBanner(),
                    ),
                    // The panes sit side by side with the same top, so a
                    // geometric sort inside them gives sidebar, sub-sidebar,
                    // content in either text direction.
                    Expanded(
                      child: _ShellRegion(
                        order: 4,
                        child: _buildPanes(showSpacesSubSidebar),
                      ),
                    ),
                  ],
                ),
                // The floating layers share one region after the panes. The
                // HUD is a Positioned, so they keep a Stack of their own.
                const Positioned.fill(
                  child: _ShellRegion(
                    order: 5,
                    child: Stack(
                      children: [
                        // Floating recording HUD — persists across navigation
                        // while a meeting is being recorded.
                        MeetingRecordingHud(),
                        // Agent-action approvals awaiting a human decision —
                        // surfaces anywhere in the app so a blocked agent can
                        // be unblocked in a glance. Renders nothing when
                        // nothing is pending.
                        AgentApprovalOverlay(),
                        // Runs the server has PARKED on a credential — a spent
                        // plan, a signed-out account, a provider with no key.
                        // Unlike the approval above, nothing has failed: the
                        // turn is held open and continues by itself once the
                        // credential works, so this is a modal rather than a
                        // card (the fix is a login form, not a yes/no).
                        CredentialGateOverlay(),
                        // Ambient banner rail (PRD 25 §1): time-critical,
                        // actionable events (meeting starting, calendar auth
                        // expired). Self-positions top-center below the title
                        // bar; renders nothing when idle.
                        BannerRail(),
                        // The demo's first-run disclosure. Positioned like the
                        // banner rail and, like it, renders nothing when there
                        // is nothing to say — against a real server that is
                        // always. It says the three things a visitor cannot
                        // work out for themselves: the data is invented, the
                        // agents are scripted, and the workspace is temporary.
                        DemoShellOverlay(),
                      ],
                    ),
                  ),
                ),
                // Always-mounted soundscape audio host: owns the Player that
                // streams the server-generated ambience and persists across
                // navigation. Renders nothing (SizedBox.shrink).
                const SoundscapeAudioHost(),
                // Opens What's new on the first launch of a new version.
                // Renders nothing.
                const ChangelogAfterUpdate(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanes(bool showSpacesSubSidebar) {
    final sidebar = FocusTraversalGroup(
      key: _sidebarKey,
      child: const RepaintBoundary(child: AppSidebar()),
    );
    final content = FocusTraversalGroup(
      key: _contentKey,
      child: RepaintBoundary(child: widget.child),
    );
    if (ref.watch(sidebarCollapsedProvider)) {
      return Row(
        children: [
          sidebar,
          if (showSpacesSubSidebar)
            FocusTraversalGroup(
              child: const RepaintBoundary(child: SpacesSubSidebar()),
            ),
          Expanded(child: content),
        ],
      );
    }
    final width = ref.watch(sidebarWidthProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        // Desktop windows start at 1024px. A narrower web viewport must not
        // overflow just because both expanded panes have desktop minima.
        if (available < kMinSidebarWidth + 320) {
          return Row(
            children: [
              SizedBox(width: math.min(width, available / 2), child: sidebar),
              Expanded(child: content),
            ],
          );
        }
        return CcResizable(
          axis: Axis.horizontal,
          // CcSidebar already paints its trailing hairline on this seam, in
          // every layout. A resting divider would stack on it half a pixel
          // over and read thicker than the app's other hairlines, so only the
          // hover/drag highlight is drawn here.
          dividerThickness: 0,
          dividerColor: context.ds.borderPrimary,
          onResize: (extents) =>
              ref.read(sidebarWidthProvider.notifier).setWidth(extents.first),
          regions: [
            CcResizableRegion(
              initialExtent: width,
              minExtent: kMinSidebarWidth,
              maxExtent: kMaxSidebarWidth,
              builder: (_) => sidebar,
            ),
            CcResizableRegion(
              initialExtent: available - width,
              minExtent: 320,
              builder: (_) => content,
            ),
          ],
        );
      },
    );
  }
}

/// One Tab region of the shell: Tab finishes it before moving on, and the
/// shell visits the regions by [order].
class _ShellRegion extends StatelessWidget {
  const _ShellRegion({required this.order, required this.child});

  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: FocusTraversalGroup(child: child),
    );
  }
}
