import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/provider_bindings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_workspace.dart'
    show CreateWorkspaceCommand, CreateWorkspaceUseCase;
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// shared_preferences key for the last-active workspace id. Public so the web
/// bootstrap can read it to land in the last workspace on a fresh load — the web
/// active-id notifier is overridden there and can't reuse the desktop `build()`
/// (which reconciles against the Drift bootstrap stream that web lacks).
const String activeWorkspaceIdPrefKey = 'active_workspace_id';
const String _activeWorkspaceNameKey = 'active_workspace_name';
const String _activeWorkspaceLogoKey = 'active_workspace_logo';
const String _activeRepoIdKeyPrefix = 'active_repo_id:';

/// Watches all workspaces ordered by updated time.
final workspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll();
});

/// Server-truth workspace list for BOOTSTRAP reconciliation only.
///
/// [ActiveWorkspaceIdNotifier] resolves the active workspace id, and the
/// in-process [rpcClientProvider] binds its session to that id. So the active
/// id sits BELOW the RPC client and must not be resolved over the RPC path —
/// reconciling against the public (RPC-flipped) [workspacesProvider] would
/// cycle (rpcClient → activeWorkspaceId → workspaces → workspace RPC →
/// rpcClient). This Dao-backed stream is the same authoritative source the host
/// itself reads, so the active-id bootstrap stays acyclic. UI/display surfaces
/// keep using [workspacesProvider].
final _bootstrapWorkspacesProvider = StreamProvider<List<Workspace>>(buildBootstrapWorkspacesStream);

/// Tracks the id of the workspace currently scoped in the UI.
///
/// Persists to shared_preferences so the choice survives restarts.
/// Falls back to the first available workspace, or null when there are none.
class ActiveWorkspaceIdNotifier extends Notifier<String?> {
  String? _cachedStoredId;

  @override
  String? build() {
    _cachedStoredId ??= ref
        .watch(appPreferencesProvider)
        .getString(activeWorkspaceIdPrefKey);

    // The workspace list comes from a Drift stream whose first emission is
    // gated on opening the database (a couple of seconds on a cold start).
    // Until it arrives, optimistically expose the persisted id instead of
    // null so workspace-scoped providers can start their queries immediately
    // and the title-bar chip resolves without flashing "no workspace". The id
    // is reconciled against the real list below once it emits.
    //
    // Reconcile against the Dao-backed bootstrap list, NOT the RPC-flipped
    // public provider: the in-process RPC client binds to this active id, so
    // resolving it must not route back through the RPC path (see
    // [_bootstrapWorkspacesProvider]).
    final workspaces = ref.watch(_bootstrapWorkspacesProvider).value;
    if (workspaces == null) {
      return _cachedStoredId;
    }

    if (workspaces.isEmpty) {
      return null;
    }

    if (_cachedStoredId != null &&
        workspaces.any((w) => w.id == _cachedStoredId)) {
      return _cachedStoredId;
    }
    return workspaces.first.id;
  }

  /// Sets the active workspace id and persists it.
  Future<void> setActive(String id) async {
    // Flip in-memory state FIRST, before the (slow) shared_preferences write.
    // Persisting first left a window where the route had already changed but
    // readers still saw the previous id — long enough for a mutation to write
    // to the wrong workspace. The write is best-effort after the flip.
    _cachedStoredId = id;
    state = id;
    await ref
        .read(appPreferencesProvider)
        .setString(activeWorkspaceIdPrefKey, id);
  }
}

/// Active workspace id (persisted across restarts).
///
/// The URL is the source of truth: `workspaceUrlSyncProvider` (in
/// `workspace_url_sync_provider.dart`) pushes the `:workspaceId` of the current
/// route into this notifier. The persisted value
/// is the cold-start optimistic default (and the splash redirect's landing
/// target) until the router resolves.
final activeWorkspaceIdProvider =
    NotifierProvider<ActiveWorkspaceIdNotifier, String?>(
      ActiveWorkspaceIdNotifier.new,
    );

/// Convenience accessor for the active workspace row.
final activeWorkspaceProvider = Provider<Workspace?>((ref) {
  final id = ref.watch(activeWorkspaceIdProvider);
  if (id == null) {
    return null;
  }

  final workspaces = ref.watch(workspacesProvider).value ?? const [];
  for (final w in workspaces) {
    if (w.id == id) {
      return w;
    }
  }
  return null;
});

/// Lightweight display info (name + logo) for the active workspace.
typedef WorkspaceDisplay = ({String name, String? logoPath});

/// Name + logo of the active workspace for chrome that only needs to *display*
/// it (e.g. the title-bar chip).
///
/// Prefers the real workspace row, but while the workspace list is still
/// loading on a cold start it falls back to the last-active workspace cached in
/// shared_preferences by [workspaceDisplayCacheProvider]. That fallback is what
/// stops the chip from showing "no workspace" for the couple of seconds the
/// database takes to open. Returns null only once the list has loaded with no
/// active workspace (or on a first-ever run with nothing cached).
final activeWorkspaceDisplayProvider = Provider<WorkspaceDisplay?>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  if (active != null) {
    return (name: active.name, logoPath: active.logoPath);
  }

  // No real row yet. Once the list has loaded there genuinely is no active
  // workspace; before that, fall back to the cached display.
  if (ref.watch(workspacesProvider).hasValue) {
    return null;
  }

  final prefs = ref.watch(appPreferencesProvider);
  final name = prefs.getString(_activeWorkspaceNameKey);
  if (name == null) {
    return null;
  }
  return (name: name, logoPath: prefs.getString(_activeWorkspaceLogoKey));
});

/// Write-through cache that persists the active workspace's display info
/// (id + name + logo) to shared_preferences whenever it resolves, so
/// [activeWorkspaceDisplayProvider] can render it instantly on the next cold
/// start. Reacts to the resolved row rather than the act of switching, so it
/// covers every selection path — explicit switch, post-create, and the
/// auto-select-first-workspace fallback. Kept alive from `main.dart`.
class WorkspaceDisplayCacheNotifier extends Notifier<void> {
  @override
  void build() {
    ref.listen<Workspace?>(activeWorkspaceProvider, (_, next) {
      final prefs = ref.read(appPreferencesProvider);
      if (next == null) {
        // Only clear once the list has actually loaded and is empty; a null
        // seen mid-load must not wipe the cache the chip depends on.
        final loaded = ref.read(workspacesProvider).value;
        if (loaded != null && loaded.isEmpty) {
          unawaited(prefs.remove(activeWorkspaceIdPrefKey));
          unawaited(prefs.remove(_activeWorkspaceNameKey));
          unawaited(prefs.remove(_activeWorkspaceLogoKey));
        }
        return;
      }
      unawaited(prefs.setString(activeWorkspaceIdPrefKey, next.id));
      unawaited(prefs.setString(_activeWorkspaceNameKey, next.name));
      final logo = next.logoPath;
      if (logo != null && logo.isNotEmpty) {
        unawaited(prefs.setString(_activeWorkspaceLogoKey, logo));
      } else {
        unawaited(prefs.remove(_activeWorkspaceLogoKey));
      }
    }, fireImmediately: true);
  }
}

/// Keeps the workspace display-cache writer alive across the app lifetime.
final workspaceDisplayCacheProvider =
    NotifierProvider<WorkspaceDisplayCacheNotifier, void>(
      WorkspaceDisplayCacheNotifier.new,
    );

/// Tracks the id of the repo currently scoped within the active workspace.
///
/// Falls back to the first linked repo, or null if the workspace has none.
class ActiveRepoIdNotifier extends Notifier<String?> {
  String? _cachedStoredId;

  @override
  String? build() {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }

    final prefs = ref.watch(appPreferencesProvider);
    _cachedStoredId = prefs.getString('$_activeRepoIdKeyPrefix$workspaceId');
    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
    if (repos.isEmpty) {
      return null;
    }

    if (_cachedStoredId != null && repos.any((r) => r.id == _cachedStoredId)) {
      return _cachedStoredId;
    }
    return repos.first.id;
  }

  /// Sets the active repo for the current workspace and persists it.
  Future<void> setActive(String repoId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }

    // Flip in-memory state FIRST, before the (slow) shared_preferences write.
    // Callers like openPrInRepo() / the command palette do NOT await this before
    // navigating, so persisting first left a window where the PR detail screen
    // had already built but readers still saw the PREVIOUS active repo — long
    // enough for the PR-review surface to resolve against the wrong repo and
    // 404 a cross-repo PR. The synchronous portion of this method (up to the
    // first await) now runs before the caller's `go()`, so the detail's first
    // build sees the right repo. The write is best-effort after the flip.
    // Mirrors [ActiveWorkspaceIdNotifier.setActive].
    _cachedStoredId = repoId;
    state = repoId;
    await ref
        .read(appPreferencesProvider)
        .setString('$_activeRepoIdKeyPrefix$workspaceId', repoId);
  }
}

/// Active repo id within the active workspace (persisted across restarts).
final activeRepoIdProvider = NotifierProvider<ActiveRepoIdNotifier, String?>(
  ActiveRepoIdNotifier.new,
);

/// The currently active [Repo] in the active workspace, or `null`.
final activeRepoProvider = Provider<Repo?>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }

  final repoId = ref.watch(activeRepoIdProvider);
  if (repoId == null) {
    return null;
  }

  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  for (final r in repos) {
    if (r.id == repoId) {
      return r;
    }
  }
  return null;
});

/// Manages workspace creation state and side effects.
class CreateWorkspaceNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// Creates a workspace and returns its id when successful.
  Future<String?> create({required String name, String? logoPath}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(workspaceRepositoryProvider);
      final eventBus = ref.read(domainEventBusProvider);
      final filesystem = ref.read(workspaceFilesystemPortProvider);
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        eventBus: eventBus,
        filesystem: filesystem,
      );
      final workspace = await useCase.execute(
        CreateWorkspaceCommand(name: name, logoPath: logoPath),
      );
      // Pre-seed the active id so workspace-scoped providers resolve before the
      // navigation lands, then enter the new workspace. The URL is the source
      // of truth, so we must move there or the route sync would revert the id.
      await ref
          .read(activeWorkspaceIdProvider.notifier)
          .setActive(workspace.id);
      // Navigate via the root navigator's context rather than `routerProvider`
      // so this core provider file does not import `app_router.dart` (which
      // transitively imports the screens that import this file — an import
      // cycle that breaks top-level provider initialization on web/DDC).
      rootNavigatorKey.currentContext?.go(dashboardRoute(workspace.id));
      state = AsyncData(workspace.id);
      return workspace.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

/// Provider that exposes [CreateWorkspaceNotifier] to the UI.
final createWorkspaceProvider =
    NotifierProvider<CreateWorkspaceNotifier, AsyncValue<String?>>(
      CreateWorkspaceNotifier.new,
    );
