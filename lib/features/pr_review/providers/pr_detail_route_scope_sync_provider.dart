import 'dart:async';

import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suffix of the PR-detail route's `fullPath` pattern
/// (`…/pull-requests/:owner/:repo/:prNumber`) — the placeholder pattern, not
/// concrete values, exactly as keyed in `route_title_registry.dart` /
/// `breadcrumb_registry.dart`. Only the PR-detail route ends this way.
const _prDetailPathSuffix = '/:owner/:repo/:prNumber';

/// Derives the PR-detail repo scope from a route's `fullPath` pattern and its
/// resolved [pathParameters], or null on any non-PR-detail route. Pure so it is
/// unit-testable without a live router.
PrDetailRepoScope? prDetailScopeFromRoute(
  String? fullPath,
  Map<String, String> pathParameters,
) {
  if (fullPath == null || !fullPath.endsWith(_prDetailPathSuffix)) {
    return null;
  }
  final owner = pathParameters['owner'];
  final repo = pathParameters['repo'];
  if (owner == null || owner.isEmpty || repo == null || repo.isEmpty) {
    return null;
  }
  return (owner: owner, repo: repo);
}

/// Drives [prDetailRepoScopeProvider] from the current route, making the URL the
/// single source of truth for which PR (and therefore which repo) the detail
/// surface is scoped to — the same pattern `workspaceUrlSyncProvider` uses for
/// the active workspace. Kept alive for the app's lifetime by `ControlCenterApp`.
///
/// This replaces the old `initState`-pin on `PullRequestDetailScreen`: go_router
/// reuses one screen State across PR→PR navigations (the page key is the route
/// *pattern*, not the resolved params), so `initState` did not re-run on a hop
/// and the pinned scope went stale — the number-keyed PR-review streams then
/// re-subscribed against the WRONG repo and flooded the GitHub API. Syncing off
/// the live route re-scopes every hop (same-repo, cross-repo, even the same PR
/// number in a different repo) with no staleness.
///
/// **Why its own file** (mirrors `workspace_url_sync_provider.dart`): it is the
/// one PR-review provider that depends on `routerProvider`, and `app_router.dart`
/// transitively imports the PR screens — which import `pr_review_providers.dart`.
/// Defining this there would fold that core provider file into an import cycle
/// with the router; on the web (DDC) a top-level `final` in a cyclic library can
/// be observed as `null` before its initializer runs. Keeping it here — a sink
/// imported only by `ControlCenterApp` — stays out of that cycle: it touches the
/// PR-review providers only at runtime (the scope write plus the inert
/// keep-active listener below), never as a top-level `watch`.
final prDetailRouteScopeSyncProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);

  // Keep the chain derived from the scope ACTIVE for the app's lifetime.
  //
  // riverpod's scheduler settles an invalidated provider off-frame only while it
  // still has a listener (`_performRefresh` → `if (element.isActive)`), and every
  // subscriber of this chain is an autoDispose, PR-number-keyed stream that dies
  // with the detail route. So a scope write left `prDetailRepoProvider` /
  // `prScopedReviewRepositoryProvider` invalidated-but-inactive: nothing settled
  // them, their dependents were only lazily marked, and the FIRST read rebuilt
  // them — which lands inside `RouteTitle`'s build (it sits above the router in
  // `MaterialApp.router`'s builder, so the tab title mounts `prDetailProvider`
  // before the screen does). A provider rebuilding mid-build notifies its OTHER
  // dependents (`currentPrRepoProvider`, `prReviewRepositoryProvider`), whose
  // `invalidateSelf` → `scheduleProviderRefresh` → `setState` on the
  // `UncontrolledProviderScope` the framework is already building:
  // "setState() or markNeedsBuild() called during build".
  //
  // One inert listener defuses that: the chain now refreshes inside the
  // scheduler's own task, which IS re-entrancy-safe (a cascade there queues onto
  // `stateToRefresh` instead of calling `setState`). Cheap by construction —
  // resolving the repository is a pure value construction with no I/O until a
  // stream is watched, and it short-circuits to null on every non-PR route
  // (so it never touches the RPC client outside the PR surface).
  ref.listen(prScopedReviewRepositoryProvider, (_, _) {});

  // The sync is deferred to a microtask (below), so a queued microtask can
  // outlive this provider (a rebuild when `routerProvider` changes). Guard
  // against touching `ref` after disposal so a late microtask is a no-op.
  var disposed = false;

  void sync() {
    if (disposed) {
      return;
    }
    final PrDetailRepoScope? scope;
    try {
      scope = prDetailScopeFromRoute(
        router.state.fullPath,
        router.state.pathParameters,
      );
    } on Object {
      // No resolved match yet (e.g. a deep link still being restored). The
      // next notification retries; leave the scope as-is.
      return;
    }
    ref.read(prDetailRepoScopeProvider.notifier).set(scope);
  }

  // GoRouter fires delegate listeners synchronously during the Router widget's
  // build (`setInitialRoutePath` → `notifyListeners`), so writing the scope
  // inline would mutate a provider mid-build. Defer to a microtask: the write
  // lands off the build frame. (Redundant notifications schedule cheap no-op
  // syncs — `set` is idempotent via its `state == scope` guard.)
  void scheduleSync() => Future.microtask(sync);

  router.routerDelegate.addListener(scheduleSync);
  ref.onDispose(() {
    disposed = true;
    router.routerDelegate.removeListener(scheduleSync);
  });
  // Initial sync, likewise deferred past the current build frame.
  Future.microtask(sync);
});
