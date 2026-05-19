import 'package:control_center/features/shell/breadcrumbs/current_route_match_provider.dart';
import 'package:control_center/features/shell/route_titles/route_title_registry.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Owns the browser/tab title for the active page.
///
/// Mounted once in `MaterialApp.router`'s `builder` so every page flows through
/// it. It watches [currentRouteMatchProvider] (which re-emits on each
/// navigation) and rebuilds a [Title] with the resolved page label, instead of
/// the static `MaterialApp.title` that every page would otherwise share. The
/// label comes from [routeTitleFor]; a page without an entry falls back to the
/// bare app name so the tab is never blank.
///
/// `Title.color` is required and feeds the Android task switcher; it is opaque
/// (the surface color) and ignored on web.
class RouteTitle extends ConsumerWidget {
  /// Creates a [RouteTitle].
  const RouteTitle({super.key, required this.child});

  /// The active page subtree.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoRouterState routeState;
    try {
      routeState = ref.watch(currentRouteMatchProvider);
    } catch (_) {
      // Router not ready yet (e.g. the very first frame) — keep the app name.
      return _TitleBox(
        title: kAppTitle,
        color: Theme.of(context).colorScheme.surface,
        child: child,
      );
    }
    final l10n = AppLocalizations.of(context);
    final title = routeTitleFor(ref, routeState, l10n);
    return _TitleBox(
      title: title,
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}

class _TitleBox extends StatelessWidget {
  const _TitleBox({
    required this.title,
    required this.color,
    required this.child,
  });

  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Title(title: title, color: color, child: child);
  }
}
