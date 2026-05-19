import 'dart:async';
import 'dart:io';

// StreamControllers on the workspace/isolated-repo fakes live for the test
// and are abandoned with the fake; close_sinks cannot see that lifecycle.
// ignore_for_file: close_sinks

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_index_run_reporter.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_infra/src/code_graph/code_graph_watch_service.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        DirectoryChangeBatch,
        DirectoryChangeWatcher,
        NativeDirectoryWatcher,
        defaultWatcherLibraryResolver,
        nativeLibraryCandidates,
        tryOpenFirst,
        watcherLibraryBaseName,
        watcherLibraryEnvVar;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The watch service is the piece that makes "reindex on save" real: it
/// discovers checkouts from the repo + worktree registries, builds a
/// worktree's own graph partition the moment the worktree appears and folds
/// any on-disk change (IDE save, agent write, PR sync checkout) into one
/// debounced incremental index run.
///
/// Two layers of coverage, deliberately:
///
///  * the bulk of the tests inject a hand-driven watcher and emit change
///    BATCHES directly. That makes the semantics timing-exact (a burst really
///    is one window; a rescan-with-no-paths really is one run) instead of
///    depending on filesystem-event latency and it needs no dylib;
///  * one group at the bottom drives the REAL native `cc_watcher` over a real
///    temp directory, so the production path — kernel events → native ignore
///    filter → drain → the service's `affectsIndex` gate — is exercised
///    end-to-end. It skips when the dylib is not built.
///
/// There is deliberately no `package:watcher` anywhere: it is not a fallback
/// in production (its per-arm full-tree scan is the 65s freeze this all
/// exists to remove), so it is not a test dependency either.
void main() {
  late Directory tempRoot;
  late _FakeIndexer indexer;
  late _FakeWorkspaceRepository workspaces;
  late _FakeIsolatedRepoRepository isolated;
  late _FakeWatchers watchers;
  late CodeGraphWatchService service;

  const debounce = Duration(milliseconds: 30);

  Workspace workspace(String id) => Workspace(
    id: id,
    name: 'ws',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  Repo repo(String id, String path) => Repo(
    id: id,
    name: 'repo',
    path: path,
    remoteOwner: '',
    remoteName: '',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  IsolatedRepo worktree(String id, String repoId, String path) => IsolatedRepo(
    id: id,
    workspaceId: 'ws1',
    spaceId: 'ch1',
    repoId: repoId,
    path: path,
    branch: 'pr-1',
    backend: RepoIsolationBackend.rift,
    sourcePath: '/src',
    createdAt: DateTime(2025),
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('cg_watch_test');
    indexer = _FakeIndexer();
    workspaces = _FakeWorkspaceRepository();
    isolated = _FakeIsolatedRepoRepository();
    watchers = _FakeWatchers();
    service = CodeGraphWatchService(
      indexer: indexer,
      workspaces: workspaces,
      isolatedRepos: isolated,
      debounce: debounce,
      // These tests are not about the linked-vs-worktree window split, so the
      // two are pinned together and every checkout coalesces on the same tick.
      linkedDebounce: debounce,
      reconcileInterval: const Duration(milliseconds: 50),
      watcherFactory: watchers.create,
    )..start();
  });

  tearDown(() async {
    await service.dispose();
    await tempRoot.delete(recursive: true);
  });

  /// Waits until [predicate] holds or the deadline passes.
  Future<void> until(
    bool Function() predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!predicate()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not met within $timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('arms the linked checkout and runs the initial index', () async {
    final dir = await Directory('${tempRoot.path}/linked').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );

    await until(() => indexer.calls.isNotEmpty);
    final call = indexer.calls.single;
    expect(call.workspaceId, 'ws1');
    expect(call.repoId, 'r1');
    expect(call.repoPath, dir.path);
    expect(call.checkoutId, isNull);
  });

  test('arms a worktree with its own partition when the row appears', () async {
    final dir = await Directory('${tempRoot.path}/wt').create();
    workspaces.emit([workspace('ws1')], const {});
    isolated.emit('ws1', [worktree('wt1', 'r1', dir.path)]);

    await until(() => indexer.calls.isNotEmpty);
    final call = indexer.calls.single;
    expect(call.repoId, 'r1');
    expect(call.repoPath, dir.path);
    expect(call.checkoutId, 'wt1');
  });

  test(
    'the ignore list handed to the watcher is the walker\'s own set',
    () async {
      // The native filters events by these names and `affectsIndex` gates what
      // survives. Feeding the watcher anything else would let the two disagree.
      final dir = await Directory('${tempRoot.path}/linked').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => watchers.byPath.containsKey(dir.path));

      expect(watchers.ignoreFor(dir.path), contains('node_modules'));
      expect(watchers.ignoreFor(dir.path), contains('.git'));
    },
  );

  test(
    'a file save triggers one debounced reindex, coalescing bursts',
    () async {
      final dir = await Directory('${tempRoot.path}/linked').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.length == 1);

      // A burst of saves within the debounce window coalesces into ONE extra
      // run — rapid IDE saves must not pile index runs up.
      for (var i = 0; i < 5; i++) {
        watchers.save(dir.path, 'file$i.dart');
      }
      await until(() => indexer.calls.length >= 2);
      // Allow any wrongly-scheduled extra runs to fire, then assert the total.
      await Future<void>.delayed(debounce * 6);
      expect(indexer.calls.length, 2);
      expect(indexer.calls.last.checkoutId, isNull);
    },
  );

  test('build output and generated files never trigger a reindex', () async {
    // The walker enumerates via `git ls-files` + an extension/generated filter,
    // so none of these can change the graph — but each event would otherwise
    // cost a full walk plus a SHA-256 of every source file. A `flutter run` or
    // `build_runner` pass writes these continuously.
    final dir = await Directory('${tempRoot.path}/linked').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.length == 1);

    watchers.save(dir.path, '.dart_tool/package_config.json');
    watchers.save(dir.path, 'build/out/app.dart');
    watchers.save(dir.path, 'node_modules/pkg/index.js');
    watchers.save(dir.path, 'model.g.dart');
    watchers.save(dir.path, 'notes.md');
    await Future<void>.delayed(debounce * 8);
    expect(indexer.calls.length, 1);

    // ...but a real source file still does.
    watchers.save(dir.path, 'real.dart');
    await until(() => indexer.calls.length == 2);
  });

  group('run reporting', () {
    late _FakeRunReporter reporter;
    late CodeGraphWatchService reporting;

    /// Swaps the shared reporter-less service (the rest of the file's subject,
    /// and proof that indexing behaves identically with no reporter wired) for
    /// one that reports, so a single service owns the watcher for `dir`.
    Future<Directory> armReporting() async {
      await service.dispose();
      final dir = await Directory('${tempRoot.path}/reported').create();
      reporter = _FakeRunReporter();
      reporting = CodeGraphWatchService(
        indexer: indexer,
        workspaces: workspaces,
        isolatedRepos: isolated,
        runReporter: reporter,
        debounce: debounce,
        linkedDebounce: debounce,
        reconcileInterval: const Duration(milliseconds: 50),
        watcherFactory: watchers.create,
      )..start();
      addTearDown(reporting.dispose);
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => reporter.runs.isNotEmpty);
      return dir;
    }

    test('every run opens a report, identifying its checkout', () async {
      final dir = await armReporting();

      final run = reporter.runs.single;
      expect(run.workspaceId, 'ws1');
      expect(run.repoId, 'r1');
      expect(run.repoPath, dir.path);
      expect(run.checkoutId, isNull);
    });

    test('progress and the result reach the report', () async {
      await armReporting();
      final run = reporter.runs.single;

      await until(() => run.finished != null);
      expect(run.progress, hasLength(1));
      expect(run.progress.single.filesToIndex, 4);
      expect(run.finished!.filesIndexed, 0);
      expect(run.failure, isNull);
    });

    test('a failing index is reported as a failure', () async {
      indexer.failNext = true;
      await armReporting();

      final run = reporter.runs.single;
      await until(() => run.failure != null);
      expect(run.finished, isNull);
      expect('${run.failure}', contains('index boom'));
    });

    test('a cancel on the report stops the indexer', () async {
      final dir = await armReporting();
      await until(() => reporter.runs.single.finished != null);

      // Park the next run, cancel its report while it is parked and let it
      // resume: the indexer's `isCancelled` must go true, so a Stop stops the
      // real work rather than only relabelling the row.
      final gate = Completer<void>();
      indexer.block = gate.future;
      watchers.save(dir.path, 'real.dart');
      await until(() => reporter.runs.length == 2);
      reporter.runs.last.cancel();
      gate.complete();

      await until(() => indexer.cancelledDuringRun);
    });

    test('the arm-time run is reported as an initial pass', () async {
      await armReporting();

      expect(reporter.runs.single.cause.kind, CodeIndexCauseKind.initial);
      expect(reporter.runs.single.cause.paths, isEmpty);
    });

    test('a save is reported with the path that caused it', () async {
      // The whole point: a published run has to say WHY it ran. The service
      // used to stop at the first relevant path in a batch and keep only a
      // dirty flag, so every background run was indistinguishable from the next.
      final dir = await armReporting();
      await until(() => reporter.runs.single.finished != null);

      watchers.save(dir.path, 'lib/foo.dart');
      await until(() => reporter.runs.length == 2);

      final cause = reporter.runs.last.cause;
      expect(cause.kind, CodeIndexCauseKind.changes);
      expect(cause.paths, ['lib/foo.dart']);
      expect(cause.totalChanged, 1);
    });

    test('paths are repo-relative, not absolute', () async {
      // A run row shows `lib/foo.dart`, never the operator's home directory.
      final dir = await armReporting();
      await until(() => reporter.runs.single.finished != null);

      watchers.save(dir.path, 'lib/nested/deep.dart');
      await until(() => reporter.runs.length == 2);

      expect(reporter.runs.last.cause.paths.single, 'lib/nested/deep.dart');
      expect(reporter.runs.last.cause.paths.single, isNot(contains(dir.path)));
    });

    test('a coalesced burst reports every distinct path once', () async {
      final dir = await armReporting();
      await until(() => reporter.runs.single.finished != null);

      // Same file written four times (write, rename, chmod, atomic replace) is
      // ONE reason, not four; two other files make it three.
      watchers.save(dir.path, 'lib/a.dart');
      watchers.save(dir.path, 'lib/a.dart');
      watchers.save(dir.path, 'lib/b.dart');
      watchers.save(dir.path, 'lib/c.dart');
      await until(() => reporter.runs.length == 2);

      final cause = reporter.runs.last.cause;
      expect(cause.totalChanged, 3);
      expect(cause.paths, ['lib/a.dart', 'lib/b.dart', 'lib/c.dart']);
    });

    test(
      'a rescan batch is reported as a rescan, not as zero changes',
      () async {
        // An empty path list would read as "nothing changed", which is the one
        // thing a queue overflow does NOT mean.
        final dir = await armReporting();
        await until(() => reporter.runs.single.finished != null);

        watchers.byPath[dir.path]!.emit(
          const DirectoryChangeBatch(rescanNeeded: true, dropped: 12),
        );
        await until(() => reporter.runs.length == 2);

        expect(reporter.runs.last.cause.kind, CodeIndexCauseKind.rescan);
      },
    );

    test(
      'a huge change set caps the path list but keeps the true count',
      () async {
        final dir = await armReporting();
        await until(() => reporter.runs.single.finished != null);

        for (var i = 0; i < 40; i++) {
          watchers.save(dir.path, 'lib/f$i.dart');
        }
        await until(() => reporter.runs.length == 2);

        final cause = reporter.runs.last.cause;
        expect(cause.paths, hasLength(CodeIndexCause.maxPaths));
        expect(cause.totalChanged, 40);
        expect(cause.omittedCount, 40 - CodeIndexCause.maxPaths);
      },
    );

    test('the cause is drained per run, never carried into the next', () async {
      final dir = await armReporting();
      await until(() => reporter.runs.single.finished != null);

      watchers.save(dir.path, 'lib/first.dart');
      await until(() => reporter.runs.length == 2);
      await until(() => reporter.runs.last.finished != null);

      watchers.save(dir.path, 'lib/second.dart');
      await until(() => reporter.runs.length == 3);

      expect(reporter.runs.last.cause.paths, [
        'lib/second.dart',
      ], reason: 'a stale path would attribute this run to the previous save');
      expect(reporter.runs.last.cause.totalChanged, 1);
    });
  });

  test('a linked checkout coalesces on its own, longer window', () async {
    // A worktree is an agent's tree: it writes, then may query the graph on the
    // next tool call, so it stays responsive. A linked checkout is the
    // operator's own tree in their own editor — a drip of single-file saves
    // that never ends while they work, and at the worktree window that drip
    // reindexed every couple of seconds forever.
    final linkedDir = await Directory('${tempRoot.path}/split-linked').create();
    final wtDir = await Directory('${tempRoot.path}/split-wt').create();
    final splitWatchers = _FakeWatchers();
    final splitIndexer = _FakeIndexer();
    final splitWorkspaces = _FakeWorkspaceRepository();
    final splitIsolated = _FakeIsolatedRepoRepository();
    final split = CodeGraphWatchService(
      indexer: splitIndexer,
      workspaces: splitWorkspaces,
      isolatedRepos: splitIsolated,
      debounce: const Duration(milliseconds: 30),
      maxDebounce: const Duration(seconds: 10),
      linkedDebounce: const Duration(seconds: 10),
      linkedMaxDebounce: const Duration(seconds: 30),
      reconcileInterval: const Duration(milliseconds: 50),
      watcherFactory: splitWatchers.create,
    )..start();
    addTearDown(split.dispose);

    splitWorkspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', linkedDir.path)],
      },
    );
    splitIsolated.emit('ws1', [worktree('wt1', 'r1', wtDir.path)]);
    // Both arm and take their initial pass.
    await until(() => splitIndexer.calls.length == 2);

    splitIndexer.calls.clear();
    splitWatchers.save(linkedDir.path, 'lib/edited.dart');
    splitWatchers.save(wtDir.path, 'lib/edited.dart');

    // The worktree reindexes on its short window; the linked checkout is still
    // coalescing and must NOT have run.
    await until(() => splitIndexer.calls.any((c) => c.repoPath == wtDir.path));
    expect(
      splitIndexer.calls.where((c) => c.repoPath == linkedDir.path),
      isEmpty,
      reason: 'the linked checkout must still be inside its longer window',
    );
  });

  test('writes under .git never trigger a reindex', () async {
    final dir = await Directory('${tempRoot.path}/linked').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.length == 1);

    watchers.save(dir.path, '.git/refs/heads/main');
    watchers.save(dir.path, '.git/index.lock');
    await Future<void>.delayed(debounce * 8);
    expect(indexer.calls.length, 1);
  });

  test('a rescan-needed batch (overflow / unknown paths) triggers exactly one '
      'debounced run', () async {
    final dir = await Directory('${tempRoot.path}/rescan').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.length == 1);

    // Paths unknown — the consumer must treat it as "changed".
    watchers.byPath[dir.path]!.emit(
      const DirectoryChangeBatch(rescanNeeded: true, dropped: 12),
    );
    await until(() => indexer.calls.length == 2);
    await Future<void>.delayed(debounce * 6);
    expect(indexer.calls.length, 2, reason: 'one batch → one coalesced run');
    expect(indexer.calls.last.force, isTrue);
  });

  group('targeted runs', () {
    // The whole point of tracking paths: a run that knows what changed indexes
    // those paths instead of re-walking and re-hashing the checkout. Measured
    // before this, a one-file save on a 19k-file worktree cost 5-9 SECONDS and
    // ~19k stats, ~90 times an hour while an agent worked.
    test('a save hands the indexer exactly the path that changed', () async {
      final dir = await Directory('${tempRoot.path}/targeted').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.length == 1);
      expect(
        indexer.calls.single.changedPaths,
        isNull,
        reason: 'the arm-time pass is the full enumeration, by design',
      );

      watchers.save(dir.path, 'lib/one.dart');
      await until(() => indexer.calls.length == 2);
      expect(indexer.calls.last.changedPaths, ['lib/one.dart']);
    });

    test('a coalesced burst is targeted at the whole window', () async {
      final dir = await Directory('${tempRoot.path}/burst').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.length == 1);

      watchers.save(dir.path, 'lib/a.dart');
      watchers.save(dir.path, 'lib/b.dart');
      watchers.save(dir.path, 'lib/a.dart');
      await until(() => indexer.calls.length == 2);
      expect(indexer.calls.last.changedPaths, [
        'lib/a.dart',
        'lib/b.dart',
      ], reason: 'every distinct path in the window, each exactly once');
    });

    test('a rescan takes the FULL pass — a partial set is worse than '
        'none', () async {
      final dir = await Directory('${tempRoot.path}/rescan-full').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.length == 1);

      // A save, then a rescan hint in the same window: the watcher lost paths,
      // so targeting the one it kept would leave the rest silently stale.
      watchers.save(dir.path, 'lib/known.dart');
      watchers.byPath[dir.path]!.emit(
        const DirectoryChangeBatch(rescanNeeded: true, dropped: 40),
      );
      await until(() => indexer.calls.length == 2);
      expect(indexer.calls.last.changedPaths, isNull);
    });

    test('the work list is drained per run, never carried into the '
        'next', () async {
      final dir = await Directory('${tempRoot.path}/drain').create();
      workspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.length == 1);

      watchers.save(dir.path, 'lib/first.dart');
      await until(() => indexer.calls.length == 2);
      watchers.save(dir.path, 'lib/second.dart');
      await until(() => indexer.calls.length == 3);
      expect(indexer.calls.last.changedPaths, [
        'lib/second.dart',
      ], reason: 'a stale path would re-index a file this run never touched');
    });
  });

  test(
    'a continuously-written tree still indexes within the max debounce',
    () async {
      // Every event restarts the debounce window, so without a ceiling a tree
      // that is never quiet (a long `git checkout`, save-on-keystroke) would
      // defer indexing forever.
      final dir = await Directory('${tempRoot.path}/busy').create();
      final busyWatchers = _FakeWatchers();
      final busyWorkspaces = _FakeWorkspaceRepository();
      final busy = CodeGraphWatchService(
        indexer: indexer,
        workspaces: busyWorkspaces,
        isolatedRepos: _FakeIsolatedRepoRepository(),
        debounce: const Duration(milliseconds: 200),
        maxDebounce: const Duration(milliseconds: 120),
        // The subject is a linked checkout, so the linked pair is what this
        // test actually exercises; pinned to the same values as above.
        linkedDebounce: const Duration(milliseconds: 200),
        linkedMaxDebounce: const Duration(milliseconds: 120),
        reconcileInterval: const Duration(milliseconds: 50),
        watcherFactory: busyWatchers.create,
      )..start();
      addTearDown(busy.dispose);
      busyWorkspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => indexer.calls.isNotEmpty);

      // Keep writing faster than the 200ms debounce for well past the 120ms cap.
      final stop = DateTime.now().add(const Duration(milliseconds: 600));
      var i = 0;
      while (DateTime.now().isBefore(stop)) {
        busyWatchers.save(dir.path, 'busy${i++}.dart');
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      expect(
        indexer.calls.length,
        greaterThan(1),
        reason: 'the max-debounce ceiling must force a run mid-burst',
      );
    },
  );

  test('never runs more than the concurrency ceiling at once', () async {
    // Indexing is CPU-bound (hashing isolate + a parse isolate per file + ONNX
    // embedding) and runs are per-checkout. Unthrottled, a cold start with ~40
    // checkouts pinned ten cores and made the machine lag.
    //
    // The suite's default service shares this indexer, so it has to go first or
    // it contributes runs of its own to the count.
    await service.dispose();
    final throttled = CodeGraphWatchService(
      indexer: indexer,
      workspaces: workspaces,
      isolatedRepos: isolated,
      debounce: debounce,
      // These tests are not about the linked-vs-worktree window split, so the
      // two are pinned together and every checkout coalesces on the same tick.
      linkedDebounce: debounce,
      reconcileInterval: const Duration(milliseconds: 50),
      maxConcurrentRuns: 2,
      watcherFactory: _FakeWatchers().create,
    )..start();
    addTearDown(throttled.dispose);

    indexer.holdEveryRun = true;
    final repos = <Repo>[];
    for (var i = 0; i < 6; i++) {
      final dir = await Directory('${tempRoot.path}/r$i').create();
      repos.add(repo('r$i', dir.path));
    }
    workspaces.emit([workspace('ws1')], {'ws1': repos});

    await until(() => indexer.inFlight == 2);
    // Give any unthrottled extra runs a chance to (wrongly) start.
    await Future<void>.delayed(debounce * 6);
    expect(indexer.inFlight, 2);
    expect(indexer.maxObservedInFlight, 2);

    indexer.releaseAll();
    await until(() => indexer.calls.length == 6);
    expect(indexer.maxObservedInFlight, 2);
  });

  test('a worktree waits for its base partition before indexing', () async {
    // A worktree stores only its delta against the linked checkout, so running
    // before the base is indexed measures the delta against nothing and stores
    // the whole tree. On a cold start everything arms at once, so ordering here
    // is what keeps the first pass from writing a full copy per worktree.
    final linked = await Directory('${tempRoot.path}/linked').create();
    final wt = await Directory('${tempRoot.path}/wt').create();
    final gate = Completer<void>();
    indexer.block = gate.future; // holds the FIRST run (the linked checkout)

    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', linked.path)],
      },
    );
    isolated.emit('ws1', [worktree('wt1', 'r1', wt.path)]);

    // The linked run started and is parked; the worktree must not have run.
    await until(() => indexer.calls.isNotEmpty);
    await Future<void>.delayed(debounce * 4);
    expect(
      indexer.calls.map((c) => c.checkoutId),
      everyElement(isNull),
      reason: 'the worktree indexed before its base existed',
    );

    gate.complete();
    await until(() => indexer.calls.any((c) => c.checkoutId == 'wt1'));
    // ...and it only ran after the linked checkout completed.
    expect(indexer.calls.first.checkoutId, isNull);
  });

  test('never watches a worktree whose conversation is dormant', () async {
    // `isolated_repos` accumulates — 117 rows on a real host, of which only 15
    // belonged to a conversation active in the last week and 72 had never
    // exchanged a message. Nobody is editing a dormant conversation's
    // worktree, so it gets neither a watch nor an index run.
    await service.dispose();
    final live = await Directory('${tempRoot.path}/live').create();
    final dead = await Directory('${tempRoot.path}/dead').create();
    final scopedWatchers = _FakeWatchers();
    final scoped = CodeGraphWatchService(
      indexer: indexer,
      workspaces: workspaces,
      isolatedRepos: isolated,
      debounce: debounce,
      // These tests are not about the linked-vs-worktree window split, so the
      // two are pinned together and every checkout coalesces on the same tick.
      linkedDebounce: debounce,
      reconcileInterval: const Duration(milliseconds: 50),
      shouldWatchSpace: (workspaceId, spaceId) async => spaceId == 'ch-live',
      watcherFactory: scopedWatchers.create,
    )..start();
    addTearDown(scoped.dispose);

    workspaces.emit([workspace('ws1')], const {});
    isolated.emit('ws1', [
      worktree('wt-live', 'r1', live.path).copyWith(spaceId: 'ch-live'),
      worktree('wt-dead', 'r1', dead.path).copyWith(spaceId: 'ch-dead'),
    ]);

    await until(() => indexer.calls.any((c) => c.checkoutId == 'wt-live'));
    await Future<void>.delayed(debounce * 8);
    expect(indexer.calls.map((c) => c.checkoutId), isNot(contains('wt-dead')));
    // No watcher was ever created for it either — that is the resource the
    // filter exists to save.
    expect(scopedWatchers.byPath.containsKey(dead.path), isFalse);
    expect(scopedWatchers.byPath.containsKey(live.path), isTrue);
  });

  test('dispose cancels the in-flight run and waits for it', () async {
    // A run left detached outlives dispose and keeps querying a database the
    // shutdown sequence is closing — which surfaced as
    // "Space was closed before receiving a response" on every server kill.
    final dir = await Directory('${tempRoot.path}/linked').create();
    final gate = Completer<void>();
    indexer.block = gate.future;
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.isNotEmpty);

    var disposed = false;
    final disposal = service.dispose().then((_) => disposed = true);
    // Still blocked in indexRepo → dispose must not have returned.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(disposed, isFalse);

    gate.complete();
    await disposal;
    expect(disposed, isTrue);
    expect(
      indexer.cancelledDuringRun,
      isTrue,
      reason: 'dispose must flip isCancelled so the run stops at the next file',
    );
  });

  test('dispose closes every armed watcher', () async {
    final dir = await Directory('${tempRoot.path}/closing').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.isNotEmpty);

    await service.dispose();
    expect(
      watchers.byPath[dir.path]!.closed,
      isTrue,
      reason: 'a leaked native watch handle outlives its checkout',
    );
  });

  test('disarms a removed worktree — later saves are not indexed', () async {
    final dir = await Directory('${tempRoot.path}/wt').create();
    workspaces.emit([workspace('ws1')], const {});
    isolated.emit('ws1', [worktree('wt1', 'r1', dir.path)]);
    await until(() => indexer.calls.length == 1);
    final armed = watchers.byPath[dir.path]!;

    // Worktree GC'd: the registry row disappears → watcher disarmed (the
    // graph partition itself is FK-cascade-deleted at the DAO level).
    isolated.emit('ws1', const []);
    await until(() => armed.closed);
    armed.emit(DirectoryChangeBatch(paths: [p.join(dir.path, 'late.dart')]));
    await Future<void>.delayed(debounce * 8);
    expect(indexer.calls.length, 1);
  });

  test('a rootGone batch drops the watch so reconcile can re-arm', () async {
    final dir = await Directory('${tempRoot.path}/gone').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.isNotEmpty);
    expect(watchers.created, hasLength(1));
    final first = watchers.created.first;

    // The root vanished (worktree re-provisioned at the same path): the dead
    // watch must be dropped and the sweep must arm a FRESH one — before this
    // existed, a re-provisioned checkout at the same path kept a dead watch.
    first.emit(const DirectoryChangeBatch(rootGone: true));
    await until(() => watchers.created.length >= 2);
    expect(first.closed, isTrue);
  });

  test('a failed index run is swallowed and the next save retries', () async {
    final dir = await Directory('${tempRoot.path}/linked').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    indexer.failNext = true;
    await until(() => indexer.calls.length == 1);

    watchers.save(dir.path, 'retry.dart');
    await until(() => indexer.calls.length >= 2);
  });

  test('the initial arm-time run passes force:false, an event-driven run '
      'force:true', () async {
    final dir = await Directory('${tempRoot.path}/linked').create();
    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );
    await until(() => indexer.calls.length == 1);
    expect(
      indexer.calls.first.force,
      isFalse,
      reason: 'boot/arm is exactly the path the checkpoint exists for',
    );

    watchers.save(dir.path, 'save.dart');
    await until(() => indexer.calls.length >= 2);
    expect(
      indexer.calls.last.force,
      isTrue,
      reason:
          'a watcher event is proof a file changed; the run it '
          'triggers must bypass the checkpoint fingerprint',
    );
  });

  test('initialDelay holds the first reconcile, then arms', () async {
    final dir = await Directory('${tempRoot.path}/held').create();
    final late = _FakeIndexer();
    final heldWorkspaces = _FakeWorkspaceRepository();
    final held = CodeGraphWatchService(
      indexer: late,
      workspaces: heldWorkspaces,
      isolatedRepos: _FakeIsolatedRepoRepository(),
      debounce: debounce,
      // These tests are not about the linked-vs-worktree window split, so the
      // two are pinned together and every checkout coalesces on the same tick.
      linkedDebounce: debounce,
      reconcileInterval: const Duration(milliseconds: 50),
      initialDelay: const Duration(milliseconds: 400),
      watcherFactory: _FakeWatchers().create,
    )..start();
    addTearDown(held.dispose);
    heldWorkspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );

    // Well inside the hold: registry changes are seen but nothing arms.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(
      late.calls,
      isEmpty,
      reason: 'the hold keeps the arm/index sweep off the boot tail',
    );

    // Past the hold: the deferred reconcile arms and indexes.
    await until(() => late.calls.isNotEmpty);
  });

  test('a watcher that cannot be created leaves the key unarmed and the '
      'sweep retries', () async {
    // The native watcher is REQUIRED, so a create failure is a broken install
    // — but one unwatchable checkout must not take the service (or the other
    // checkouts) down.
    await service.dispose();
    final dir = await Directory('${tempRoot.path}/broken').create();
    var attempts = 0;
    final flaky = CodeGraphWatchService(
      indexer: indexer,
      workspaces: workspaces,
      isolatedRepos: isolated,
      debounce: debounce,
      // These tests are not about the linked-vs-worktree window split, so the
      // two are pinned together and every checkout coalesces on the same tick.
      linkedDebounce: debounce,
      reconcileInterval: const Duration(milliseconds: 50),
      watcherFactory: (path, {ignoreDirNames = const {}}) {
        attempts++;
        if (attempts == 1) {
          throw const _WatcherUnavailableForTest();
        }
        return _FakeChangeWatcher();
      },
    )..start();
    addTearDown(flaky.dispose);

    workspaces.emit(
      [workspace('ws1')],
      {
        'ws1': [repo('r1', dir.path)],
      },
    );

    // The first arm threw; the reconcile sweep re-arms and the run happens.
    await until(() => indexer.calls.isNotEmpty);
    expect(attempts, greaterThanOrEqualTo(2));
  });

  // ──────────────────────────────────────────────────────────────────────────
  // The production path, end to end: real files → the native cc_watcher →
  // the service's `affectsIndex` gate → one debounced index run.
  // ──────────────────────────────────────────────────────────────────────────
  group('native cc_watcher integration', () {
    late bool available;

    setUpAll(() {
      NativeDirectoryWatcher.debugResetBindings();
      final home = Platform.environment['HOME'] ?? '';
      final appSupport = Platform.isMacOS
          ? p.join(
              home,
              'Library',
              'Application Support',
              'com.alev.control-center',
            )
          : p.join(home, '.local', 'share', 'control-center');
      NativeDirectoryWatcher.libraryResolver = () => tryOpenFirst(
        nativeLibraryCandidates(
          watcherLibraryBaseName,
          appSupportRoot: appSupport,
          envVar: watcherLibraryEnvVar,
        ),
      );
      NativeDirectoryWatcher.pumpInterval = const Duration(milliseconds: 50);
      available = NativeDirectoryWatcher.isAvailable;
    });

    tearDownAll(() {
      NativeDirectoryWatcher.pumpInterval = const Duration(milliseconds: 500);
      NativeDirectoryWatcher.libraryResolver = defaultWatcherLibraryResolver;
      NativeDirectoryWatcher.debugResetBindings();
    });

    test('a real source save reindexes; build/vendor churn does not', () async {
      if (!available) {
        markTestSkipped(
          'libcc_watcher not built — run scripts/natives/build_watcher.sh',
        );
        return;
      }
      final nativeIndexer = _FakeIndexer();
      final nativeWorkspaces = _FakeWorkspaceRepository();
      final dir = await Directory('${tempRoot.path}/native').create();
      await Directory('${dir.path}/node_modules/pkg').create(recursive: true);
      await Directory('${dir.path}/.dart_tool').create();
      final native = CodeGraphWatchService(
        indexer: nativeIndexer,
        workspaces: nativeWorkspaces,
        isolatedRepos: _FakeIsolatedRepoRepository(),
        debounce: const Duration(milliseconds: 100),
        linkedDebounce: const Duration(milliseconds: 100),
        reconcileInterval: const Duration(milliseconds: 100),
        // Production default factory: the real native watcher.
      )..start();
      addTearDown(native.dispose);

      nativeWorkspaces.emit(
        [workspace('ws1')],
        {
          'ws1': [repo('r1', dir.path)],
        },
      );
      await until(() => nativeIndexer.calls.length == 1);
      // Let the native watch settle before the first write.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Churn the native is told to ignore + a file the Dart gate rejects.
      await File('${dir.path}/node_modules/pkg/index.js').writeAsString('x');
      await File(
        '${dir.path}/.dart_tool/package_config.json',
      ).writeAsString('{}');
      await File('${dir.path}/model.g.dart').writeAsString('// generated');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(
        nativeIndexer.calls.length,
        1,
        reason: 'ignored dirs and generated files must not wake the indexer',
      );

      // A real source file does.
      await File('${dir.path}/real.dart').writeAsString('void f() {}');
      await until(() => nativeIndexer.calls.length == 2);
      expect(nativeIndexer.calls.last.force, isTrue);
      expect(nativeIndexer.calls.last.repoPath, dir.path);
    });
  });
}

/// Registry of hand-driven watchers, keyed by the path they were created for,
/// so a test can emit a change into a SPECIFIC checkout's watcher.
class _FakeWatchers {
  final Map<String, _FakeChangeWatcher> byPath = {};
  final Map<String, Set<String>> _ignoreByPath = {};
  final List<_FakeChangeWatcher> created = [];

  DirectoryChangeWatcher create(
    String path, {
    Set<String> ignoreDirNames = const {},
  }) {
    final fake = _FakeChangeWatcher();
    // A re-arm replaces the entry; `created` keeps the full history.
    byPath[path] = fake;
    _ignoreByPath[path] = ignoreDirNames;
    created.add(fake);
    return fake;
  }

  /// The ignore set the service passed for [path].
  Set<String> ignoreFor(String path) => _ignoreByPath[path] ?? const {};

  /// Emits a single-path change for `<path>/<relative>`, the shape a real
  /// backend delivers for one file write.
  void save(String path, String relative) => byPath[path]!.emit(
    DirectoryChangeBatch(paths: [p.join(path, p.joinAll(relative.split('/')))]),
  );
}

/// A hand-driven [DirectoryChangeWatcher]: tests emit batches directly, with
/// no filesystem latency, making batch-shape semantics (rescan, rootGone,
/// ignored paths) timing-exact.
class _FakeChangeWatcher implements DirectoryChangeWatcher {
  final _controller = StreamController<DirectoryChangeBatch>();
  bool closed = false;

  void emit(DirectoryChangeBatch batch) {
    if (!_controller.isClosed) {
      _controller.add(batch);
    }
  }

  @override
  Stream<DirectoryChangeBatch> get changes => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    if (!_controller.isClosed) {
      final done = _controller.close();
      if (_controller.hasListener) {
        await done;
      }
    }
  }
}

/// Records what the service reports about each run, so a test can assert the
/// watcher publishes its background work without a database in the loop.
class _FakeRunReporter implements CodeIndexRunReporter {
  final List<_FakeRun> runs = <_FakeRun>[];

  @override
  CodeIndexRun begin({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    CodeIndexCause cause = const CodeIndexCause.initial(),
  }) {
    final run = _FakeRun(
      workspaceId: workspaceId,
      repoId: repoId,
      repoPath: repoPath,
      checkoutId: checkoutId,
      cause: cause,
    );
    runs.add(run);
    return run;
  }
}

class _FakeRun implements CodeIndexRun {
  _FakeRun({
    required this.workspaceId,
    required this.repoId,
    required this.repoPath,
    required this.checkoutId,
    required this.cause,
  });

  final String workspaceId;
  final String repoId;
  final String repoPath;
  final String? checkoutId;
  final CodeIndexCause cause;

  final List<CodeIndexProgress> progress = <CodeIndexProgress>[];
  CodeIndexResult? finished;
  Object? failure;
  var _cancelled = false;

  /// Stands in for an operator cancelling the published run.
  void cancel() => _cancelled = true;

  @override
  bool get cancelRequested => _cancelled;

  @override
  Future<void> report(CodeIndexProgress p) async => progress.add(p);

  @override
  Future<void> finish(CodeIndexResult result) async => finished = result;

  @override
  Future<void> fail(Object error, [StackTrace? stackTrace]) async =>
      failure = error;
}

/// Stands in for the production `WatcherUnavailable` without importing it —
/// the service must treat ANY create failure the same way.
class _WatcherUnavailableForTest implements Exception {
  const _WatcherUnavailableForTest();
}

class _IndexCall {
  const _IndexCall({
    required this.workspaceId,
    required this.repoId,
    required this.repoPath,
    required this.checkoutId,
    this.force = false,
    this.changedPaths,
  });

  final String workspaceId;
  final String repoId;
  final String repoPath;
  final String? checkoutId;
  final bool force;

  /// The work list the run was targeted at, or null when it took the full pass.
  final List<String>? changedPaths;
}

class _FakeIndexer implements CodeIndexer {
  final List<_IndexCall> calls = <_IndexCall>[];
  bool failNext = false;

  /// When set, `indexRepo` parks on this until it completes — lets a test hold a
  /// run "in flight" and observe what dispose does about it.
  Future<void>? block;

  /// When true EVERY run parks until [releaseAll], so a test can observe how
  /// many the service lets run concurrently.
  bool holdEveryRun = false;
  final _held = <Completer<void>>[];
  int inFlight = 0;
  int maxObservedInFlight = 0;

  void releaseAll() {
    holdEveryRun = false;
    for (final c in _held) {
      if (!c.isCompleted) {
        c.complete();
      }
    }
    _held.clear();
  }

  /// Whether `isCancelled` went true while a run was parked (what dispose's
  /// cancellation signal is supposed to do).
  bool cancelledDuringRun = false;

  /// The single progress tick each run emits, standing in for the real
  /// indexer's "announce the work before the first parse" tick.
  static const progressTick = CodeIndexProgress(
    filesIndexed: 0,
    filesToIndex: 4,
    totalFiles: 40,
    symbols: 0,
    edges: 0,
  );

  @override
  Future<CodeIndexResult> indexRepo({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    bool force = false,
    List<String>? changedPaths,
    void Function(CodeIndexProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    calls.add(
      _IndexCall(
        workspaceId: workspaceId,
        repoId: repoId,
        repoPath: repoPath,
        checkoutId: checkoutId,
        force: force,
        changedPaths: changedPaths,
      ),
    );
    inFlight++;
    if (inFlight > maxObservedInFlight) {
      maxObservedInFlight = inFlight;
    }
    onProgress?.call(progressTick);
    try {
      if (holdEveryRun) {
        final held = Completer<void>();
        _held.add(held);
        await held.future;
      }
      final gate = block;
      if (gate != null) {
        block = null;
        await gate;
        cancelledDuringRun = isCancelled?.call() ?? false;
      }
    } finally {
      inFlight--;
    }
    if (failNext) {
      failNext = false;
      throw StateError('index boom');
    }
    return const CodeIndexResult(
      filesIndexed: 0,
      filesSkipped: 0,
      symbols: 0,
      edges: 0,
      removedFiles: 0,
      resolvedReferences: 0,
      nativeAvailable: true,
    );
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final _allController = StreamController<List<Workspace>>.broadcast();
  final Map<String, StreamController<List<Repo>>> _repoControllers = {};
  List<Workspace> _workspaces = const [];

  void emit(List<Workspace> all, Map<String, List<Repo>> reposByWorkspace) {
    _workspaces = all;
    _allController.add(all);
    for (final entry in reposByWorkspace.entries) {
      final controller = _repoControllers[entry.key];
      if (controller != null && controller.hasListener) {
        controller.add(entry.value);
      } else {
        _pendingRepos[entry.key] = entry.value;
      }
    }
  }

  final Map<String, List<Repo>> _pendingRepos = {};

  @override
  Stream<List<Workspace>> watchAll() async* {
    yield _workspaces;
    yield* _allController.stream;
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    late StreamController<List<Repo>> controller;
    controller = StreamController<List<Repo>>(
      onListen: () {
        scheduleMicrotask(() {
          controller.add(_pendingRepos[workspaceId] ?? const []);
        });
      },
    );
    _repoControllers[workspaceId] = controller;
    return controller.stream;
  }

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      Future.value(true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIsolatedRepoRepository implements IsolatedRepoRepository {
  final Map<String, StreamController<List<IsolatedRepo>>> _controllers = {};
  final Map<String, List<IsolatedRepo>> _latest = {};

  void emit(String workspaceId, List<IsolatedRepo> rows) {
    _latest[workspaceId] = rows;
    final controller = _controllers[workspaceId];
    if (controller != null && controller.hasListener) {
      controller.add(rows);
    }
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) {
    late StreamController<List<IsolatedRepo>> controller;
    controller = StreamController<List<IsolatedRepo>>(
      onListen: () {
        scheduleMicrotask(() {
          controller.add(_latest[workspaceId] ?? const []);
        });
      },
    );
    _controllers[workspaceId] = controller;
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
