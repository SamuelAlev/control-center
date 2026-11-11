import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart'
    show externalUrlOpenerProvider;
import 'package:control_center/features/forge/presentation/widgets/hidden_repos_notice.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_access_banner.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/test_wrap.dart';

const _installUrl = 'https://github.com/apps/cc/installations/new';

RepoAccessIssue _issue(
  String name,
  RepoAccessState state, {
  String owner = 'acme',
  String? installUrl,
}) => RepoAccessIssue(
  forge: ForgeHost.github,
  owner: owner,
  name: name,
  state: state,
  installUrl: installUrl,
);

Widget _wrap(
  Widget child, {
  WorkspaceRole? role,
  List<String> admins = const [],
  List<String>? opened,
  TextDirection? textDirection,
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdOverride(),
    myWorkspaceRoleProvider.overrideWith((ref, _) => role),
    workspaceAdminNamesProvider.overrideWith((ref, _) => admins),
    externalUrlOpenerProvider.overrideWithValue((url) {
      opened?.add(url);
      return true;
    }),
  ],
  child: testWrap(child, textDirection: textDirection),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('RepoAccessBanner', () {
    testWidgets('renders nothing while every repository is reachable', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const RepoAccessBanner(issues: [])));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('an admin gets the install page for a missing App', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _wrap(
          RepoAccessBanner(
            issues: [
              _issue(
                'api',
                RepoAccessState.appNotInstalled,
                installUrl: _installUrl,
              ),
              _issue('web', RepoAccessState.appNotInstalled),
            ],
          ),
          role: WorkspaceRole.admin,
          opened: opened,
        ),
      );
      await tester.pumpAndSettle();
      // One notice per owner, naming both repositories.
      expect(find.text(l10n.repoAccessInstallTitle('acme')), findsOneWidget);
      expect(
        find.text(l10n.repoAccessInstallBody('acme/api, acme/web')),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.githubInstallApp));
      expect(opened, [_installUrl]);
    });

    testWidgets('a member is told who to ask and gets no install button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RepoAccessBanner(
            issues: [
              _issue(
                'api',
                RepoAccessState.repoNotSelected,
                installUrl: _installUrl,
              ),
            ],
          ),
          role: WorkspaceRole.member,
          admins: const ['Ana Lima'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.repoAccessSelectTitle('acme/api')), findsOneWidget);
      expect(
        find.text(
          '${l10n.repoAccessSelectBody} ${l10n.repoAccessAskAdmins('Ana Lima')}',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.repoAccessChooseRepos), findsNothing);
    });

    testWidgets('each remaining state reads distinctly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RepoAccessBanner(
            issues: [
              _issue('a', RepoAccessState.installationSuspended),
              _issue('b', RepoAccessState.ownerCannotSee),
              _issue('c', RepoAccessState.ownerNotSignedIn),
              _issue('d', RepoAccessState.transient),
            ],
          ),
          role: WorkspaceRole.admin,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.repoAccessSuspendedTitle), findsOneWidget);
      expect(find.text(l10n.repoAccessSuspendedBody('acme/a')), findsOneWidget);
      expect(
        find.text(l10n.repoAccessOwnerCannotSeeBody('acme/b')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.repoAccessOwnerNotSignedInBody('acme/c')),
        findsOneWidget,
      );
      expect(find.text(l10n.repoAccessTransient('acme/d')), findsOneWidget);
    });

    testWidgets('renders right to left', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RepoAccessBanner(
            issues: [
              _issue(
                'api',
                RepoAccessState.appNotInstalled,
                installUrl: _installUrl,
              ),
              _issue('d', RepoAccessState.transient),
            ],
          ),
          role: WorkspaceRole.admin,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.githubInstallApp), findsOneWidget);
    });
  });

  group('a replaced repository', () {
    final repo = Repo(
      id: 'r-api',
      name: 'acme/api',
      path: '/srv/acme-api',
      remoteOwner: 'acme',
      remoteName: 'api',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final issue = RepoAccessIssue(
      forge: ForgeHost.github,
      owner: 'acme',
      name: 'api',
      repoId: 'r-api',
      state: RepoAccessState.repoReplaced,
    );

    Widget scope(WorkspaceRole role, List<bool> relinks) => ProviderScope(
      overrides: [
        reposForWorkspaceProvider(
          kTestWorkspaceId,
        ).overrideWith((ref) => Stream.value([repo])),
        linkRepoProvider.overrideWithValue((
          workspaceId,
          linked, {
          relink = false,
        }) async {
          relinks.add(relink);
          return (repoId: linked.id, issues: const <RepoAccessIssue>[]);
        }),
      ],
      child: _wrap(RepoAccessBanner(issues: [issue]), role: role),
    );

    testWidgets('an admin relinks it', (tester) async {
      final relinks = <bool>[];
      await tester.pumpWidget(scope(WorkspaceRole.admin, relinks));
      await tester.pumpAndSettle();

      expect(find.text(l10n.repoAccessReplacedTitle('acme/api')), findsOne);
      expect(find.text(l10n.repoAccessReplacedBody('GitHub')), findsOneWidget);
      await tester.tap(find.text(l10n.repoRelink));
      await tester.pumpAndSettle();

      expect(relinks, [true]);
      expect(find.text(l10n.repoRelinked('acme/api')), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a member is told who to ask, with nothing to press', (
      tester,
    ) async {
      await tester.pumpWidget(scope(WorkspaceRole.member, <bool>[]));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '${l10n.repoAccessReplacedBody('GitHub')} '
          '${l10n.repoAccessAskAnAdmin}',
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.repoRelink), findsNothing);
    });
  });

  group('HiddenReposNotice', () {
    testWidgets('renders nothing when nothing is hidden', (tester) async {
      await tester.pumpWidget(_wrap(const HiddenReposNotice(hidden: [])));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('each reason reads distinctly with counts only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HiddenReposNotice(
            hidden: [
              HiddenRepos(
                forge: ForgeHost.github,
                reason: HiddenRepoReason.signInRequired,
                count: 2,
              ),
              HiddenRepos(
                forge: ForgeHost.gitlab,
                reason: HiddenRepoReason.noForgeAccess,
                count: 1,
              ),
              HiddenRepos(
                forge: ForgeHost.github,
                reason: HiddenRepoReason.noGrant,
                count: 3,
              ),
              HiddenRepos(
                forge: ForgeHost.github,
                reason: HiddenRepoReason.checking,
                count: 1,
              ),
              HiddenRepos(
                forge: ForgeHost.gitlab,
                reason: HiddenRepoReason.checking,
                count: 2,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.hiddenReposSignIn(2, 'GitHub')), findsOneWidget);
      expect(
        find.text(l10n.hiddenReposNoForgeAccess(1, 'GitLab')),
        findsOneWidget,
      );
      expect(find.text(l10n.hiddenReposNoGrant(3)), findsOneWidget);
      // Checks still running are summed into one quiet line.
      expect(find.text(l10n.hiddenReposChecking(3)), findsOneWidget);
    });

    testWidgets('a token forge offers the token, GitHub its sign-in', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HiddenReposNotice(
            hidden: [
              HiddenRepos(
                forge: ForgeHost.gitlab,
                reason: HiddenRepoReason.signInRequired,
                count: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.addToken), findsOneWidget);
    });

    testWidgets('renders right to left', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HiddenReposNotice(
            hidden: [
              HiddenRepos(
                forge: ForgeHost.github,
                reason: HiddenRepoReason.signInRequired,
                count: 1,
              ),
              HiddenRepos(
                forge: ForgeHost.github,
                reason: HiddenRepoReason.checking,
                count: 1,
              ),
            ],
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.hiddenReposSignIn(1, 'GitHub')), findsOneWidget);
    });
  });
}
