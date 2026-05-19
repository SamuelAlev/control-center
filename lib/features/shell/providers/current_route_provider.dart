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
///
/// Both sides are compared as *paths only*. A notification route may carry a
/// deep-link query (`…/spaces/<id>?m=<messageId>` for a message permalink),
/// while the current location is read as a bare path — comparing the raw
/// strings made every such notification look off-route and defeated the
/// "already viewing this" suppression.
bool isRouteActive(GoRouter router, String route) {
  final target = Uri.parse(route).path;
  final current = router.state.uri.path;
  if (target == current) {
    return true;
  }
  // Prefix match: "/pull-requests" matches "/pull-requests/42".
  if (current.startsWith(target) &&
      (target.endsWith('/') ||
          current.length == target.length ||
          current[target.length] == '/')) {
    return true;
  }
  return false;
}
