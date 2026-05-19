import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/presentation/screens/signed_out_screen.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:control_center/features/inbox/presentation/inbox_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_detail_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_record_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/messaging/presentation/screens/messaging_screen.dart';
import 'package:control_center/features/messaging/presentation/screens/spaces_home_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen.dart'
    if (dart.library.js_interop) 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen_web.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_screen.dart';
import 'package:control_center/features/observability/presentation/screens/observability_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_detail_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_template_editor_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plan_studio_screen.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plans_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/compose_pull_request_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/settings/presentation/screens/about_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/adapters_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/agent_permissions_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/agents_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/audio_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/backup_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/diagnostics_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/keybindings_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/mcp_servers_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/members_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/newsfeed_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/profile_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/remote_control_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/repos_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/rigs_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/sandbox_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/server_connection_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/skills_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/sso_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/voice_meetings_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/workspace_general_settings_screen.dart';
import 'package:control_center/features/shell/presentation/layout/control_center_layout.dart';
import 'package:control_center/features/ticketing/presentation/screens/project_overview_screen.dart';
import 'package:control_center/features/ticketing/presentation/screens/tickets_screen.dart';
import 'package:control_center/features/user_profiles/presentation/screens/user_profile_screen.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/router/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wraps a route's child with an opaque [GestureDetector] so taps in
/// transparent areas don't fall through to the route's underlying
/// [ModalBarrier], which plays the macOS alert sound on every tap (Flutter's
/// MaterialPageRoute defaults to barrierDismissible: false). The wrapper must
/// live inside the inner navigator's modal scope to win the gesture arena
/// against the barrier; wrapping at the shell level isn't sufficient because
/// ShellRoute creates an inner Navigator whose barrier sits below this layer.
/// Also drops focus from any active TextField, matching macOS click-outside
/// behavior.
Widget _absorb(Widget child) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
  child: child,
);

/// Whether the current platform should skip page transitions.
///
/// Native on iOS/Android (even inside a mobile browser, where the engine still
/// reports the mobile platform); instant open/close on web and desktop.
bool get _platformWantsNoTransition {
  if (kIsWeb) {
    return true;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return false;
    default:
      return true;
  }
}

/// A go_router [Page] that adapts transitions to the platform.
///
/// On web/desktop it behaves like [NoTransitionPage] (instant). On iOS/Android
/// it builds a [MaterialPageRoute], whose transitions come from the theme's
/// `appPageTransitionsTheme` (Cupertino swipe on iOS, zoom on Android). Routes
/// are built with [buildPage] so call sites stay platform-agnostic.
class AdaptivePage<T> extends Page<T> {
  /// Creates an adaptive page wrapping [child].
  const AdaptivePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The screen rendered by this page.
  final Widget child;

  /// Creates the platform-adaptive route.
  ///
  /// Both branches return a *page-based* route that reads its content from the
  /// current `settings` (the [Page]) at build time rather than capturing `child`
  /// in a closure. This is what lets a page reused across locations via a shared
  /// key (e.g. the calendar list↔detail routes, both keyed `calendarPageKey`)
  /// update in place: when the Navigator reuses the route for a new page of the
  /// same key, it calls `_updateSettings`, swapping in the new page whose
  /// `child` carries the new route arguments (here, `selectedEventId`). A route
  /// that captured the original `child` would keep rendering the stale screen
  /// until a full refresh remounted it.
  @override
  Route<T> createRoute(BuildContext context) {
    if (_platformWantsNoTransition) {
      return _AdaptiveNoTransitionRoute<T>(page: this);
    }
    return _AdaptiveMaterialRoute<T>(page: this);
  }
}

/// A page-based [PageRoute] mirroring [MaterialPageRoute] (theme-driven
/// transitions: Cupertino swipe on iOS, zoom on Android) but reading its content
/// from the owning [AdaptivePage] via `settings`, so reused-key pages update in
/// place. See [AdaptivePage.createRoute].
class _AdaptiveMaterialRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _AdaptiveMaterialRoute({required AdaptivePage<T> page})
    : super(settings: page);

  AdaptivePage<T> get _page => settings as AdaptivePage<T>;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  Widget buildContent(BuildContext context) => _page.child;
}

/// A page-based [PageRoute] with an instant (zero-duration) transition for web
/// and desktop, reading its content from the owning [AdaptivePage] via
/// `settings`. See [AdaptivePage.createRoute].
class _AdaptiveNoTransitionRoute<T> extends PageRoute<T> {
  _AdaptiveNoTransitionRoute({required AdaptivePage<T> page})
    : super(settings: page);

  AdaptivePage<T> get _page => settings as AdaptivePage<T>;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Builds an [AdaptivePage] with the given [child] (already wrapped via
/// [_absorb]). Falls back to [GoRouterState.pageKey] when no explicit [key] is
/// supplied (the common case); pass one to share a page across master–detail
/// locations.
Page<void> buildPage(GoRouterState state, Widget child, {ValueKey? key}) =>
    AdaptivePage<void>(key: key ?? state.pageKey, child: child);

/// Provides the configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final gateNotifier = ValueNotifier<OnboardingGate>(
    ref.read(onboardingGateProvider),
  );

  ref.listen(onboardingGateProvider, (_, next) {
    gateNotifier.value = next;
  });

  // Stable page keys for the master–detail screens (tickets, calendar) that
  // share one screen instance across list/detail locations. They include the
  // `:workspaceId` literal because the pattern is constant per shell.
  const ticketsPageKey = ValueKey('tickets_screen');
  const calendarPageKey = ValueKey('calendar_screen');
  const spacesPageKey = ValueKey('spaces_screen');
  const spacesHomePageKey = ValueKey('spaces_home_screen');

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splashRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) => onboardingGuard(
      context,
      state,
      gateNotifier,
      () => ref.read(activeWorkspaceIdProvider),
    ),
    routes: [
      GoRoute(
        path: splashRoute,
        pageBuilder: (context, state) =>
            buildPage(state, _absorb(const SplashScreen())),
      ),
      GoRoute(
        path: onboardingRoute,
        pageBuilder: (context, state) =>
            buildPage(state, _absorb(const OnboardingScreen())),
      ),
      // Re-authentication for an operator who is already set up. Full-screen
      // like onboarding — with no forge credential there is nothing behind it
      // that would render.
      GoRoute(
        path: signedOutRoute,
        pageBuilder: (context, state) =>
            buildPage(state, _absorb(const SignedOutScreen())),
      ),
      // The workspace picker is full-screen (outside the workspace shell): it
      // has no single-workspace context. Selecting one enters its inbox.
      GoRoute(
        path: workspaceListRoute,
        pageBuilder: (context, state) =>
            buildPage(state, _absorb(const WorkspaceListScreen())),
      ),
      // A bare `/workspaces/:workspaceId` enters the workspace at its inbox.
      GoRoute(
        path: workspaceRoot(workspaceIdParam),
        redirect: (context, state) =>
            inboxRoute(state.pathParameters['workspaceId']!),
      ),
      // Everything else lives inside the workspace shell, scoped by the
      // `:workspaceId` path parameter (the app's active-workspace source of
      // truth). ShellRoute children use absolute, prefixed paths.
      ShellRoute(
        builder: (context, state, child) => ControlCenterLayout(child: child),
        routes: [
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const PullRequestListScreen())),
            routes: [
              // Static `compose` segment, declared before `:prNumber` so it is
              // matched as the compose screen rather than parsed as a PR number.
              GoRoute(
                path: 'compose',
                pageBuilder: (context, state) => buildPage(
                  state,
                  _absorb(
                    ComposePullRequestScreen(
                      // Optional: set when composing from a conversation's
                      // Source Control panel, so the screen can offer that
                      // conversation's worktree branch as the compare head.
                      spaceId: state.uri.queryParameters['space'],
                    ),
                  ),
                ),
              ),
              // `:owner/:repo/:prNumber` — PR numbers are per-repo, so the repo
              // owner/name are part of the path. Three segments, so this never
              // collides with the single-segment `compose` route above.
              GoRoute(
                path: ':owner/:repo/:prNumber',
                redirect: (context, state) {
                  final raw = state.pathParameters['prNumber'] ?? '';
                  final parsed = int.tryParse(raw);
                  if (parsed == null) {
                    return pullRequestsRoute(
                      state.pathParameters['workspaceId']!,
                    );
                  }

                  return null;
                },
                pageBuilder: (context, state) {
                  final prNumber = int.parse(state.pathParameters['prNumber']!);
                  return buildPage(
                    state,
                    _absorb(
                      PullRequestDetailScreen(
                        workspaceId: state.pathParameters['workspaceId']!,
                        owner: state.pathParameters['owner']!,
                        repo: state.pathParameters['repo']!,
                        prNumber: prNumber,
                        // The focused workbench tab rides as `?tab=` (same
                        // convention as the space page).
                        focusedTabKey: state.uri.queryParameters['tab'],
                        // A comment permalink rides as `?comment=<rest id>`,
                        // the same one-shot shape as the space page's `?m=`:
                        // consumed once on open to reveal the thread, then
                        // dropped so a rebuild does not re-scroll.
                        pendingCommentId: int.tryParse(
                          state.uri.queryParameters['comment'] ?? '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: spacesRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const SpacesHomeScreen()),
              key: spacesHomePageKey,
            ),
          ),
          // SIBLING (not nested) with its own page key ([spacesPageKey]) so
          // detail↔detail locations reuse the one MessagingScreen instance in
          // place — the selected space id comes from the URL (source of
          // truth), same pattern as the tickets list↔detail routes.
          GoRoute(
            path: '${spacesRoute(workspaceIdParam)}/:spaceId',
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(
                MessagingScreen(
                  selectedSpaceId: state.pathParameters['spaceId'],
                  pendingMessageId: state.uri.queryParameters['m'],
                  // The focused editor tab rides as `?tab=` so back/forward
                  // steps through tab switches and a refresh re-focuses it.
                  focusedTabKey: state.uri.queryParameters['tab'],
                ),
              ),
              key: spacesPageKey,
            ),
          ),
          GoRoute(
            path: ticketsRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const TicketsScreen()),
              key: ticketsPageKey,
            ),
          ),
          // SIBLING (not nested) so the detail location reuses the one
          // TicketsScreen instance in place — shared page key → state preserved,
          // no transition. Nesting stacked a second TicketsScreen under the same
          // key, which both defeated that intent and tripped the Navigator's
          // duplicate-page-key assertion on web debug (see the calendar routes).
          GoRoute(
            path: '${ticketsRoute(workspaceIdParam)}/:ticketId',
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(
                TicketsScreen(
                  selectedTicketId: state.pathParameters['ticketId'],
                ),
              ),
              key: ticketsPageKey,
            ),
          ),
          GoRoute(
            path: projectOverviewRoute(workspaceIdParam, ':projectId'),
            pageBuilder: (context, state) {
              final id = state.pathParameters['projectId'] ?? '';
              return buildPage(
                state,
                _absorb(ProjectOverviewScreen(projectId: id)),
                key: const ValueKey('project_overview'),
              );
            },
          ),
          GoRoute(
            path: newsfeedRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const NewsfeedScreen())),
            routes: [
              GoRoute(
                path: 'article/:articleId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['articleId'] ?? '';
                  return buildPage(
                    state,
                    _absorb(ArticleWebviewScreen(articleId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: apiKeysRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const ApiKeysScreen())),
          ),
          // ── Settings ──────────────────────────────────────────────
          //
          // Paths are namespaced by SCOPE (`you/`, `workspace/`, `server/`) so
          // the blast radius of a change is legible in the URL and the route
          // registry, not just in the sidebar grouping. The IA itself lives in
          // `kSettingsNav` and `settings_nav_test.dart` asserts every route
          // registered here appears there exactly once — a page cannot be
          // half-wired.
          GoRoute(
            path: settingsRoute(workspaceIdParam),
            redirect: (_, state) =>
                settingsProfileRoute(state.pathParameters['workspaceId']!),
          ),
          // You — follows the signed-in user across devices.
          GoRoute(
            path: settingsProfileRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const ProfileSettingsScreen())),
          ),
          GoRoute(
            path: settingsAppearanceRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const AppearanceSettingsScreen())),
          ),
          GoRoute(
            path: settingsNotificationsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const NotificationsSettingsScreen())),
          ),
          GoRoute(
            path: settingsKeybindingsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const KeybindingsSettingsScreen())),
          ),
          GoRoute(
            path: settingsAudioRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const AudioSettingsScreen())),
          ),
          GoRoute(
            path: settingsRemoteControlRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const RemoteControlSettingsScreen())),
          ),
          GoRoute(
            path: settingsNewsfeedRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const NewsfeedSettingsScreen())),
          ),
          // Workspace — affects everyone in this workspace.
          GoRoute(
            path: settingsWorkspaceGeneralRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const WorkspaceGeneralSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsMembersRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const MembersSettingsScreen())),
          ),
          GoRoute(
            path: settingsAgentsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const AgentsSettingsScreen())),
          ),
          GoRoute(
            path: settingsReposRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const ReposSettingsScreen())),
          ),
          GoRoute(
            path: settingsSkillsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const SkillsSettingsScreen())),
          ),
          GoRoute(
            path: settingsGuardrailsRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const AgentPermissionsSettingsScreen()),
            ),
          ),
          // Server — affects every workspace on this install.
          GoRoute(
            path: settingsServerConnectionRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const ServerConnectionSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsSsoRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const SsoSettingsScreen())),
          ),
          GoRoute(
            path: settingsAdaptersRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const AdaptersSettingsScreen())),
          ),
          GoRoute(
            path: settingsMcpRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const McpServersSettingsScreen())),
          ),
          GoRoute(
            path: settingsRigsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const RigsSettingsScreen())),
          ),
          GoRoute(
            path: settingsSandboxRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const SandboxSettingsScreen())),
          ),
          GoRoute(
            path: settingsVoiceMeetingsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const VoiceMeetingsSettingsScreen())),
          ),
          GoRoute(
            path: settingsDiagnosticsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const DiagnosticsSettingsScreen())),
          ),
          GoRoute(
            path: settingsBackupRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const BackupSettingsScreen())),
          ),
          GoRoute(
            path: settingsAboutRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const AboutSettingsScreen())),
          ),
          GoRoute(
            path: observabilityRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const ObservabilityScreen())),
          ),
          GoRoute(
            path: inboxRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const InboxScreen())),
          ),
          GoRoute(
            path: userProfileRoute(workspaceIdParam, ':login'),
            pageBuilder: (context, state) {
              final login = state.pathParameters['login'] ?? '';
              return buildPage(state, _absorb(UserProfileScreen(login: login)));
            },
          ),
          GoRoute(
            path: pipelinesRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const PipelinesScreen())),
            routes: [
              // Static `run` must precede the `:runId` param route so
              // /pipelines/run resolves to the launcher, not a run detail.
              GoRoute(
                path: 'run',
                pageBuilder: (context, state) => buildPage(
                  state,
                  _absorb(
                    PipelineRunScreen(
                      initialTemplateId:
                          state.uri.queryParameters['templateId'],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: ':runId',
                pageBuilder: (context, state) => buildPage(
                  state,
                  _absorb(
                    PipelineRunDetailScreen(
                      runId: state.pathParameters['runId'] ?? '',
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Plan Studio (PRD 17): the plans hub + the studio for one plan.
          GoRoute(
            path: plansRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(
                PlansScreen(
                  workspaceId: state.pathParameters['workspaceId'] ?? '',
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: ':kind/:id',
                pageBuilder: (context, state) => buildPage(
                  state,
                  _absorb(
                    PlanStudioScreen(
                      workspaceId: state.pathParameters['workspaceId'] ?? '',
                      kind: state.pathParameters['kind'] ?? 'orchestration',
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: settingsPipelinesRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const PipelineTemplatesSettingsScreen()),
            ),
            routes: [
              GoRoute(
                path: ':templateId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['templateId'] ?? '';
                  return buildPage(
                    state,
                    _absorb(PipelineTemplateEditorScreen(templateId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: memoryRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const MemoryScreen())),
          ),
          GoRoute(
            path: meetingsRoute(workspaceIdParam),
            pageBuilder: (context, state) =>
                buildPage(state, _absorb(const MeetingsScreen())),
            routes: [
              GoRoute(
                path: 'record',
                pageBuilder: (context, state) =>
                    buildPage(state, _absorb(const MeetingRecordScreen())),
              ),
              GoRoute(
                path: ':meetingId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['meetingId'] ?? '';
                  return buildPage(
                    state,
                    _absorb(MeetingDetailScreen(meetingId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: calendarRoute(workspaceIdParam),
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(const CalendarScreen()),
              key: calendarPageKey,
            ),
          ),
          // The event-detail location is a SIBLING (not a nested child) so that
          // exactly one page ever carries `calendarPageKey`: a sole sibling
          // matches at a time and the shared key makes the Navigator reuse the
          // one CalendarScreen instance across list↔detail — state preserved,
          // no transition (the master–detail pane lives inside the screen).
          // Nesting kept the parent /calendar page mounted AND stacked the child
          // /calendar/:eventId page under the SAME key, which both defeats the
          // single-instance intent and trips the Navigator's
          // `_debugCheckDuplicatedPageKeys` assertion (debug-only — it surfaced
          // on the web/DDC build, stripped in desktop release).
          GoRoute(
            path: '${calendarRoute(workspaceIdParam)}/:eventId',
            pageBuilder: (context, state) => buildPage(
              state,
              _absorb(
                CalendarScreen(
                  selectedEventId: state.pathParameters['eventId'],
                ),
              ),
              key: calendarPageKey,
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gateNotifier.dispose();
  });

  return router;
});
