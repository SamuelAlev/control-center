import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_editor.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

/// Mounts [origin] on its own route, with Settings → Environments on another,
/// so nothing on the settings page is alive until the origin navigates there.
Future<void> _pump(
  WidgetTester tester,
  FakeEnvironmentRepository repository,
  Widget origin,
) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = historyTestRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Center(child: origin),
      ),
      ...environmentSettingsRoutes(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isDemoServerProvider.overrideWith((ref) => false),
        environmentRepositoryProvider.overrideWithValue(repository),
        activeWorkspaceIdOverride(kWorkspace),
        myWorkspaceRoleProvider.overrideWith((ref, _) => WorkspaceRole.admin),
        reposForWorkspaceProvider.overrideWith(
          (ref, _) => Stream.value(const <Repo>[]),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: kSupportedAppLocales,
        locale: const Locale('en'),
        builder: (context, child) => CcTheme(
          data: CcThemeData.light(),
          child: CcToastScope(child: child ?? const SizedBox.shrink()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Edit definition lands on the editor, not the list', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
      EnvironmentOverflowMenu(
        spaceKey: (workspaceId: kWorkspace, spaceId: kSpace),
        environment: environment(),
      ),
    );

    await tester.tap(find.byType(CcMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit definition'));
    await tester.pumpAndSettle();

    expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);
  });

  testWidgets('setting up a repo lands on its definition, not the list', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
      Consumer(
        builder: (context, ref, _) => CcButton(
          onPressed: () => openEnvironmentSetup(
            context,
            ref,
            workspaceId: kWorkspace,
            repoId: 'repo-1',
          ),
          child: const Text('Set up'),
        ),
      ),
    );

    await tester.tap(find.text('Set up'));
    await tester.pumpAndSettle();

    expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);
  });
}
