import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/shell/presentation/layout/control_center_layout.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/soundscape/device_location_reader.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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

    // The primary sidebar should render with its top-level items. Workspace
    // destinations have no section header.
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('WORKSPACE'), findsNothing);
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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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
    expect(find.text('Filter settings'), findsNothing);
    // The settings nav replaces the global one rather than sitting beside it.
    expect(find.text('Inbox'), findsNothing);
    expect(find.text('Exit settings'), findsOneWidget);
  });

  Future<GoRouter> pumpShellAt(
    WidgetTester tester,
    String location, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final router = shellRouter(
      const Text('Page Content'),
      initialLocation: location,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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
          builder: (context, child) =>
              Directionality(textDirection: direction, child: child!),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pumpAndSettle();
    return router;
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'resize survives collapsing and reopening the sidebar ($direction)',
      (tester) async {
        await pumpShellAt(tester, inboxRoute('ws-1'), direction: direction);
        final initialWidth = tester.getSize(find.byType(AppSidebar)).width;
        final rect = tester.getRect(find.byType(AppSidebar));
        final seam = direction == TextDirection.ltr ? rect.right : rect.left;
        final delta = direction == TextDirection.ltr ? 80.0 : -80.0;
        await tester.dragFrom(Offset(seam, 400), Offset(delta, 0));
        await tester.pumpAndSettle();
        final resizedWidth = tester.getSize(find.byType(AppSidebar)).width;
        expect(resizedWidth, greaterThan(initialWidth));
        expect(prefs.getDouble(sidebarWidthKey), resizedWidth);

        await tester.tap(find.byIcon(AppIcons.panelLeftClose));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(AppSidebar)).width,
          lessThan(initialWidth),
        );
        expect(find.byType(CcResizable), findsNothing);

        await tester.tap(find.byIcon(AppIcons.panelLeftOpen));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(AppSidebar)).width, resizedWidth);
        expect(find.byType(CcResizable), findsOneWidget);
      },
    );
  }

  testWidgets('settings drills the global sidebar in, and exit returns to '
      'the page it was opened from', (tester) async {
    final router = await pumpShellAt(tester, pullRequestsRoute('ws-1'));
    expect(find.text('Inbox'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      settingsAppearanceRoute('ws-1'),
    );
    expect(find.text('Exit settings'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    // The global nav stays mounted beneath, offstage, to slide back to.
    expect(find.text('Inbox'), findsNothing);
    expect(find.text('Inbox', skipOffstage: false), findsOneWidget);
    // The workspace switcher is the one thing that never moves.
    expect(find.text('Select a workspace'), findsOneWidget);

    await tester.tap(find.text('Exit settings'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      pullRequestsRoute('ws-1'),
    );
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Exit settings', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exit from a settings deep link lands on the inbox', (
    tester,
  ) async {
    final router = await pumpShellAt(tester, settingsAppearanceRoute('ws-1'));

    await tester.tap(find.text('Exit settings'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      inboxRoute('ws-1'),
    );
  });

  testWidgets('the collapsed rail keeps settings as icons with tooltips', (
    tester,
  ) async {
    await prefs.setBool(sidebarCollapsedKey, value: true);
    await pumpShellAt(tester, settingsAppearanceRoute('ws-1'));

    // Labels give way to icons; each icon names itself in a tooltip.
    expect(find.text('Exit settings'), findsNothing);
    Finder inSidebar(Finder f) =>
        find.descendant(of: find.byType(AppSidebar), matching: f);
    expect(inSidebar(find.byIcon(AppIcons.chevronLeft)), findsOneWidget);
    expect(inSidebar(find.byIcon(AppIcons.paintbrushVertical)), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CcTooltip && w.message == 'Exit settings',
      ),
      findsOneWidget,
    );
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
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
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

  testWidgets(
    'the sidebar retains its return destination across a rail toggle',
    (tester) async {
      final router = await pumpShellAt(tester, pullRequestsRoute('ws-1'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.panelLeftClose));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.panelLeftOpen));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit settings'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        pullRequestsRoute('ws-1'),
      );
    },
  );
}
