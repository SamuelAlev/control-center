import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tracks the current route path for notification suppression.
///
/// Notifications are suppressed when the user is already viewing the
/// target content. This provider exposes the current location string
/// and a helper to check whether a given route prefix is active.
final currentRouteProvider = Provider<String>((ref) {
  final router = ref.watch(routerProvider);
  return router.state.uri.path;
});

/// Returns `true` when [route] matches the current location.
///
/// Uses prefix matching so `/pull-requests` matches
/// `/pull-requests/123`.
bool isRouteActive(GoRouter router, String route) {
  final current = router.state.uri.path;
  if (route == current) {
    return true;
  }
  // Prefix match: "/pull-requests" matches "/pull-requests/42".
  if (current.startsWith(route) &&
      (route.endsWith('/') ||
          current.length == route.length ||
          current[route.length] == '/')) {
    return true;
  }
  return false;
}
