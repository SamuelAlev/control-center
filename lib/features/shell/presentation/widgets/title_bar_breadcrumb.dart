import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/features/shell/breadcrumbs/current_route_match_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Renders the title-bar breadcrumb trail by looking up the current route in
/// [breadcrumbRegistry]. The router itself is the source of truth — no screen
/// pushes state, so there's no race during navigation transitions.
class TitleBarBreadcrumb extends ConsumerWidget {
  /// Creates a [TitleBarBreadcrumb].
  const TitleBarBreadcrumb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoRouterState routeState;
    try {
      routeState = ref.watch(currentRouteMatchProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final fullPath = routeState.fullPath;
    final builder = fullPath == null ? null : breadcrumbRegistry[fullPath];
    if (builder == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final crumbs = builder(ref, context, routeState, l10n);
    if (crumbs.isEmpty) {
      return const SizedBox.shrink();
    }
    // No leading separator: the breadcrumb is the first segment in the bar, so
    // a chevron before it would point at nothing. FBreadcrumb draws its own
    // separators between items.
    return FBreadcrumb(children: crumbs);
  }
}
