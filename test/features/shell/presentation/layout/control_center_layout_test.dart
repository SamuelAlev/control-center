import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/shell/presentation/layout/control_center_layout.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Offline queue stub: no pending mutations, always online.
class _NoOpOfflineQueue extends OfflineQueueController {
  @override
  int build() => 0;
}

void main() {
  late AppPreferences prefs;

  GoRouter shellRouter(Widget child, {String? initialLocation}) => GoRouter(
    initialLocation: initialLocation ?? inboxRoute('ws-1'),
    routes: [
      ShellRoute(
        builder: (context, state, shellChild) => CcTheme(
          data: CcThemeData.light(),
          child: ControlCenterLayout(child: shellChild),
        ),
        routes: [
          GoRoute(path: inboxRoute(workspaceIdParam), builder: (_, _) => child),
          GoRoute(
            path: settingsAppearanceRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(
            path: settingsAdaptersRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(
            path: settingsAgentsRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(
            path: newsfeedRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(
            path: spacesRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
        ],
      ),
    ],
  );

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  testWidgets('renders sidebar with main items', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = shellRouter(const Text('Page Content'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          isOnlineProvider.overrideWithValue(true),
          offlineQueueControllerProvider.overrideWith(_NoOpOfflineQueue.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));

    // The primary sidebar should render with its top-level items.
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('SPACES'), findsOneWidget);
  });

  testWidgets('renders workspace switcher with no workspace', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = shellRouter(const Text('Page Content'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
          isOnlineProvider.overrideWithValue(true),
          offlineQueueControllerProvider.overrideWith(_NoOpOfflineQueue.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Select a workspace'), findsOneWidget);
  });

  testWidgets('renders workspace switcher with active workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workspace = Workspace(
      id: 'ws-1',
      name: 'My Project',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final router = shellRouter(const Text('Page Content'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceSpacesProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const []),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
          activeWorkspaceProvider.overrideWith((ref) => workspace),
          workspacePipelineRunsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
          reposForWorkspaceProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
          workspaceProjectsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('My Project'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('renders workspace with GitHub avatar', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workspace = Workspace(
      id: 'ws-gh',
      name: 'GitHub Project',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final router = shellRouter(const Text('Page Content'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceSpacesProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const []),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
          workspacePipelineRunsProvider(
            workspace.id,
          ).overrideWith((_) => Stream.value([])),
          workspaceProjectsProvider(
            workspace.id,
          ).overrideWith((_) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => workspace),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('GitHub Project'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('shows settings sub-row when on settings route', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = shellRouter(
      const Text('Settings content'),
      initialLocation: settingsAppearanceRoute('ws-1'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));

    // Settings groups are SCOPES now — You / Workspace / Server — uppercased
    // by CcSidebarGroup. The scope name is the whole statement of who a change
    // below it affects.
    expect(find.text('YOU'), findsWidgets);
    expect(find.text('WORKSPACE'), findsWidgets);
    expect(find.text('SERVER'), findsWidgets);
  });

  testWidgets('renders newsfeed content without an inner sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = shellRouter(
      const Text('Newsfeed content'),
      initialLocation: newsfeedRoute('ws-1'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));

    // The newsfeed no longer has a contextual second sidebar; the routed
    // content renders directly next to the primary navigation.
    expect(find.text('Newsfeed content'), findsOneWidget);
    expect(find.text('Feeds'), findsNothing);
  });

  testWidgets('toggling the rail never moves the nav icons; the workspace '
      'mark glides the chooser indent', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = shellRouter(const Text('Page Content'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
          isOnlineProvider.overrideWithValue(true),
          offlineQueueControllerProvider.overrideWith(_NoOpOfflineQueue.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 200));

    // The nav icons must hold their horizontal position in every phase of
    // the toggle: settled expanded, mid-collapse, settled rail, mid-expand.
    // The workspace mark is the one deliberate exception: the expanded
    // chooser pads its content 10px in (the hover pill itself stays flush
    // with the nav-item pills) so the avatar's left edge lands on the
    // group-label/nav-icon line — moving its CENTER 9px off the shared
    // x=27 rail line (10 internal − 1 reserved = 9). The mark therefore
    // glides between the rail line (rail and mid-animation, where the
    // iconOnly chip shows) and the +9 line (settled expanded).
    const mark =
        AppIcons.menu; // workspace mark placeholder (no active workspace)
    const navIcons = [
      AppIcons.inbox,
      AppIcons.ticket,
      AppIcons.gitPullRequest,
      AppIcons.calendarBlank,
      AppIcons.audioLines,
      AppIcons.workflow,
      AppIcons.newspaper,
      AppIcons.gauge,
      AppIcons.settings,
    ];

    double iconX(IconData icon) => tester.getCenter(find.byIcon(icon)).dx;

    void expectNavUnmoved(Map<IconData, double> baseline, String phase) {
      for (final icon in navIcons) {
        expect(
          find.byIcon(icon),
          findsOneWidget,
          reason: '$icon should stay mounted while $phase',
        );
        expect(
          iconX(icon),
          moreOrLessEquals(baseline[icon]!, epsilon: 0.5),
          reason: '$icon moved while $phase',
        );
      }
    }

    void expectMark(double x, String phase) {
      expect(
        find.byIcon(mark),
        findsOneWidget,
        reason: 'workspace mark should stay mounted while $phase',
      );
      expect(
        iconX(mark),
        moreOrLessEquals(x, epsilon: 0.5),
        reason: 'workspace mark off its expected line while $phase',
      );
    }

    final expandedX = {for (final icon in navIcons) icon: iconX(icon)};
    // The rail line IS the shared nav-icon line (x=27); the settled expanded
    // mark's center sits 9px to its right (the chip's 10px internal left
    // padding, minus the 1px it had on the shared line).
    final railMarkX = expandedX[AppIcons.inbox]!;
    final expandedMarkX = iconX(mark);
    expect(
      expandedMarkX,
      moreOrLessEquals(railMarkX + 9, epsilon: 0.5),
      reason:
          'the expanded chooser pads its content 10px in, so the avatar’s '
          'left edge aligns with the nav icons and group-label text',
    );

    // Collapse: tap the title-bar rail toggle, then measure mid-animation
    // (CcMotion.slow is 240ms) and at the settled rail.
    await tester.tap(find.byIcon(AppIcons.panelLeftClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expectNavUnmoved(expandedX, 'collapsing');
    expectMark(railMarkX, 'collapsing');
    await tester.pumpAndSettle();
    expectNavUnmoved(expandedX, 'collapsed');
    expectMark(railMarkX, 'collapsed');

    // Expand: same assertions on the way back.
    await tester.tap(find.byIcon(AppIcons.panelLeftOpen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expectNavUnmoved(expandedX, 'expanding');
    expectMark(railMarkX, 'expanding');
    await tester.pumpAndSettle();
    expectNavUnmoved(expandedX, 're-expanded');
    expectMark(expandedMarkX, 're-expanded');
    expect(tester.takeException(), isNull);
  });
}
