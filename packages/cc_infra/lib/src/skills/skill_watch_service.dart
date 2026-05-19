import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        DirectoryChangeBatch,
        DirectoryChangeWatcher,
        DirectoryChangeWatcherFactory,
        NativeDirectoryWatcher,
        WatcherUnavailable;
import 'package:path/path.dart' as p;

/// Watches every workspace's `skills/` directory and publishes
/// [SkillUpdated] (origin `watch`) when skill content changes on disk outside
/// the gated write paths — an external editor, a hand-copied directory, an
/// agent file write. Those events drive the seeded `skill_analysis` pipeline
/// trigger, so an out-of-band edit gets the same antivirus re-scan a gated
/// write does.
///
/// Modeled on `CodeGraphWatchService` at a fraction of its size:
/// stream-driven root discovery (`WorkspaceRepository.watchAll`) plus a slow
/// reconcile sweep that re-arms anything missed. One native watcher per
/// workspace skills dir — arming is O(1), the trees are tiny and independent
/// watcher instances share only the process-wide pump. The lock file is
/// deliberately IGNORED: the antivirus itself rewrites `skills-lock.json`
/// (quarantine verdicts) and reacting to our own bookkeeping would
/// feedback-loop.
///
/// Failure discipline mirrors the code-graph service: a per-root `StateError`
/// (the directory vanished mid-arm, watch limits) is logged and retried by the
/// next reconcile; [WatcherUnavailable] (a broken native install) is logged
/// loud by the reconcile catch — `cc_server`'s native preflight normally makes
/// it unreachable. One workspace's failure never takes the service down.
class SkillWatchService {
  /// Creates the service. [watcherFactory] is a test hook (production uses the
  /// required native `cc_watcher`).
  SkillWatchService({
    required WorkspaceRepository workspaces,
    required WorkspaceFilesystemPort filesystem,
    required DomainEventBus eventBus,
    required SkillBundlePort bundles,
    Duration debounce = const Duration(seconds: 2),
    Duration maxDebounce = const Duration(seconds: 15),
    Duration reconcileInterval = const Duration(minutes: 1),
    DirectoryChangeWatcherFactory? watcherFactory,
  }) : _workspaces = workspaces,
       _filesystem = filesystem,
       _eventBus = eventBus,
       _bundles = bundles,
       _debounce = debounce,
       _maxDebounce = maxDebounce,
       _reconcileInterval = reconcileInterval,
       _watcherFactory = watcherFactory ?? _defaultWatcherFactory;

  final WorkspaceRepository _workspaces;
  final WorkspaceFilesystemPort _filesystem;
  final DomainEventBus _eventBus;

  /// Hashes a changed skill's current bytes for the event payload (and its
  /// dedup key) — cheap: a skills dir is a handful of small text files.
  final SkillBundlePort _bundles;

  final Duration _debounce;

  /// Ceiling on how long coalescing may defer the publish. Each event
  /// restarts the [_debounce] window, so a tree written to continuously would
  /// otherwise never reach a quiet gap and never publish at all.
  final Duration _maxDebounce;
  final Duration _reconcileInterval;
  final DirectoryChangeWatcherFactory _watcherFactory;

  StreamSubscription<dynamic>? _workspaceSub;
  Timer? _reconcileTimer;
  final Map<String, _SkillRootWatch> _roots = {};
  var _disposed = false;

  /// Serializes reconciles: the workspace stream's emission and the boot
  /// microtask (or the timer) can race and an unsynchronized check-then-arm
  /// would double-arm the same root — two watches on one directory, twice the
  /// events. Chained, the second reconcile sees the first's root and skips.
  Future<void>? _reconcileChain;

  static DirectoryChangeWatcher _defaultWatcherFactory(
    String path, {
    Set<String> ignoreDirNames = const {},
  }) => NativeDirectoryWatcher.create(path, ignoreDirNames: const {});

  /// Starts watching. Subscribes the workspace set immediately; the first
  /// reconcile runs on the next event-loop tick so construction stays
  /// synchronous.
  void start() {
    _workspaceSub = _workspaces.watchAll().listen(
      (_) => unawaited(_reconcile()),
    );
    _reconcileTimer = Timer.periodic(_reconcileInterval, (_) {
      unawaited(_reconcile());
    });
    unawaited(Future<void>.microtask(_reconcile));
  }

  /// Stops watching and releases every native watcher.
  Future<void> dispose() async {
    _disposed = true;
    await _workspaceSub?.cancel();
    _reconcileTimer?.cancel();
    for (final root in _roots.values) {
      await root.dispose();
    }
    _roots.clear();
  }

  Future<void> _reconcile() {
    final next = (_reconcileChain ?? Future<void>.value()).then(
      (_) => _reconcileNow(),
    );
    // Keep the chain alive across failures — one bad sweep must not poison
    // every later one.
    _reconcileChain = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _reconcileNow() async {
    if (_disposed) {
      return;
    }
    try {
      final workspaces = await _workspaces.watchAll().first;
      if (_disposed) {
        return;
      }
      final desired = <String>{};
      for (final ws in workspaces) {
        // Only arm roots that exist: watching a missing dir is a per-root
        // refusal we would log every sweep. A dir that appears later (CEO
        // seeding calls ensureWorkspaceDirs) is picked up by the next
        // reconcile.
        final dir = Directory(await _filesystem.skillsDir(ws.id));
        if (dir.existsSync()) {
          desired.add(ws.id);
        }
      }
      final stale = _roots.keys.where((id) => !desired.contains(id)).toList();
      for (final id in stale) {
        await _roots.remove(id)?.dispose();
      }
      for (final id in desired) {
        if (!_roots.containsKey(id)) {
          await _arm(id);
        }
      }
    } on Object catch (e, st) {
      CcInfraLog.error('skill watch: reconcile failed', e, st);
    }
  }

  Future<void> _arm(String workspaceId) async {
    final root = await _SkillRootWatch.arm(
      workspaceId: workspaceId,
      filesystem: _filesystem,
      bundles: _bundles,
      eventBus: _eventBus,
      watcherFactory: _watcherFactory,
      debounce: _debounce,
      maxDebounce: _maxDebounce,
      // A vanished root drops its watch; the next reconcile re-arms it if
      // the directory is back.
      onGone: () => _roots.remove(workspaceId),
    );
    if (root != null) {
      _roots[workspaceId] = root;
    }
    // A null return means a per-root refusal (StateError) — already logged
    // inside arm, retried by the next reconcile.
  }
}

/// One workspace's watched skills dir: native watcher + per-root debounce
/// that coalesces changed paths into per-slug [SkillUpdated] publishes.
class _SkillRootWatch {
  _SkillRootWatch._({
    required this.workspaceId,
    required String dirPath,
    required WorkspaceFilesystemPort filesystem,
    required SkillBundlePort bundles,
    required DomainEventBus eventBus,
    required DirectoryChangeWatcher createdWatcher,
    required Duration debounce,
    required Duration maxDebounce,
    required void Function() onGone,
  }) : _dirPath = dirPath,
       _filesystem = filesystem,
       _bundles = bundles,
       _eventBus = eventBus,
       _debounce = debounce,
       _maxDebounce = maxDebounce,
       _onGone = onGone,
       watcher = createdWatcher {
    _subscription = watcher.changes.listen(
      _onChange,
      onError: (Object e) {
        CcInfraLog.warning(
          'skill watch: watcher error for workspace $workspaceId: $e',
        );
      },
    );
  }

  /// Arms a watch on the workspace's skills dir. Returns null on a per-root
  /// refusal (the directory vanished mid-arm, watch-descriptor limits) after
  /// logging — the reconcile retries. [WatcherUnavailable] propagates.
  static Future<_SkillRootWatch?> arm({
    required String workspaceId,
    required WorkspaceFilesystemPort filesystem,
    required SkillBundlePort bundles,
    required DomainEventBus eventBus,
    required DirectoryChangeWatcherFactory watcherFactory,
    required Duration debounce,
    required Duration maxDebounce,
    required void Function() onGone,
  }) async {
    final dirPath = await filesystem.skillsDir(workspaceId);
    try {
      final watcher = watcherFactory(dirPath);
      return _SkillRootWatch._(
        workspaceId: workspaceId,
        dirPath: dirPath,
        filesystem: filesystem,
        bundles: bundles,
        eventBus: eventBus,
        createdWatcher: watcher,
        debounce: debounce,
        maxDebounce: maxDebounce,
        onGone: onGone,
      );
    } on StateError catch (e) {
      CcInfraLog.warning(
        'skill watch: cannot arm workspace $workspaceId ($dirPath): $e',
      );
      return null;
    }
  }

  final String workspaceId;
  final String _dirPath;
  final WorkspaceFilesystemPort _filesystem;
  final SkillBundlePort _bundles;
  final DomainEventBus _eventBus;
  final Duration _debounce;

  /// Ceiling on how long coalescing may defer the publish.
  final Duration _maxDebounce;
  final void Function() _onGone;

  final DirectoryChangeWatcher watcher;
  late final StreamSubscription<DirectoryChangeBatch> _subscription;

  /// Slugs with pending changes, coalescing until a quiet gap.
  final Set<String> _dirty = {};

  /// When the current coalescing window opened (bounds it at [_maxDebounce]).
  DateTime? _firstDirtyAt;
  Timer? _debounceTimer;

  void _onChange(DirectoryChangeBatch batch) {
    if (batch.rootGone) {
      unawaited(dispose());
      _onGone();
      return;
    }
    if (batch.rescanNeeded) {
      // Paths unknown (queue overflow, kernel rescan hint) — be conservative:
      // treat every installed skill as changed.
      unawaited(_markAllDirty());
      return;
    }
    for (final path in batch.paths) {
      final slug = _slugFor(path);
      if (slug != null) {
        _dirty.add(slug);
      }
    }
    if (_dirty.isNotEmpty) {
      _schedule();
    }
  }

  /// Maps an absolute changed path to its skill slug, or null when the path
  /// is not skill content: the lock file (our own bookkeeping) and stray
  /// files directly under `skills/` are both ignored.
  String? _slugFor(String path) {
    final rel = p.relative(path, from: _dirPath);
    if (rel.startsWith('..') || p.isAbsolute(rel)) {
      return null; // Outside the root (defensive).
    }
    final parts = p.split(rel);
    if (parts.length < 2 || parts.first == 'skills-lock.json') {
      return null; // The lock lives directly under skills/ — never a trigger.
    }
    return parts.first;
  }

  Future<void> _markAllDirty() async {
    final slugs = await _filesystem.listSkillSlugs(workspaceId);
    if (slugs.isEmpty) {
      return;
    }
    _dirty.addAll(slugs);
    _schedule();
  }

  void _schedule() {
    _firstDirtyAt ??= DateTime.now();
    _debounceTimer?.cancel();
    final waited = DateTime.now().difference(_firstDirtyAt!);
    final remaining = waited >= _maxDebounce ? Duration.zero : _debounce;
    _debounceTimer = Timer(remaining, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    final slugs = List.of(_dirty);
    _dirty.clear();
    _firstDirtyAt = null;
    for (final slug in slugs) {
      try {
        final hash = await _bundles.computeSkillHash(workspaceId, slug);
        if (hash == null) {
          continue; // Deleted between event and flush — nothing to analyze.
        }
        _eventBus.publish(
          SkillUpdated(
            workspaceId: workspaceId,
            slug: slug,
            origin: SkillUpdateOrigin.watch,
            computedHash: hash,
            occurredAt: DateTime.now(),
          ),
        );
      } on Object catch (e, st) {
        CcInfraLog.error(
          'skill watch: failed to publish update for $slug '
          'in workspace $workspaceId',
          e,
          st,
        );
      }
    }
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    // Flush pending changes so a shutdown doesn't swallow the last edits —
    // best-effort; events are advisory and the periodic sweep re-covers them.
    if (_dirty.isNotEmpty) {
      await _flush();
    }
    await _subscription.cancel();
    await watcher.close();
  }
}
