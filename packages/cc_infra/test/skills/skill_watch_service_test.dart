import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_infra/src/skills/skill_bundle_service.dart';
import 'package:cc_infra/src/skills/skill_watch_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:cc_natives/cc_natives.dart'
    show DirectoryChangeBatch, DirectoryChangeWatcher;
import 'package:test/test.dart';

/// The skills dir watcher (PRD 23 §6 on-disk trigger): coalesces filesystem
/// changes under a workspace's `skills/` into per-slug `SkillUpdated` events,
/// ignoring the lock file (the antivirus's own bookkeeping).
void main() {
  late Directory temp;
  late DomainEventBus bus;
  late List<SkillUpdated> events;
  late StreamSubscription<SkillUpdated> sub;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('skill_watch_test_');
    bus = DomainEventBus();
    events = [];
    sub = bus.on<SkillUpdated>().listen(events.add);
  });

  tearDown(() async {
    await sub.cancel();
    bus.dispose();
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  Future<SkillWatchService> arm({
    required _FakeWatcherFactory factory,
  }) async {
    final fs = WorkspaceFilesystemService(CcPaths(temp.path));
    await fs.ensureWorkspaceDirs('ws');
    // A real skill on disk so computeSkillHash resolves a hash.
    await fs.writeSkillFile('ws', 'foo', '# foo');
    await fs.writeSkillFile('ws', 'bar', '# bar');

    final bundles = SkillBundleService(
      filesystem: fs,
      fetchGitHubFile:
          ({
            required owner,
            required repo,
            required path,
            required ref,
          }) async => '',
    );
    final service = SkillWatchService(
      workspaces: _OneWorkspaceRepo(),
      filesystem: fs,
      eventBus: bus,
      bundles: bundles,
      debounce: const Duration(milliseconds: 20),
      maxDebounce: const Duration(milliseconds: 60),
      watcherFactory: factory.call,
    );
    service.start();
    // Let the first reconcile arm (microtask + async skillsDir).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return service;
  }

  test('a skill file change publishes SkillUpdated for its slug', () async {
    final factory = _FakeWatcherFactory();
    final service = await arm(factory: factory);
    final skillsDir = pJoin(temp.path, 'ws', 'skills');

    factory.watcherFor(skillsDir).emit(
      DirectoryChangeBatch(paths: [pJoin(skillsDir, 'foo', 'SKILL.md')]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(events, hasLength(1));
    expect(events.single.slug, 'foo');
    expect(events.single.origin, SkillUpdateOrigin.watch);
    expect(events.single.computedHash, isNotEmpty);
    await service.dispose();
  });

  test('skills-lock.json changes never publish (no feedback loop)', () async {
    final factory = _FakeWatcherFactory();
    final service = await arm(factory: factory);
    final skillsDir = pJoin(temp.path, 'ws', 'skills');

    factory
        .watcherFor(skillsDir)
        .emit(DirectoryChangeBatch(paths: [pJoin(skillsDir, 'skills-lock.json')]));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(events, isEmpty);
    await service.dispose();
  });

  test('rapid changes to several slugs coalesce into one flush', () async {
    final factory = _FakeWatcherFactory();
    final service = await arm(factory: factory);
    final skillsDir = pJoin(temp.path, 'ws', 'skills');
    final watcher = factory.watcherFor(skillsDir);

    watcher.emit(
      DirectoryChangeBatch(paths: [pJoin(skillsDir, 'foo', 'SKILL.md')]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    watcher.emit(
      DirectoryChangeBatch(paths: [pJoin(skillsDir, 'bar', 'NOTES.md')]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(events.map((e) => e.slug), containsAll(['foo', 'bar']));
    await service.dispose();
  });

  test('a vanished root drops its watch without crashing', () async {
    final factory = _FakeWatcherFactory();
    final service = await arm(factory: factory);
    final skillsDir = pJoin(temp.path, 'ws', 'skills');

    factory.watcherFor(skillsDir).emit(const DirectoryChangeBatch(rootGone: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Still disposed cleanly afterwards.
    await service.dispose();
  });

  test('dispose flushes pending changes', () async {
    final factory = _FakeWatcherFactory();
    final service = await arm(factory: factory);
    final skillsDir = pJoin(temp.path, 'ws', 'skills');

    factory
        .watcherFor(skillsDir)
        .emit(DirectoryChangeBatch(paths: [pJoin(skillsDir, 'foo', 'SKILL.md')]));
    await service.dispose();

    expect(events.map((e) => e.slug), ['foo']);
  });
}

String pJoin(String a, String b, [String? c, String? d]) {
  var result = '$a/$b';
  if (c != null) {
    result = '$result/$c';
  }
  if (d != null) {
    result = '$result/$d';
  }
  return result;
}

class _OneWorkspaceRepo implements WorkspaceRepository {
  @override
  Stream<List<Workspace>> watchAll() => Stream.value([
    Workspace(
      id: 'ws',
      name: 'ws',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scriptable fake watcher: one per armed root, fed by the test.
class _FakeWatcher implements DirectoryChangeWatcher {
  _FakeWatcher(this.root);

  final String root;
  final _controller = StreamController<DirectoryChangeBatch>.broadcast();
  bool closed = false;

  void emit(DirectoryChangeBatch batch) => _controller.add(batch);

  @override
  Stream<DirectoryChangeBatch> get changes => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }
}

class _FakeWatcherFactory {
  final watchers = <String, _FakeWatcher>{};

  _FakeWatcher watcherFor(String root) {
    final existing = watchers[root];
    if (existing != null) {
      return existing;
    }
    throw StateError('no watcher armed for $root');
  }

  DirectoryChangeWatcher call(String path, {Set<String> ignoreDirNames = const {}}) {
    return watchers.putIfAbsent(path, () => _FakeWatcher(path));
  }
}
