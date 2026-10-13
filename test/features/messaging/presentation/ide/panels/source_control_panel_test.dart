import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/source_control_panel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/space_stack_provider.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/shared/widgets/source_control/scm_commit_box.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/fake_rpc_client.dart';
import '../../../../../helpers/test_wrap.dart';

class _CommitHost extends FakeRpcHost {
  late final rpc = client();
}

Repo _repo(String id) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: 'helix',
  remoteName: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

IsolatedRepo _worktree(String workspace, String space, String repo) =>
    IsolatedRepo(
      id: '$workspace-$space-$repo',
      workspaceId: workspace,
      spaceId: space,
      repoId: repo,
      path: '/tmp/$workspace/$space/$repo',
      branch: 'feature/$space',
      backend: RepoIsolationBackend.rift,
      sourcePath: '/tmp/$repo',
      createdAt: DateTime.utc(2026),
    );

final _staged = PrFile(
  filename: 'changed.txt',
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 0,
  patch: '',
);

Widget _panel(String workspace, String space) => SourceControlPanel(
  workspaceId: workspace,
  spaceId: space,
  onOpenReview: (_) {},
  onViewSource: (_) {},
  onRevertFiles: (_) {},
);

Widget _app(Widget child, _CommitHost host) => ProviderScope(
  overrides: [
    activeWorkspaceIdOverride(),
    rpcClientProvider.overrideWithValue(host.rpc),
    reposForWorkspaceProvider.overrideWith(
      (ref, workspace) => Stream.value([_repo('alpha'), _repo('beta')]),
    ),
    spaceWorktreesProvider.overrideWith(
      (ref, args) async => [
        _worktree(args.workspaceId, args.spaceId, 'alpha'),
        _worktree(args.workspaceId, args.spaceId, 'beta'),
      ],
    ),
    spaceProvisioningStatusProvider.overrideWith(
      (ref, space) => SpaceProvisioningStatus.ready,
    ),
    spaceBranchPullRequestForRepoProvider.overrideWith((ref, key) => null),
    repoChangesGroupedProvider.overrideWith(
      (ref, args) async => (
        staged: [_staged],
        unstaged: <PrFile>[],
        hasUpstream: false,
        ahead: 0,
        behind: 0,
        aheadOfBase: 0,
        aheadOfBaseKnown: false,
        statusKnown: false,
      ),
    ),
  ],
  child: testWrap(child),
);

Future<void> _show(WidgetTester tester, _CommitHost host, Widget child) async {
  await tester.pumpWidget(_app(child, host));
  await tester.pump();
  await tester.pump();
}

String _input(WidgetTester tester, int index) => tester
    .widget<EditableText>(find.byType(EditableText).at(index))
    .controller
    .text;

SpaceStackLayer _layer(int position, {int? prNumber}) => SpaceStackLayer(
  repoId: 'alpha',
  position: position,
  branch: position == 0 ? 'feature/base' : 'feature/space-a',
  baseBranch: position == 0 ? 'main' : 'feature/base',
  label: position == 0 ? 'Base' : 'Next',
  current: position == 1,
  prNumber: prNumber,
);

PullRequest _pr(
  int number, {
  String head = 'feature/space-a',
  String repo = 'helix/alpha',
}) => PullRequest(
  id: number,
  number: number,
  title: 'Part $number',
  body: '',
  state: PrState.open,
  isDraft: true,
  author: null,
  createdAt: null,
  updatedAt: null,
  repoFullName: repo,
  htmlUrl: '',
  headRef: head,
);

Widget _stackApp({
  required List<SpaceStackLayer> layers,
  List<PullRequest> pullRequests = const [],
  PullRequest? currentPr,
  bool complete = true,
}) => _app(
  ProviderScope(
    overrides: [
      reposForWorkspaceProvider.overrideWith(
        (ref, workspace) => Stream.value([_repo('alpha')]),
      ),
      spaceStackProvider.overrideWith((ref, space) async => layers),
      spacePullRequestsProvider.overrideWith((ref, space) => pullRequests),
      spaceBranchPullRequestsProvider.overrideWith(
        (ref, space) => Stream.value((matches: const [], complete: complete)),
      ),
      spaceBranchPullRequestForRepoProvider.overrideWith(
        (ref, key) => currentPr,
      ),
      repoChangesGroupedProvider.overrideWith(
        (ref, args) async => (
          staged: <PrFile>[],
          unstaged: <PrFile>[],
          hasUpstream: true,
          ahead: 3,
          behind: 0,
          aheadOfBase: 3,
          aheadOfBaseKnown: true,
          statusKnown: true,
        ),
      ),
    ],
    child: _panel('workspace-a', 'space-a'),
  ),
  _CommitHost()
    ..onCall = (op, args) => {'ok': true, 'content': '', 'files': const []},
);

void main() {
  testWidgets(
    'conversation commit input survives panel navigation and isolates worktrees',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final host = _CommitHost()
        ..onCall = (op, args) => {'ok': true, 'content': '', 'files': const []};
      await _show(tester, host, _panel('workspace-a', 'space-a'));
      await tester.enterText(find.byType(EditableText).at(0), 'Alpha draft');
      await tester.enterText(find.byType(EditableText).at(1), 'Beta draft');
      await _show(tester, host, const SizedBox.shrink());
      await _show(tester, host, _panel('workspace-a', 'space-a'));
      expect(_input(tester, 0), 'Alpha draft');
      expect(_input(tester, 1), 'Beta draft');

      await _show(tester, host, _panel('workspace-a', 'space-b'));
      expect(_input(tester, 0), isEmpty);
      expect(_input(tester, 1), isEmpty);
      await _show(tester, host, _panel('workspace-b', 'space-a'));
      expect(_input(tester, 0), isEmpty);
      expect(_input(tester, 1), isEmpty);
      await _show(tester, host, _panel('workspace-a', 'space-a'));
      expect(_input(tester, 0), 'Alpha draft');
      expect(_input(tester, 1), 'Beta draft');
    },
  );

  testWidgets(
    'conversation commit retains failures and clears only successful repo',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var committed = false;
      var pushed = false;
      final calls = <Map<String, dynamic>>[];
      final host = _CommitHost()
        ..onCall = (op, args) {
          if (op == 'worktree.commitAndPush') {
            calls.add(args);
            return {'ok': true, 'committed': committed, 'pushed': pushed};
          }
          return {'ok': true, 'content': '', 'files': const []};
        };
      await _show(tester, host, _panel('workspace-a', 'space-a'));
      await tester.enterText(find.byType(EditableText).at(0), 'Alpha draft');
      await tester.enterText(find.byType(EditableText).at(1), 'Beta draft');
      void submit(ScmCommitAction action) => tester
          .widget<ScmCommitBox>(find.byType(ScmCommitBox).first)
          .onAction(action);

      submit(ScmCommitAction.commit);
      await tester.pump();
      await tester.pump();
      expect(_input(tester, 0), 'Alpha draft');
      committed = true;
      submit(ScmCommitAction.commitAndPush);
      await tester.pump();
      await tester.pump();
      expect(_input(tester, 0), 'Alpha draft');
      pushed = true;
      submit(ScmCommitAction.commit);
      await tester.pump();
      await tester.pump();
      expect(_input(tester, 0), isEmpty);
      expect(_input(tester, 1), 'Beta draft');
      expect(calls.map((c) => c['repo_id']), ['alpha', 'alpha', 'alpha']);
      expect(calls.map((c) => c['space_id']), [
        'space-a',
        'space-a',
        'space-a',
      ]);
    },
  );

  group('stack pull request actions', () {
    testWidgets('recorded PRs replace publishing and single-PR actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _stackApp(
          layers: [_layer(1, prNumber: 11), _layer(0, prNumber: 10)],
          currentPr: _pr(11),
          complete: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publish stack'), findsNothing);
      expect(find.text('View pull request #11'), findsNothing);
      await tester.tap(find.text('feature/space-a'));
      await tester.pumpAndSettle();
      expect(find.text('Publish stack'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stacked pull requests (2)'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('#10 · Base')).dy,
        lessThan(tester.getTopLeft(find.text('#11 · Next')).dy),
      );
    });

    testWidgets('PRs created outside stack.publish count as published parts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _stackApp(
          layers: [_layer(0), _layer(1)],
          pullRequests: [
            _pr(10, head: 'feature/base'),
            _pr(11),
          ],
          currentPr: _pr(11),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publish stack'), findsNothing);
      expect(find.text('View pull request #11'), findsNothing);
      await tester.tap(find.text('Stacked pull requests (2)'));
      await tester.pumpAndSettle();
      expect(find.text('#10 · Base'), findsOneWidget);
      expect(find.text('#11 · Next'), findsOneWidget);
    });

    testWidgets('a partial stack keeps publishing and opens its existing PRs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _stackApp(
          layers: [_layer(0, prNumber: 10), _layer(1)],
          currentPr: _pr(10, head: 'feature/base'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publish stack'), findsOneWidget);
      expect(find.text('View pull request #10'), findsNothing);
      await tester.tap(find.text('Stacked pull requests (1)'));
      await tester.pumpAndSettle();
      expect(find.text('#10 · Base'), findsOneWidget);
      expect(find.textContaining('Next'), findsNothing);
    });

    testWidgets(
      'another repo cannot make an unpublished stack look published',
      (tester) async {
        await tester.pumpWidget(
          _stackApp(
            layers: [_layer(0), _layer(1)],
            pullRequests: [
              _pr(10, head: 'feature/base', repo: 'helix/beta'),
              _pr(11, repo: 'helix/beta'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Publish stack'), findsOneWidget);
        expect(find.textContaining('Stacked pull requests'), findsNothing);
        expect(find.text('Create pull request'), findsNothing);
        await tester.tap(find.text('feature/space-a'));
        await tester.pumpAndSettle();
        expect(find.text('Publish stack'), findsNWidgets(2));
      },
    );

    testWidgets('an incomplete lookup is not evidence of unpublished parts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _stackApp(layers: [_layer(0), _layer(1)], complete: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publish stack'), findsNothing);
      expect(find.text('Create pull request'), findsNothing);
    });

    testWidgets('a single branch retains its direct PR action', (tester) async {
      await tester.pumpWidget(
        _stackApp(layers: [_layer(1, prNumber: 11)], currentPr: _pr(11)),
      );
      await tester.pumpAndSettle();

      expect(find.text('View pull request #11'), findsOneWidget);
      expect(find.text('Publish stack'), findsNothing);
      expect(find.textContaining('Stacked pull requests'), findsNothing);
    });
  });
}
