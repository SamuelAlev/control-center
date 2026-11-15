import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/presentation/repo_deep_link_target.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _workspace = Workspace(
  id: 'ws-1',
  name: 'Shop',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _Workspaces implements WorkspaceRepository {
  @override
  Future<List<Workspace>> getAll() async => [_workspace];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoRepos implements RepoRepository {
  @override
  Future<List<Repo>> getAll(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Active extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

/// A link to a repository no workspace links: only the server's owner may
/// add its checkout (that browses the server's folders).
void main() {
  testWidgets('someone who is not the owner is told to ask the owner', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(_Workspaces()),
        repoRepositoryProvider.overrideWithValue(_NoRepos()),
        activeWorkspaceIdProvider.overrideWith(_Active.new),
        canCreateWorkspacesProvider.overrideWithValue(false),
        canUseHostProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Toasts sit above the navigator, as in the app, so the link
            // (which speaks from the navigator's context) can raise one.
            builder: (context, navigator) => Overlay(
              initialEntries: [
                OverlayEntry(builder: (_) => CcToastScope(child: navigator!)),
              ],
            ),
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );

    final result = await tester.runAsync(
      () => activateLinkedRepo(container, owner: 'acme', repo: 'shop-ui'),
    );
    await tester.pump();

    expect(result?.workspaceId, isNull);
    expect(result?.dismissed, isTrue);
    expect(
      find.text(
        'acme/shop-ui is not linked in any of your workspaces. Ask the '
        'server owner to add it.',
      ),
      findsOneWidget,
    );
    // No add-a-checkout dialog opened.
    expect(find.byType(CcDialog), findsNothing);
    await tester.pump(const Duration(seconds: 10));
  });
}
