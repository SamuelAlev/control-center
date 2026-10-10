import 'dart:async';

import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The path (no query) of a router's current location, re-emitting only when
/// the path itself changes.
///
/// Keyed by the router a widget gets from `GoRouter.of(context)`: that lookup,
/// unlike `GoRouterState.of`, does not rebuild its caller on navigation. Chrome
/// that watches this, or a `.select` of it, rebuilds only where the derived
/// answer changed — the row losing the highlight and the row gaining it — not
/// the whole sidebar on every route change. A `?tab=` / `?m=` change re-runs
/// this provider and stops here, since the path is unchanged.
///
/// Invalidation is deferred to a microtask for the same reason as
/// `currentRouteMatchProvider`: the delegate can notify during the build
/// phase (initial route restoration), where a synchronous refresh would mark
/// widgets dirty mid-build.
final routerPathProvider = Provider.autoDispose.family<String, GoRouter>((
  ref,
  router,
) {
  final delegate = router.routerDelegate;
  var scheduled = false;
  void listener() {
    if (scheduled) {
      return;
    }
    scheduled = true;
    scheduleMicrotask(() {
      scheduled = false;
      if (ref.mounted) {
        ref.invalidateSelf();
      }
    });
  }

  delegate.addListener(listener);
  ref.onDispose(() => delegate.removeListener(listener));
  final configuration = delegate.currentConfiguration;
  // `router.state` reads the leaf match, which an empty configuration (before
  // the initial route resolves) does not have.
  return configuration.isEmpty ? configuration.uri.path : router.state.uri.path;
});

/// [routerPathProvider] with the `/workspaces/:workspaceId` prefix stripped:
/// `/inbox`, `/spaces/<id>`, `/settings/appearance`. See
/// [workspaceShellLogicalRoute].
final shellLogicalRouteProvider = Provider.autoDispose.family<String, GoRouter>(
  (ref, router) =>
      workspaceShellLogicalRoute(ref.watch(routerPathProvider(router))),
);

/// The `:workspaceId` the current location names, or null outside the
/// workspace shell. Changes only on a workspace switch.
final routeWorkspaceIdProvider = Provider.autoDispose.family<String?, GoRouter>(
  (ref, router) =>
      workspaceIdFromLocation(ref.watch(routerPathProvider(router))),
);

/// Identifies the router and the workspace a route space id is read against.
typedef RouteSpaceKey = ({GoRouter router, String? workspaceId});

/// The space the current location opens (`/workspaces/<ws>/spaces/<id>`), or
/// null on any other location — including a space route of a workspace other
/// than the key's `workspaceId`, so a row never reads as selected for a
/// URL that names a different workspace.
///
/// A row reads its own highlight with
/// `ref.watch(routeSpaceIdProvider(key).select((id) => id == space.id))`, so a
/// space switch rebuilds only the two rows whose answer flipped.
final routeSpaceIdProvider = Provider.autoDispose
    .family<String?, RouteSpaceKey>(
      (ref, key) => spaceIdFromLocation(
        ref.watch(routerPathProvider(key.router)),
        key.workspaceId,
      ),
    );

/// The `:workspaceId` segment of a `/workspaces/<id>/…` [path], or null.
String? workspaceIdFromLocation(String path) {
  const prefix = '/workspaces/';
  if (!path.startsWith(prefix)) {
    return null;
  }
  final rest = path.substring(prefix.length);
  final slash = rest.indexOf('/');
  final id = slash == -1 ? rest : rest.substring(0, slash);
  return id.isEmpty ? null : id;
}

/// The space id of a `/workspaces/<workspaceId>/spaces/<id>` [location], or
/// null when [location] is not a space of [workspaceId].
String? spaceIdFromLocation(String location, String? workspaceId) {
  if (workspaceId == null) {
    return null;
  }
  final prefix = '${spacesRoute(workspaceId)}/';
  if (!location.startsWith(prefix)) {
    return null;
  }
  final rest = location.substring(prefix.length);
  final slash = rest.indexOf('/');
  final id = slash == -1 ? rest : rest.substring(0, slash);
  return id.isEmpty ? null : id;
}

/// How a shell destination's logical path matches the current logical route.
enum ShellNavMatch {
  /// Only the destination itself.
  exact,

  /// The destination or anything below it (`/tickets`, `/tickets/42`), but
  /// not a sibling that merely shares the prefix (`/ticketsArchive`).
  section,

  /// Any logical route starting with the destination's path.
  prefix,
}

/// Whether [logical] (a [shellLogicalRouteProvider] value) is [path] under
/// [match].
bool shellRouteMatches(String logical, String path, ShellNavMatch match) =>
    switch (match) {
      ShellNavMatch.exact => logical == path,
      ShellNavMatch.section => logical == path || logical.startsWith('$path/'),
      ShellNavMatch.prefix => logical.startsWith(path),
    };
