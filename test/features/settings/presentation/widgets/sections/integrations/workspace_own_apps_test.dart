import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/connect/domain/repositories/workspace_connect_repository.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../helpers/active_workspace.dart';
import '../../../../../../helpers/settings_contribution.dart';

class _StatusRepo implements WorkspaceConnectRepository {
  _StatusRepo(this.current);

  final WorkspaceConnectStatus current;

  @override
  Future<WorkspaceConnectStatus> status(String workspaceId) async => current;

  @override
  Future<WorkspaceConnectStatus> set(
    String workspaceId,
    WorkspaceConnectMode mode, {
    String? url,
  }) => throw UnimplementedError();

  @override
  Future<WorkspaceConnectStatus> test(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<WorkspaceConnectStatus> confirmPins(String workspaceId) =>
      throw UnimplementedError();
}

WorkspaceConnectStatus _status(
  WorkspaceConnectMode mode, {
  WorkspaceLaneSource klipy = WorkspaceLaneSource.connect,
}) => WorkspaceConnectStatus(
  mode: mode,
  url: mode == WorkspaceConnectMode.custom ? 'https://connect.example.com' : '',
  effectiveMode: mode == WorkspaceConnectMode.own
      ? WorkspaceConnectEffective.own
      : WorkspaceConnectEffective.hosted,
  lanes: [WorkspaceConnectLane(provider: 'klipy', source: klipy)],
);

const _apps = [
  WorkspaceProviderAppView(
    provider: 'google',
    clientId: 'g-client',
    state: ProviderAppState.partial,
  ),
  WorkspaceProviderAppView(provider: 'linear', clientId: 'lin-client'),
  WorkspaceProviderAppView(provider: 'klipy', hasAppKey: true),
];

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required WorkspaceConnectStatus status,
    WorkspaceRole role = WorkspaceRole.admin,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        // A fresh scope per pump: a test may pump several statuses in turn.
        key: UniqueKey(),
        overrides: [
          isDemoServerProvider.overrideWith((ref) => false),
          activeWorkspaceIdOverride('ws-1'),
          workspacesProvider.overrideWith((ref) => const Stream.empty()),
          myWorkspaceRoleProvider.overrideWith((ref, _) => role),
          workspaceConnectRepositoryProvider.overrideWithValue(
            _StatusRepo(status),
          ),
          workspaceProviderAppsProvider.overrideWith(
            (ref) async => role.isAdmin ? _apps : const [],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            ...appLocalizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: kSupportedAppLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: CcToastScope(
              child: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('WorkspaceOwnAppCard', () {
    testWidgets('shows nothing unless the workspace uses its own apps', (
      tester,
    ) async {
      for (final mode in [
        WorkspaceConnectMode.inherit,
        WorkspaceConnectMode.hosted,
        WorkspaceConnectMode.custom,
      ]) {
        await pump(
          tester,
          const ContributedSection('settings.workspace-app.linear'),
          status: _status(mode),
        );
        expect(find.byType(SectionCard), findsNothing, reason: mode.name);
      }
    });

    testWidgets('own apps: the provider form, with what is missing', (
      tester,
    ) async {
      await pump(
        tester,
        const ContributedSection('settings.workspace-app.google'),
        status: _status(WorkspaceConnectMode.own),
      );
      expect(
        find.text(l10n.workspaceOwnAppTitle('Google Calendar')),
        findsOneWidget,
      );
      expect(find.text('g-client'), findsOneWidget);
      // Half set up is an error, never a fallback to another app.
      expect(find.text(l10n.providerAppPartial), findsOneWidget);
      expect(
        find.text(
          l10n.workspaceProviderAppMissingFields(l10n.providerClientSecret),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a member never sees the form', (tester) async {
      await pump(
        tester,
        const ContributedSection('settings.workspace-app.linear'),
        status: _status(WorkspaceConnectMode.own),
        role: WorkspaceRole.member,
      );
      expect(find.byType(SectionCard), findsNothing);
    });
  });

  group('WorkspaceGifsCard', () {
    testWidgets('says where GIF search runs when the workspace follows', (
      tester,
    ) async {
      await pump(
        tester,
        const ContributedSection('settings.gifs'),
        status: _status(WorkspaceConnectMode.inherit),
      );
      expect(find.text(l10n.workspaceGifsTitle), findsOneWidget);
      expect(find.text(l10n.workspaceGifsSourceConnect), findsOneWidget);
      expect(find.text(l10n.workspaceProviderAppKlipyKey), findsNothing);
    });

    testWidgets('own apps: an admin gets the Klipy key field', (tester) async {
      await pump(
        tester,
        const ContributedSection('settings.gifs'),
        status: _status(
          WorkspaceConnectMode.own,
          klipy: WorkspaceLaneSource.workspaceOwn,
        ),
      );
      expect(find.text(l10n.workspaceGifsSourceWorkspaceOwn), findsOneWidget);
      expect(find.text(l10n.workspaceProviderAppKlipyKey), findsOneWidget);
    });

    testWidgets('own apps: a member only reads the status', (tester) async {
      await pump(
        tester,
        const ContributedSection('settings.gifs'),
        status: _status(
          WorkspaceConnectMode.own,
          klipy: WorkspaceLaneSource.off,
        ),
        role: WorkspaceRole.member,
      );
      expect(find.text(l10n.workspaceGifsSourceOff), findsOneWidget);
      expect(find.text(l10n.workspaceProviderAppKlipyKey), findsNothing);
    });
  });
}
