import 'dart:async';

import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Emits the current [GoRouterState] and re-emits on every navigation.
///
/// Bridges `GoRouter` (a `Listenable`) into Riverpod by invalidating itself on
/// each notification. Replaces the old "publish breadcrumbs from build()"
/// pattern: the router is the source of truth, no screen pushes state.
///
/// The invalidation is deferred to a microtask because `GoRouterDelegate` can
/// dispatch notifications synchronously during the build phase (e.g. initial
/// route restoration via `setInitialRoutePath`). Calling `ref.invalidateSelf()`
/// inline would schedule a provider refresh -> `setState` while the framework
/// is already building, which throws "setState/markNeedsBuild called during
/// build".
final currentRouteMatchProvider = Provider<GoRouterState>((ref) {
  final router = ref.watch(routerProvider);
  bool scheduled = false;
  void listener() {
    if (scheduled) {
      return;
    }
    scheduled = true;
    scheduleMicrotask(() {
      scheduled = false;
      if (!ref.mounted) {
        return;
      }
      ref.invalidateSelf();
    });
  }

  router.routerDelegate.addListener(listener);
  ref.onDispose(() => router.routerDelegate.removeListener(listener));
  return router.state;
});
