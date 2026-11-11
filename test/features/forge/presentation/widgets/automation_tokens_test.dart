import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, RemoteRpcException;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_access_banner.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_automation_tokens_card.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/test_wrap.dart';

/// Answers the three automation-token ops from [tokens]; records each call.
class _FakeRpc implements RemoteRpcClient {
  _FakeRpc(this.tokens);

  final List<Map<String, dynamic>> tokens;
  final calls = <(String, Map<String, dynamic>)>[];
  RemoteRpcException? refuseSave;

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async {
    calls.add((op, args));
    switch (op) {
      case 'forge.listAutomationTokens':
        return {'tokens': tokens};
      case 'forge.setAutomationToken':
        if (refuseSave case final refusal?) {
          throw refusal;
        }
        return {'unreadable_repos': <String>[]};
      default:
        return {};
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRpc.${invocation.memberName}');
}

Repo _repo(String id, String owner, String name, ForgeHost forge) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/src/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  forge: forge,
);

final _api = _repo('r-api', 'group', 'api', ForgeHost.gitlab);
final _web = _repo('r-web', 'group', 'web', ForgeHost.gitlab);
final _svc = _repo('r-svc', 'team', 'svc', ForgeHost.bitbucket);
final _gh = _repo('r-gh', 'acme', 'app', ForgeHost.github);

Widget _wrap(
  Widget child, {
  required _FakeRpc rpc,
  WorkspaceRole? role = WorkspaceRole.admin,
  bool demo = false,
  TextDirection? textDirection,
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdOverride(),
    isDemoServerProvider.overrideWith((ref) => demo),
    myWorkspaceRoleProvider.overrideWith((ref, _) => role),
    workspaceAdminNamesProvider.overrideWith((ref, _) => const ['Ada']),
    rpcClientProvider.overrideWithValue(rpc),
  ],
  child: testWrap(
    SingleChildScrollView(child: child),
    textDirection: textDirection,
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  _FakeRpc rpcWithTokens() => _FakeRpc([
    {
      'forge': 'gitlab',
      'scope': 'repo',
      'repo_id': _api.id,
      'bot_name': 'Deploy bot',
      'bot_login': 'project_7_bot',
      'status': 'active',
    },
    {'forge': 'gitlab', 'scope': 'workspace', 'status': 'active'},
  ]);

  group('RepoAutomationTokensCard', () {
    testWidgets('an admin sees each GitLab/Bitbucket repository and which '
        'bot acts there', (tester) async {
      final rpc = rpcWithTokens();
      await tester.pumpWidget(
        _wrap(
          RepoAutomationTokensCard(
            workspaceId: kTestWorkspaceId,
            repos: [_api, _web, _svc, _gh],
          ),
          rpc: rpc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.automationTokensRepoHint), findsOneWidget);
      expect(find.text(l10n.automationTokenActsAs('Deploy bot')), findsOne);
      // group/web has no token of its own; the workspace's covers it.
      expect(find.text(l10n.automationTokenFromWorkspace), findsOneWidget);
      // Bitbucket has no workspace token: paused.
      expect(find.text(l10n.automationTokenNone), findsOneWidget);
      // GitHub automation rides the App, never a token row.
      expect(find.textContaining('acme/app'), findsNothing);
      expect(rpc.calls.map((c) => c.$1), ['forge.listAutomationTokens']);
    });

    testWidgets('a member sees nothing and nothing is asked of the server', (
      tester,
    ) async {
      final rpc = rpcWithTokens();
      await tester.pumpWidget(
        _wrap(
          RepoAutomationTokensCard(
            workspaceId: kTestWorkspaceId,
            repos: [_api, _svc],
          ),
          rpc: rpc,
          role: WorkspaceRole.member,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.automationTokensRepoHint), findsNothing);
      expect(rpc.calls, isEmpty);
    });

    testWidgets('a demo server shows nothing', (tester) async {
      final rpc = rpcWithTokens();
      await tester.pumpWidget(
        _wrap(
          RepoAutomationTokensCard(
            workspaceId: kTestWorkspaceId,
            repos: [_api],
          ),
          rpc: rpc,
          demo: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.automationTokensRepoHint), findsNothing);
      expect(rpc.calls, isEmpty);
    });

    testWidgets('adding a token stores it for that repository; a refusal '
        'shows the server reason', (tester) async {
      final rpc = _FakeRpc([])
        ..refuseSave = RemoteRpcException(
          RpcErrorCodes.validation,
          'This is a personal access token.',
        );
      await tester.pumpWidget(
        _wrap(
          RepoAutomationTokensCard(
            workspaceId: kTestWorkspaceId,
            repos: [_svc],
          ),
          rpc: rpc,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.addToken));
      await tester.pumpAndSettle();
      expect(find.text(l10n.automationTokenBitbucketHint), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ATCTT-secret');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final save = rpc.calls.lastWhere(
        (c) => c.$1 == 'forge.setAutomationToken',
      );
      expect(save.$2, {
        'workspace_id': kTestWorkspaceId,
        'forge': 'bitbucket',
        'token': 'ATCTT-secret',
        'repo_id': _svc.id,
      });
      expect(find.text('This is a personal access token.'), findsOneWidget);

      rpc.refuseSave = null;
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(find.text(l10n.automationTokenBitbucketHint), findsNothing);
    });

    testWidgets('lays out right to left', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RepoAutomationTokensCard(
            workspaceId: kTestWorkspaceId,
            repos: [_api, _svc],
          ),
          rpc: rpcWithTokens(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final title = tester.getRect(
        find.text(l10n.automationTokenActsAs('Deploy bot')),
      );
      final card = tester.getRect(find.byType(RepoAutomationTokensCard));
      expect(
        card.right - title.right,
        lessThan(title.left - card.left),
        reason: 'the row status starts at the right edge under RTL',
      );
    });
  });

  group('RepoAccessBanner automation token notice', () {
    final missing = RepoAccessIssue(
      forge: ForgeHost.gitlab,
      owner: 'group',
      name: 'api',
      repoId: 'r-api',
      state: RepoAccessState.automationTokenMissing,
    );

    testWidgets("an admin gets 'Add token' for the repository", (tester) async {
      await tester.pumpWidget(
        _wrap(RepoAccessBanner(issues: [missing]), rpc: _FakeRpc([])),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.repoAccessAutomationTokenMissingBody('group/api')),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.addToken));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.automationTokenDialogTitle('GitLab')),
        findsOneWidget,
      );
      expect(find.text(l10n.automationTokenGitLabHint), findsOneWidget);
    });

    testWidgets('a member is told whom to ask and gets no action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RepoAccessBanner(issues: [missing]),
          rpc: _FakeRpc([]),
          role: WorkspaceRole.member,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(l10n.repoAccessAskAdmins('Ada')),
        findsOneWidget,
      );
      expect(find.text(l10n.addToken), findsNothing);
    });
  });
}
