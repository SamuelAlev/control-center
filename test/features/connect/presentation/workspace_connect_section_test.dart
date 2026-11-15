import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/connect/domain/repositories/workspace_connect_repository.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/connect/presentation/settings/workspace_connect_section.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/active_workspace.dart';

/// Records every `workspaceConnect.*` call and answers with [current].
class _FakeRepo implements WorkspaceConnectRepository {
  _FakeRepo(this.current);

  WorkspaceConnectStatus current;
  final calls = <(String, Map<String, Object?>)>[];

  @override
  Future<WorkspaceConnectStatus> status(String workspaceId) async {
    calls.add(('status', {'workspace_id': workspaceId}));
    return current;
  }

  @override
  Future<WorkspaceConnectStatus> set(
    String workspaceId,
    WorkspaceConnectMode mode, {
    String? url,
  }) async {
    calls.add(('set', {'workspace_id': workspaceId, 'mode': mode, 'url': url}));
    return current = WorkspaceConnectStatus(
      mode: mode,
      url: url ?? '',
      serverMode: current.serverMode,
      effectiveMode: WorkspaceConnectEffective.own,
    );
  }

  @override
  Future<WorkspaceConnectStatus> test(String workspaceId) async {
    calls.add(('test', {'workspace_id': workspaceId}));
    return current;
  }

  @override
  Future<WorkspaceConnectStatus> confirmPins(String workspaceId) async {
    calls.add(('confirmPins', {'workspace_id': workspaceId}));
    return current;
  }

  Iterable<String> get ops =>
      calls.map((c) => c.$1).where((o) => o != 'status');
}

WorkspaceConnectStatus _inheritHosted({bool locked = false}) =>
    WorkspaceConnectStatus(
      mode: WorkspaceConnectMode.inherit,
      serverMode: ServerConnectChoice.hosted,
      serverUrl: 'https://connect.controlcenter.example',
      effectiveMode: WorkspaceConnectEffective.hosted,
      locked: locked,
      health: WorkspaceConnectHealth.ok,
      epoch: 7,
      installId: 'INST01',
      lanes: [
        WorkspaceConnectLane(
          provider: 'github',
          source: WorkspaceLaneSource.connect,
        ),
        WorkspaceConnectLane(
          provider: 'klipy',
          source: WorkspaceLaneSource.off,
          error: 'Klipy is not set up on this Connect.',
        ),
      ],
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<_FakeRepo> pump(
    WidgetTester tester, {
    required WorkspaceConnectStatus status,
    WorkspaceRole role = WorkspaceRole.admin,
    bool demo = false,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo(status);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDemoServerProvider.overrideWith((ref) => demo),
          activeWorkspaceIdOverride('ws-1'),
          workspacesProvider.overrideWith((ref) => const Stream.empty()),
          myWorkspaceRoleProvider.overrideWith((ref, _) => role),
          workspaceConnectRepositoryProvider.overrideWithValue(repo),
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
              child: Scaffold(
                body: Directionality(
                  textDirection: textDirection,
                  child: const SingleChildScrollView(
                    child: WorkspaceConnectSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Finder apply() => find.widgetWithText(CcButton, l10n.apply);

  testWidgets('an admin sees the facts, four choices, lanes and install id', (
    tester,
  ) async {
    await pump(tester, status: _inheritHosted());

    // Section labels render uppercase.
    expect(find.text(l10n.connectTitle.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.workspaceConnectDescription), findsOneWidget);
    // Facts row: the choice (also the radio title), health, version.
    expect(find.text(l10n.workspaceConnectModeInherit), findsNWidgets(2));
    expect(find.text(l10n.connectHealthOk), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    // "Same as this server" names what the server uses.
    expect(find.text(l10n.workspaceConnectInheritHosted), findsOneWidget);
    expect(find.text(l10n.connectModeHosted), findsOneWidget);
    expect(find.text(l10n.connectModeOwn), findsOneWidget);
    expect(find.text(l10n.connectModeCustom), findsOneWidget);
    // Where each sign-in runs.
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Klipy is not set up on this Connect.'), findsOneWidget);
    expect(find.text('INST01'), findsOneWidget);
    expect(find.widgetWithText(CcButton, l10n.testLabel), findsOneWidget);
    expect(apply(), findsNothing);
  });

  testWidgets('switching to own apps confirms, then sets and publishes', (
    tester,
  ) async {
    final repo = await pump(tester, status: _inheritHosted());

    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pumpAndSettle();
    await tester.tap(apply());
    await tester.pumpAndSettle();
    expect(find.text(l10n.workspaceConnectSwitchTitle), findsOneWidget);
    expect(repo.ops, isEmpty);

    await tester.tap(find.text(l10n.workspaceConnectSwitchAction));
    await tester.pumpAndSettle();
    expect(repo.ops, ['set']);
    expect(repo.calls.last.$2, {
      'workspace_id': 'ws-1',
      'mode': WorkspaceConnectMode.own,
      'url': null,
    });
    // The returned status is what the card shows now.
    expect(find.text(l10n.connectModeOwn), findsNWidgets(2));
    expect(apply(), findsNothing);
  });

  testWidgets('a member reads the choice but cannot change it', (tester) async {
    final repo = await pump(
      tester,
      status: WorkspaceConnectStatus(
        mode: WorkspaceConnectMode.inherit,
        serverMode: ServerConnectChoice.off,
        effectiveMode: WorkspaceConnectEffective.serverOwn,
        lanes: [
          WorkspaceConnectLane(
            provider: 'google',
            source: WorkspaceLaneSource.serverOwn,
          ),
        ],
      ),
      role: WorkspaceRole.member,
    );

    expect(find.text(l10n.workspaceConnectInheritOwn), findsOneWidget);
    expect(find.text(l10n.workspaceConnectLaneServerOwn), findsOneWidget);
    expect(find.text(l10n.settingsWorkspaceAdminOnly), findsOneWidget);
    expect(find.text(l10n.connectInstallId), findsNothing);

    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pumpAndSettle();
    expect(apply(), findsNothing);
    expect(repo.ops, isEmpty);
  });

  testWidgets('a locked server leaves only following it or own apps', (
    tester,
  ) async {
    await pump(tester, status: _inheritHosted(locked: true));

    expect(find.text(l10n.workspaceConnectLocked), findsOneWidget);
    await tester.tap(find.text(l10n.connectModeCustom));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(apply(), findsNothing);

    await tester.tap(find.text(l10n.connectModeOwn));
    await tester.pumpAndSettle();
    expect(apply(), findsOneWidget);
  });

  testWidgets('a custom Connect needs HTTPS before anything is sent', (
    tester,
  ) async {
    final repo = await pump(tester, status: _inheritHosted());

    await tester.tap(find.text(l10n.connectModeCustom));
    await tester.pumpAndSettle();
    expect(find.text(l10n.workspaceConnectCustomUrlHint), findsOneWidget);

    // Loopback HTTP is the server owner's privilege, never a workspace's.
    await tester.enterText(find.byType(EditableText), 'http://127.0.0.1:8787');
    await tester.pump();
    await tester.tap(apply());
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectCustomUrlInvalid), findsOneWidget);
    expect(repo.ops, isEmpty);

    await tester.enterText(
      find.byType(EditableText),
      'https://connect.example.com',
    );
    await tester.pump();
    await tester.tap(apply());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.workspaceConnectSwitchAction));
    await tester.pumpAndSettle();
    expect(repo.calls.last.$2, {
      'workspace_id': 'ws-1',
      'mode': WorkspaceConnectMode.custom,
      'url': 'https://connect.example.com',
    });
  });

  testWidgets('changed pins wait for an admin to trust them', (tester) async {
    final repo = await pump(
      tester,
      status: WorkspaceConnectStatus(
        mode: WorkspaceConnectMode.custom,
        url: 'https://connect.example.com',
        effectiveMode: WorkspaceConnectEffective.custom,
        health: WorkspaceConnectHealth.down,
        error: ConnectHealthError.pinsChanged,
        installId: 'INST01',
        pendingPins: const {'github_app_id': '42'},
      ),
    );
    expect(find.text(l10n.connectErrorPinsChanged), findsOneWidget);
    expect(find.text('github_app_id  42'), findsOneWidget);
    await tester.tap(find.widgetWithText(CcButton, l10n.connectConfirmPins));
    await tester.pumpAndSettle();
    expect(repo.ops, ['confirmPins']);
  });

  testWidgets('a member sees changed pins but cannot trust them', (
    tester,
  ) async {
    await pump(
      tester,
      status: WorkspaceConnectStatus(
        mode: WorkspaceConnectMode.custom,
        url: 'https://connect.example.com',
        effectiveMode: WorkspaceConnectEffective.custom,
        health: WorkspaceConnectHealth.down,
        error: ConnectHealthError.pinsChanged,
      ),
      role: WorkspaceRole.member,
    );
    expect(find.text(l10n.connectErrorPinsChanged), findsOneWidget);
    expect(
      find.widgetWithText(CcButton, l10n.connectConfirmPins),
      findsNothing,
    );
  });

  testWidgets('a demo server says so and never asks', (tester) async {
    final repo = await pump(tester, status: _inheritHosted(), demo: true);
    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text(l10n.workspaceConnectModeInherit), findsNothing);
    expect(repo.calls, isEmpty);
  });

  testWidgets('lays out right to left without overflow', (tester) async {
    await pump(
      tester,
      status: _inheritHosted(),
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    // The radio leads the row on the reading side: right of its title.
    final radio = tester.getCenter(
      find.byType(CcRadio<WorkspaceConnectMode>).at(1),
    );
    final title = tester.getCenter(find.text(l10n.connectModeHosted));
    expect(radio.dx, greaterThan(title.dx));
  });
}
