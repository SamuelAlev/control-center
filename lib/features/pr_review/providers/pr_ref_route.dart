import 'package:control_center/features/pr_review/providers/pr_review_providers.dart'
    show PrRef;
import 'package:go_router/go_router.dart';

/// Builds the [PrRef] for the PR-detail route's resolved params, or null when
/// any segment is missing/unparseable. The route IS the PR identity — the
/// workspace, owner, repo and number all live in the path, so no ambient state
/// is consulted.
///
/// Deliberately its own file (the same discipline the old
/// `pr_detail_route_scope_sync_provider.dart` followed): `pr_review_providers`
/// must not import go_router, because the router transitively imports the PR
/// screens, which import the providers — a cycle that on web (DDC) can surface
/// a top-level `null` before its initializer runs.
PrRef? prRefFromRouteState(GoRouterState state) {
  final workspaceId = state.pathParameters['workspaceId'];
  final owner = state.pathParameters['owner'];
  final repo = state.pathParameters['repo'];
  final number = int.tryParse(state.pathParameters['prNumber'] ?? '');
  if (workspaceId == null ||
      owner == null ||
      repo == null ||
      owner.isEmpty ||
      repo.isEmpty ||
      number == null) {
    return null;
  }
  return (
    workspaceId: workspaceId,
    repoFullName: '$owner/$repo',
    number: number,
  );
}
