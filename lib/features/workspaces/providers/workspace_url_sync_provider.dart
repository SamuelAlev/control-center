import 'dart:async';

import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Writes [activeWorkspaceIdProvider] from the route `:workspaceId` (URL SoT).
///
/// Write-only (never watch) to avoid `rpcClient → activeWorkspaceId` cycles.
/// Listen to GoRouter's delegate; defer writes to a microtask — delegate
/// notifies synchronously during build. Own file: depends on `routerProvider`;
/// putting it in `workspace_providers.dart` cycles with the router and on web
/// DDC left the provider `null` at first watch.
final workspaceUrlSyncProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);

  // Deferring the sync (below) means a queued microtask can outlive this
  // provider (e.g. a rebuild when `routerProvider` changes). Guard against
  // touching `ref` after disposal so a late microtask is a no-op, not a
  // "ref used after dispose" crash.
  var disposed = false;

  void sync() {
    if (disposed) {
      return;
    }
    String? id;
    try {
      id = router.state.pathParameters['workspaceId'];
    } on Object {
      // The router has no resolved match yet (e.g. a deep link still being
      // restored). Nothing to sync; the next notification will retry.
      return;
    }
    // Leave the active id untouched on routes with no workspace context
    // (splash, onboarding, the picker), so it is remembered on re-entry.
    if (id != null && id != ref.read(activeWorkspaceIdProvider)) {
      ref.read(activeWorkspaceIdProvider.notifier).setActive(id);
      // Regression guard: `setActive` flips state synchronously (before its
      // async persist), so the mirror MUST now equal the route. The route is
      // the single source of truth — workspace-scoped *writes* read it directly
      // (`context.currentWorkspaceId`); this provider only mirrors it for the
      // non-widget / shell / overlay readers that have no route context. If a
      // future change makes the mirror lag the route again, this trips in debug
      // (and in tests) instead of letting those readers silently see — and
      // write to — the previous workspace.
      assert(
        ref.read(activeWorkspaceIdProvider) == id,
        'activeWorkspaceIdProvider did not adopt route workspace "$id" '
        'synchronously — the route→mirror sync is lagging again.',
      );
    }
  }

  // GoRouter fires delegate listeners synchronously during the Router widget's
  // build (`setInitialRoutePath` → `notifyListeners`), so calling `sync`
  // directly would mutate `activeWorkspaceIdProvider` mid-build. Schedule it in
  // a microtask instead: the write lands off the build frame, while `setActive`
  // still flips state synchronously *within* the microtask, so `sync`'s
  // regression assert holds. The closure is captured so `removeListener`
  // detaches the exact same reference on dispose. (Redundant notifications
  // schedule cheap no-op syncs — `sync` is idempotent via its `id !=` guard.)
  void scheduleSync() => Future.microtask(sync);

  router.routerDelegate.addListener(scheduleSync);
  ref.onDispose(() {
    disposed = true;
    router.routerDelegate.removeListener(scheduleSync);
  });
  // Initial sync, likewise deferred past the current build frame.
  Future.microtask(sync);
});
