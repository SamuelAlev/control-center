import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/isolation/worktree_isolation.dart';
import 'package:cc_infra/src/dispatch/worktree_isolation_runner.dart';
import 'package:cc_infra/src/git/process_git_command_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const git = ProcessGitCommandAdapter();
  late Directory repoDir;
  late GitWorktreeIsolationRunner runner;

  Future<void> g(List<String> args, String dir) async {
    final r = await git.run(args, workdir: dir);
    expect(r.isSuccess, isTrue, reason: '${args.join(' ')} → ${r.stderr}');
  }

  setUp(() async {
    repoDir = await Directory.systemTemp.createTemp('cc-iso-repo-');
    await g(['init', '-q'], repoDir.path);
    await g(['config', 'user.email', 'test@local'], repoDir.path);
    await g(['config', 'user.name', 'Test'], repoDir.path);
    await File('${repoDir.path}/seed.txt').writeAsString('seed\n');
    await g(['add', '-A'], repoDir.path);
    await g(['commit', '-q', '-m', 'seed'], repoDir.path);
    runner = GitWorktreeIsolationRunner(git);
  });

  tearDown(() async {
    if (repoDir.existsSync()) {
      await repoDir.delete(recursive: true);
    }
  });

  test('patch mode captures a diff and applies it back to the parent', () async {
    final ctx = await runner.prepareContext(repoDir.path);
    final artifacts = await Directory.systemTemp.createTemp('cc-iso-art-');
    addTearDown(() => artifacts.delete(recursive: true));

    final result = await runner.runIsolated(
      context: ctx,
      agentId: 'task1',
      mergeMode: IsolationMergeMode.patch,
      artifactsDir: artifacts.path,
      run: (worktreeDir) async {
        await File('$worktreeDir/new.txt').writeAsString('isolated\n');
        return 0;
      },
    );

    expect(result.succeeded, isTrue);
    expect(result.patchPath, isNotNull);
    expect(File(result.patchPath!).existsSync(), isTrue);
    // Not applied to the parent yet.
    expect(File('${repoDir.path}/new.txt').existsSync(), isFalse);

    final merge = await runner.mergeChanges(
      result: result,
      repoRoot: ctx.repoRoot,
      mergeMode: IsolationMergeMode.patch,
    );
    expect(merge.changesApplied, isTrue);
    expect(merge.hadChanges, isTrue);
    expect(File('${repoDir.path}/new.txt').readAsStringSync(), 'isolated\n');
  });

  test('branch mode commits to cc/task/<id> and cherry-picks back', () async {
    final ctx = await runner.prepareContext(repoDir.path);

    final result = await runner.runIsolated(
      context: ctx,
      agentId: 'task2',
      mergeMode: IsolationMergeMode.branch,
      artifactsDir: repoDir.path,
      description: 'add feature file',
      run: (worktreeDir) async {
        await File('$worktreeDir/feature.txt').writeAsString('feature\n');
        return 0;
      },
    );

    expect(result.succeeded, isTrue);
    expect(result.branchName, 'cc/task/task2');

    final merge = await runner.mergeChanges(
      result: result,
      repoRoot: ctx.repoRoot,
      mergeMode: IsolationMergeMode.branch,
    );
    expect(merge.changesApplied, isTrue);
    expect(merge.hadChanges, isTrue);
    expect(File('${repoDir.path}/feature.txt').readAsStringSync(), 'feature\n');
  });

  test('a non-zero run captures nothing', () async {
    final ctx = await runner.prepareContext(repoDir.path);
    final result = await runner.runIsolated(
      context: ctx,
      agentId: 'task3',
      mergeMode: IsolationMergeMode.patch,
      artifactsDir: repoDir.path,
      run: (_) async => 1,
    );
    expect(result.exitCode, 1);
    expect(result.succeeded, isFalse);
    expect(result.patchPath, isNull);
  });

  test('a clean run (no changes) merges as no-op', () async {
    final ctx = await runner.prepareContext(repoDir.path);
    final result = await runner.runIsolated(
      context: ctx,
      agentId: 'task4',
      mergeMode: IsolationMergeMode.patch,
      artifactsDir: repoDir.path,
      run: (_) async => 0,
    );
    expect(result.succeeded, isTrue);
    expect(result.patchPath, isNull);
    final merge = await runner.mergeChanges(
      result: result,
      repoRoot: ctx.repoRoot,
      mergeMode: IsolationMergeMode.patch,
    );
    expect(merge.hadChanges, isFalse);
  });

  test('prepareContext throws outside a git repository', () async {
    final notRepo = await Directory.systemTemp.createTemp('cc-not-repo-');
    addTearDown(() => notRepo.delete(recursive: true));
    await expectLater(
      runner.prepareContext(notRepo.path),
      throwsA(isA<StateError>()),
    );
  });
}
