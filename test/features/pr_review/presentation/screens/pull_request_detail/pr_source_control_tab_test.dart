import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_source_control_tab.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/source_control/scm_commit_box.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/fake_rpc_client.dart';
import '../../../../../helpers/test_wrap.dart';

PullRequest _pr({int number = 412, String repo = 'helix/evalkit'}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Cap eval-run token budget per model family',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: repo,
    htmlUrl: 'https://example.invalid/$repo/pull/$number',
    headRef: 'review/$number',
  );
}

class _CommitHost extends FakeRpcHost {
  _CommitHost() {
    onCall = (op, args) {
      if (op == 'worktree.commitAndPush') {
        calls.add(args);
        return {'ok': true, 'committed': committed, 'pushed': pushed};
      }
      return {'ok': true, 'content': '', 'files': const []};
    };
  }

  late final rpc = client();
  Completer<void>? releaseCommit;
  final commitEntered = Completer<void>();
  final calls = <Map<String, dynamic>>[];
  bool committed = true;
  bool pushed = true;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (frame['method'] == 'repo/call' &&
        (frame['params'] as Map?)?['op'] == 'worktree.commitAndPush' &&
        releaseCommit != null) {
      if (!commitEntered.isCompleted) {
        commitEntered.complete();
      }
      await releaseCommit!.future;
    }
    await super.send(frame);
  }
}

final _staged = PrFile(
  filename: 'changed.txt',
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 0,
  patch: '',
);

Repo _repo(String id, String name) => Repo(
  id: id,
  name: name,
  path: '/tmp/$name',
  remoteOwner: 'helix',
  remoteName: name,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Widget _testWorkbench(Widget child, _CommitHost host) => ProviderScope(
  overrides: [
    activeWorkspaceIdOverride(),
    rpcClientProvider.overrideWithValue(host.rpc),
    reposForWorkspaceProvider.overrideWith(
      (ref, workspaceId) => Stream.value([
        _repo('repo-evalkit', 'evalkit'),
        _repo('repo-other', 'other'),
      ]),
    ),
    prSpaceProvider.overrideWith(
      (ref, key) async => 'review-space-${key.repoFullName}-${key.number}',
    ),
    spaceProvisioningStatusProvider.overrideWith(
      (ref, spaceId) => SpaceProvisioningStatus.ready,
    ),
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

Widget _tab(PullRequest pr) => PrSourceControlTab(
  pr: pr,
  prRef: (
    workspaceId: kTestWorkspaceId,
    repoFullName: pr.repoFullName,
    number: pr.number,
  ),
  onOpenInEditor: (_) {},
);

Future<void> _show(WidgetTester tester, _CommitHost host, Widget child) async {
  await tester.pumpWidget(_testWorkbench(child, host));
  await tester.pump();
  await tester.pump();
}

String _input(WidgetTester tester) => tester
    .widget<EditableText>(find.byType(EditableText).first)
    .controller
    .text;

void main() {
  testWidgets('demo server shows DemoUnavailable, not an RPC error', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        PrSourceControlTab(
          pr: _pr(),
          prRef: (
            workspaceId: 'ws',
            repoFullName: 'helix/evalkit',
            number: 412,
          ),
          onOpenInEditor: (_) {},
        ),
        isDemo: true,
      ),
    );

    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text('Not available in the demo'), findsOneWidget);
    expect(find.textContaining('Unknown op'), findsNothing);
    expect(find.textContaining('pr.ensureSpace'), findsNothing);
  });

  testWidgets(
    'commit input survives navigation and isolates PR, repo, and workspace',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final host = _CommitHost();
      final first = _pr();
      await _show(tester, host, _tab(first));
      await tester.enterText(find.byType(EditableText).first, 'Review commit');
      await _show(tester, host, const SizedBox.shrink());
      await _show(tester, host, _tab(first));
      expect(_input(tester), 'Review commit');

      await _show(tester, host, _tab(_pr(number: 413)));
      expect(_input(tester), isEmpty);
      await tester.enterText(find.byType(EditableText).first, 'Second PR');
      await _show(tester, host, _tab(_pr(repo: 'helix/other')));
      expect(_input(tester), isEmpty);
      late WidgetRef workspaceRef;
      await _show(
        tester,
        host,
        Consumer(
          builder: (context, ref, _) {
            workspaceRef = ref;
            return _tab(first);
          },
        ),
      );
      expect(_input(tester), 'Review commit');

      // A change of active workspace must not reuse the first one's controller.
      await workspaceRef
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('another-workspace');
      await tester.pumpAndSettle();
      expect(_input(tester), isEmpty);
      await workspaceRef
          .read(activeWorkspaceIdProvider.notifier)
          .setActive(kTestWorkspaceId);
      await tester.pumpAndSettle();
      expect(_input(tester), 'Review commit');
    },
  );

  testWidgets('commit clears on success, retains on failed commit or push', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final host = _CommitHost();
    await _show(tester, host, _tab(_pr()));
    final input = find.byType(EditableText).first;

    host.committed = false;
    await tester.enterText(input, 'Keep failed commit');
    tester
        .widget<ScmCommitBox>(find.byType(ScmCommitBox))
        .onAction(ScmCommitAction.commit);
    await tester.pump();
    await tester.pump();
    expect(_input(tester), 'Keep failed commit');

    host.committed = true;
    host.pushed = false;
    tester
        .widget<ScmCommitBox>(find.byType(ScmCommitBox))
        .onAction(ScmCommitAction.commitAndPush);
    await tester.pump();
    await tester.pump();
    expect(_input(tester), 'Keep failed commit');

    host.pushed = true;
    tester
        .widget<ScmCommitBox>(find.byType(ScmCommitBox))
        .onAction(ScmCommitAction.commit);
    await tester.pump();
    await tester.pump();
    expect(_input(tester), isEmpty);
    expect(host.calls.map((c) => c['message']), [
      'Keep failed commit',
      'Keep failed commit',
      'Keep failed commit',
    ]);
  });

  testWidgets('in-flight commit clears only its original unedited worktree', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final host = _CommitHost()..releaseCommit = Completer<void>();
    final first = _pr();
    await _show(tester, host, _tab(first));
    await tester.enterText(find.byType(EditableText).first, 'First PR commit');
    tester
        .widget<ScmCommitBox>(find.byType(ScmCommitBox))
        .onAction(ScmCommitAction.commit);
    await tester.pump();
    await host.commitEntered.future;
    await _show(tester, host, _tab(_pr(number: 413)));
    await tester.enterText(find.byType(EditableText).first, 'Other PR draft');
    host.releaseCommit!.complete();
    await tester.pump();
    await tester.pump();
    expect(_input(tester), 'Other PR draft');
    await _show(tester, host, _tab(first));
    expect(_input(tester), isEmpty);
    expect(host.calls.single['space_id'], 'review-space-helix/evalkit-412');
  });

  testWidgets('an in-flight commit never erases a newer edit to its draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final host = _CommitHost()..releaseCommit = Completer<void>();
    final first = _pr();
    await _show(tester, host, _tab(first));
    await tester.enterText(find.byType(EditableText).first, 'Original');
    tester
        .widget<ScmCommitBox>(find.byType(ScmCommitBox))
        .onAction(ScmCommitAction.commit);
    await tester.pump();
    await host.commitEntered.future;
    await _show(tester, host, const SizedBox.shrink());
    await _show(tester, host, _tab(first));
    await tester.enterText(find.byType(EditableText).first, 'Newer message');
    host.releaseCommit!.complete();
    await tester.pump();
    await tester.pump();
    expect(_input(tester), 'Newer message');
    expect(host.calls.single['message'], 'Original');
  });
}
