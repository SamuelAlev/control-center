import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart'
    show RepoAccessIssue;
import 'package:cc_domain/core/domain/value_objects/repo_path_issue.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/presentation/settings/repos_settings_view.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Active extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-test';
}

Repo _repo(String id) => Repo(
  id: id,
  name: 'acme/$id',
  path: '/Users/sam/code/$id',
  remoteOwner: 'acme',
  remoteName: id,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

const _hostPath =
    "This folder is outside the workspace's storage. Confirm that this server "
    'may use it.';
const _askOwner =
    "This folder is outside the workspace's storage. Only the server's owner "
    'can confirm it.';

void main() {
  late StreamController<Map<String, RepoPathIssue>> issues;
  late List<String> linked;

  setUp(() {
    issues = StreamController<Map<String, RepoPathIssue>>();
    linked = [];
  });
  tearDown(() => issues.close());

  Future<void> pump(
    WidgetTester tester, {
    required List<Repo> repos,
    required Map<String, RepoPathIssue> initial,
    required bool owner,
    bool admin = false,
    TextDirection direction = TextDirection.ltr,
  }) async {
    issues.add(initial);
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_Active.new),
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          canUseHostProvider.overrideWithValue(owner),
          myWorkspaceRoleProvider('ws-test').overrideWithValue(
            admin ? WorkspaceRole.admin : WorkspaceRole.member,
          ),
          reposForWorkspaceProvider(
            'ws-test',
          ).overrideWith((ref) => Stream.value(repos)),
          repoPathIssuesProvider(
            'ws-test',
          ).overrideWith((ref) => issues.stream),
          linkRepoProvider.overrideWithValue((
            workspaceId,
            repo, {
            relink = false,
          }) async {
            linked.add(repo.id);
            return (repoId: repo.id, issues: const <RepoAccessIssue>[]);
          }),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                Directionality(textDirection: direction, child: child!),
            home: const Scaffold(body: ReposSettingsView()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('the owner confirms a folder, and the notice clears when the '
      'server re-sends the repository', (tester) async {
    await pump(
      tester,
      repos: [_repo('shop-ui')],
      initial: {'shop-ui': RepoPathIssue.hostPath},
      owner: true,
    );
    expect(find.text(_hostPath), findsOneWidget);
    // One repository needs no list-level action.
    expect(find.text('Confirm all'), findsNothing);

    await tester.tap(find.widgetWithText(CcButton, 'Confirm'));
    await tester.pump();
    expect(linked, ['shop-ui']);

    issues.add(const {});
    await tester.pump();
    await tester.pump();
    expect(find.text(_hostPath), findsNothing);
    expect(find.widgetWithText(CcButton, 'Confirm'), findsNothing);
  });

  testWidgets('someone else is told who can confirm, with no action', (
    tester,
  ) async {
    await pump(
      tester,
      repos: [_repo('shop-ui'), _repo('api-server')],
      initial: {
        'shop-ui': RepoPathIssue.hostPath,
        'api-server': RepoPathIssue.hostPath,
      },
      owner: false,
    );
    expect(find.text(_askOwner), findsNWidgets(2));
    expect(find.widgetWithText(CcButton, 'Confirm'), findsNothing);
    expect(find.text('Confirm all'), findsNothing);
  });

  testWidgets('Confirm all re-saves each folder in turn', (tester) async {
    await pump(
      tester,
      repos: [_repo('shop-ui'), _repo('api-server'), _repo('docs')],
      initial: {
        'shop-ui': RepoPathIssue.hostPath,
        'api-server': RepoPathIssue.hostPath,
        'docs': RepoPathIssue.missing,
      },
      owner: true,
    );
    expect(
      find.text("2 folders are outside the workspace's storage"),
      findsOneWidget,
    );
    expect(
      find.text(
        'Nothing exists at this path on the server anymore. Remove this '
        'repository and add it again from its current folder.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(CcButton, 'Confirm all'));
    await tester.pump();
    await tester.pump();
    expect(linked, ['shop-ui', 'api-server']);
  });

  testWidgets('an unusable folder says to remove it and add it again, with '
      'Remove for an admin', (tester) async {
    await pump(
      tester,
      repos: [_repo('shop-ui')],
      initial: {'shop-ui': RepoPathIssue.workspaceRoot},
      owner: true,
      admin: true,
    );
    expect(
      find.text(
        "This folder can't be used as a repository. Remove it and add the "
        'repository from another folder.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(CcButton, 'Confirm'), findsNothing);
    expect(find.widgetWithText(CcButton, 'Remove'), findsOneWidget);
  });

  testWidgets('a member gets no Remove on an unusable folder', (tester) async {
    await pump(
      tester,
      repos: [_repo('shop-ui')],
      initial: {'shop-ui': RepoPathIssue.missing},
      owner: false,
    );
    expect(find.widgetWithText(CcButton, 'Remove'), findsNothing);
  });

  testWidgets('right to left, the notice wraps without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    await pump(
      tester,
      repos: [_repo('shop-ui')],
      initial: {'shop-ui': RepoPathIssue.hostPath},
      owner: true,
      direction: TextDirection.rtl,
    );
    tester.view.physicalSize = const Size(420, 900);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(_hostPath), findsOneWidget);
    final text = tester.getRect(find.text(_hostPath));
    final button = tester.getRect(find.widgetWithText(CcButton, 'Confirm'));
    // The action closes the line, which in RTL is to the text's left.
    expect(button.right, lessThanOrEqualTo(text.left));
  });
}
