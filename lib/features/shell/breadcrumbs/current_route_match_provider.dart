import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Emits the current [GoRouterState] and re-emits on every navigation.
///
/// Bridges `GoRouter` (a `Listenable`) into Riverpod by invalidating itself on
/// each notification. Replaces the old "publish breadcrumbs from build()"
/// pattern: the router is the source of truth, no screen pushes state.
final currentRouteMatchProvider = Provider<GoRouterState>((ref) {
  final router = ref.watch(routerProvider);
  void listener() => ref.invalidateSelf();
  router.routerDelegate.addListener(listener);
  ref.onDispose(() => router.routerDelegate.removeListener(listener));
  return router.state;
});
