import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/dashboard/providers/active_processes_provider.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_database.dart';

/// Test-only [ActiveProcessesNotifier] that skips the periodic refresh timer.
class _NoProcesses extends ActiveProcessesNotifier {
  @override
  List<ActiveProcessInfo> build() => [];
}

void main() {
  late AppDatabase testDb;
  late AppPreferences prefs;

  GoRouter shellRouter(
    Widget child, {
    String? initialLocation,
  }) => GoRouter(
    initialLocation: initialLocation ?? dashboardRoute('ws-1'),
    routes: [
      ShellRoute(
        builder: (context, state, shellChild) => CcTheme(
          data: CcThemeData.light(),
          child: ControlCenterLayout(child: shellChild),
        ),
        routes: [
          GoRoute(path: dashboardRoute(workspaceIdParam), builder: (_, _) => child),
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
          GoRoute(path: newsfeedRoute(workspaceIdParam), builder: (_, _) => child),
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            builder: (_, _) => child,
          ),
          GoRoute(path: messagingRoute(workspaceIdParam), builder: (_, _) => child),
          GoRoute(path: analyticsRoute(workspaceIdParam), builder: (_, _) => child),
        ],
      ),
    ],
  );

  setUp(() async {
    testDb = createTestDatabase();
    prefs = AppPreferences.inMemory();
  });

  tearDown(() async {
    await testDb.close();
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
          databaseProvider.overrideWithValue(testDb),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          activeWorkspaceProvider.overrideWith((ref) => null),
          dmChannelsProvider.overrideWith((ref) => const []),
          groupChannelsProvider.overrideWith((ref) => const []),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
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
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('CONVERSATIONS'), findsOneWidget);
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
          databaseProvider.overrideWithValue(testDb),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
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
    expect(find.text('No workspace'), findsOneWidget);
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
          databaseProvider.overrideWithValue(testDb),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceChannelsProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const []),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
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
          databaseProvider.overrideWithValue(testDb),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceChannelsProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const []),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
          workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
          workspacePipelineRunsProvider(workspace.id).overrideWith((_) => Stream.value([])),
          workspaceProjectsProvider(workspace.id).overrideWith((_) => Stream.value([])),
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
          databaseProvider.overrideWithValue(testDb),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
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

    // Settings sub-row group label is uppercased by CcSidebarGroup.
    expect(find.text('GENERAL'), findsWidgets);
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
          databaseProvider.overrideWithValue(testDb),
          channelsProvider.overrideWith((ref) => Stream.value(const [])),
          appPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(router),
          activeProcessesProvider.overrideWith(_NoProcesses.new),
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
}
