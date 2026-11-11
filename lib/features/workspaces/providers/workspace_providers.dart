import 'dart:async';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preference key (qualified by the session's [SessionScope]) for the
/// workspace this server and user last had open: the cold-start landing hint.
/// The pre-scope `active_workspace_id` key is ignored, so the first launch
/// after upgrading lands from the live list.
const String activeWorkspaceIdPrefKey = 'active_workspace_id';
const String _activeWorkspaceNameKey = 'active_workspace_name';
const String _activeWorkspaceHasLogoKey = 'active_workspace_has_logo';
const String _activeRepoIdKeyPrefix = 'active_repo_id:';

/// Watches all workspaces ordered by updated time.
final workspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll();
});

/// Mirrors the workspace of the current route for readers without a route
/// context (the shell, overlays, notification mapping, the RPC client).
///
/// The route is the source of truth: `workspaceUrlSyncProvider` pushes the
/// route's `:workspaceId` here, and nothing derives a different id. Until the
/// router resolves, [build] exposes the workspace this server and user last
/// had open (scoped by [SessionScope]) so workspace-scoped providers can start
/// and the splash redirect has a landing hint; [landingWorkspaceIdFor] checks
/// that hint against the live list.
class ActiveWorkspaceIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final scope = ref.watch(sessionScopeProvider);
    if (scope == null) {
      return null;
    }
    return ref
        .watch(appPreferencesProvider)
        .getString(scope.key(activeWorkspaceIdPrefKey));
  }

  /// Adopts [id] and remembers it for the next cold start of this session's
  /// server and user.
  ///
  /// Callers: the route sync, and a flow that picks the workspace it is about
  /// to navigate into (onboarding creating one mid-flow). The in-memory flip
  /// comes first: persisting first left a window where the route had already
  /// changed but readers still saw the previous id — long enough for a
  /// mutation to write to the wrong workspace.
  Future<void> setActive(String id) async {
    state = id;
    final scope = ref.read(sessionScopeProvider);
    if (scope != null) {
      await ref
          .read(appPreferencesProvider)
          .setString(scope.key(activeWorkspaceIdPrefKey), id);
    }
  }

  /// Drops a remembered id the connected server does not know.
  ///
  /// Reconciling only the in-memory value left the WRONG id persisted, and the
  /// cold-start hint re-reads it — so against a server that no longer has it
  /// the router landed on `/workspaces/<dead-id>/…` on every launch and every
  /// workspace-scoped provider opened a subscription the server refused.
  Future<void> forget() async {
    state = null;
    final scope = ref.read(sessionScopeProvider);
    if (scope != null) {
      await ref
          .read(appPreferencesProvider)
          .remove(scope.key(activeWorkspaceIdPrefKey));
    }
  }
}

/// Active workspace id: the route's workspace (see [ActiveWorkspaceIdNotifier]).
final activeWorkspaceIdProvider =
    NotifierProvider<ActiveWorkspaceIdNotifier, String?>(
      ActiveWorkspaceIdNotifier.new,
    );

/// The workspace a landing (the splash redirect, a dead route) enters.
///
/// The [remembered] hint while the [workspaces] list has not loaded; once it
/// has, the hint if this server still has it, else the first workspace in the
/// operator's order, else null (the picker).
String? landingWorkspaceIdFor({
  required String? remembered,
  required List<Workspace>? workspaces,
}) {
  if (workspaces == null) {
    return remembered;
  }
  if (remembered != null && workspaces.any((w) => w.id == remembered)) {
    return remembered;
  }
  return workspaces.firstOrNull?.id;
}

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

/// Lightweight display info (name + id + has-logo) for the active workspace.
typedef WorkspaceDisplay = ({String name, String workspaceId, bool hasLogo});

/// Name + logo of the active workspace for chrome that only needs to *display*
/// it (e.g. the title-bar chip).
///
/// Prefers the real workspace row, but while the workspace list is still
/// loading on a cold start it falls back to the display cached for this
/// server and user by [workspaceDisplayCacheProvider]. That fallback is what
/// stops the chip from showing "no workspace" while the list loads. Returns
/// null once the list has loaded with no active workspace (or with nothing
/// cached for this session).
final activeWorkspaceDisplayProvider = Provider<WorkspaceDisplay?>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  if (active != null) {
    return (name: active.name, workspaceId: active.id, hasLogo: active.hasLogo);
  }

  // No real row yet. Once the list has loaded there genuinely is no active
  // workspace; before that, fall back to the cached display.
  if (ref.watch(workspacesProvider).hasValue) {
    return null;
  }

  final scope = ref.watch(sessionScopeProvider);
  final id = ref.watch(activeWorkspaceIdProvider);
  if (scope == null || id == null) {
    return null;
  }
  final prefs = ref.watch(appPreferencesProvider);
  final name = prefs.getString(scope.key(_activeWorkspaceNameKey));
  if (name == null) {
    return null;
  }
  return (
    name: name,
    workspaceId: id,
    hasLogo: prefs.getBool(scope.key(_activeWorkspaceHasLogoKey)) ?? false,
  );
});

/// Write-through cache that persists the active workspace's display info
/// (name + logo) for this server and user whenever it resolves, so
/// [activeWorkspaceDisplayProvider] can render it instantly on the next cold
/// start. The id itself is remembered by [ActiveWorkspaceIdNotifier]. Reacts to
/// the resolved row rather than the act of switching, so it covers every
/// selection path. Kept alive from `ControlCenterApp`, which is also what
/// guarantees [activeWorkspaceProvider] always has one never-paused listener
/// (see the comment at that `ref.watch`).
class WorkspaceDisplayCacheNotifier extends Notifier<void> {
  @override
  void build() {
    ref.listen<Workspace?>(activeWorkspaceProvider, (_, next) {
      final scope = ref.read(sessionScopeProvider);
      if (scope == null) {
        return;
      }
      final prefs = ref.read(appPreferencesProvider);
      final nameKey = scope.key(_activeWorkspaceNameKey);
      final logoKey = scope.key(_activeWorkspaceHasLogoKey);
      if (next == null) {
        // Only clear once the list has actually loaded and is empty; a null
        // seen mid-load must not wipe the cache the chip depends on.
        final loaded = ref.read(workspacesProvider).value;
        if (loaded != null && loaded.isEmpty) {
          unawaited(prefs.remove(nameKey));
          unawaited(prefs.remove(logoKey));
        }
        return;
      }
      unawaited(prefs.setString(nameKey, next.name));
      unawaited(prefs.setBool(logoKey, value: next.hasLogo));
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

  /// Picks [repoId] as [workspaceId]'s active repo before navigating there.
  ///
  /// For a caller that is about to enter [workspaceId] (a deep link): the
  /// workspace becomes active only once the route says so, and this
  /// notifier re-reads the stored choice for it then. The preference write
  /// is synchronous, so the first frame of the new route already sees it.
  Future<void> setActiveFor(String workspaceId, String repoId) async {
    if (workspaceId == ref.read(activeWorkspaceIdProvider)) {
      return setActive(repoId);
    }
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

  /// Creates a workspace and returns its id when successful. A picked logo
  /// travels as [logoBytes] with its [logoExtension] (`.png`): a path would
  /// name a file on this machine, and the server reads server paths only for
  /// its owner.
  Future<String?> create({
    required String name,
    Uint8List? logoBytes,
    String logoExtension = '',
  }) async {
    state = const AsyncLoading();
    try {
      final workspace = await RpcWorkspaceRepository(
        ref.read(rpcClientProvider),
      ).create(name: name);
      if (logoBytes != null && logoBytes.isNotEmpty) {
        final filesystem = ref.read(workspaceFilesystemPortProvider);
        String? persistedLogo;
        try {
          persistedLogo = await filesystem.persistLogoBytes(
            workspace.id,
            logoBytes,
            logoExtension,
          );
        } on Exception {
          persistedLogo = null;
        }
        if (persistedLogo != null) {
          await ref
              .read(workspaceRepositoryProvider)
              .upsert(
                workspace.copyWith(
                  logoPath: persistedLogo,
                  updatedAt: DateTime.now(),
                ),
              );
        }
      }
      // Pre-seed the active id so workspace-scoped providers resolve against
      // the new workspace immediately. NAVIGATION is the caller's business —
      // this provider file must not change the route: onboarding's workspace
      // step creates the workspace mid-flow and still has steps to show
      // (sandbox, adapter, model downloads); navigating here ripped the user
      // straight to the inbox and skipped them. The onboarding screen lands
      // on the new workspace's inbox itself at finish (via the active id),
      // and the picker/chip call sites navigate explicitly.
      await ref
          .read(activeWorkspaceIdProvider.notifier)
          .setActive(workspace.id);
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
