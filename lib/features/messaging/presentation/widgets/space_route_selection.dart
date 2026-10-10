/// How the sidebar's space rows read the open space from the route and
/// navigate to one, without depending on `GoRouterState`. Split out of
/// `space_sidebar_item.dart` (which re-exports it) to keep that file inside
/// the presentation size budget.
library;

import 'package:control_center/features/shell/providers/shell_route_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Extracts the selected space id from the current [location] path, or null
/// when not on a `/workspaces/<ws>/spaces/<id>` location. Parses the location
/// rather than `pathParameters` because the sidebar sits in the shell, above
/// the space route, so its `:spaceId` is not in `GoRouterState` scope here.
String? selectedSpaceIdFromLocation(String location, String? workspaceId) =>
    spaceIdFromLocation(location, workspaceId);

/// Whether [spaceId] is the space the current route opens.
///
/// The URL is the source of truth for the open space. A `.select` over the
/// router-derived [routeSpaceIdProvider] rather than a `GoRouterState` read,
/// so the caller rebuilds only when ITS answer flips: a space switch repaints
/// the row being left and the row being opened, and a `?tab=` change none.
bool watchRouteSpaceSelected(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return ref.watch(
    routeSpaceIdProvider((
      router: GoRouter.of(context),
      workspaceId: workspaceId,
    )).select((id) => id == spaceId),
  );
}

/// The `:workspaceId` of the current route, read through the router.
///
/// For press handlers in the shell: unlike `context.currentWorkspaceId`
/// (a `GoRouterState` lookup), it registers no dependency on the route, so a
/// handler that ran once does not leave its widget rebuilding on every later
/// navigation.
String? routeWorkspaceIdOf(BuildContext context) => workspaceIdFromLocation(
  GoRouter.of(context).routeInformationProvider.value.uri.path,
);

/// Navigates to [spaceId] in the workspace the current route names. Navigate
/// only — the messaging screen mirrors the URL into the selection provider,
/// keeping the URL the single source of truth.
void openSpaceFromSidebar(BuildContext context, String spaceId) {
  final workspaceId = routeWorkspaceIdOf(context);
  if (workspaceId != null) {
    GoRouter.of(context).go(spaceRoute(workspaceId, spaceId));
  }
}
